import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_logger.dart';
import 'package:marktext_plus/services/plugin_proxy.dart';

/// The way out to the network for anything a plugin renders itself.
///
/// A web view fetches whatever its page asks for, and the three desktop
/// platforms each intercept that differently — WebView2 has an event,
/// WKWebView wants a scheme handler, WebKitGTK emits a signal. A local proxy
/// is the one mechanism all three already speak, and it is what makes the
/// promise to the reader keepable: their system proxy is followed, and they
/// can afterwards see which servers a plugin talked to.
void main() {
  late Directory root;
  late PluginLogger logger;
  late PluginProxy proxy;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('plugin_proxy_');
    logger = PluginLogger('com.example.demo', '${root.path}/logs');
    proxy = PluginProxy(logger: logger);
  });

  tearDown(() async {
    await proxy.stop();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  Future<String> log() => File(logger.path).readAsString();

  test('a plain request is forwarded and its host written down', () async {
    final origin = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => origin.close(force: true));
    origin.listen((request) {
      request.response
        ..headers.contentType = ContentType.text
        ..write('hello from the origin')
        ..close();
    });

    final port = await proxy.start();
    final client = HttpClient()
      ..findProxy = (_) => 'PROXY 127.0.0.1:$port';
    addTearDown(() => client.close(force: true));

    final response = await (await client.getUrl(
      Uri.parse('http://127.0.0.1:${origin.port}/thing'),
    ))
        .close();
    expect(response.statusCode, 200);
    expect(await utf8.decoder.bind(response).join(), 'hello from the origin');

    final written = await log();
    expect(written, contains('webview GET http://127.0.0.1'),
        reason: '读者要能查出插件的页面访问了哪台服务器');
    expect(written, contains('200'));
    expect(written, isNot(contains('/thing')),
        reason: '只记到主机：查询串和路径可能带着页面送出去的东西');
  });

  test('a CONNECT tunnel is opened and its size written down', () async {
    // Not a TLS server: the proxy's job with CONNECT is to move bytes without
    // looking at them, so anything that echoes is enough to prove it.
    final origin = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => origin.close());
    origin.listen((socket) {
      socket.listen((chunk) => socket.add(chunk), onDone: socket.close);
    });

    final port = await proxy.start();
    final client = await Socket.connect(InternetAddress.loopbackIPv4, port);
    client.write('CONNECT 127.0.0.1:${origin.port} HTTP/1.1\r\n\r\n');

    final replies = <int>[];
    final done = client.listen(replies.addAll).asFuture<void>();

    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(String.fromCharCodes(replies), contains('200'),
        reason: '隧道该先应答再转发');

    client.write('ping through the tunnel');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(String.fromCharCodes(replies), contains('ping through the tunnel'),
        reason: 'CONNECT 之后代理只搬字节，不看内容');

    await client.close();
    await done.timeout(const Duration(seconds: 2), onTimeout: () {});
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final written = await log();
    expect(written, contains('webview CONNECT 127.0.0.1'));
    expect(written, contains('B↑'), reason: '记得下字节数，内容记不下也不该记');
  });

  test('a request to nowhere is written down as a failure', () async {
    final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final dead = closed.port;
    await closed.close();

    final port = await proxy.start();
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    client.findProxy = (_) => 'PROXY 127.0.0.1:$port';
    addTearDown(() => client.close(force: true));

    await expectLater(
      client
          .getUrl(Uri.parse('http://127.0.0.1:$dead/'))
          .then((request) => request.close()),
      throwsA(anything),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(await log(), contains('failed'),
        reason: '失败也要留下痕迹，否则日志只证明成功的那些');
  });

  test('it listens on loopback only', () async {
    // A proxy reachable from the network would be an open relay running
    // inside somebody's text editor. Checked by asking where it bound rather
    // than by trying to reach it from elsewhere: on this machine 0.0.0.0
    // resolves to the loopback anyway, so that test would have passed either
    // way and measured nothing.
    await proxy.start();
    expect(proxy.address?.address, '127.0.0.1');
    expect(proxy.address?.isLoopback, isTrue);
  });
}

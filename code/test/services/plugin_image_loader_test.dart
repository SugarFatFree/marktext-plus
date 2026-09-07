import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_image_loader.dart';
import 'package:marktext_plus/services/plugin_logger.dart';

/// Where a plugin's pictures come from, and what the reader can find out.
///
/// A plugin may reach the network — that is what `network.request` grants —
/// and the point of fetching through the editor rather than letting the
/// plugin do it is that the reader can afterwards see where it went. A
/// permission that cannot be observed is a promise.
void main() {
  late Directory root;
  late PluginImageLoader loader;
  late PluginLogger logger;

  /// A loader for a plugin that holds [allowNetwork].
  PluginImageLoader loaderWith({required bool allowNetwork}) =>
      PluginImageLoader(
        pluginDirectory: '${root.path}/plugin',
        logger: logger,
        allowNetwork: allowNetwork,
        maxBytes: 1024,
      );

  setUp(() {
    root = Directory.systemTemp.createTempSync('plugin_images_');
    Directory('${root.path}/plugin').createSync();
    logger = PluginLogger('com.example.demo', '${root.path}/logs');
    loader = loaderWith(allowNetwork: true);
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('a data URI is decoded without leaving the machine', () async {
    final bytes = await loader.load(
      'data:image/png;base64,${base64Encode([1, 2, 3, 4])}',
    );
    expect(bytes, [1, 2, 3, 4]);
  });

  test('a relative path is read from the plugin directory', () async {
    File('${root.path}/plugin/logo.png').writeAsBytesSync([9, 9, 9]);
    expect(await loader.load('logo.png'), [9, 9, 9]);
  });

  test('a path may not leave the plugin directory', () async {
    File('${root.path}/secret.txt').writeAsBytesSync([1]);
    await expectLater(
      loader.load('../secret.txt'),
      throwsA(isA<PluginImageException>()),
      reason: '插件的图片是它自己的；读别处的文件是 workspace.read 的事',
    );
  });

  test('an absolute path is refused', () async {
    await expectLater(
      loader.load('/etc/hostname'),
      throwsA(isA<PluginImageException>()),
    );
  });

  test('a picture larger than the limit is refused', () async {
    File('${root.path}/plugin/big.png').writeAsBytesSync(List.filled(2048, 7));
    await expectLater(
      loader.load('big.png'),
      throwsA(isA<PluginImageException>()),
    );
  });

  test('a fetch is written to the plugin log', () async {
    // Served from this machine, so the test needs nothing outside it.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) {
      request.response
        ..add([1, 2, 3])
        ..close();
    });

    final bytes = await loader.load('http://127.0.0.1:${server.port}/pic.png');
    expect(bytes, [1, 2, 3]);

    final log = await File(logger.path).readAsString();
    expect(log, contains('image http://127.0.0.1'),
        reason: '读者要能查出插件访问了哪里');
    expect(log, contains('200'));
    expect(log, isNot(contains('/pic.png')),
        reason: '只记到主机名：查询串可能带着插件送出去的东西，'
            '日志不该变成文档的第二份副本');
  });

  test('an http source is refused when the plugin has no network permission',
      () async {
    // Reached by this test rather than by the network: if the check is
    // missing, the request goes out and the server answers, so the failure
    // says "expected a throw" instead of quietly passing on a timeout.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var asked = false;
    server.listen((request) {
      asked = true;
      request.response
        ..add([1, 2, 3])
        ..close();
    });

    await expectLater(
      loaderWith(allowNetwork: false)
          .load('http://127.0.0.1:${server.port}/pic.png'),
      throwsA(isA<PluginImageException>()),
      reason: '没申请 network.request 的插件，不能靠一个 image 节点把宿主'
          '当成它的出站通道',
    );
    // The point is not only the exception: an editor that throws after the
    // request has already left has not stopped anything. A URL can carry the
    // document in its query string.
    expect(asked, isFalse, reason: '请求根本不该发出去');
  });

  test('a refused fetch is written to the log', () async {
    // A reachable server, deliberately. Pointed at a host that is merely
    // unreachable, this test passes whether the fetch was refused or simply
    // failed to connect — and those are the two hypotheses it exists to tell
    // apart.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) => request.response.close());

    await expectLater(
      loaderWith(allowNetwork: false)
          .load('http://127.0.0.1:${server.port}/pic.png'),
      throwsA(isA<PluginImageException>()),
    );
    final log = await File(logger.path).readAsString();
    expect(log, contains('refused'),
        reason: '插件试图出站这件事本身，读者应该看得到——'
            '被挡住的尝试和成功的请求一样值得记');
    expect(log, contains('127.0.0.1'));
  });

  test('a failed fetch is written to the log too', () async {
    // Nothing is listening on this port.
    final closed = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = closed.port;
    await closed.close();

    await expectLater(
      loader.load('http://127.0.0.1:$port/pic.png'),
      throwsA(isA<PluginImageException>()),
    );
    expect(await File(logger.path).readAsString(), contains('failed'));
  });
}

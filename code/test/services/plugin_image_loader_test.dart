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

  setUp(() {
    root = Directory.systemTemp.createTempSync('plugin_images_');
    Directory('${root.path}/plugin').createSync();
    logger = PluginLogger('com.example.demo', '${root.path}/logs');
    loader = PluginImageLoader(
      pluginDirectory: '${root.path}/plugin',
      logger: logger,
      maxBytes: 1024,
    );
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

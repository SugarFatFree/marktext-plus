import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_logger.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_webview.dart';

/// The web view a plugin may draw its own page in, and the way out it gets.
///
/// The rules are tested without opening a window: a window needs a desktop,
/// and it is the rules that are worth pinning. What is *not* tested here is
/// that a window appears at all — that needs a real machine, and on Linux it
/// needs libwebkit2gtk to be installed.
void main() {
  late Directory root;
  late PluginLogger logger;

  PluginManifest manifest(List<String> permissions) => PluginManifest.fromJson({
        'id': 'com.example.demo',
        'name': 'Demo',
        'version': '1.0.0',
        'runtime': 'lua',
        'entrypoint': 'plugin.lua',
        'permissions': permissions,
      });

  setUp(() {
    root = Directory.systemTemp.createTempSync('plugin_webview_');
    Directory('${root.path}/plugin').createSync();
    File('${root.path}/plugin/page.html').writeAsStringSync('<h1>hi</h1>');
    logger = PluginLogger('com.example.demo', '${root.path}/logs');
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  group('which page may be opened', () {
    test('a page inside the plugin directory', () {
      expect(
        PluginWebView.resolvePage(
          plugin: manifest(['ui.webview']),
          pluginDirectory: '${root.path}/plugin',
          page: 'page.html',
        ),
        endsWith('page.html'),
      );
    });

    test('not without the permission', () {
      expect(
        () => PluginWebView.resolvePage(
          plugin: manifest(const []),
          pluginDirectory: '${root.path}/plugin',
          page: 'page.html',
        ),
        throwsA(isA<PluginWebViewException>()),
      );
    });

    test('not one that leaves the directory', () {
      File('${root.path}/elsewhere.html').writeAsStringSync('<h1>no</h1>');
      expect(
        () => PluginWebView.resolvePage(
          plugin: manifest(['ui.webview']),
          pluginDirectory: '${root.path}/plugin',
          page: '../elsewhere.html',
        ),
        throwsA(isA<PluginWebViewException>()),
        reason: '页面是随插件装进来的那一份，不是磁盘上任意一个文件',
      );
    });

    test('not an absolute one', () {
      expect(
        () => PluginWebView.resolvePage(
          plugin: manifest(['ui.webview']),
          pluginDirectory: '${root.path}/plugin',
          page: '/etc/hostname',
        ),
        throwsA(isA<PluginWebViewException>()),
      );
    });
  });

  group('the way out', () {
    Future<(bool, String)> ask(
      PluginWebView view,
      Map<String, dynamic> request,
    ) async {
      var ok = false;
      var payload = '';
      await view.handleRequest(request, (id, o, p) async {
        ok = o;
        payload = p;
      });
      return (ok, payload);
    }

    test('a request is made by the editor and written down whole', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        final body = await utf8.decoder.bind(request).join();
        request.response
          ..write('echo:$body')
          ..close();
      });

      final view = PluginWebView(
        plugin: manifest(['ui.webview', 'network.request']),
        logger: logger,
      );
      final (ok, payload) = await ask(view, {
        'id': '1',
        'url': 'http://127.0.0.1:${server.port}/ask',
        'method': 'POST',
        'body': 'hello',
      });

      expect(ok, isTrue);
      expect(payload, 'echo:hello');

      final log = await File(logger.path).readAsString();
      expect(log, contains('webview fetch POST http://127.0.0.1'));
      expect(log, contains('/ask'),
          reason: '这条路上宿主亲自发的请求，'
              '所以整条 URL 都记得下——隧道只能记到主机名');
      expect(log, contains('200'));
    });

    test('only http and https', () async {
      final view = PluginWebView(
        plugin: manifest(['ui.webview', 'network.request']),
        logger: logger,
      );
      final (ok, payload) = await ask(view, {
        'id': '2',
        'url': 'file:///etc/hostname',
        'method': 'GET',
      });
      expect(ok, isFalse);
      expect(payload, contains('only http and https'));
    });

    test('not without network.request', () async {
      // ui.webview carries it, so this is a manifest edited after install.
      final view = PluginWebView(
        plugin: manifest(['ui.webview']),
        logger: logger,
      );
      final (ok, payload) = await ask(view, {
        'id': '3',
        'url': 'http://127.0.0.1:1/x',
        'method': 'GET',
      });
      expect(ok, isFalse);
      expect(payload, contains('did not ask for network access'));
    });

    test('a failure is written down too', () async {
      final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final dead = closed.port;
      await closed.close();

      final view = PluginWebView(
        plugin: manifest(['ui.webview', 'network.request']),
        logger: logger,
      );
      final (ok, _) = await ask(view, {
        'id': '4',
        'url': 'http://127.0.0.1:$dead/x',
        'method': 'GET',
      });
      expect(ok, isFalse);
      expect(await File(logger.path).readAsString(), contains('failed'));
    });
  });

  test('the bridge offers one way out and says so', () {
    // The page gets `marktext.fetch` and nothing else from the editor. What
    // it cannot be stopped from doing — its own `fetch` — is why the page is
    // local: what runs is what was installed.
    expect(PluginWebView.bridgeScript, contains('window.marktext.fetch'));
    expect(PluginWebView.bridgeScript, contains('postMessage'));
  });
}

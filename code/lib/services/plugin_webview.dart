import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:path/path.dart' as p;

import 'plugin_logger.dart';
import 'plugin_manifest.dart';

/// A page a plugin draws for itself, in a window of its own.
///
/// The declarative tree covers a form, a list, an answer. This is for what it
/// cannot express, and it is deliberately the harder path to take: it needs
/// `ui.webview`, which carries `network.request` with it and says so to the
/// reader.
///
/// **The page is local.** It is loaded from inside the plugin's own directory
/// rather than from a URL, so what runs is what was installed rather than
/// whatever a server decided to send today.
///
/// **The network goes through the host.** The page calls
/// `marktext.fetch(url, options)`, which crosses into Dart, is made with the
/// editor's own client — the reader's system proxy and all — and is written to
/// the plugin's log with the method, the URL, the status and the size. Not the
/// host alone: everything, because here the host really can see it.
///
/// That is stronger than the local proxy this editor also has. A proxy sees a
/// CONNECT tunnel and then encrypted bytes; this sees the request. The proxy
/// stays for a web view that can be pointed at one — `desktop_webview_window`
/// exposes no proxy setting on any of the three platforms, which is the whole
/// reason this bridge exists.
class PluginWebView {
  PluginWebView({required this.plugin, required this.logger});

  final PluginManifest plugin;
  final PluginLogger logger;

  Webview? _window;

  /// Whether a web view can be created on this machine at all.
  ///
  /// Windows answers honestly, since WebView2 may not be installed. The other
  /// two say yes and find out later, so a failure to create is treated as the
  /// same answer — on Linux that usually means `libwebkit2gtk` is missing,
  /// and the reader deserves to be told which library rather than shown a
  /// window that never appears.
  static Future<bool> get available => WebviewWindow.isWebviewAvailable();

  static String unavailableAdvice() {
    if (Platform.isLinux) {
      return 'This plugin needs a system web view. On Linux that is '
          'libwebkit2gtk — try installing libwebkit2gtk-4.1-0 (Debian and '
          'Ubuntu) or webkit2gtk-4.1 (Fedora and Arch).';
    }
    if (Platform.isWindows) {
      return 'This plugin needs the Microsoft Edge WebView2 Runtime, which '
          'this machine does not have. It is a free download from Microsoft.';
    }
    return 'This plugin needs a system web view, which this machine does not '
        'appear to have.';
  }

  /// Where [page] resolves to, or an exception saying why it does not.
  ///
  /// Separate from [open] so the rules can be tested without a window: a
  /// window needs a desktop, and these rules are the part worth pinning.
  static String resolvePage({
    required PluginManifest plugin,
    required String pluginDirectory,
    required String page,
  }) {
    if (!plugin.hasPermission(PluginPermission.uiWebview)) {
      throw const PluginWebViewException(
        'the plugin did not ask for the ui.webview permission',
      );
    }
    if (p.isAbsolute(page)) {
      throw const PluginWebViewException(
        'a page must be relative to the plugin directory',
      );
    }
    final resolved = p.normalize(p.join(pluginDirectory, page));
    if (!p.isWithin(pluginDirectory, resolved)) {
      throw const PluginWebViewException(
        'a page may not leave the plugin directory',
      );
    }
    if (!File(resolved).existsSync()) {
      throw PluginWebViewException('no such page: $page');
    }
    return resolved;
  }

  /// Opens [page], a path inside the plugin's own directory.
  Future<void> open({
    required String pluginDirectory,
    required String page,
    int width = 900,
    int height = 700,
  }) async {
    final resolved = resolvePage(
      plugin: plugin,
      pluginDirectory: pluginDirectory,
      page: page,
    );
    if (!await available) throw PluginWebViewException(unavailableAdvice());

    final window = await WebviewWindow.create(
      configuration: CreateConfiguration(
        windowWidth: width,
        windowHeight: height,
        title: plugin.name,
        titleBarTopPadding: Platform.isMacOS ? 20 : 0,
      ),
    );
    _window = window;

    window.addScriptToExecuteOnDocumentCreated(bridgeScript);
    window.registerJavaScriptMessageHandler('marktext', _onMessage);
    // Deliberately not awaited: this completes when the reader closes the
    // window, which is exactly what must not block opening it.
    unawaited(window.onClose.then((_) => _window = null));
    window.launch(Uri.file(resolved).toString());
    await logger.info('webview opened $page');
  }

  Future<void> close() async {
    _window?.close();
    _window = null;
  }

  /// What the page gets: one function, and no way around it the editor has
  /// not seen.
  static const bridgeScript = '''
window.marktext = window.marktext || {};
window.marktext._waiting = {};
window.marktext._next = 1;
window.marktext.fetch = function (url, options) {
  var id = String(window.marktext._next++);
  var message = JSON.stringify({
    id: id,
    url: url,
    method: (options && options.method) || 'GET',
    headers: (options && options.headers) || {},
    body: (options && options.body) || null
  });
  return new Promise(function (resolve, reject) {
    window.marktext._waiting[id] = { resolve: resolve, reject: reject };
    window.marktext.postMessage(message);
  });
};
window.marktext._answer = function (id, ok, payload) {
  var pending = window.marktext._waiting[id];
  if (!pending) return;
  delete window.marktext._waiting[id];
  ok ? pending.resolve(payload) : pending.reject(new Error(payload));
};
''';

  void _onMessage(String name, dynamic body) {
    Map<String, dynamic> request;
    try {
      request = jsonDecode('$body') as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    // Deliberately not awaited: the handler is synchronous by signature, and
    // the page is waiting on the promise the bridge gave it rather than on
    // this returning.
    unawaited(_reply(request));
  }

  Future<void> _reply(Map<String, dynamic> request) async {
    await handleRequest(request, (id, ok, payload) async {
      final window = _window;
      if (window == null) return;
      await window.evaluateJavaScript(
        'window.marktext._answer(${jsonEncode(id)}, $ok, '
        '${jsonEncode(payload)})',
      );
    });
  }

  /// Makes one request the page asked for, and says what happened.
  ///
  /// Takes the reply as a callback so the rules and the logging can be tested
  /// against a real server without a window in the way.
  Future<void> handleRequest(
    Map<String, dynamic> request,
    Future<void> Function(String id, bool ok, String payload) answer,
  ) async {
    final id = '${request['id']}';
    final url = Uri.tryParse('${request['url']}');
    if (url == null || !(url.scheme == 'http' || url.scheme == 'https')) {
      await answer(id, false, 'only http and https are allowed');
      return;
    }
    if (!plugin.hasPermission(PluginPermission.networkRequest)) {
      // `ui.webview` carries `network.request`, so this only happens to a
      // manifest edited by hand after installation.
      await answer(id, false, 'the plugin did not ask for network access');
      return;
    }

    final method = '${request['method']}'.toUpperCase();
    final started = DateTime.now();
    final client = HttpClient()
      ..findProxy = (target) => HttpClient.findProxyFromEnvironment(
        target,
        environment: Platform.environment,
      );
    try {
      final outgoing = await client.openUrl(method, url);
      final headers = request['headers'];
      if (headers is Map) {
        headers.forEach(
          (name, value) => outgoing.headers.set('$name', '$value'),
        );
      }
      final body = request['body'];
      if (body is String && body.isNotEmpty) outgoing.add(utf8.encode(body));
      final response = await outgoing.close();
      final text = await utf8.decoder.bind(response).join();
      final took = DateTime.now().difference(started).inMilliseconds;
      // The whole URL, not just the host. A proxy could only ever see the
      // host of an https request; here the editor made the request itself,
      // so there is nothing it cannot say.
      await logger.info(
        'webview fetch $method $url ${response.statusCode} '
        '${text.length}B ${took}ms',
      );
      await answer(id, true, text);
    } catch (error) {
      await logger.warning('webview fetch $method $url failed: $error');
      await answer(id, false, '$error');
    } finally {
      client.close(force: true);
    }
  }
}

class PluginWebViewException implements Exception {
  const PluginWebViewException(this.message);

  final String message;

  @override
  String toString() => message;
}

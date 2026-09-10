import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../services/app_log.dart';

/// A plugin's own HTML, drawn by the platform's web engine.
///
/// The one place a plugin gets an interface the editor did not design. Every
/// other answer it can give is described to the editor — a tree of named nodes,
/// or text — and drawn with the editor's own widgets, which is why those cost
/// nothing at startup and follow the reader's theme without the plugin knowing
/// what the theme is. This does not: it is a browser context, and a page can
/// look like anything and reach any server.
///
/// So it is behind `ui.webview`, which carries `network.request` with it, and
/// nothing is created until a plugin actually asks. A reader who never opens
/// such a plugin never pays for an engine: no webview is built at startup, and
/// this widget is the only thing that builds one.
///
/// The engine is the operating system's — WebView2 on Windows, WKWebView on
/// macOS, WPE on Linux — rather than a browser packaged with the editor. That
/// is what keeps the download and the memory where they were, and it is why
/// the reader's own proxy settings apply without the editor arranging it.
///
/// Where the page goes is written to the log, which is what the permission
/// promises. It comes from the engine reporting where it went rather than from
/// routing the traffic somewhere: no second hop, and no certificate of the
/// editor's standing between a plugin and the servers it was allowed to reach.
///
/// It takes three reports to keep that promise, because no one of them is
/// dispatched everywhere. `onLoadResource` — every image, script and fetch —
/// is the fullest, and is the one Windows never sends: its native side has no
/// such event at all, so a build that listened only for that logged nothing on
/// the platform most readers are on. `onLoadStart` and `onUpdateVisitedHistory`
/// are sent by Windows and Linux both, and between them they cover where the
/// page *goes* — a plugin writing the document into a query string and setting
/// `location` is the thing the log is there to catch. Sub-resources are still
/// only seen where `onLoadResource` arrives; that is the engine's limit, not a
/// decision, and it is written down here so the next reader of this file does
/// not have to find it out from the C++.
///
/// Each host is written once per pane. The question the log answers is where a
/// plugin went, and a page with fifty images would otherwise answer it fifty
/// times and bury everything else.
///
/// A local proxy was written for this first, and is not here — do not write it
/// again. It was the one mechanism all three desktops speak, chosen because the
/// APIs for intercepting a page's requests differ on every one; but no desktop
/// implementation of `flutter_inappwebview` offers a `ProxyController`, so
/// nothing could be pointed at it. The callback below is on all three, and the
/// half the proxy also bought — the reader's own proxy settings — the operating
/// system's engine already honours.
class PluginWebPane extends StatefulWidget {
  const PluginWebPane({
    super.key,
    required this.html,
    required this.pluginName,
  });

  /// The page itself. A plugin sends HTML, not an address: what it draws is
  /// its own, and a plugin that wants a remote page can fetch it and say so.
  final String html;

  /// Whose page this is, for the log and for what the reader is told when
  /// there is no engine to draw it with.
  final String pluginName;

  /// Whether this machine has a web engine for the editor to use.
  ///
  /// False under `flutter test`, where nothing registers a platform, so the
  /// message below is what the tests see — which is the point: the message is
  /// the part a reader might actually meet.
  static bool get supported => InAppWebViewPlatform.instance != null;

  @override
  State<PluginWebPane> createState() => _PluginWebPaneState();
}

class _PluginWebPaneState extends State<PluginWebPane> {
  final _trail = PluginWebTrail();

  void _note(Uri? url) {
    final line = _trail.note(widget.pluginName, url);
    if (line != null) AppLog.instance.info(line);
  }

  @override
  Widget build(BuildContext context) {
    if (!PluginWebPane.supported) {
      // Said, not left blank. A pane that draws nothing looks like a plugin
      // that failed, and the reader would go looking for the fault in it.
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          AppLocalizations.of(context)?.pluginNoWebEngine(widget.pluginName) ??
              '',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return InAppWebView(
      initialData: InAppWebViewInitialData(data: widget.html),
      initialSettings: InAppWebViewSettings(
        transparentBackground: true,
        // The page is the plugin's own and has to be able to run: an interface
        // drawn in HTML without script is a picture of an interface.
        javaScriptEnabled: true,
        // Nothing the reader picks up should follow them out of the editor.
        incognito: true,
      ),
      onLoadResource: (controller, resource) => _note(resource.url),
      onLoadStart: (controller, url) => _note(url),
      onUpdateVisitedHistory: (controller, url, isReload) => _note(url),
    );
  }
}

/// The hosts one pane's page has reached, and what to write about the next.
///
/// Apart from the widget because this is the part worth testing and the engine
/// is not: under `flutter test` no web engine exists, so a test that went
/// through the pane would be testing the message about there being no engine.
class PluginWebTrail {
  final _seen = <String>{};

  /// The line to write for [url], or null when there is nothing new to say.
  ///
  /// The host, never the whole address: a query string can carry the document
  /// itself, and this ends up in a file on disk. `about:` and `data:` are the
  /// page's own inline content — it has not gone anywhere — and are not worth
  /// a line, while `file:` is, even though it has no host, because a page
  /// reaching for the disk is exactly what a reader would want to know.
  String? note(String pluginName, Uri? url) {
    if (url == null) return null;
    final scheme = url.scheme.toLowerCase();
    if (scheme.isEmpty || scheme == 'about' || scheme == 'data') return null;
    final where = '$scheme://${url.host}';
    if (!_seen.add(where)) return null;
    return 'webview $pluginName → $where';
  }
}

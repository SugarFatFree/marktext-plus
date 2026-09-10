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
/// Where the page goes is written to the plugin's log, which is what the
/// permission promises. It comes from the engine reporting each resource it
/// loads rather than from routing the traffic somewhere: no second hop, and no
/// certificate of the editor's standing between a plugin and the servers it
/// was allowed to reach.
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
      onLoadResource: (controller, resource) {
        final url = resource.url;
        if (url == null) return;
        // The host, not the whole address: a query string can carry the
        // document, and this goes to a file on disk.
        AppLog.instance.info(
          'webview ${widget.pluginName} → ${url.scheme}://${url.host}',
        );
      },
    );
  }
}

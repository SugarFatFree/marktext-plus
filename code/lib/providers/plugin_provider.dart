import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../services/plugin_manager.dart';
import '../services/plugin_manifest.dart';
import '../services/plugin_script_runtime.dart';
import '../services/plugin_catalog_service.dart';

/// Loads only manifests; plugin processes and network requests remain lazy.
final installedPluginManifestsProvider = FutureProvider<List<PluginManifest>>((ref) async {
  final directory = await getApplicationSupportDirectory();
  return PluginManager(p.join(directory.path, 'plugins')).loadInstalled();
});


/// The community plugin currently open in the main content detail tab.
final pluginDetailProvider = StateProvider<PluginCatalogEntry?>((ref) => null);

/// What the plugin panel found the last time it looked for community plugins.
///
/// Held outside the panel because the side bar destroys it when another tab is
/// chosen: results that had just cost a network round trip were thrown away by
/// a visit to Files, with nothing on screen to say why the list had emptied.
class PluginDiscovery {
  const PluginDiscovery({this.results, this.searching = false, this.error});

  /// Null until a search has been run — which is not the same as a search that
  /// came back with nothing, and the panel says something different for each.
  final List<PluginCatalogEntry>? results;
  final bool searching;
  final String? error;
}

class PluginDiscoveryNotifier extends StateNotifier<PluginDiscovery> {
  PluginDiscoveryNotifier() : super(const PluginDiscovery());

  void started() => state = PluginDiscovery(
        results: state.results,
        searching: true,
      );

  void succeeded(List<PluginCatalogEntry> results) =>
      state = PluginDiscovery(results: results);

  void failed(String error) => state = PluginDiscovery(
        results: state.results,
        error: error,
      );
}

final pluginDiscoveryProvider =
    StateNotifierProvider<PluginDiscoveryNotifier, PluginDiscovery>(
  (ref) => PluginDiscoveryNotifier(),
);

/// A result a plugin asked to be shown beside the document rather than over it.
///
/// Document-sized output does not belong in a dialog: a reader comparing a
/// translation against what is on screen cannot do it through a box covering
/// the screen.
class PluginPanelResult {
  const PluginPanelResult({
    required this.pluginName,
    required this.title,
    required this.text,
  });

  final String pluginName;

  /// What the plugin called this result, if it said. Its own language.
  final String title;
  final String text;
}

final pluginPanelResultProvider =
    StateProvider<PluginPanelResult?>((ref) => null);

/// Text a plugin asked to be shown in one of the panes beside the document.
class PluginPaneContent {
  const PluginPaneContent({
    required this.pluginName,
    required this.title,
    required this.text,
    required this.slot,
    this.render = PluginPaneRender.text,
  });

  final String pluginName;

  /// What the plugin called this pane, in its own language. Empty is allowed;
  /// the pane then carries the plugin's name.
  final String title;
  final String text;
  final PluginPaneSlot slot;

  /// How the text is drawn: as it stands, as Markdown source, or rendered.
  final PluginPaneRender render;

  PluginPaneContent withText(String value) => PluginPaneContent(
        pluginName: pluginName,
        title: title,
        text: value,
        slot: slot,
        render: render,
      );
}

/// The panes plugins have open, by slot.
///
/// The editor already splits a tab between source and preview; this is that
/// split offered to plugins. The document keeps the first cell of a two by two
/// grid, and a plugin may fill the other three — no more, because a fifth pane
/// would have nowhere to go that is not already somewhere.
class PluginPanesNotifier extends StateNotifier<Map<PluginPaneSlot, PluginPaneContent>> {
  PluginPanesNotifier() : super(const {});

  void show(PluginPaneContent content) =>
      state = {...state, content.slot: content};

  /// Adds to what a pane holds, so a plugin can show its work as it arrives
  /// rather than only when it is finished.
  void append(PluginPaneContent content) {
    final existing = state[content.slot];
    if (existing == null) {
      show(content);
      return;
    }
    state = {
      ...state,
      content.slot: content.withText(
        existing.text.isEmpty
            ? content.text
            : '${existing.text}\n\n${content.text}',
      ),
    };
  }

  void close(PluginPaneSlot slot) =>
      state = {for (final e in state.entries) if (e.key != slot) e.key: e.value};

  void closeAll() => state = const {};
}

final pluginPanesProvider = StateNotifierProvider<PluginPanesNotifier,
    Map<PluginPaneSlot, PluginPaneContent>>((ref) => PluginPanesNotifier());

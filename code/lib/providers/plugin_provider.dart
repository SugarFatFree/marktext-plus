import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/tab_info.dart';
import '../services/plugin_manager.dart';
import '../services/plugin_manifest.dart';
import '../services/plugin_script_runtime.dart';
import '../services/plugin_catalog_service.dart';
import 'tab_provider.dart';

/// Loads only manifests; plugin processes and network requests remain lazy.
final installedPluginManifestsProvider = FutureProvider<List<PluginManifest>>((ref) async {
  final directory = await getApplicationSupportDirectory();
  return PluginManager(p.join(directory.path, 'plugins')).loadInstalled();
});


/// Opens a plugin's page as a tab, or returns to the one already open.
///
/// The page used to be state that replaced the editor area: whichever document
/// was open stayed the active tab, stayed highlighted in the tab bar, and had
/// a plugin page drawn over it. A page the editor has open is a tab, like
/// everything else it has open.
void openPluginDetailTab(WidgetRef ref, PluginCatalogEntry plugin) {
  final tab = TabInfo.pluginDetail(plugin);
  final tabs = ref.read(tabProvider);
  final already = tabs.tabs.where((open) => open.id == tab.id).firstOrNull;
  if (already != null) {
    ref.read(tabProvider.notifier).setActiveTab(already.id);
    return;
  }
  ref.read(tabProvider.notifier).addTab(tab);
}

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
    this.busy = false,
  });

  final String pluginName;

  /// What the plugin called this pane, in its own language. Empty is allowed;
  /// the pane then carries the plugin's name.
  final String title;
  final String text;
  final PluginPaneSlot slot;

  /// How the text is drawn: as it stands, as Markdown source, or rendered.
  final PluginPaneRender render;

  /// Whether the plugin has more to put here.
  ///
  /// A pane filled a block at a time is worth watching while it fills, and the
  /// reader has to be able to tell "still going" from "this is all there is".
  final bool busy;

  /// What a pane action asks for, including whether more is coming.
  ///
  /// "Still working" is exactly "there is a next step", and this is the one
  /// place that says so. Left at the call site it was a spelling nobody
  /// checked: writing `busy: false` there broke nothing that any test could
  /// see, and the pane would have sat finished while blocks were still
  /// arriving.
  factory PluginPaneContent.fromAction(
    PluginPaneAction action,
    String pluginName,
  ) =>
      PluginPaneContent(
        pluginName: pluginName,
        title: action.title,
        text: action.text,
        slot: action.slot,
        render: action.render,
        busy: action.nextPrompt != null,
      );

  PluginPaneContent withText(String value) => PluginPaneContent(
        pluginName: pluginName,
        title: title,
        text: value,
        slot: slot,
        render: render,
        busy: busy,
      );

  PluginPaneContent settled() => PluginPaneContent(
        pluginName: pluginName,
        title: title,
        text: text,
        slot: slot,
        render: render,
        busy: false,
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
    // The arriving block carries the newer answer to "is there more", so it
    // is `content` that is kept and the text that is merged into it. Keeping
    // the pane already on screen would leave it working forever, because the
    // block that ends a run is the one that says the run ended.
    state = {
      ...state,
      content.slot: content.withText(
        existing.text.isEmpty
            ? content.text
            : '${existing.text}\n\n${content.text}',
      ),
    };
  }

  /// Stops every pane saying it is still working.
  ///
  /// Called when a run ends for any reason — including one that threw, which
  /// would otherwise leave a pane spinning over half a translation with
  /// nothing coming.
  void settle() => state = {
        for (final entry in state.entries)
          entry.key: entry.value.busy ? entry.value.settled() : entry.value,
      };

  void close(PluginPaneSlot slot) =>
      state = {for (final e in state.entries) if (e.key != slot) e.key: e.value};

  void closeAll() => state = const {};
}

final pluginPanesProvider = StateNotifierProvider<PluginPanesNotifier,
    Map<PluginPaneSlot, PluginPaneContent>>((ref) => PluginPanesNotifier());


/// One short answer from a plugin, shown beside the text rather than over it.
///
/// A translation of a sentence is a note: it is read next to the sentence,
/// which means the sentence has to still be there and still be scrollable. A
/// modal dialog is the one place it cannot be.
class PluginTip {
  const PluginTip({required this.title, required this.text, required this.busy});

  final String title;

  /// Empty while the plugin is still working.
  final String text;
  final bool busy;
}

class PluginTipNotifier extends StateNotifier<PluginTip?> {
  PluginTipNotifier() : super(null);

  /// Says a plugin has started, before it has anything to say.
  void working(String title) =>
      state = PluginTip(title: title, text: '', busy: true);

  /// The answer, in the same place the waiting was.
  void show({required String title, required String text}) =>
      state = PluginTip(title: title, text: text, busy: false);

  void dismiss() => state = null;

  /// Takes down a tip that is still waiting, leaving an answer alone.
  ///
  /// For the end of a run: a plugin that finished by writing somewhere else
  /// must not leave "working…" on screen, but neither should it wipe an
  /// answer the reader is in the middle of reading.
  void dismissIfWaiting() {
    if (state?.busy ?? false) state = null;
  }
}

final pluginTipProvider =
    StateNotifierProvider<PluginTipNotifier, PluginTip?>(
        (ref) => PluginTipNotifier());

import 'dart:async';

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


/// Where each installed plugin came from, by plugin id.
///
/// Separate from the manifests because it is not the plugin's own claim about
/// itself: whether a release was a pre-release is a property of the release,
/// and the reader is entitled to know which one they took.
final installedPluginSourcesProvider =
    FutureProvider<Map<String, PluginSource>>((ref) async {
  final directory = await getApplicationSupportDirectory();
  return PluginManager(p.join(directory.path, 'plugins')).sources();
});

/// Opens a plugin's page as a tab, or returns to the one already open.
///
/// The page used to be state that replaced the editor area: whichever document
/// was open stayed the active tab, stayed highlighted in the tab bar, and had
/// a plugin page drawn over it. A page the editor has open is a tab, like
/// everything else it has open.
/// The directory installed plugins live in.
final pluginInstallDirectoryProvider = FutureProvider<String>((ref) async {
  final directory = await getApplicationSupportDirectory();
  return p.join(directory.path, 'plugins');
});

/// Opens a plugin's settings as a tab, or returns to the one already open.
void openPluginSettingsTab(WidgetRef ref, PluginManifest plugin) {
  final tab = TabInfo.pluginSettings(plugin);
  final tabs = ref.read(tabProvider);
  final already = tabs.tabs.where((open) => open.id == tab.id).firstOrNull;
  if (already != null) {
    ref.read(tabProvider.notifier).setActiveTab(already.id);
    return;
  }
  ref.read(tabProvider.notifier).addTab(tab);
}

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
class PluginPanesNotifier
    extends StateNotifier<Map<String, Map<PluginPaneSlot, PluginPaneContent>>> {
  PluginPanesNotifier() : super(const {});

  /// The panes open in [tabId], which is empty for a tab that has none.
  Map<PluginPaneSlot, PluginPaneContent> forTab(String tabId) =>
      state[tabId] ?? const {};

  void show(String tabId, PluginPaneContent content) {
    // A pane with no tab to belong to has nowhere to be drawn, and would
    // otherwise sit in the map waiting to appear beside an unrelated document.
    if (tabId.isEmpty) return;
    state = {
      ...state,
      tabId: {...forTab(tabId), content.slot: content},
    };
  }

  /// Adds to what a pane holds, so a plugin can show its work as it arrives
  /// rather than only when it is finished.
  void append(String tabId, PluginPaneContent content) {
    if (tabId.isEmpty) return;
    final existing = forTab(tabId)[content.slot];
    if (existing == null) {
      show(tabId, content);
      return;
    }
    // The arriving block carries the newer answer to "is there more", so it
    // is `content` that is kept and the text that is merged into it. Keeping
    // the pane already on screen would leave it working forever, because the
    // block that ends a run is the one that says the run ended.
    show(
      tabId,
      content.withText(
        existing.text.isEmpty
            ? content.text
            : '${existing.text}\n\n${content.text}',
      ),
    );
  }

  void close(String tabId, PluginPaneSlot slot) {
    final remaining = {
      for (final entry in forTab(tabId).entries)
        if (entry.key != slot) entry.key: entry.value,
    };
    state = {
      for (final tab in state.entries)
        if (tab.key != tabId) tab.key: tab.value,
      if (remaining.isNotEmpty) tabId: remaining,
    };
  }

  /// Stops every pane in [tabId] saying it is still working.
  ///
  /// Called when a run ends for any reason — including one that threw, which
  /// would otherwise leave a pane spinning over half a translation with
  /// nothing coming. Only that tab: another tab may still be translating.
  void settle(String tabId) {
    final panes = forTab(tabId);
    if (panes.isEmpty) return;
    state = {
      ...state,
      tabId: {
        for (final entry in panes.entries)
          entry.key: entry.value.busy ? entry.value.settled() : entry.value,
      },
    };
  }

  /// Drops the panes of every tab that is no longer open.
  ///
  /// A pane belongs to its tab, so closing the tab closes the pane with it.
  void retain(Set<String> tabIds) {
    if (state.keys.every(tabIds.contains)) return;
    state = {
      for (final tab in state.entries)
        if (tabIds.contains(tab.key)) tab.key: tab.value,
    };
  }

  void closeAll() => state = const {};
}

/// The panes plugins have open, by tab and then by slot.
///
/// Keyed by tab because a pane belongs to the document it was opened beside:
/// one map for the whole editor meant a translation stayed on screen when the
/// reader switched tabs, which is not a pane in a tab but a window in the
/// application.
final pluginPanesProvider = StateNotifierProvider<PluginPanesNotifier,
    Map<String, Map<PluginPaneSlot, PluginPaneContent>>>(
  (ref) => PluginPanesNotifier(),
);


/// One short answer from a plugin, shown beside the text rather than over it.
///
/// A translation of a sentence is a note: it is read next to the sentence,
/// which means the sentence has to still be there and still be scrollable. A
/// modal dialog is the one place it cannot be.
class PluginTip {
  const PluginTip({
    required this.title,
    required this.text,
    required this.busy,
    this.question,
    this.answer,
    this.choices = const <String>[],
    this.suggested = '',
  });

  final String title;

  /// Empty while the plugin is still working.
  final String text;

  /// What the plugin is asking, if it is asking rather than answering.
  ///
  /// The question used to be a modal dialog of its own — a second, larger
  /// window for one line of input, on the way to an answer that would arrive
  /// in a card a quarter its size.
  final String? question;

  /// Where the answer is collected, so the card can be rebuilt without losing
  /// what has been typed.
  final Completer<String?>? answer;

  /// Answers the plugin offered outright, shown as chips.
  final List<String> choices;

  /// What the plugin remembered from last time, already filled in.
  ///
  /// Offering it as one chip among many still asks the reader to pick the same
  /// answer every time; it is what they chose, so it is what the box says.
  final String suggested;

  bool get asking => question != null;
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

  /// Asks the reader something, in the same card the answer will appear in.
  Completer<String?> ask({
    required String title,
    required String question,
    required List<String> choices,
    String answer = '',
  }) {
    final completer = Completer<String?>();
    state = PluginTip(
      title: title,
      text: '',
      busy: false,
      question: question,
      answer: completer,
      choices: choices,
      suggested: answer,
    );
    return completer;
  }

  void dismiss() {
    // A question nobody answered is a question that was declined, and the run
    // waiting on it has to be told so rather than left holding a future that
    // never completes.
    final pending = state?.answer;
    state = null;
    if (pending != null && !pending.isCompleted) pending.complete(null);
  }

  void answerWith(String value) {
    final pending = state?.answer;
    state = null;
    if (pending != null && !pending.isCompleted) pending.complete(value);
  }

  /// Takes down a tip that is still waiting, leaving an answer alone.
  ///
  /// For the end of a run: a plugin that finished by writing somewhere else
  /// must not leave "working…" on screen, but neither should it wipe an
  /// answer the reader is in the middle of reading.
  void dismissIfWaiting() {
    if (state?.busy ?? false) state = null;
  }

  /// Whether a question is on screen, so a run knows the reader has not yet
  /// closed the card it is waiting on.
  bool get asking => state?.asking ?? false;
}

final pluginTipProvider =
    StateNotifierProvider<PluginTipNotifier, PluginTip?>(
        (ref) => PluginTipNotifier());

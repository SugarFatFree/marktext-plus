import 'dart:convert';
import '../core/diagnostics/resident_memory.dart';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../models/tab_info.dart';
import '../services/app_log.dart';
import '../services/plugin_script_runtime.dart';
import '../services/plugin_manager.dart';
import '../services/plugin_catalog_service.dart';
import '../services/mcp_server.dart';
import '../services/mcp_tools.dart';
import '../services/window_capture.dart';
import 'plugin_provider.dart';
import 'settings_provider.dart';
import 'tab_provider.dart';

/// What the editor tells the reader about its MCP server.
class McpStatus {
  const McpStatus({
    this.running = false,
    this.port,
    this.token = '',
    this.error,
  });

  final bool running;
  final int? port;
  final String token;

  /// Why it is not running, when the reader asked for it to be.
  final String? error;
}

/// A token nobody can guess, made once and kept.
///
/// Kept, because a configuration the reader wrote into their agent should go
/// on working: rolling it on every launch would silently break it.
String newMcpToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(24, (_) => random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

class McpController extends StateNotifier<McpStatus> {
  McpController(this._ref) : super(const McpStatus());

  final Ref _ref;
  final _server = McpServer();

  /// Brings the server into line with the settings.
  Future<void> apply(AppConfig config) async {
    if (!config.mcpEnabled) {
      await _server.stop();
      if (mounted) state = const McpStatus();
      return;
    }
    if (_server.running && _server.port == config.mcpPort) return;

    try {
      await _server.start(
        port: config.mcpPort,
        token: config.mcpToken,
        tools: _toolset(),
      );
      if (!mounted) return;
      state = McpStatus(
        running: true,
        port: _server.port,
        token: config.mcpToken,
      );
    } catch (error) {
      AppLog.instance.error('MCP server did not start: $error');
      if (!mounted) return;
      state = McpStatus(error: '$error');
    }
  }

  McpToolset _toolset() {
    final capture = WindowCapture();
    return McpToolset(
      log: AppLog.instance,
      screenshot: capture.png,
      recordGif: capture.gif,
      describeState: describeState,
      perform: performAction,
    );
  }

  /// What the editor has open, for `get_state`.
  ///
  /// Exposed for the same reason [performAction] is: the only test of this
  /// layer hands the toolset a stub, so what an agent is actually told about
  /// the editor had never been compared with the editor.
  @visibleForTesting
  Future<Map<String, dynamic>> describeState() async {
    final tabs = _ref.read(tabProvider);
    final config = _ref.read(settingsProvider);
    final plugins =
        _ref.read(installedPluginManifestsProvider).valueOrNull ?? const [];
    final panes = _ref.read(pluginPanesProvider);
    // How much the process is holding, when the platform will say.
    //
    // This editor's first promise is that it stays light, and until now the
    // only way to read that number was a log line the preview writes — and
    // only on the batched path, so a document small enough to parse in one go
    // never produced one. Which meant the figure could be had while a heavy
    // document was open and not afterwards: exactly the wrong way round for
    // the question anyone actually asks, which is whether it came back down.
    //
    // Omitted rather than zeroed where the platform does not answer: "0 MB"
    // reads as a measurement, and the absence of a measurement is not one.
    final resident = ResidentMemory.megabytes();

    return {
      'viewMode': config.editMode.name,
      'activeTabId': tabs.activeTabId,
      if (resident != null) 'residentMB': resident,
      'tabs': [
        for (final tab in tabs.tabs)
          {
            'id': tab.id,
            'name': tab.fileName,
            'path': tab.filePath,
            'modified': tab.isModified,
            'kind': tab.isPluginDetail ? 'plugin' : 'document',
            // UTF-16 units, as `get_state` says. Not code points like the
            // status bar: this is asked for on every poll and would then walk
            // every open document to answer.
            'characters': tab.content.length,
          },
      ],
      'plugins': [
        for (final plugin in plugins)
          {
            'id': plugin.id,
            'name': plugin.name,
            'version': plugin.version,
            'commands': plugin.commandIds,
          },
      ],
      'panes': {
        for (final tab in panes.entries)
          tab.key: {
            for (final pane in tab.value.entries)
              pane.key.name: {
                'title': pane.value.title,
                'busy': pane.value.busy,
                'characters': pane.value.text.length,
              },
          },
      },
    };
  }

  /// Runs one plugin command, when the widget layer has said how.
  ///
  /// Not done here: a command draws panes, cards and messages, all of which
  /// come out of a `BuildContext`, and this layer has none. The widget that
  /// has one registers this instead, which is the same shape the toolset
  /// already uses for screenshots.
  Future<McpOutcome> Function(String pluginId, String command, String? answer)?
  runPluginCommand;

  /// Presses an icon in the right-hand rail, and says what the drawer showed.
  ///
  /// Registered by the rail itself, for the reason [runPluginCommand] is
  /// registered by the screen: the drawer is a widget's own state, and a
  /// panel's answer goes into it rather than anywhere this layer can read.
  Future<McpOutcome> Function(String pluginId, String panelId, String? answer)?
  openPluginPanel;

  /// Carries out one `control` action and says, truthfully, what happened.
  ///
  /// Exposed because until now the only test of this layer handed the toolset
  /// a stub, so the switch below — every action an agent can ask for — had
  /// never been run.
  @visibleForTesting
  Future<McpOutcome> performAction(
    String action,
    Map<String, dynamic> arguments,
  ) async {
    String? text(String key) => arguments[key] as String?;

    final wanted = McpAction.byWireName(action);
    if (wanted == null) {
      // `open_file` and `run_plugin_command` used to be listed here and
      // implemented nowhere; the comment beside this fallthrough claimed the
      // widget layer wired them up, and it did not. They are gone from the
      // schema, and the list an agent is shown is now generated from the same
      // enum this switch covers, so the two cannot drift apart again.
      //
      // Both are worth having, and neither belongs in this layer as it
      // stands. Opening a path in *this* window is thirty lines living in the
      // side bar; a second copy here is the defect this codebase keeps
      // removing, so the first step is lifting it onto `TabNotifier`. Running
      // a plugin command needs a `BuildContext` — panes, cards and messages
      // all come from one — so the widget layer has to register a handler.
      return mcpRefused('action "$action" is not available');
    }

    switch (wanted) {
      case McpAction.setViewMode:
        final mode = EditMode.values
            .where((m) => m.name == text('mode'))
            .firstOrNull;
        if (mode == null) return mcpRefused('unknown mode "${text('mode')}"');
        _ref.read(settingsProvider.notifier).setEditMode(mode);
        return mcpDid('view mode is now ${mode.name}');

      case McpAction.newTab:
        final tab = TabInfo(
          id: 'mcp-${DateTime.now().microsecondsSinceEpoch}',
          fileName: text('path') ?? 'Untitled',
          content: text('content') ?? '',
        );
        _ref.read(tabProvider.notifier).addTab(tab);
        return mcpDid('opened tab ${tab.id}');

      case McpAction.activateTab:
        final id = text('tabId');
        if (id == null) return mcpRefused('no tabId given');
        // The answer is the provider's, not this line's optimism: an id
        // naming no tab used to be written into the state and reported as a
        // switch that had happened.
        return _ref.read(tabProvider.notifier).setActiveTab(id)
            ? mcpDid('tab $id is active')
            : mcpRefused('there is no tab $id');

      case McpAction.closeTab:
        final id = text('tabId') ?? _ref.read(tabProvider).activeTabId;
        if (id == null) return mcpRefused('no tab to close');
        return _ref.read(tabProvider.notifier).removeTab(id)
            ? mcpDid('closed tab $id')
            : mcpRefused('there is no tab $id');

      case McpAction.setContent:
        final id = text('tabId') ?? _ref.read(tabProvider).activeTabId;
        final content = text('content');
        if (id == null) return mcpRefused('no tab to write to');
        if (content == null) return mcpRefused('no content given');
        return _ref
                .read(tabProvider.notifier)
                .updateContent(id, content, external: true)
            ? mcpDid('wrote ${content.length} characters to $id')
            : mcpRefused('there is no tab $id');

      case McpAction.runPluginCommand:
        final pluginId = text('pluginId');
        final command = text('command');
        if (pluginId == null) return mcpRefused('no pluginId given');
        if (command == null) return mcpRefused('no command given');
        final run = runPluginCommand;
        if (run == null) {
          // Only before the first frame: the widget that registers this is
          // built once and stays.
          return mcpRefused('the editor is not ready to run plugin commands yet');
        }
        // The handler's own answer, not a blanket success: it refuses a
        // plugin that is not installed and a command that plugin has not got,
        // and wrapping those in `mcpDid` reported both as done.
        return run(pluginId, command, text('answer'));

      case McpAction.openPanel:
        final pluginId = text('pluginId');
        final panelId = text('panelId');
        if (pluginId == null) return mcpRefused('no pluginId given');
        if (panelId == null) return mcpRefused('no panelId given');
        final open = openPluginPanel;
        if (open == null) {
          return mcpRefused('the editor is not ready to open panels yet');
        }
        // The rail's own answer: it refuses a plugin that is not installed, a
        // panel that plugin has not got, and a plugin that never asked for
        // `ui.sidebar` — which is the same refusal a reader gets by finding no
        // icon to press.
        return open(pluginId, panelId, text('answer'));

      case McpAction.installPlugin:
        final wanted = text('pluginId') ?? '';
        // The empty one is refused inside, beside every other reason a name
        // can fail to name something, so both answers read the same way.
        return installPlugin(wanted);

      case McpAction.closePane:
        final slot = PluginPaneSlot.values
            .where((s) => s.name == text('slot'))
            .firstOrNull;
        final id = _ref.read(tabProvider).activeTabId;
        if (slot == null) return mcpRefused('unknown slot "${text('slot')}"');
        if (id == null) return mcpRefused('no tab is active');
        return _ref.read(pluginPanesProvider.notifier).close(id, slot)
            ? mcpDid('closed the ${slot.name} pane')
            : mcpRefused('no ${slot.name} pane was open');

    }
  }

  /// Which catalogue entry [wanted] names, or the sentence saying why none.
  ///
  /// Pulled out of [installPlugin] so the deciding can be checked without a
  /// network: everything above it is one search and one download, and
  /// everything below it is the installer that already has its own tests.
  ///
  /// Refusals rather than a best guess. Two entries answering to one name
  /// means the name is not one, and installing whichever sorted first is a
  /// coin toss the caller cannot see the result of. Both refusals say what
  /// the catalogue actually held, because "no such plugin" with nothing
  /// beside it reads as an editor fault when it is usually a typo or a
  /// listing that came back short.
  @visibleForTesting
  static ({PluginCatalogEntry? entry, String? refusal}) chooseForInstall(
    String wanted,
    List<PluginCatalogEntry> entries, {
    String repository = '',
  }) {
    if (wanted.trim().isEmpty) {
      return (entry: null, refusal: 'no pluginId given');
    }
    final matches =
        entries.where((e) => e.namedBy(wanted, repository: repository)).toList();
    if (matches.isEmpty) {
      final had = entries.isEmpty
          ? 'the catalogue came back empty'
          : 'the catalogue has ${entries.length}: '
              '${entries.map((e) => e.id).join(', ')}';
      return (
        entry: null,
        refusal: 'no plugin in the catalogue is called "$wanted" — $had',
      );
    }
    if (matches.length > 1) {
      return (
        entry: null,
        refusal: '"$wanted" names ${matches.length} plugins: '
            '${matches.map((e) => e.id).join(', ')}',
      );
    }
    return (entry: matches.single, refusal: null);
  }

  /// Installs the plugin [wanted] names, or updates it if it is installed.
  ///
  /// Separate from the switch above because it is the one action that reaches
  /// the network and the disk, and because what it has to report — which
  /// version was there before, which is there now — is worth a sentence
  /// rather than "done".
  ///
  /// The catalogue is refreshed rather than read from its cache. The whole
  /// point of asking is that something was published a minute ago; a listing
  /// kept for six hours would answer with the release this is replacing.
  @visibleForTesting
  Future<McpOutcome> installPlugin(String wanted) async {
    if (wanted.trim().isEmpty) return mcpRefused('no pluginId given');
    final directory = await _ref.read(pluginInstallDirectoryProvider.future);
    final manager = PluginManager(directory);

    // What is installed under that id now, if anything. Two things come from
    // it: the repository, which is the only bridge from a manifest id to a
    // catalogue entry, and the version, so the answer can say what moved.
    final installed = await manager.loadInstalled();
    final before = installed.where((p) => p.id == wanted).firstOrNull;

    final List<PluginCatalogEntry> entries;
    try {
      entries = await PluginCatalogService().searchGitHubTopic(refresh: true);
    } catch (error) {
      return mcpRefused(
        'the catalogue could not be read: ${PluginCatalogService.describeError(error)}',
      );
    }

    final chosen = chooseForInstall(
      wanted,
      entries,
      repository: before?.repository ?? '',
    );
    final refusal = chosen.refusal;
    if (refusal != null) return mcpRefused(refusal);
    final entry = chosen.entry!;
    try {
      final manifest = await PluginCatalogService().install(entry, manager);
      _ref.invalidate(installedPluginManifestsProvider);
      _ref.invalidate(installedPluginProblemsProvider);
      _ref.invalidate(installedPluginSourcesProvider);
      final from = before == null ? 'nothing' : before.version;
      return mcpDid(
        'installed ${manifest.id} ${entry.version} (was $from) '
        'from ${entry.repositoryUrl ?? entry.id}',
      );
    } catch (error) {
      // The refusals worth reading are in here: a digest that did not match,
      // an archive that unpacks to more than the limit, an entry that climbs
      // out of its directory. None of them is "install failed".
      return mcpRefused('$wanted was not installed: $error');
    }
  }

  @override
  void dispose() {
    _server.stop();
    super.dispose();
  }
}

final mcpProvider = StateNotifierProvider<McpController, McpStatus>(
  (ref) => McpController(ref),
);

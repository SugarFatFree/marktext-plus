import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../models/tab_info.dart';
import '../services/app_log.dart';
import '../services/plugin_script_runtime.dart';
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
      describeState: _describe,
      perform: _perform,
    );
  }

  Future<Map<String, dynamic>> _describe() async {
    final tabs = _ref.read(tabProvider);
    final config = _ref.read(settingsProvider);
    final plugins =
        _ref.read(installedPluginManifestsProvider).valueOrNull ?? const [];
    final panes = _ref.read(pluginPanesProvider);
    return {
      'viewMode': config.editMode.name,
      'activeTabId': tabs.activeTabId,
      'tabs': [
        for (final tab in tabs.tabs)
          {
            'id': tab.id,
            'name': tab.fileName,
            'path': tab.filePath,
            'modified': tab.isModified,
            'kind': tab.isPluginDetail ? 'plugin' : 'document',
            'characters': tab.content.length,
          },
      ],
      'plugins': [
        for (final plugin in plugins)
          {
            'id': plugin.id,
            'name': plugin.name,
            'version': plugin.version,
            'commands': [for (final menu in plugin.menus) menu.id],
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
  Future<String> Function(String pluginId, String command)? runPluginCommand;

  Future<String> _perform(String action, Map<String, dynamic> arguments) async {
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
      return 'action "$action" is not available';
    }

    switch (wanted) {
      case McpAction.setViewMode:
        final mode = EditMode.values
            .where((m) => m.name == text('mode'))
            .firstOrNull;
        if (mode == null) return 'unknown mode "${text('mode')}"';
        _ref.read(settingsProvider.notifier).setEditMode(mode);
        return 'view mode is now ${mode.name}';

      case McpAction.newTab:
        final tab = TabInfo(
          id: 'mcp-${DateTime.now().microsecondsSinceEpoch}',
          fileName: text('path') ?? 'Untitled',
          content: text('content') ?? '',
        );
        _ref.read(tabProvider.notifier).addTab(tab);
        return 'opened tab ${tab.id}';

      case McpAction.activateTab:
        final id = text('tabId');
        if (id == null) return 'no tabId given';
        // The answer is the provider's, not this line's optimism: an id
        // naming no tab used to be written into the state and reported as a
        // switch that had happened.
        return _ref.read(tabProvider.notifier).setActiveTab(id)
            ? 'tab $id is active'
            : 'there is no tab $id';

      case McpAction.closeTab:
        final id = text('tabId') ?? _ref.read(tabProvider).activeTabId;
        if (id == null) return 'no tab to close';
        _ref.read(tabProvider.notifier).removeTab(id);
        return 'closed tab $id';

      case McpAction.setContent:
        final id = text('tabId') ?? _ref.read(tabProvider).activeTabId;
        final content = text('content');
        if (id == null) return 'no tab to write to';
        if (content == null) return 'no content given';
        _ref.read(tabProvider.notifier).updateContent(id, content);
        return 'wrote ${content.length} characters to $id';

      case McpAction.runPluginCommand:
        final pluginId = text('pluginId');
        final command = text('command');
        if (pluginId == null) return 'no pluginId given';
        if (command == null) return 'no command given';
        final run = runPluginCommand;
        if (run == null) {
          // Only before the first frame: the widget that registers this is
          // built once and stays.
          return 'the editor is not ready to run plugin commands yet';
        }
        return run(pluginId, command);

      case McpAction.closePane:
        final slot = PluginPaneSlot.values
            .where((s) => s.name == text('slot'))
            .firstOrNull;
        final id = _ref.read(tabProvider).activeTabId;
        if (slot == null) return 'unknown slot "${text('slot')}"';
        if (id == null) return 'no tab is active';
        return _ref.read(pluginPanesProvider.notifier).close(id, slot)
            ? 'closed the ${slot.name} pane'
            : 'no ${slot.name} pane was open';

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

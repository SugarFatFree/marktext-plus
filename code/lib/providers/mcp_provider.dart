import 'dart:convert';
import 'dart:ui' show Size;

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'dart:io';
import '../core/diagnostics/resident_memory.dart';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../core/config/app_config.dart';
import '../core/constants.dart';
import '../models/tab_info.dart';
import '../services/app_log.dart';
import '../services/plugin_script_runtime.dart';
import '../services/self_update_service.dart';
import '../services/plugin_manager.dart';
import '../services/plugin_catalog_service.dart';
import '../services/mcp_server.dart';
import '../services/mcp_tools.dart';
import 'editor_provider.dart';
import '../services/clipboard_service.dart';
import '../services/editor_window.dart';
import '../services/format_target.dart';
import '../services/window_capture.dart';
import '../services/window_placement.dart';
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
  McpController(
    this._ref, {
    this.window = const PlatformEditorWindow(),
    this.formatPatience = const Duration(seconds: 3),
  }) : super(const McpStatus());

  final Ref _ref;

  /// The window this editor is drawn in. Injectable because `window_manager`
  /// speaks to the platform over a channel and there is no platform under
  /// `flutter test`.
  final EditorWindow window;

  /// How long to wait for a pane to take a formatting command.
  ///
  /// A pane clears the request on its next frame, which is milliseconds when
  /// the editor is idle and much longer while a large document is being
  /// redrawn. Three seconds is generous for the second case and irrelevant to
  /// the first; a test with no pane at all shortens it rather than waiting.
  final Duration formatPatience;
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

    // What the window looks like, so an agent that moves it can put it back.
    //
    // Found by doing exactly that: `set_window` was used on a real machine
    // before anything had read what was there, and there was nothing to read
    // it with — the editor was left 1200 wide when it had been maximised, and
    // only the startup trace remembered that. `set_window` cannot answer
    // without changing something, and should not: "nothing to do" is the right
    // reply to a request that asks for nothing.
    //
    // Omitted rather than faked when the platform will not answer, for the
    // reason [resident] is omitted: the absence of a measurement is not one.
    WindowReading? windowNow;
    try {
      windowNow = await window.read();
    } catch (_) {
      // No platform under the tests, and an older runner may not answer
      // either. Everything else here is still worth having.
    }

    return {
      // Which editor is answering. An agent can update this one now, and
      // after the installer has run the only question that matters is what
      // came back; the handshake carries this too, but a client reads that
      // once at connect time and never surfaces it again.
      'version': AppConstants.appVersion,
      'viewMode': config.editMode.name,
      'activeTabId': tabs.activeTabId,
      if (resident != null) 'residentMB': resident,
      if (windowNow != null)
        'window': {
          'state': windowNow.state.name,
          'width': windowNow.size.width.round(),
          'height': windowNow.size.height.round(),
        },
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
      // Named back with the ones there are. An agent that guessed wrong has
      // the schema to re-read, but the answer costs nothing to carry and
      // saves the round trip; every other closed set here does the same.
      return mcpRefused('action "$action" is not available — '
          '${McpAction.values.map((a) => a.wireName).join(', ')}');
    }

    switch (wanted) {
      case McpAction.setViewMode:
        // The same two answers `close_pane` gives, for the same reasons. This
        // branch was left as it was when that one was fixed an hour earlier,
        // which is the miss this repository has recorded before: read the
        // siblings of the branch you touched.
        final modes = EditMode.values.map((m) => m.name).join(', ');
        final wantedMode = text('mode');
        if (wantedMode == null) return mcpRefused('no mode given — $modes');
        final mode =
            EditMode.values.where((m) => m.name == wantedMode).firstOrNull;
        if (mode == null) {
          return mcpRefused('unknown mode "$wantedMode" — $modes');
        }
        // Awaited, because the sentence below says it already happened. It
        // was not, so an agent that set the mode and asked for the state in
        // the next breath could be told "view mode is now split" and then
        // shown the old one — the editor saying something that is not so,
        // which is the fault this repository keeps finding.
        await _ref.read(settingsProvider.notifier).setEditMode(mode);
        return mcpDid('view mode is now ${mode.name}');

      case McpAction.newTab:
        final tab = TabInfo(
          id: 'mcp-${DateTime.now().microsecondsSinceEpoch}',
          fileName: text('path') ?? 'Untitled',
          content: text('content') ?? '',
        );
        _ref.read(tabProvider.notifier).addTab(tab);
        return mcpDid('opened tab ${tab.id}');

      case McpAction.saveTab:
        final id = text('tabId') ?? _ref.read(tabProvider).activeTabId;
        if (id == null) return mcpRefused('no tab to save');
        final saving =
            _ref.read(tabProvider).tabs.where((tab) => tab.id == id).firstOrNull;
        if (saving == null) return mcpRefused('there is no tab $id');
        // The same write Ctrl+S makes, through the same method auto-save uses,
        // so the checks cannot drift apart: the file must not have changed
        // underneath, and the encoding the write actually used is recorded.
        final to = text('path');
        switch (await _ref.read(tabProvider.notifier).saveToDisk(id, to: to)) {
          case SaveOutcome.saved:
            final now =
                _ref.read(tabProvider).tabs.where((t) => t.id == id).firstOrNull;
            // The name it wrote, which is not the name it had when `path`
            // gave a tab its first file — and that is the only case where
            // the two differ, so the answer was wrong in exactly the case
            // the caller most needs it: "saved Untitled as UTF-8" about a
            // file the caller had just named. `now` was already being read,
            // one line down, for the encoding.
            return mcpDid('saved ${(now ?? saving).fileName}'
                '${now == null ? '' : ' as ${now.encoding.label}'}');
          case SaveOutcome.nothingToWrite:
            return mcpDid('${saving.fileName} had nothing unsaved');
          case SaveOutcome.noFile:
            // No picker on this side, and inventing a path would put the
            // reader's document somewhere they never chose — so the caller
            // names one.
            return mcpRefused(
              '"${saving.fileName}" has no file behind it — pass "path" to '
              'say where to keep it',
            );
          case SaveOutcome.alreadyHasFile:
            return mcpRefused(
              '"${saving.fileName}" already has a file; moving a document the '
              'reader opened is not this action',
            );
          case SaveOutcome.pathNotAbsolute:
            return mcpRefused(
              '"$to" is relative, and the editor\'s working directory is not '
              'something you can see from there — give a whole path',
            );
          case SaveOutcome.wouldOverwrite:
            return mcpRefused(
              'there is already a file at "$to", and there is no picker here '
              'to ask about replacing it',
            );
          case SaveOutcome.conflict:
            return mcpRefused(
              '"${saving.fileName}" changed on disk since it was read — '
              'writing now would decide which version survives, which is the '
              "reader's to decide",
            );
          case SaveOutcome.failed:
            return mcpRefused('could not write ${saving.fileName}');
          case SaveOutcome.noTab:
            return mcpRefused('there is no tab $id');
        }

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
        final closing =
            _ref.read(tabProvider).tabs.where((tab) => tab.id == id).firstOrNull;
        if (closing == null) return mcpRefused('there is no tab $id');
        // The same refusal [McpAction.updateApp] makes, for the same reason it
        // gives: there is no automation on this side that can press Save, so
        // this names the tab rather than deciding for the reader. Closing a
        // modified tab lets its undo history go with it, so there is nothing
        // left to take the decision back with — and every way a *person* closes
        // a tab asks first, including the window's own close button. This was
        // the one way that did not.
        //
        // A tab with no file behind it counts too: auto-save skips those
        // entirely, so its contents exist nowhere else at all.
        //
        // `discard: true` is the same answer the reader gives that dialog by
        // pressing "Don't save". Refusing without it and accepting it when
        // given is the whole of the difference between an interface that
        // cannot tidy up after itself and one that throws work away silently:
        // the decision still has to be made, and now it can be made from here
        // and is recorded in what this answers with.
        final discard = arguments['discard'] == true;
        if (closing.isModified && !discard) {
          return mcpRefused(
            'not while "${closing.fileName}" has unsaved work — '
            'save_tab writes it first, or pass discard: true to answer the '
            '"Don\'t save" the reader would be asked',
          );
        }
        final lost = closing.isModified ? closing.content.length : 0;
        return _ref.read(tabProvider.notifier).removeTab(id)
            ? mcpDid(lost == 0
                ? 'closed tab $id'
                : 'closed tab $id, discarding $lost unsaved characters')
            : mcpRefused('there is no tab $id');

      case McpAction.reopenTab:
        // Named in the answer rather than left to `get_state`: the point of
        // taking a close back is knowing which document came back.
        final closed = _ref.read(tabProvider).recentlyClosed.firstOrNull;
        if (closed == null) {
          return mcpRefused('nothing has been closed in this session');
        }
        return await _ref.read(tabProvider.notifier).reopenLastClosedTab()
            ? mcpDid('reopened ${closed.fileName}')
            : mcpRefused(
                '"${closed.fileName}" could not be read back from '
                '${closed.filePath} — it has been moved or deleted since, '
                'and it is no longer offered',
              );

      case McpAction.setContent:
        final id = text('tabId') ?? _ref.read(tabProvider).activeTabId;
        final content = text('content');
        if (id == null) return mcpRefused('no tab to write to');
        if (content == null) return mcpRefused('no content given');
        // A restore point first, for the reason a plugin's rewrite gets one and
        // an edit in the preview gets one: the reader did not type this, and
        // Ctrl+Z is how they take back something they did not do. Every other
        // writer of a document in this application records one; this was the
        // one that did not, so an agent's rewrite either could not be undone at
        // all or stepped back past it to whatever the reader last typed.
        _ref.read(tabProvider.notifier).recordExternalEdit(id, content);
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

      case McpAction.updateApp:
        return updateApp(
          source: text('source') ?? 'release',
          ref: text('ref') ?? '',
          token: text('token'),
          dryRun: arguments['dryRun'] == true,
        );

      case McpAction.closePane:
        // "Missing" and "wrong" are different answers. Asked with no slot at
        // all this used to reply `unknown slot "null"` — a value the caller
        // never sent, quoted back at them as though they had. Both answers
        // name the slots there are, listed from the enum so there is no second
        // list of them to fall behind.
        final named = PluginPaneSlot.values.map((s) => s.name).join(', ');
        final wanted = text('slot');
        if (wanted == null) return mcpRefused('no slot given — $named');
        final slot =
            PluginPaneSlot.values.where((s) => s.name == wanted).firstOrNull;
        final id = _ref.read(tabProvider).activeTabId;
        if (slot == null) return mcpRefused('unknown slot "$wanted" — $named');
        if (id == null) return mcpRefused('no tab is active');
        return _ref.read(pluginPanesProvider.notifier).close(id, slot)
            ? mcpDid('closed the ${slot.name} pane')
            : mcpRefused('no ${slot.name} pane was open');

      case McpAction.format:
        return _format(text('format'));

      case McpAction.undo:
      case McpAction.redo:
        final back = wanted == McpAction.undo;
        final was = _ref.read(tabProvider).activeTabId;
        if (was == null) return mcpRefused('no tab to step');
        // The same method Edit ▸ Undo goes through, so the two cannot drift
        // the way they did before it was one method (BUG-494).
        final text = _ref.read(tabProvider.notifier).stepHistory(back: back);
        return text == null
            ? mcpRefused('there is nothing to ${back ? 'undo' : 'redo'}')
            : mcpDid('stepped ${back ? 'back' : 'forward'} to '
                '${text.length} characters');

      case McpAction.setClipboard:
        final plain = text('content');
        final html = text('html');
        if (plain == null) {
          return mcpRefused('no content given — the plain text to put on the '
              'clipboard, with "html" beside it when a browser would leave '
              'some');
        }
        // The reader's real clipboard, so say so rather than only in the
        // schema: whatever they had copied is gone after this.
        if (html == null || html.isEmpty) {
          await Clipboard.setData(ClipboardData(text: plain));
          return mcpDid('the clipboard holds ${plain.length} characters of '
              'plain text; whatever was on it is gone');
        }
        await ClipboardService.copyWithHtml(plain, html);
        return mcpDid('the clipboard holds ${plain.length} characters of plain '
            'text and ${html.length} of HTML, the way a browser leaves both; '
            'whatever was on it is gone');

      case McpAction.setWindow:
        return _setWindow(text('state'), arguments['width'], arguments['height']);

      case McpAction.setSetting:
        return _setSetting(text('setting'), arguments['value']);
    }
  }

  /// Runs one formatting command, and says whether anything carried it out.
  ///
  /// The refusal matters more than the doing. `applyFormat` only records a
  /// request; a pane picks it up on the next frame. In preview mode with no
  /// block open there is no pane to pick it up, so the request would sit in
  /// the state and fire the moment one appeared — an edit nobody asked for, at
  /// a time nobody chose. [FormatTarget] already knows which pane takes a
  /// command, and is asked here rather than copied.
  Future<McpOutcome> _format(String? name) async {
    final named = FormatAction.values.map((f) => f.name).join(', ');
    if (name == null) return mcpRefused('no format given — $named');
    final action = FormatAction.values.where((f) => f.name == name).firstOrNull;
    if (action == null) return mcpRefused('unknown format "$name" — $named');

    final mode = _ref.read(settingsProvider).editMode;
    final editing = _ref.read(editorProvider).previewBlockEditing;
    if (!FormatTarget.anything(mode: mode, previewBlockEditing: editing)) {
      return mcpRefused(
        'nothing would carry out $name: the reader is in preview mode with no '
        'block open, so there is no field to act in — set_view_mode to source '
        'or split first',
      );
    }

    final id = _ref.read(tabProvider).activeTabId;
    if (id == null) return mcpRefused('no tab to format');
    final editor = _ref.read(editorProvider.notifier);

    // The field, not the tab. The tab's copy is written on a 300 ms debounce,
    // so measuring it either side of a command that finishes in one frame
    // compares two copies of the text from *before* — which is how this came
    // to answer "the document is the same length" about a document that had
    // just grown by four characters, measured on a real machine (BUG-495).
    int? measure() =>
        editor.textOnScreen?.length ??
        _ref
            .read(tabProvider)
            .tabs
            .where((t) => t.id == id)
            .firstOrNull
            ?.content
            .length;
    final before = measure() ?? 0;

    editor.applyFormat(action);

    // Waited for rather than assumed. A pane clears the request when it has
    // acted, so this is the one observable that says it happened; without it
    // this would answer "applied bold" about a request still sitting in the
    // state.
    final gone = await _settled(
      () => _ref.read(editorProvider).pendingFormat == null,
    );
    if (!gone) {
      // Left there, it fires whenever a pane next appears. Clearing it is the
      // only honest end to a command nobody carried out.
      editor.clearFormat();
      return mcpRefused('$name was not carried out — no pane took it, and the '
          'request has been dropped rather than left to fire later');
    }

    final after = measure() ?? 0;
    return mcpDid(after == before
        ? 'ran $name; the document is the same length'
        : 'ran $name; the document went from $before to $after characters');
  }

  /// Polls [done] until it is true, or gives up. Says which happened.
  ///
  /// A condition rather than a sleep: a frame is a few milliseconds when the
  /// editor is idle and much longer while a large document is being redrawn,
  /// and a fixed wait is either wasted time or a wrong answer.
  Future<bool> _settled(bool Function() done) async {
    for (var waited = Duration.zero;
        waited < formatPatience;
        waited += const Duration(milliseconds: 20)) {
      if (done()) return true;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    return done();
  }

  /// Puts the window into a state, or gives it a size, and says what it became.
  ///
  /// The answer is read back off the window rather than repeated from the
  /// request: a window manager clamps a size to the work area and to the
  /// window's own minimum, so what was asked for and what happened are
  /// different numbers. Saying the first would be this editor describing a
  /// window that does not exist.
  Future<McpOutcome> _setWindow(
    String? state,
    Object? width,
    Object? height,
  ) async {
    final states = WindowState.values.map((s) => s.name).join(', ');

    WindowState? wanted;
    if (state != null) {
      wanted = WindowState.values.where((s) => s.name == state).firstOrNull;
      if (wanted == null) {
        return mcpRefused('unknown state "$state" — $states');
      }
    }

    // Both or neither: half a size is not a size, and guessing the other half
    // would resize the reader's window to something nobody asked for.
    final w = width is num ? width.toDouble() : null;
    final h = height is num ? height.toDouble() : null;
    if ((w == null) != (h == null)) {
      return mcpRefused('a size needs both "width" and "height"');
    }
    if (wanted == null && w == null) {
      return mcpRefused('nothing to do — pass "state" ($states), '
          'or "width" and "height"');
    }

    if (w != null) {
      // The floor session restore uses, for the reason written beside it:
      // below this the title bar is not reliably grabbable, and a reader
      // handed a window they cannot grab has no way back to a usable one.
      final least = WindowPlacement.minimumSize;
      if (w < least.width || h! < least.height) {
        return mcpRefused(
          'a window smaller than ${least.width.round()}×${least.height.round()} '
          'cannot reliably be grabbed by its title bar, and nothing here can '
          'give it back',
        );
      }
    }

    // The state first, then the size: a maximised window ignores a resize, so
    // whichever is asked for last has to be the one that lands.
    if (wanted != null) await window.apply(wanted);
    if (w != null) await window.resize(Size(w, h!));

    return mcpDid('the window is ${await window.read()}');
  }

  /// Writes one setting, and says what it actually became.
  ///
  /// Through [AppConfig]'s own JSON rather than through a switch over names:
  /// `toJson` and `fromJson` already enumerate every field, so this needs no
  /// third list to fall behind them.
  ///
  /// Worked out in full before anything is written, and that order is the whole
  /// of it. `fromJson` reads a value of the wrong type as the field's default,
  /// so writing first and checking after did not merely answer wrongly — it had
  /// already put the default in the config file and saved it. Asking for
  /// `fontSize: "large"` reset the reader's font size to 16 and then said it
  /// would not take the value, which is worse than not refusing at all.
  Future<McpOutcome> _setSetting(String? name, Object? value) async {
    if (name == null) return mcpRefused('no setting given');
    final refusal = McpSettings.notOverTheWire[name];
    if (refusal != null) return mcpRefused('$name is not set over this interface: $refusal');

    final notifier = _ref.read(settingsProvider.notifier);
    final before = notifier.state.toJson();
    if (!before.containsKey(name)) {
      return mcpRefused('no such setting "$name"');
    }
    if (value == null) {
      return mcpRefused('no value given for "$name"; it is now ${before[name]}');
    }

    final candidate = AppConfig.fromJson({...before, name: value});
    final after = candidate.toJson();
    if (!_sameSettingValue(after[name], value)) {
      return mcpRefused(
        '$name would not take ${jsonEncode(value)}; it reads as '
        '${jsonEncode(after[name])} — a value of the wrong kind is read as the '
        'default, so nothing was written',
      );
    }

    // Nothing else moved. Writing a setting goes out through `fromJson`, so a
    // field that does not survive that round trip would be reset every time any
    // setting was changed — quietly, and by the interface meant for checking
    // things.
    final collateral = [
      for (final key in after.keys)
        if (key != name && jsonEncode(after[key]) != jsonEncode(before[key]))
          key,
    ];
    if (collateral.isNotEmpty) {
      return mcpRefused(
        'setting $name would also change $collateral — that is a round trip '
        'fault in the config, and nothing was written',
      );
    }

    await notifier.updateConfig((_) => candidate);
    return mcpDid('$name is now ${jsonEncode(after[name])}');
  }

  /// Whether the setting took the value that was asked for.
  ///
  /// Numbers compared as numbers: a whole number arrives from the wire as `22`
  /// and a `double` field holds it as `22.0`, which is the same answer written
  /// two ways. Everything else compared as JSON, so a list or a string has to
  /// match exactly.
  static bool _sameSettingValue(Object? got, Object? asked) {
    if (got is num && asked is num) return got == asked;
    return jsonEncode(got) == jsonEncode(asked);
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

  /// Replaces this editor with the build [source] and [ref] name.
  ///
  /// Three answers, and they are deliberately different sentences: what would
  /// be installed (a dry run), what went wrong before anything ran, and the
  /// one case where this returns while the editor is on its way out.
  ///
  /// Nothing is stored. The token is a parameter of this call and lives as
  /// long as it; the repository is a constant in the service and not
  /// something a caller can point somewhere else.
  @visibleForTesting
  Future<McpOutcome> updateApp({
    required String source,
    required String ref,
    String? token,
    bool dryRun = false,
  }) async {
    final wanted = UpdateSource.byWireName(source);
    if (wanted == null) {
      return mcpRefused('unknown source "$source" — '
          '${UpdateSource.values.map((u) => u.wireName).join(' or ')}');
    }

    // Before anything is fetched, and skipped for a dry run: asking what
    // would be installed is worth answering with unsaved work open, and
    // installing it is not.
    //
    // `/CLOSEAPPLICATIONS` ends this process through the Restart Manager,
    // which asks and then stops waiting. A tab with unsaved text in it is
    // gone at that point, and nothing about the update would say so — the
    // editor would come back a version newer and a document short. There is
    // no automation on this side that can press Save, so this refuses and
    // names the tabs rather than deciding for the reader.
    //
    // Ahead of the request rather than after it: a refusal that costs a round
    // trip to GitHub first is a refusal that arrives late and looks like a
    // network fault.
    if (!dryRun) {
      final unsaved = _ref
          .read(tabProvider)
          .tabs
          .where((tab) => tab.isModified)
          .map((tab) => tab.fileName)
          .toList();
      if (unsaved.isNotEmpty) {
        return mcpRefused(
          'not while there is unsaved work: ${unsaved.join(', ')} — '
          'installing closes this editor, and what is in those tabs would go '
          'with it',
        );
      }
    }

    const service = SelfUpdateService();

    final UpdateBuild build;
    try {
      build = await service.find(source: wanted, ref: ref, token: token);
    } catch (error) {
      return mcpRefused('no build to install: $error');
    }

    if (dryRun) {
      return mcpDid('would install ${build.describe()} from ${build.url}');
    }

    // Refused here rather than after the download, because a build older than
    // the running one is nearly always a mistyped tag, and the cost of being
    // wrong is an editor rolled back without anybody meaning to. A CI build
    // is named after a commit and calls itself no version, so there is
    // nothing to compare — and answering "not older" about a comparison that
    // never happened would be a lie told by an empty string.
    if (build.version.isNotEmpty && !isNewerBuild(build.version, AppConstants.appVersion)) {
      return mcpRefused(
        'that build is ${build.version} and this one is ${AppConstants.appVersion} '
        '— name a newer tag, or use source "ci" to install a specific commit',
      );
    }

    final File installer;
    try {
      installer = await service.fetch(build, token: token);
    } catch (error) {
      return mcpRefused('$error');
    }

    try {
      // Where the installer should leave its account. The same directory the
      // startup trace goes to, which is the one this editor always has.
      final directory = await getApplicationSupportDirectory();
      final said = await service.apply(installer, logDirectory: directory.path);
      return mcpDid('${build.describe()}: $said');
    } catch (error) {
      return mcpRefused('${build.describe()} arrived and verified, '
          'but could not be installed: $error');
    }
  }

  /// Whether [candidate] is a later version than [current].
  ///
  /// Three parts compared as numbers. `update_service` has the same rule for
  /// the banner it shows the reader; this is the one that decides whether to
  /// replace the program, so it errs the other way — anything it cannot read
  /// as three numbers is not newer, and the caller is told to name a tag.
  @visibleForTesting
  static bool isNewerBuild(String candidate, String current) {
    List<int>? parts(String v) {
      final bits = v.trim().replaceFirst('v', '').split('.');
      if (bits.length != 3) return null;
      final numbers = [for (final b in bits) int.tryParse(b)];
      return numbers.contains(null) ? null : numbers.cast<int>();
    }

    final a = parts(candidate);
    final b = parts(current);
    if (a == null || b == null) return false;
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i] > b[i];
    }
    return false;
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

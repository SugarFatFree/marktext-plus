import 'dart:async';
import 'dart:convert';

import 'app_log.dart';
import '../core/diagnostics/startup_trace.dart';

/// Everything `control` can be asked to do.
///
/// The schema below is generated from these names, and the editor's handler
/// switches on this type, so the list an agent is shown and the list the
/// editor implements cannot drift apart: adding a value here is a compile
/// error until the handler answers it. They *had* drifted — two actions were
/// advertised for months that no code implemented anywhere.
enum McpAction {
  newTab('new_tab'),
  closeTab('close_tab'),

  /// Writes a tab to its own file, the way Ctrl+S does.
  ///
  /// Added because [closeTab] refuses a tab with unsaved work — there is no
  /// automation on this side that can press Save, so an agent that wrote to a
  /// tab could neither keep what it had written nor tidy the tab away. The
  /// missing piece was saving, not a way to discard: the explicit decision an
  /// automated caller can be asked for is "keep this", never "throw it away".
  saveTab('save_tab'),
  activateTab('activate_tab'),
  setViewMode('set_view_mode'),
  setContent('set_content'),
  closePane('close_pane'),
  runPluginCommand('run_plugin_command'),

  /// Installs a plugin from the catalogue, or updates one already installed.
  ///
  /// The same path the reader's Install button takes — HTTPS, the release's
  /// own SHA-256, and an archive unpacked with the limits and the refusal of
  /// paths that climb out of it. Nothing here loosens any of that; it only
  /// removes the need for somebody to press the button, so a plugin fix can
  /// be built, installed and driven without a person in the loop.
  installPlugin('install_plugin'),

  /// Replaces this editor with a newer build of itself.
  ///
  /// The loop this exists for: a fix is pushed, CI packages it, this installs
  /// it, and the editor comes back on the same port with the same token — so
  /// the fix can be exercised without anybody downloading anything. The build
  /// comes from this project's own repository and nowhere else, and it is
  /// checked against the SHA-256 the release or the artifact publishes before
  /// a single byte of it is run.
  updateApp('update_app'),

  /// Presses one of the icons in the right-hand rail.
  ///
  /// Not the same as running that command by name: a panel runs it with the
  /// drawer as the place its answer goes, and that path had no way in from
  /// here at all. A defect lived in it — an answer shown with no way to take
  /// it — precisely because everything automated went the other way.
  openPanel('open_panel'),

  /// Changes one of the reader's settings.
  ///
  /// The interface could open documents, write into them, save them and run
  /// plugins, and could not put the editor into the state a check needs: every
  /// change that shows up as an appearance — a font, a theme, a width, whether
  /// code blocks wrap — could only be verified by asking a person to open the
  /// settings page. An interface whose premise is that nobody is present was
  /// missing the one thing that makes an appearance testable at all.
  ///
  /// Not everything. See [McpSettings.notOverTheWire].
  setSetting('set_setting');

  const McpAction(this.wireName);

  /// The name an agent sends, which is snake_case where Dart is camelCase.
  final String wireName;

  /// The action [wireName] names, or null if nothing does.
  static McpAction? byWireName(String? wireName) =>
      values.where((a) => a.wireName == wireName).firstOrNull;
}

/// Which settings [McpAction.setSetting] will not touch, and why each.
///
/// A list of what is *refused* rather than of what is allowed, because
/// [AppConfig] already enumerates its own fields twice — in `toJson` and in
/// `fromJson` — and a third list of settable names beside them is the drift
/// this codebase keeps removing. A setting is applied by writing the name into
/// that JSON, so every field is reachable by construction and this says which
/// ones must not be.
///
/// A list of refusals fails *open*: a sensitive setting added later would be
/// settable until somebody remembered. So `mcp_settings_are_classified_test`
/// pins the whole field list and goes red when [AppConfig] grows one, which
/// turns "somebody remembers" into "the suite will not go green".
abstract final class McpSettings {
  static const notOverTheWire = <String, String>{
    // Credentials, and where a credential is sent. The host holds the key and
    // nothing else is ever handed it — a wire that could move the endpoint
    // could move the key with it.
    'aiApiKey': '凭据，永远不经过这个接口',
    'aiEndpoint': '改它就是改密钥发往哪里',
    'aiProvider': '同上，它决定请求去哪个服务',
    'aiEnabled': '和上面三个一组，整组都不放行',
    'aiModel': '同上',

    // The connection this very request arrived on.
    'mcpEnabled': '关掉它就再也连不上，只有人能打开',
    'mcpPort': '换端口等于挂断，而挂断之后没人能重连',
    'mcpToken': '换令牌等于把钥匙交给别处',

    // Records of what happened, not settings. Writing a scalar into one of
    // these would either do nothing or corrupt the record.
    'recentFiles': '这是记录不是设置',
    'sessionTabs': '这是记录不是设置',
    'sessionActiveTab': '这是记录不是设置',
    'sideBarDirectory': '这是记录不是设置',
    'sideBarOpenedFiles': '这是记录不是设置',
    'lastUpdateCheck': '更新检查的记账',
    'skipVersion': '写它会让读者再也收不到某个版本的更新提示',

    // Written by the window manager as the window moves. Setting them stores
    // a number and moves nothing, which would be the editor saying something
    // that is not so.
    'windowWidth': '窗口尺寸由窗口管理器写入，设它不会移动窗口',
    'windowHeight': '同上',
    'windowX': '同上',
    'windowY': '同上',
    'isMaximized': '同上',
    'splitRatio': '分隔条的位置由拖动写入，设它不会移动分隔条',

    // One thing, one way in.
    'editMode': 'set_view_mode 就是做这件事的，一件事两条路是这个仓库一直在删的缺陷',
  };
}

/// What an action did, and whether it did it.
///
/// A refusal reads as a sentence either way — "there is no tab x" — and a
/// caller checking `isError` needs the difference in the protocol, not only
/// in the prose.
typedef McpOutcome = ({String said, bool ok});

/// Something the editor did, with what to say about it.
McpOutcome mcpDid(String said) => (said: said, ok: true);

/// Something the editor did not do, and why.
McpOutcome mcpRefused(String said) => (said: said, ok: false);

/// One thing an agent can ask the editor to do.
class McpTool {
  const McpTool({
    required this.name,
    required this.description,
    required this.schema,
    required this.run,
  });

  final String name;
  final String description;

  /// JSON Schema for the arguments, as MCP describes tools.
  final Map<String, dynamic> schema;
  final FutureOr<McpContent> Function(Map<String, dynamic> arguments) run;

  Map<String, dynamic> describe() => {
    'name': name,
    'description': description,
    'inputSchema': schema,
  };
}

/// What a tool gives back: text, or an image, or both.
class McpContent {
  const McpContent(this.parts, {this.isError = false});

  McpContent.text(String text, {bool isError = false})
    : this([
        {'type': 'text', 'text': text},
      ], isError: isError);

  /// [bytes] as base64, which is how MCP carries an image.
  McpContent.image(List<int> bytes, {String mimeType = 'image/png'})
    : this([
        {'type': 'image', 'data': base64Encode(bytes), 'mimeType': mimeType},
      ]);

  final List<Map<String, dynamic>> parts;
  final bool isError;

  Map<String, dynamic> toJson() => {'content': parts, 'isError': isError};
}

/// What the editor can be asked to do, and what does it.
///
/// The bodies are supplied by the application — screenshots need a widget tree
/// and opening a file needs the tab notifier — so this holds functions rather
/// than reaching for them. It also means every tool can be exercised without
/// running an editor.
class McpToolset {
  const McpToolset({
    this.log,
    this.screenshot,
    this.recordGif,
    this.describeState,
    this.perform,
    this.startupTrace,
  });

  final AppLog? log;

  /// The startup trace, as text. Injectable so a test need not have started
  /// an application to have one.
  final String Function()? startupTrace;

  /// PNG bytes of the editor window.
  final Future<List<int>> Function()? screenshot;

  /// GIF bytes of the next [Duration], capped by the caller.
  final Future<List<int>> Function(Duration length, int fps)? recordGif;

  /// What is open, as JSON: tabs, view mode, plugins.
  final Future<Map<String, dynamic>> Function()? describeState;

  /// Carries out one named action with arguments.
  ///
  /// [McpOutcome.ok] is false when the editor did not do what was asked — no
  /// such tab, no pane to close, an action nothing implements. The sentence
  /// alone was not enough: MCP reports failure in `isError`, and a caller
  /// reading that saw success for every refusal the editor phrased politely.
  final Future<McpOutcome> Function(
    String action,
    Map<String, dynamic> arguments,
  )?
  perform;

  /// The longest recording allowed.
  ///
  /// Five seconds of frames is already several megabytes of base64, and a GIF
  /// is for looking at an animation, not for recording a session.
  static const maxRecording = Duration(seconds: 5);

  List<McpTool> get all => [
    McpTool(
      name: 'read_logs',
      description:
          'Recent lines from the editor log, including plugin output. '
          'Use this to find out what just happened.',
      schema: {
        'type': 'object',
        'properties': {
          'limit': {
            'type': 'integer',
            'description': 'How many lines, newest last. Default 200.',
          },
          'level': {
            'type': 'string',
            'enum': ['debug', 'info', 'warning', 'error'],
            'description': 'Only lines at least this bad.',
          },
          'source': {
            'type': 'string',
            'description':
                'Only lines from this plugin id. Omit for everything.',
          },
        },
      },
      run: _readLogs,
    ),
    McpTool(
      name: 'read_startup_trace',
      description:
          'How long each step of starting up took, including the part before '
          'Dart runs — loading the executable, booting the engine, reading '
          'the snapshot. Previous launches are kept too, so a cold start can '
          'be compared with the warm ones after it. Use this when a launch '
          'is slow; read_logs carries only the milestones.',
      schema: {'type': 'object', 'properties': {}},
      run: _readStartupTrace,
    ),
    McpTool(
      name: 'screenshot',
      description: 'A PNG of the editor window as it looks right now.',
      schema: {'type': 'object', 'properties': {}},
      run: _screenshot,
    ),
    McpTool(
      name: 'record_gif',
      description:
          'Record the editor window as an animated GIF, for looking at an '
          'animation or a transition. Five seconds at most.',
      schema: {
        'type': 'object',
        'properties': {
          'seconds': {
            'type': 'number',
            'description': 'How long, up to 5. Default 3.',
          },
          'fps': {
            'type': 'integer',
            'description': 'Frames per second, 1 to 20. Default 10.',
          },
        },
      },
      run: _recordGif,
    ),
    McpTool(
      name: 'get_state',
      description:
          'What the editor has open: tabs, which is active, the view '
          'mode, the installed plugins and the panes they filled — and '
          '"residentMB", how many megabytes the process is holding, absent '
          'on a platform that will not say. Ask before and after opening '
          'something large: this editor is meant to stay light, and that is '
          'the number the claim is made of. '
          '"characters" counts UTF-16 units, which is what a length is in '
          'most languages; the status bar counts code points instead, so an '
          'emoji is one there and two here. The two disagree on purpose — '
          'the reader is told what they would count, and this is told what '
          'it can compare against a string it holds.',
      schema: {'type': 'object', 'properties': {}},
      run: _state,
    ),
    McpTool(
      name: 'control',
      description:
          'Drive the editor: open and close tabs, switch between them, '
          'change the view mode, write a tab\'s text, run a plugin command, '
          'close a plugin pane, install or update a plugin, update the '
          'editor itself.',
      schema: {
        'type': 'object',
        'required': ['action'],
        'properties': {
          'action': {
            'type': 'string',
            'enum': [for (final a in McpAction.values) a.wireName],
          },
          'path': {
            'type': 'string',
            'description':
                'What to call a new tab. This names the tab; it does not '
                'read the file, so pass the text as "content". For save_tab '
                'it is where to keep a tab that has no file yet — a whole '
                'path, and nothing there already.',
          },
          'tabId': {
            'type': 'string',
            'description': 'Which tab, from get_state. Defaults to the '
                'active one where an action allows it.',
          },
          'mode': {
            'type': 'string',
            'enum': ['source', 'preview', 'split'],
          },
          'content': {
            'type': 'string',
            'description': 'The text a tab should hold.',
          },
          'pluginId': {
            'type': 'string',
            'description': 'Which plugin. For a plugin already installed, '
                'the id from get_state; install_plugin also takes '
                '"owner/repo" for one that is not installed yet.',
          },
          'command': {
            'type': 'string',
            'description':
                'Which of its commands, from the plugin\'s command list in '
                'get_state.',
          },
          'slot': {
            'type': 'string',
            'enum': ['right', 'bottom', 'corner'],
          },
          'panelId': {
            'type': 'string',
            'description':
                'Which panel of that plugin to open, from its manifest. The '
                'rail draws one icon per panel.',
          },
          'source': {
            'type': 'string',
            'enum': ['release', 'ci'],
            'description':
                'For update_app: a published release, or what CI built for '
                'one commit. "ci" needs a token and is how a fix is tried '
                'without publishing a version for it.',
          },
          'ref': {
            'type': 'string',
            'description':
                'Which one: a release tag — for example v1.6.2 — or, for '
                'source "ci", anything that names a commit: the short sha, '
                'the whole one, or a branch such as dev for whatever its tip '
                'built. Empty with source "release" means the newest.',
          },
          'token': {
            'type': 'string',
            'description':
                'A GitHub token, used for this call and never written down. '
                'Needed only for source "ci": workflow artifacts are not '
                'public, on a public repository or otherwise.',
          },
          'setting': {
            'type': 'string',
            'description':
                'For set_setting: which one, by the name it has in the config '
                'file — previewFontFamily, themeName, editorMaxWidth. '
                'Credentials, the connection this request arrived on, and the '
                'records of what happened are refused by name, and the refusal '
                'says which it was.',
          },
          'value': {
            'description':
                'For set_setting: the value, of the kind that setting holds — '
                'a string, a number or true/false. A value of the wrong kind '
                'is refused rather than quietly read as the default.',
          },
          'dryRun': {
            'type': 'boolean',
            'description':
                'For update_app: work out which build would be installed and '
                'say so, without fetching or running anything.',
          },
          'answer': {
            'type': 'string',
            'description':
                'What to answer if the plugin asks something — for '
                'open_panel and for run_plugin_command alike. Without it, '
                'one that asks will wait, the way it waits for a reader, '
                'and nothing here can press the button.',
          },
        },
      },
      run: _control,
    ),
  ];

  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    final tool = all.where((t) => t.name == name).firstOrNull;
    if (tool == null) {
      return McpContent.text('no tool called "$name"', isError: true).toJson();
    }
    try {
      return (await tool.run(arguments)).toJson();
    } catch (error) {
      // Reported as a failed tool call rather than a protocol error: the agent
      // asked a reasonable question and deserves the answer, not a disconnect.
      return McpContent.text('$name failed: $error', isError: true).toJson();
    }
  }

  McpContent _readLogs(Map<String, dynamic> arguments) {
    final source = log ?? AppLog.instance;
    final level = LogLevel.values
        .where((l) => l.name == arguments['level'])
        .firstOrNull;
    final text = source.asText(
      limit: _asInt(arguments['limit']) ?? 200,
      atLeast: level,
      source: arguments['source'] as String?,
    );
    return McpContent.text(text.isEmpty ? '(no log lines)' : text);
  }

  McpContent _readStartupTrace(Map<String, dynamic> arguments) {
    final read = startupTrace ?? StartupTrace.readBack;
    final text = read();
    return McpContent.text(
      text.isEmpty
          ? '(no startup trace yet — nothing has been marked, or the '
              'directory to write it to has not been resolved)'
          : text,
    );
  }

  Future<McpContent> _screenshot(Map<String, dynamic> arguments) async {
    final take = screenshot;
    if (take == null) {
      return McpContent.text('screenshots are not available', isError: true);
    }
    return McpContent.image(await take());
  }

  Future<McpContent> _recordGif(Map<String, dynamic> arguments) async {
    final record = recordGif;
    if (record == null) {
      return McpContent.text('recording is not available', isError: true);
    }
    final seconds = _asDouble(arguments['seconds']) ?? 3.0;
    final requested = Duration(milliseconds: (seconds * 1000).round());
    // Clamped rather than refused: an agent asking for ten seconds wants to
    // see the animation, and five seconds of it is still an answer.
    final length = requested > maxRecording ? maxRecording : requested;
    final fps = (_asInt(arguments['fps']) ?? 10).clamp(1, 20);
    return McpContent.image(await record(length, fps), mimeType: 'image/gif');
  }

  Future<McpContent> _state(Map<String, dynamic> arguments) async {
    final describe = describeState;
    if (describe == null) {
      return McpContent.text('state is not available', isError: true);
    }
    return McpContent.text(
      const JsonEncoder.withIndent('  ').convert(await describe()),
    );
  }

  Future<McpContent> _control(Map<String, dynamic> arguments) async {
    final act = perform;
    if (act == null) {
      return McpContent.text('control is not available', isError: true);
    }
    final action = arguments['action'];
    if (action is! String || action.isEmpty) {
      return McpContent.text('no action given', isError: true);
    }
    final outcome = await act(action, arguments);
    return McpContent.text(outcome.said, isError: !outcome.ok);
  }

  static int? _asInt(Object? value) =>
      value is int ? value : (value is num ? value.toInt() : null);

  static double? _asDouble(Object? value) =>
      value is num ? value.toDouble() : null;
}

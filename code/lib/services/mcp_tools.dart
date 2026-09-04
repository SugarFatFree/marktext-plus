import 'dart:async';
import 'dart:convert';

import 'app_log.dart';

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
  });

  final AppLog? log;

  /// PNG bytes of the editor window.
  final Future<List<int>> Function()? screenshot;

  /// GIF bytes of the next [Duration], capped by the caller.
  final Future<List<int>> Function(Duration length, int fps)? recordGif;

  /// What is open, as JSON: tabs, view mode, plugins.
  final Future<Map<String, dynamic>> Function()? describeState;

  /// Carries out one named action with arguments, returning what it did.
  final Future<String> Function(String action, Map<String, dynamic> arguments)?
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
          'mode, the installed plugins and the panes they filled.',
      schema: {'type': 'object', 'properties': {}},
      run: _state,
    ),
    McpTool(
      name: 'control',
      description:
          'Drive the editor: open a file, switch tabs, change the view '
          'mode, run a plugin command, close a pane.',
      schema: {
        'type': 'object',
        'required': ['action'],
        'properties': {
          'action': {
            'type': 'string',
            'enum': [
              'open_file',
              'new_tab',
              'close_tab',
              'activate_tab',
              'set_view_mode',
              'set_content',
              'run_plugin_command',
              'close_pane',
            ],
          },
          'path': {'type': 'string'},
          'tabId': {'type': 'string'},
          'mode': {
            'type': 'string',
            'enum': ['source', 'preview', 'split'],
          },
          'content': {'type': 'string'},
          'pluginId': {'type': 'string'},
          'command': {'type': 'string'},
          'slot': {
            'type': 'string',
            'enum': ['right', 'bottom', 'corner'],
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
    return McpContent.text(await act(action, arguments));
  }

  static int? _asInt(Object? value) =>
      value is int ? value : (value is num ? value.toInt() : null);

  static double? _asDouble(Object? value) =>
      value is num ? value.toDouble() : null;
}

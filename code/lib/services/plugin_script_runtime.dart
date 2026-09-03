import 'package:lua_dardo/lua.dart';

/// A plugin script that could not be loaded or ran into an error.
class PluginScriptException implements Exception {
  const PluginScriptException(this.message);

  final String message;

  @override
  String toString() => 'PluginScriptException: $message';
}

/// What the editor tells a plugin about the moment its command fired.
class PluginScriptContext {
  const PluginScriptContext({
    required this.command,
    this.selection = '',
    this.document = '',
    this.answer,
  });

  /// The manifest id of the menu entry or command the reader chose.
  final String command;

  /// The selected text, empty when nothing is selected.
  final String selection;

  /// The whole document.
  final String document;

  /// What the reader typed the last time the script asked a question.
  final String? answer;

  PluginScriptContext withAnswer(String value) => PluginScriptContext(
        command: command,
        selection: selection,
        document: document,
        answer: value,
      );
}

/// What a plugin asks the editor to do next.
///
/// The script is synchronous — Lua here has no coroutines — so anything that
/// takes time (asking the reader, calling a model) is handed back as one of
/// these and performed by the editor, which then calls the script again. The
/// plugin still owns the prompt and the flow; the editor owns the I/O and the
/// credentials.
sealed class PluginScriptAction {
  const PluginScriptAction();
}

/// Ask the reader a question, then run the command again with the answer.
class PluginAskAction extends PluginScriptAction {
  const PluginAskAction({required this.label, required this.defaultValue});

  final String label;
  final String defaultValue;
}

/// Send [prompt] to the model the reader configured, then call `on_result`.
///
/// The API key never reaches the script.
class PluginAiAction extends PluginScriptAction {
  const PluginAiAction(this.prompt);

  final String prompt;
}

/// Show two texts side by side. Nothing is written to the document.
class PluginDiffAction extends PluginScriptAction {
  const PluginDiffAction({required this.original, required this.result});

  final String original;
  final String result;
}

/// Say something to the reader and stop.
class PluginNotifyAction extends PluginScriptAction {
  const PluginNotifyAction(this.message);

  final String message;
}

/// Replace the current selection. Only for plugins that asked for it.
class PluginReplaceAction extends PluginScriptAction {
  const PluginReplaceAction(this.text);

  final String text;
}

/// The script chose to do nothing.
class PluginNoAction extends PluginScriptAction {
  const PluginNoAction();
}

/// Runs one plugin's script, whatever language it is written in.
///
/// Every runtime speaks the same protocol: `on_command` returns an action, the
/// host performs it, `on_result` gets what came back. That protocol is what
/// lets a plugin author pick a language without the editor caring which.
abstract class PluginRuntimeHost {
  /// Runs the script's `on_command` for [context].
  PluginScriptAction runCommand(PluginScriptContext context);

  /// Hands a host result back to the script's `on_result`.
  PluginScriptAction onResult(PluginScriptContext context, String result);

  /// The plugin's settings, as the script left them.
  Map<String, String> get storage;

  /// Whether the script wrote anything, so the host knows to save.
  bool get storageChanged;

  void dispose();
}

/// Runs a plugin written in Lua.
///
/// The interpreter is pure Dart, so a plugin is a text file that runs on any
/// machine the editor runs on — no SDK, no per-platform binaries, nothing for
/// the plugin author to compile.
class PluginScriptRuntime implements PluginRuntimeHost {
  PluginScriptRuntime(
    String source, {
    Map<String, String> storage = const {},
    Map<String, String> strings = const {},
  })  : _storage = Map<String, String>.of(storage),
        _strings = Map<String, String>.of(strings) {
    _state = LuaState.newState();
    _state.openLibs();
    _sandbox();
    _installCapabilities();
    // The compiler throws on a syntax error rather than returning a status,
    // so a plugin with a typo in it would otherwise reach the editor as a raw
    // exception from inside the interpreter.
    final ThreadStatus status;
    try {
      status = _state.loadString(source);
    } catch (error) {
      throw PluginScriptException(_describe(error));
    }
    if (status != ThreadStatus.luaOk) {
      final message = _state.toStr(-1) ?? 'the script could not be parsed';
      _state.pop(1);
      throw PluginScriptException(message);
    }
    _protectedCall(0, 0);
  }

  late final LuaState _state;
  final Map<String, String> _storage;
  final Map<String, String> _strings;
  bool _disposed = false;
  bool _storageChanged = false;

  /// The plugin's own settings, as the script left them.
  ///
  /// A plugin keeps its settings in its own file under its own directory, so
  /// one plugin cannot read or overwrite another's.
  @override
  Map<String, String> get storage => Map.unmodifiable(_storage);

  /// Whether the script wrote anything, so the host knows to save.
  @override
  bool get storageChanged => _storageChanged;

  /// Removes what a plugin from a stranger's repository must not reach.
  ///
  /// `openLibs` brings in `os` — which has `execute`, `remove`, `rename`,
  /// `getenv` and `exit` — along with `package` and the file-loading half of
  /// the base library. The script keeps `string`, `table` and `math`; anything
  /// beyond that it asks the editor for, and the editor decides.
  void _sandbox() {
    for (final global in const [
      'os',
      'package',
      'require',
      'dofile',
      'loadfile',
    ]) {
      _state.pushNil();
      _state.setGlobal(global);
    }
  }

  /// The capabilities a plugin may use without asking the editor first.
  ///
  /// These are local and immediate — reading its own settings, looking up its
  /// own translated strings — so they are ordinary functions. Anything that
  /// takes time or touches the reader's credentials is an action instead.
  void _installCapabilities() {
    _state.newTable();
    _state.pushDartFunction((ls) {
      final key = ls.toStr(1);
      final value = key == null ? null : _storage[key];
      if (value == null) {
        ls.pushNil();
      } else {
        ls.pushString(value);
      }
      return 1;
    });
    _state.setField(-2, 'get');
    _state.pushDartFunction((ls) {
      final key = ls.toStr(1);
      final value = ls.toStr(2);
      if (key != null) {
        if (value == null) {
          _storage.remove(key);
        } else {
          _storage[key] = value;
        }
        _storageChanged = true;
      }
      return 0;
    });
    _state.setField(-2, 'set');
    _state.setGlobal('storage');

    // A plugin ships its own strings for whatever languages its author wants
    // to support; the host resolves the reader's locale and hands the winning
    // table in. An unknown key comes back as itself so a missing translation
    // shows a key rather than an empty menu entry.
    _state.pushDartFunction((ls) {
      final key = ls.toStr(1) ?? '';
      ls.pushString(_strings[key] ?? key);
      return 1;
    });
    _state.setGlobal('t');
  }

  /// Runs the script's `on_command` for [context].
  @override
  PluginScriptAction runCommand(PluginScriptContext context) =>
      _invoke('on_command', context, null);

  @override
  /// Hands the model's reply back to the script's `on_result`.
  @override
  PluginScriptAction onResult(PluginScriptContext context, String result) =>
      _invoke('on_result', context, result);

  @override
  void dispose() => _disposed = true;

  PluginScriptAction _invoke(
    String function,
    PluginScriptContext context,
    String? result,
  ) {
    if (_disposed) {
      throw const PluginScriptException('the plugin script was disposed');
    }
    if (_state.getGlobal(function) != LuaType.luaFunction) {
      _state.pop(1);
      // A plugin that contributes a menu entry but never handles it is a
      // mistake in the plugin, not a reason to take the editor down.
      return const PluginNoAction();
    }

    _pushContext(context);
    var arguments = 1;
    if (result != null) {
      _state.pushString(result);
      arguments = 2;
    }
    _protectedCall(arguments, 1);

    final action = _readAction();
    _state.pop(1);
    return action;
  }

  void _pushContext(PluginScriptContext context) {
    _state.newTable();
    _state.pushString(context.command);
    _state.setField(-2, 'command');
    _state.pushString(context.selection);
    _state.setField(-2, 'selection');
    _state.pushString(context.document);
    _state.setField(-2, 'document');
    if (context.answer == null) {
      _state.pushNil();
    } else {
      _state.pushString(context.answer);
    }
    _state.setField(-2, 'answer');
  }

  PluginScriptAction _readAction() {
    if (!_state.isTable(-1)) return const PluginNoAction();

    final ask = _field('ask');
    if (ask != null) {
      return PluginAskAction(
        label: ask,
        defaultValue: _field('default') ?? '',
      );
    }

    final ai = _field('ai');
    if (ai != null) return PluginAiAction(ai);

    final notify = _field('notify');
    if (notify != null) return PluginNotifyAction(notify);

    final replace = _field('replace');
    if (replace != null) return PluginReplaceAction(replace);

    if (_state.getField(-1, 'diff') == LuaType.luaTable) {
      final original = _field('original') ?? '';
      final translated = _field('result') ?? '';
      _state.pop(1);
      return PluginDiffAction(original: original, result: translated);
    }
    _state.pop(1);

    return const PluginNoAction();
  }

  /// The string at `table[key]`, or null when it is absent or not a string.
  String? _field(String key) {
    final type = _state.getField(-1, key);
    final value = type == LuaType.luaString ? _state.toStr(-1) : null;
    _state.pop(1);
    return value;
  }

  void _protectedCall(int arguments, int results) {
    final ThreadStatus status;
    try {
      status = _state.pCall(arguments, results, 0);
    } catch (error) {
      throw PluginScriptException(_describe(error));
    }
    if (status != ThreadStatus.luaOk) {
      final message = _state.toStr(-1) ?? 'the script raised an error';
      _state.pop(1);
      throw PluginScriptException(message);
    }
  }

  /// The interpreter's message without the `Exception:` Dart wraps it in,
  /// because this is shown to whoever is writing the plugin.
  static String _describe(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}

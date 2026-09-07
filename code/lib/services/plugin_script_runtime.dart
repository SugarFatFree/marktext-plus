import 'package:lua_dardo/lua.dart';

import 'plugin_ui.dart';

/// Reads one of a plugin's own files, by module name.
///
/// Returns null when the plugin has no such module. The host resolves the
/// name; a runtime never sees a path, so it cannot be handed one that leaves
/// the plugin's directory.
typedef PluginModuleLoader = String? Function(String name);

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
    this.view = '',
  });

  /// The manifest id of the menu entry or command the reader chose.
  final String command;

  /// The selected text, empty when nothing is selected.
  final String selection;

  /// The whole document.
  final String document;

  /// What the reader typed the last time the script asked a question.
  final String? answer;

  /// How the reader is looking at the document: `source`, `preview` or
  /// `split`, and empty where there is no document in view.
  ///
  /// So a plugin can answer in kind. A translated document drawn as raw
  /// Markdown beside a rendered preview is not comparable to the thing it sits
  /// beside, and the plugin could not tell which it was.
  final String view;

  PluginScriptContext withAnswer(String value) => PluginScriptContext(
        command: command,
        selection: selection,
        document: document,
        answer: value,
        view: view,
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
  const PluginAskAction({
    required this.label,
    required this.defaultValue,
    this.choices = const [],
  });

  final String label;
  final String defaultValue;

  /// Answers worth offering outright, if the plugin knows any.
  ///
  /// Anything typed is still accepted: a list of common languages saves the
  /// reader spelling one out, and does not stop them naming a language that
  /// is not on it.
  final List<String> choices;
}

/// Send [prompt] to the model the reader configured, then call `on_result`.
///
/// The API key never reaches the script.
class PluginAiAction extends PluginScriptAction {
  const PluginAiAction(this.prompt);

  final String prompt;
}

/// Show one result, briefly and small. Nothing is written to the document.
class PluginShowAction extends PluginScriptAction {
  const PluginShowAction({required this.text, this.title = ''});

  final String text;
  final String title;
}

/// Where a pane the plugin filled is put.
///
/// The editor already splits a tab between source and preview; this is that
/// split offered to a plugin. The document keeps the first cell of a two by
/// two grid and a plugin may fill the other three.
enum PluginPaneSlot {
  /// Beside the document.
  right,

  /// Under it.
  bottom,

  /// The fourth cell, under the right-hand pane.
  corner,
}

/// How a pane's text is drawn.
enum PluginPaneRender {
  /// As it stands. The default: most answers are not documents.
  text,

  /// As Markdown source, in the editor's code font.
  source,

  /// Rendered, the way the preview draws the document.
  preview,
}

/// Show text in one of the panes beside the document.
class PluginPaneAction extends PluginScriptAction {
  const PluginPaneAction({
    required this.text,
    this.title = '',
    this.slot = PluginPaneSlot.right,
    this.render = PluginPaneRender.text,
    this.append = false,
    this.nextPrompt,
    this.replaces = '',
    this.canApply = false,
  });

  final String text;
  final String title;
  final PluginPaneSlot slot;
  final PluginPaneRender render;

  /// Add to what the pane holds rather than replacing it.
  final bool append;

  /// Offer to write this back into the document.
  ///
  /// A rewrite or a correction is shown before it is applied: what a model
  /// returns is worth reading before it lands in what the reader was writing.
  /// Needs `document.write`, and the editor checks that when the button is
  /// pressed rather than trusting the flag.
  final bool canApply;

  /// What accepting would replace. Empty means the whole document.
  ///
  /// Held from when the plugin ran, so accepting replaces what it was looking
  /// at rather than whatever happens to be selected by the time the reader
  /// presses the button.
  final String replaces;

  /// Something more to ask the model, once this has been shown.
  ///
  /// This is what lets a plugin work through a document a block at a time and
  /// show each one as it arrives. Without it every way of showing something
  /// ended the run, so the only way to translate a document was to send the
  /// whole thing at once and wait.
  final String? nextPrompt;
}

/// Show one result in a panel beside the document, not on top of it.
///
/// For something document-sized: a reader comparing a translation against what
/// is on screen cannot do it through a dialog covering the screen.
class PluginPanelAction extends PluginScriptAction {
  const PluginPanelAction({required this.text, this.title = ''});

  final String text;
  final String title;
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
/// A tree the editor draws, and the events it sends back.
///
/// The container it lands in is the one the command was started from — a
/// drawer, a card, a pane — because that is where the reader was looking.
class PluginUiAction extends PluginScriptAction {
  const PluginUiAction({required this.root, this.title = ''});

  final PluginUiNode root;
  final String title;
}

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

  /// Tells the script that the reader used something it drew.
  ///
  /// [id] is what the node was given in the tree, and [values] holds every
  /// input in that tree by id — a button press is only useful together with
  /// what was typed beside it, and asking the plugin to remember what it drew
  /// would make it keep state the editor already has.
  PluginScriptAction onEvent(
    PluginScriptContext context,
    String id,
    Map<String, String> values,
  );

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
    PluginModuleLoader? modules,
  })  : _storage = Map<String, String>.of(storage),
        _strings = Map<String, String>.of(strings),
        _modules = modules {
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
  final PluginModuleLoader? _modules;
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

    _installRequire();
  }

  /// `require`, resolving only inside the plugin's own directory.
  ///
  /// The sandbox removed `require` outright because it can load anything on
  /// the disk. That also made a plugin one file forever — no splitting a large
  /// one up, and no third party wrapping these capabilities in something an
  /// author could reuse. What was wanted was not "no require" but one that
  /// cannot leave home: the host resolves the name and hands back source, so
  /// this never sees a path at all.
  void _installRequire() {
    final modules = _modules;
    if (modules == null) return;

    _state.pushDartFunction((ls) {
      final name = ls.toStr(1);
      final source = name == null ? null : modules(name);
      if (source == null) {
        ls.pushNil();
      } else {
        ls.pushString(source);
      }
      return 1;
    });
    _state.setGlobal('__load');

    // Written in Lua because `load` is what compiles it, and the caching and
    // error message read better here than as stack manipulation in Dart.
    final status = _state.loadString(r'''
local __loaded = {}
function require(name)
  if __loaded[name] ~= nil then return __loaded[name] end
  local source = __load(name)
  if source == nil then
    error("no module '" .. tostring(name) .. "' in this plugin", 2)
  end
  local chunk, err = load(source, name)
  if chunk == nil then
    error("module '" .. tostring(name) .. "' has an error: " .. tostring(err), 2)
  end
  local value = chunk()
  if value == nil then value = true end
  __loaded[name] = value
  return value
end
''');
    if (status != ThreadStatus.luaOk) {
      _state.pop(1);
      return;
    }
    _protectedCall(0, 0);
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
  PluginScriptAction onEvent(
    PluginScriptContext context,
    String id,
    Map<String, String> values,
  ) =>
      _invoke('on_event', context, null, eventId: id, values: values);

  @override
  void dispose() => _disposed = true;

  PluginScriptAction _invoke(
    String function,
    PluginScriptContext context,
    String? result, {
    String? eventId,
    Map<String, String> values = const {},
  }) {
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
    if (eventId != null) {
      // `on_event(ctx, id, values)`. The values table is the editor's record
      // of what the reader typed, so the plugin does not have to keep its own
      // copy of a form it drew one step ago.
      _state.pushString(eventId);
      _state.newTable();
      for (final entry in values.entries) {
        _state.pushString(entry.value);
        _state.setField(-2, entry.key);
      }
      arguments = 3;
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
    _state.pushString(context.view);
    _state.setField(-2, 'view');
  }

  PluginScriptAction _readAction() {
    if (!_state.isTable(-1)) return const PluginNoAction();

    // Read before the string-shaped actions: a `ui` is a table, so `_field`
    // would see it as absent and the plugin's tree would be dropped in
    // silence.
    if (_state.getField(-1, 'ui') == LuaType.luaTable) {
      var budget = PluginUiLimits.maxNodes;
      final root = _readUiNode(0, () => budget-- > 0);
      _state.pop(1);
      if (root != null) {
        return PluginUiAction(root: root, title: _field('title') ?? '');
      }
      // A tree too deep or too large is refused whole rather than drawn in
      // part: half a form is worse than none, and the plugin can be told.
      throw const PluginScriptException(
        'the interface is too large or too deeply nested to draw',
      );
    }
    _state.pop(1);

    final ask = _field('ask');
    if (ask != null) {
      return PluginAskAction(
        label: ask,
        defaultValue: _field('default') ?? '',
        choices: _stringList('choices'),
      );
    }

    // `pane` is read before `ai`, because a table carrying both means "show
    // this, then ask that" — a plugin working through a document a block at a
    // time. Reading `ai` first would swallow the block it had just finished.
    final pane = _field('pane');
    if (pane != null) return _readPane(pane);

    final ai = _field('ai');
    if (ai != null) return PluginAiAction(ai);

    final show = _field('show');
    if (show != null) {
      return PluginShowAction(text: show, title: _field('title') ?? '');
    }

    final panel = _field('panel');
    if (panel != null) {
      return PluginPanelAction(text: panel, title: _field('title') ?? '');
    }

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

  /// The strings in the array at `table[key]`, or empty when there is none.
  List<String> _stringList(String key) {
    if (_state.getField(-1, key) != LuaType.luaTable) {
      _state.pop(1);
      return const [];
    }
    final values = <String>[];
    for (var index = 1;; index++) {
      final type = _state.getI(-1, index);
      if (type != LuaType.luaString) {
        _state.pop(1);
        break;
      }
      final value = _state.toStr(-1);
      _state.pop(1);
      if (value == null) break;
      values.add(value);
    }
    _state.pop(1);
    return values;
  }

  /// The pane the script asked for, or a complaint about how it asked.
  PluginScriptAction _readPane(String text) {
    final named = _field('slot');
    final slot = named == null
        ? PluginPaneSlot.right
        : PluginPaneSlot.values
            .where((value) => value.name == named)
            .firstOrNull;
    if (slot == null) {
      // Guessing would put the pane somewhere the author did not ask for,
      // with no way for them to find out why.
      return PluginNotifyAction(
        'unknown pane slot "$named"; expected '
        '${PluginPaneSlot.values.map((s) => s.name).join(', ')}',
      );
    }

    final drawn = _field('as');
    final render = drawn == null || drawn.isEmpty
        ? PluginPaneRender.text
        : PluginPaneRender.values
            .where((value) => value.name == drawn)
            .firstOrNull;
    if (render == null) {
      return PluginNotifyAction(
        'unknown pane rendering "$drawn"; expected '
        '${PluginPaneRender.values.map((r) => r.name).join(', ')}',
      );
    }

    return PluginPaneAction(
      text: text,
      title: _field('title') ?? '',
      slot: slot,
      render: render,
      append: _boolean('append'),
      nextPrompt: _field('ai'),
      canApply: _boolean('apply'),
      replaces: _field('replaces') ?? '',
    );
  }

  /// One node of a plugin's interface, read from the table on top of the
  /// stack. Null when the shape is not one this editor draws, or when the
  /// tree has gone past what [PluginUiLimits] allows.
  ///
  /// [spend] returns false once the node budget is gone. Depth and count are
  /// both bounded because this recurses: without them a plugin decides how
  /// much of the editor's stack to use, and a plugin is not the one who
  /// should decide that.
  PluginUiNode? _readUiNode(int depth, bool Function() spend) {
    if (depth > PluginUiLimits.maxDepth) return null;
    if (!spend()) return null;
    if (!_state.isTable(-1)) return null;

    if (_state.getField(-1, 'text') == LuaType.luaString) {
      final text = _state.toStr(-1) ?? '';
      _state.pop(1);
      return PluginUiText(text, emphasis: _boolean('emphasis'));
    }
    _state.pop(1);

    if (_state.getField(-1, 'button') == LuaType.luaTable) {
      final node = PluginUiButton(
        id: _field('id') ?? '',
        label: _field('label') ?? '',
        primary: _boolean('primary'),
      );
      _state.pop(1);
      return node.id.isEmpty ? null : node;
    }
    _state.pop(1);

    if (_state.getField(-1, 'input') == LuaType.luaTable) {
      final node = PluginUiInput(
        id: _field('id') ?? '',
        value: _field('value') ?? '',
        placeholder: _field('placeholder') ?? '',
        multiline: _boolean('multiline'),
      );
      _state.pop(1);
      return node.id.isEmpty ? null : node;
    }
    _state.pop(1);

    if (_state.getField(-1, 'chips') == LuaType.luaTable) {
      final node = PluginUiChips(
        id: _field('id') ?? '',
        options: _stringList('options'),
      );
      _state.pop(1);
      return node.id.isEmpty ? null : node;
    }
    _state.pop(1);

    if (_state.getField(-1, 'markdown') == LuaType.luaString) {
      final source = _state.toStr(-1) ?? '';
      _state.pop(1);
      return PluginUiMarkdown(source);
    }
    _state.pop(1);

    if (_state.getField(-1, 'select') == LuaType.luaTable) {
      final node = PluginUiSelect(
        id: _field('id') ?? '',
        options: _stringList('options'),
        value: _field('value') ?? '',
      );
      _state.pop(1);
      return node.id.isEmpty ? null : node;
    }
    _state.pop(1);

    if (_state.getField(-1, 'checkbox') == LuaType.luaTable) {
      final node = PluginUiCheckbox(
        id: _field('id') ?? '',
        label: _field('label') ?? '',
        value: _boolean('value'),
      );
      _state.pop(1);
      return node.id.isEmpty ? null : node;
    }
    _state.pop(1);

    if (_state.getField(-1, 'image') == LuaType.luaTable) {
      final source = _field('source') ?? '';
      final height = _number('height');
      _state.pop(1);
      return source.isEmpty
          ? null
          : PluginUiImage(source: source, height: height);
    }
    _state.pop(1);

    if (_state.getField(-1, 'spacer') != LuaType.luaNil) {
      _state.pop(1);
      return const PluginUiSpacer();
    }
    _state.pop(1);

    for (final container in const ['row', 'column']) {
      if (_state.getField(-1, container) != LuaType.luaTable) {
        _state.pop(1);
        continue;
      }
      final children = <PluginUiNode>[];
      for (var index = 1;; index++) {
        if (_state.getI(-1, index) != LuaType.luaTable) {
          _state.pop(1);
          break;
        }
        final child = _readUiNode(depth + 1, spend);
        _state.pop(1);
        // One bad child refuses the tree rather than being skipped: a form
        // missing the field it was about looks like the plugin's bug.
        if (child == null) {
          _state.pop(1);
          return null;
        }
        children.add(child);
      }
      _state.pop(1);
      return container == 'row'
          ? PluginUiRow(children)
          : PluginUiColumn(children);
    }

    return null;
  }

  /// The number at `table[key]`, or zero when it is absent or not a number.
  double _number(String key) {
    _state.getField(-1, key);
    final value = _state.toNumberX(-1);
    _state.pop(1);
    return value ?? 0;
  }

  /// Whether `table[key]` is true. Anything else, including absent, is false.
  bool _boolean(String key) {
    _state.getField(-1, key);
    final value = _state.toBoolean(-1);
    _state.pop(1);
    return value;
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

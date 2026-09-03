import 'dart:convert';

import 'package:flutter_js/flutter_js.dart';

import 'plugin_script_runtime.dart';

/// Runs a plugin written in JavaScript.
///
/// Same protocol as the Lua runtime — `on_command` returns an action, the host
/// performs it, `on_result` takes what came back — so a plugin author picks the
/// language and nothing else in the editor changes.
///
/// QuickJS has no file, process or network access of its own: there is no
/// `require`, no `fs`, no `fetch`. Everything a plugin can reach is either
/// injected here or asked for through an action.
class PluginJsRuntime implements PluginRuntimeHost {
  PluginJsRuntime(
    String source, {
    Map<String, String> storage = const {},
    Map<String, String> strings = const {},
  })  : _storage = Map<String, String>.of(storage),
        _runtime = getJavascriptRuntime() {
    _install(strings);
    _evaluate(source, what: 'the plugin script');
  }

  final JavascriptRuntime _runtime;
  final Map<String, String> _storage;
  bool _storageChanged = false;
  bool _disposed = false;

  @override
  Map<String, String> get storage => Map.unmodifiable(_storage);

  @override
  bool get storageChanged => _storageChanged;

  /// The capabilities that need no permission and no waiting.
  ///
  /// Injected as plain objects rather than through a host bridge: the script
  /// is synchronous, and so is reading its own settings or its own strings.
  /// The settings are read back after every call, which is what tells the
  /// host whether there is anything to save.
  void _install(Map<String, String> strings) {
    _evaluate('''
globalThis.__storage = ${jsonEncode(_storage)};
globalThis.__strings = ${jsonEncode(strings)};
globalThis.__dirty = false;
globalThis.storage = {
  get: function (key) {
    return Object.prototype.hasOwnProperty.call(__storage, key)
      ? __storage[key]
      : null;
  },
  set: function (key, value) {
    if (value === null || value === undefined) {
      delete __storage[key];
    } else {
      __storage[key] = String(value);
    }
    __dirty = true;
  }
};
globalThis.t = function (key) {
  return Object.prototype.hasOwnProperty.call(__strings, key)
    ? __strings[key]
    : key;
};
''', what: 'the plugin sandbox');
  }

  @override
  PluginScriptAction runCommand(PluginScriptContext context) =>
      _invoke('on_command', context, null);

  @override
  PluginScriptAction onResult(PluginScriptContext context, String result) =>
      _invoke('on_result', context, result);

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _runtime.dispose();
  }

  PluginScriptAction _invoke(
    String function,
    PluginScriptContext context,
    String? result,
  ) {
    if (_disposed) {
      throw const PluginScriptException('the plugin script was disposed');
    }

    final arguments = [
      jsonEncode({
        'command': context.command,
        'selection': context.selection,
        'document': context.document,
        'answer': context.answer,
      }),
      if (result != null) jsonEncode(result),
    ].join(', ');

    // A plugin that contributes a menu entry but never handles it is a mistake
    // in the plugin, not a reason to take the editor down.
    final json = _evaluate(
      '''
(function () {
  if (typeof $function !== "function") return "null";
  return JSON.stringify($function($arguments)) || "null";
})()
''',
      what: function,
    );

    _readBackStorage();
    return parseAction(json);
  }

  void _readBackStorage() {
    final json = _evaluate(
      'JSON.stringify({ s: __storage, d: __dirty })',
      what: 'the plugin settings',
    );
    final decoded = jsonDecode(json);
    if (decoded is! Map) return;
    if (decoded['d'] == true) _storageChanged = true;
    final values = decoded['s'];
    if (values is Map) {
      _storage
        ..clear()
        ..addEntries(values.entries
            .where((e) => e.key is String && e.value is String)
            .map((e) => MapEntry(e.key as String, e.value as String)));
    }
  }

  /// Turns one action, as the script returned it, into what the host runs.
  ///
  /// Static and free of the engine so it can be tested: the QuickJS library
  /// only exists inside a built application, so everything that does not need
  /// it is kept where the test suite can reach it.
  static PluginScriptAction parseAction(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map) return const PluginNoAction();

    String? field(String key) {
      final value = decoded[key];
      return value is String ? value : null;
    }

    final ask = field('ask');
    if (ask != null) {
      return PluginAskAction(
        label: ask,
        defaultValue: field('default') ?? '',
      );
    }

    final ai = field('ai');
    if (ai != null) return PluginAiAction(ai);

    final notify = field('notify');
    if (notify != null) return PluginNotifyAction(notify);

    final replace = field('replace');
    if (replace != null) return PluginReplaceAction(replace);

    final diff = decoded['diff'];
    if (diff is Map) {
      return PluginDiffAction(
        original: diff['original'] is String ? diff['original'] as String : '',
        result: diff['result'] is String ? diff['result'] as String : '',
      );
    }

    return const PluginNoAction();
  }

  /// Evaluates [code], turning a JavaScript error into the exception the rest
  /// of the plugin system already knows how to report.
  String _evaluate(String code, {required String what}) {
    final JsEvalResult evaluated;
    try {
      evaluated = _runtime.evaluate(code);
    } catch (error) {
      throw PluginScriptException('$what could not run: $error');
    }
    if (evaluated.isError) {
      throw PluginScriptException('$what failed: ${evaluated.stringResult}');
    }
    return evaluated.stringResult;
  }
}

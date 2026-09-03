import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_js_runtime.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// QuickJS is a native library that only exists inside a built application, so
/// the engine itself cannot run here. What can run is everything around it:
/// the action a script returns is JSON, and turning that into what the editor
/// performs is the part a plugin author's mistake would land in.
void main() {
  test('a JS action becomes the same thing a Lua action does', () {
    expect(
      PluginJsRuntime.parseAction('{"ask":"Target language","default":"English"}'),
      isA<PluginAskAction>()
          .having((a) => a.label, 'label', 'Target language')
          .having((a) => a.defaultValue, 'default', 'English'),
    );
    expect(
      PluginJsRuntime.parseAction('{"ai":"translate this"}'),
      isA<PluginAiAction>().having((a) => a.prompt, 'prompt', 'translate this'),
    );
    expect(
      PluginJsRuntime.parseAction('{"notify":"nothing selected"}'),
      isA<PluginNotifyAction>()
          .having((a) => a.message, 'message', 'nothing selected'),
    );
    expect(
      PluginJsRuntime.parseAction('{"replace":"new text"}'),
      isA<PluginReplaceAction>(),
    );
    expect(
      PluginJsRuntime.parseAction('{"diff":{"original":"你好","result":"Hello"}}'),
      isA<PluginDiffAction>()
          .having((a) => a.original, 'original', '你好')
          .having((a) => a.result, 'result', 'Hello'),
    );
  });

  test('a script that returns nothing useful does nothing, and does not throw',
      () {
    expect(PluginJsRuntime.parseAction('null'), isA<PluginNoAction>());
    expect(PluginJsRuntime.parseAction('{}'), isA<PluginNoAction>());
    expect(PluginJsRuntime.parseAction('"a string"'), isA<PluginNoAction>());
    expect(PluginJsRuntime.parseAction('{"ai":42}'), isA<PluginNoAction>(),
        reason: '字段类型不对时不该当成有效动作');
  });

  test('a half-written diff still opens, with the half that is there', () {
    final action = PluginJsRuntime.parseAction('{"diff":{"result":"Hello"}}');
    expect((action as PluginDiffAction).original, isEmpty);
    expect(action.result, 'Hello');
  });

  test('the engine runs a plugin end to end', () {
    // Only inside a built application: `flutter test` has no QuickJS library,
    // and a test that cannot load it proves nothing about the plugin.
    final runtime = PluginJsRuntime(r'''
function on_command(ctx) { return { notify: "ran " + ctx.command }; }
''');
    addTearDown(runtime.dispose);
    expect(
      (runtime.runCommand(const PluginScriptContext(command: 'demo'))
              as PluginNotifyAction)
          .message,
      'ran demo',
    );
  }, skip: !_quickJsAvailable);
}

/// Whether the QuickJS native library is present, which it is only in a build.
final bool _quickJsAvailable = () {
  try {
    return Platform.environment.containsKey('MARKTEXT_QUICKJS_AVAILABLE');
  } catch (_) {
    return false;
  }
}();

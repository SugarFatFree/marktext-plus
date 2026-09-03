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

  test('the JS runtime understands the same actions as the Lua one', () {
    final show = PluginJsRuntime.parseAction(
        '{"show":"translated","title":"Japanese"}');
    expect((show as PluginShowAction).text, 'translated');
    expect(show.title, 'Japanese');

    final panel = PluginJsRuntime.parseAction(
        '{"panel":"the document","title":"Japanese"}');
    expect((panel as PluginPanelAction).text, 'the document');

    final ask = PluginJsRuntime.parseAction(
        '{"ask":"Language","default":"English","choices":["English","日本語"]}');
    expect((ask as PluginAskAction).choices, ['English', '日本語']);
  });

  test('the JS runtime knows panes and their slots too', () {
    final pane = PluginJsRuntime.parseAction(
        '{"pane":"text","title":"T","slot":"corner"}') as PluginPaneAction;
    expect(pane.slot, PluginPaneSlot.corner);
    expect(pane.text, 'text');

    expect(
      (PluginJsRuntime.parseAction('{"pane":"text"}') as PluginPaneAction).slot,
      PluginPaneSlot.right,
    );
    expect(PluginJsRuntime.parseAction('{"pane":"t","slot":"topLeft"}'),
        isA<PluginNotifyAction>());
  });

  test('the JS runtime reads a pane that carries the next prompt', () {
    final pane = PluginJsRuntime.parseAction(
      '{"pane":"block one","append":true,"ai":"next","as":"preview"}',
    ) as PluginPaneAction;
    expect(pane.text, 'block one');
    expect(pane.append, isTrue);
    expect(pane.nextPrompt, 'next');
    expect(pane.render, PluginPaneRender.preview);

    // `ai` alone still means ask and wait.
    expect(PluginJsRuntime.parseAction('{"ai":"p"}'), isA<PluginAiAction>());
  });

  test('a JS question with no choices is not given any', () {
    final ask = PluginJsRuntime.parseAction('{"ask":"Anything"}')
        as PluginAskAction;
    expect(ask.choices, isEmpty);
  });
}

/// Whether the QuickJS native library is present, which it is only in a build.
final bool _quickJsAvailable = () {
  try {
    return Platform.environment.containsKey('MARKTEXT_QUICKJS_AVAILABLE');
  } catch (_) {
    return false;
  }
}();

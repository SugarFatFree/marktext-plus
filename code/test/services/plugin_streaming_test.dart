import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// A plugin can show work as it arrives, instead of only when it is finished.
///
/// The protocol was one action per call and every way of showing something
/// ended the run, so a plugin translating a document had one choice: send the
/// whole thing to the model and wait. A long document then costs one enormous
/// request, several minutes of a window that looks stuck, and — when it fails
/// — everything rather than one paragraph.
void main() {
  PluginScriptAction run(String action) =>
      PluginScriptRuntime('function on_command(ctx) return $action end')
          .runCommand(const PluginScriptContext(command: 'c'));

  test('a pane can be added to instead of replaced', () {
    final action = run('{ pane = "more", append = true }') as PluginPaneAction;
    expect(action.append, isTrue);
  });

  test('a pane replaces by default', () {
    expect((run('{ pane = "x" }') as PluginPaneAction).append, isFalse);
  });

  test('a pane can carry the next thing to ask the model', () {
    final action =
        run('{ pane = "block one", append = true, ai = "translate two" }')
            as PluginPaneAction;
    expect(action.text, 'block one');
    expect(action.nextPrompt, 'translate two');
  });

  test('a pane with nothing after it is the end of the run', () {
    expect((run('{ pane = "done" }') as PluginPaneAction).nextPrompt, isNull);
  });

  test('an ai action on its own still means ask and wait', () {
    // Unchanged: a plugin that has nothing to show yet says only `ai`.
    expect(run('{ ai = "prompt" }'), isA<PluginAiAction>());
  });

  test('a plugin can walk a document a block at a time', () {
    // The shape the translate plugin uses: on_result appends what came back
    // and asks for the next block, until there are none left.
    final runtime = PluginScriptRuntime(r'''
local blocks = { "one", "two", "three" }

function on_command(ctx)
  storage.set("at", "1")
  return { ai = blocks[1] }
end

function on_result(ctx, result)
  local at = tonumber(storage.get("at")) + 1
  storage.set("at", tostring(at))
  if blocks[at] == nil then
    return { pane = result, append = true }
  end
  return { pane = result, append = true, ai = blocks[at] }
end
''');

    expect((runtime.runCommand(const PluginScriptContext(command: 'c'))
            as PluginAiAction).prompt, 'one');

    final first = runtime.onResult(
        const PluginScriptContext(command: 'c'), 'ONE') as PluginPaneAction;
    expect(first.text, 'ONE');
    expect(first.nextPrompt, 'two');

    final second = runtime.onResult(
        const PluginScriptContext(command: 'c'), 'TWO') as PluginPaneAction;
    expect(second.nextPrompt, 'three');

    final last = runtime.onResult(
        const PluginScriptContext(command: 'c'), 'THREE') as PluginPaneAction;
    expect(last.nextPrompt, isNull, reason: '没有下一段了，运行到此为止');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

const _translateScript = r'''
function on_command(ctx)
  if ctx.answer == nil then
    return { ask = "Target language", default = "English" }
  end
  local src = ctx.command == "translate.doc" and ctx.document or ctx.selection
  if src == "" then
    return { notify = "Select some text first" }
  end
  return { ai = "Translate to " .. ctx.answer .. ":\n\n" .. src }
end

function on_result(ctx, result)
  return { diff = { original = ctx.selection, result = result } }
end
''';

void main() {
  test('a command with no answer yet asks the reader for one', () {
    final runtime = PluginScriptRuntime(_translateScript);
    addTearDown(runtime.dispose);

    final action = runtime.runCommand(
      const PluginScriptContext(command: 'translate.sel', selection: '你好'),
    );

    expect(action, isA<PluginAskAction>());
    expect((action as PluginAskAction).label, 'Target language');
    expect(action.defaultValue, 'English');
  });

  test('with the answer in hand the script builds its own prompt', () {
    final runtime = PluginScriptRuntime(_translateScript);
    addTearDown(runtime.dispose);

    final action = runtime.runCommand(
      const PluginScriptContext(
        command: 'translate.sel',
        selection: '你好',
        answer: 'English',
      ),
    );

    expect(action, isA<PluginAiAction>());
    final prompt = (action as PluginAiAction).prompt;
    expect(prompt, contains('English'));
    expect(prompt, contains('你好'));
  });

  test('the whole-document command reads the document, not the selection', () {
    final runtime = PluginScriptRuntime(_translateScript);
    addTearDown(runtime.dispose);

    final action = runtime.runCommand(
      const PluginScriptContext(
        command: 'translate.doc',
        selection: 'ignored',
        document: '# 全文',
        answer: 'English',
      ),
    );

    expect((action as PluginAiAction).prompt, contains('# 全文'));
    expect(action.prompt, isNot(contains('ignored')));
  });

  test('an empty source becomes a message rather than a model call', () {
    final runtime = PluginScriptRuntime(_translateScript);
    addTearDown(runtime.dispose);

    final action = runtime.runCommand(
      const PluginScriptContext(command: 'translate.sel', answer: 'English'),
    );

    expect(action, isA<PluginNotifyAction>());
    expect((action as PluginNotifyAction).message, contains('Select'));
  });

  test('the model reply goes back to the script, which decides how to show it',
      () {
    final runtime = PluginScriptRuntime(_translateScript);
    addTearDown(runtime.dispose);

    final action = runtime.onResult(
      const PluginScriptContext(command: 'translate.sel', selection: '你好'),
      'Hello',
    );

    expect(action, isA<PluginDiffAction>());
    expect((action as PluginDiffAction).original, '你好');
    expect(action.result, 'Hello');
  });

  test('a script that will not load reports it instead of failing silently',
      () {
    expect(
      () => PluginScriptRuntime('function on_command( syntax error'),
      throwsA(isA<PluginScriptException>()),
    );
  });

  _capabilities();

  test('a script cannot reach the filesystem or the process', () {
    final runtime = PluginScriptRuntime(r'''
function on_command(ctx)
  if io ~= nil or os ~= nil then
    return { notify = "sandbox escaped" }
  end
  return { notify = "sandboxed" }
end
''');
    addTearDown(runtime.dispose);

    final action = runtime.runCommand(
      const PluginScriptContext(command: 'probe'),
    );
    expect((action as PluginNotifyAction).message, 'sandboxed');
  });
}

const _capabilityScript = r'''
function on_command(ctx)
  if ctx.command == "read" then
    return { notify = storage.get("lang") or "unset" }
  end
  if ctx.command == "write" then
    storage.set("lang", "ja")
    return { notify = "saved" }
  end
  return { notify = t("translate.title") }
end
''';

void _capabilities() {
  test('a plugin reads its own saved settings', () {
    final runtime = PluginScriptRuntime(
      _capabilityScript,
      storage: const {'lang': 'de'},
    );
    addTearDown(runtime.dispose);

    final action = runtime.runCommand(const PluginScriptContext(command: 'read'));
    expect((action as PluginNotifyAction).message, 'de');
  });

  test('what a plugin writes comes back for the host to persist', () {
    final runtime = PluginScriptRuntime(_capabilityScript);
    addTearDown(runtime.dispose);

    expect(runtime.storageChanged, isFalse);
    runtime.runCommand(const PluginScriptContext(command: 'write'));

    expect(runtime.storageChanged, isTrue);
    expect(runtime.storage['lang'], 'ja');
  });

  test('a plugin ships its own strings and the host picks the locale', () {
    final runtime = PluginScriptRuntime(
      _capabilityScript,
      strings: const {'translate.title': '翻訳'},
    );
    addTearDown(runtime.dispose);

    final action = runtime.runCommand(const PluginScriptContext(command: 'x'));
    expect((action as PluginNotifyAction).message, '翻訳');
  });

  test('an unknown string key falls back to the key, not to a crash', () {
    final runtime = PluginScriptRuntime(_capabilityScript);
    addTearDown(runtime.dispose);

    final action = runtime.runCommand(const PluginScriptContext(command: 'x'));
    expect((action as PluginNotifyAction).message, 'translate.title');
  });

  test('the dangerous standard libraries are not reachable', () {
    final runtime = PluginScriptRuntime(r'''
function on_command(ctx)
  local reachable = {}
  for _, name in ipairs({"os", "package", "require", "dofile", "loadfile"}) do
    if _G[name] ~= nil then reachable[#reachable + 1] = name end
  end
  return { notify = table.concat(reachable, ",") }
end
''');
    addTearDown(runtime.dispose);

    final action = runtime.runCommand(const PluginScriptContext(command: 'probe'));
    expect((action as PluginNotifyAction).message, isEmpty,
        reason: '插件不该能拿到文件系统和进程');
  });

  test('a plugin can ask for one small window showing just the answer', () {
    final runtime = PluginScriptRuntime(r'''
function on_command(ctx)
  return { show = "translated text", title = "Japanese" }
end
''');

    final action = runtime.runCommand(const PluginScriptContext(command: 'x'));

    expect(action, isA<PluginShowAction>());
    expect((action as PluginShowAction).text, 'translated text');
    expect(action.title, 'Japanese');
  });

  test('a plugin can ask for a panel beside the document instead', () {
    // Side by side in a dialog is wrong for a whole document: the reader wants
    // to read it against what is on screen, not in a box on top of it.
    final runtime = PluginScriptRuntime(r'''
function on_command(ctx)
  return { panel = "the whole translated document", title = "Japanese" }
end
''');

    final action = runtime.runCommand(const PluginScriptContext(command: 'x'));

    expect(action, isA<PluginPanelAction>());
    expect((action as PluginPanelAction).text, 'the whole translated document');
    expect(action.title, 'Japanese');
  });

  test('a question can offer choices as well as take anything typed', () {
    final runtime = PluginScriptRuntime(r'''
function on_command(ctx)
  return {
    ask = "Target language",
    default = "English",
    choices = { "English", "\u{7b80}\u{4f53}\u{4e2d}\u{6587}", "\u{65e5}\u{672c}\u{8a9e}" },
  }
end
''');

    final action = runtime.runCommand(const PluginScriptContext(command: 'x'));

    expect(action, isA<PluginAskAction>());
    final ask = action as PluginAskAction;
    expect(ask.defaultValue, 'English');
    expect(ask.choices, hasLength(3));
    expect(ask.choices.first, 'English');
  });

  test('a question with no choices still just takes what is typed', () {
    final runtime = PluginScriptRuntime(r'''
function on_command(ctx)
  return { ask = "Anything", default = "" }
end
''');

    final ask = runtime.runCommand(const PluginScriptContext(command: 'x'))
        as PluginAskAction;

    expect(ask.choices, isEmpty);
  });
}
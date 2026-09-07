import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// The contract plugins are written against.
///
/// Every name here is one somebody else's plugin has typed into a file the
/// editor will read. Renaming or removing one does not break a test elsewhere
/// — it breaks plugins, quietly, on machines nobody here can see. So the names
/// are written down, and changing them means changing this list on purpose.
///
/// Adding to any of these lists is free. Taking something away, or spelling it
/// differently, is a breaking change to every plugin that used it, and needs a
/// deprecation before it needs a diff.
void main() {
  test('the permissions a plugin may declare', () {
    expect(PluginPermission.all.toSet(), {
      'document.read',
      'document.write',
      'ui.contextMenu',
      'ui.menuBar',
      'ui.toolbar',
      'ui.sidebar',
      'ui.statusBar',
      'ui.settings',
      'ui.commandPalette',
      'ui.notifications',
      'ai.chat',
      'storage.local',
      'clipboard.read',
      'clipboard.write',
      'workspace.read',
      'workspace.write',
      'network.request',
      // Carries network.request with it — see PluginPermission.implied.
      'ui.webview',
    });
  });

  test('the runtimes a plugin may declare', () {
    expect(PluginRuntime.values.map((r) => r.name).toSet(),
        {'data', 'lua', 'js', 'process'});
  });

  test('the conditions a menu entry may carry', () {
    expect(PluginMenuCondition.values.map((c) => c.name).toSet(),
        {'always', 'selection', 'noSelection'});
  });

  test('the platforms a compiled plugin may name', () {
    expect(PluginManifest.architectures.toSet(), {'x64', 'arm64'});

    // The systems are checked by parsing, so they are read back from it.
    for (final os in ['windows', 'macos', 'linux']) {
      expect(
        () => PluginManifest.fromJson({
          'id': 'a.b',
          'name': 'N',
          'version': '1.0.0',
          'runtime': 'process',
          'entrypoints': {os: 'bin/plugin'},
        }),
        returnsNormally,
        reason: '$os 是插件作者已经写进 manifest 的系统名',
      );
    }
  });

  test('the actions a script may return', () {
    // Every shape the runtime turns into something the editor does. A plugin
    // returning one of these expects the behaviour beside it.
    const shapes = {
      'ask': PluginAskAction,
      'ai': PluginAiAction,
      'show': PluginShowAction,
      'panel': PluginPanelAction,
      'notify': PluginNotifyAction,
      'diff': PluginDiffAction,
      'replace': PluginReplaceAction,
      'pane': PluginPaneAction,
      'ui': PluginUiAction,
    };

    // The table above is written by hand and the shapes it names live in
    // `lib/`, so nothing made a tenth action come through here. Two other
    // tables in this project had exactly that gap this week. `PluginNoAction`
    // is the one deliberate absence: it is what a script returning nothing
    // produces, so there is no shape to write.
    final declared = RegExp(r'class (Plugin\w+Action) extends PluginScriptAction')
        .allMatches(
            File('lib/services/plugin_script_runtime.dart').readAsStringSync())
        .map((m) => m.group(1)!)
        .toSet()
      ..remove('PluginNoAction');
    expect(declared, isNotEmpty, reason: '没读出任何动作类，这条对账该更新了');
    final untried = declared
        .difference(shapes.values.map((t) => t.toString()).toSet())
        .toList()
      ..sort();
    expect(untried, isEmpty,
        reason: '这些动作没有对应的写法：$untried。'
            '加一个动作要同时给它一行，并让 SDK 的 lua 与 js 两份都能构造它');

    for (final entry in shapes.entries) {
      final source = switch (entry.key) {
        'diff' =>
          'function on_command(ctx) return { diff = { original = "a", result = "b" } } end',
        // A tree, not a string: `ui` is the one action whose payload has a
        // shape of its own.
        'ui' =>
          'function on_command(ctx) return { ui = { text = "hello" } } end',
        _ => 'function on_command(ctx) return { ${entry.key} = "x" } end',
      };
      final action = PluginScriptRuntime(source)
          .runCommand(const PluginScriptContext(command: 'c'));
      expect(action.runtimeType, entry.value,
          reason: '${entry.key} 是插件已经在用的写法');
    }
  });

  test('the types a settings field may declare', () {
    // Written into a manifest by hand, the same as a permission or a runtime
    // name, and spelled the same way in the JSON schema the SDK ships. Each
    // one changes what the reader is shown on the plugin's own settings page.
    const drawn = {
      'boolean': 'a switch',
      'password': 'a field that hides what is typed',
      'number': 'a field that asks for the number keyboard',
      'text': 'a plain field',
    };
    final screen =
        File('lib/ui/screens/plugin_settings_screen.dart').readAsStringSync();
    for (final type in drawn.keys) {
      if (type == 'text') continue; // the default, named by nothing
      expect(screen, contains("== '$type'"),
          reason: '$type 是插件已经写进 manifest 的写法，页面要认得它');
    }

    // An unknown type draws the plain field rather than refusing the plugin.
    // That is deliberate — a settings page half-drawn is worse than one field
    // drawn plainly — but it is also silent, so a misspelling looks like the
    // editor not supporting the type. Whoever adds a fifth type should decide
    // whether to say something here.
    expect(
      PluginSettingField.fromJson(
              {'key': 'k', 'title': 'T', 'type': 'colour'}).type,
      'colour',
      reason: '不认识的类型原样留着，而不是被改写成 text——'
          '要报出来的话得知道作者写的是什么',
    );
  });

  test('the slots a pane may be put in', () {
    expect(PluginPaneSlot.values.map((s) => s.name).toSet(),
        {'right', 'bottom', 'corner'});
  });

  test('the fields a script is given about the moment it ran', () {
    final runtime = PluginScriptRuntime(r'''
function on_command(ctx)
  return { notify = ctx.command .. "|" .. ctx.selection .. "|"
    .. ctx.document .. "|" .. tostring(ctx.answer) }
end
''');
    final action = runtime.runCommand(const PluginScriptContext(
      command: 'c',
      selection: 's',
      document: 'd',
      answer: 'a',
    ));
    expect((action as PluginNotifyAction).message, 'c|s|d|a');
  });

  test('the capabilities a script is given', () {
    final runtime = PluginScriptRuntime(
      'function on_command(ctx) return { notify = '
      'tostring(storage ~= nil) .. tostring(t ~= nil) } end',
      strings: const {'k': 'v'},
    );
    final action =
        runtime.runCommand(const PluginScriptContext(command: 'c'));
    expect((action as PluginNotifyAction).message, 'truetrue');
  });

  test('what the sandbox keeps out', () {
    // Removing one of these is not a breaking change for plugins; putting one
    // back is a change to what a plugin from a stranger can reach.
    final runtime = PluginScriptRuntime(r'''
function on_command(ctx)
  local gone = {}
  for _, name in ipairs({"os", "io", "package", "dofile", "loadfile"}) do
    if _G[name] ~= nil then gone[#gone+1] = name end
  end
  return { notify = table.concat(gone, ",") }
end
''');
    final action =
        runtime.runCommand(const PluginScriptContext(command: 'c'));
    expect((action as PluginNotifyAction).message, isEmpty,
        reason: '沙箱漏了东西出去');
  });
}

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
    };

    for (final entry in shapes.entries) {
      final source = entry.key == 'diff'
          ? 'function on_command(ctx) return { diff = { original = "a", result = "b" } } end'
          : 'function on_command(ctx) return { ${entry.key} = "x" } end';
      final action = PluginScriptRuntime(source)
          .runCommand(const PluginScriptContext(command: 'c'));
      expect(action.runtimeType, entry.value,
          reason: '${entry.key} 是插件已经在用的写法');
    }
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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_command_service.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// A pane that offers to write itself back into the document.
///
/// What a model returns is worth reading before it lands in what the reader
/// was writing, so a rewrite or a correction is shown first and applied when
/// they say so. Both runtimes have to read the same fields, or a plugin works
/// in one language and not the other.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('apply_'));
  tearDown(() => root.existsSync() ? root.deleteSync(recursive: true) : null);

  PluginManifest install(String id, String entrypoint, String source) {
    final manifest = PluginManifest(
      id: id,
      name: 'Demo',
      version: '1.0.0',
      entrypoint: entrypoint,
      runtime: entrypoint.endsWith('.lua')
          ? PluginRuntime.lua
          : PluginRuntime.js,
      permissions: const ['document.read', 'document.write', 'ui.sidebar'],
    );
    final dir = Directory('${root.path}/$id')..createSync(recursive: true);
    File('${dir.path}/$entrypoint').writeAsStringSync(source);
    return manifest;
  }

  PluginPaneAction run(PluginManifest manifest) {
    final service = PluginCommandService(root.path);
    addTearDown(service.dispose);
    return service.start(
          manifest,
          const PluginScriptContext(
            command: 'rewrite',
            selection: 'the old words',
            document: 'before the old words after',
          ),
        )
        as PluginPaneAction;
  }

  test('Lua: a pane can offer to be applied, and say what it replaces', () {
    final manifest = install('lua.demo', 'plugin.lua', '''
function on_command(ctx)
  return {
    pane = "the new words",
    title = "Rewrite",
    apply = true,
    replaces = ctx.selection,
  }
end
''');
    final action = run(manifest);
    expect(action.canApply, isTrue);
    expect(action.replaces, 'the old words');
    expect(action.text, 'the new words');
  });

  test('JS reads the same field names as Lua', () {
    // QuickJS only exists inside a built application, so the engine cannot be
    // started here. What can be checked is the thing that actually goes
    // wrong: the two runtimes reading different names, so a plugin works in
    // one language and not the other.
    final js = File('lib/services/plugin_js_runtime.dart').readAsStringSync();
    final lua = File(
      'lib/services/plugin_script_runtime.dart',
    ).readAsStringSync();
    for (final field in ["'apply'", "'replaces'", "'append'", "'ai'"]) {
      expect(js, contains(field), reason: 'JS 运行时没读 $field');
      expect(lua, contains(field), reason: 'Lua 运行时没读 $field');
    }
  });

  test('a pane that says nothing offers nothing', () {
    // Translation shows a result to read, not one to accept. A button that
    // overwrites the document must be asked for.
    final manifest = install('lua.quiet', 'plugin.lua', '''
function on_command(ctx)
  return { pane = "a translation", title = "中文" }
end
''');
    final action = run(manifest);
    expect(action.canApply, isFalse);
    expect(action.replaces, isEmpty);
  });

  test('an empty replaces means the whole document', () {
    final manifest = install('lua.whole', 'plugin.lua', '''
function on_command(ctx)
  return { pane = "a rewrite of everything", apply = true }
end
''');
    final action = run(manifest);
    expect(action.canApply, isTrue);
    expect(action.replaces, isEmpty);
  });
}

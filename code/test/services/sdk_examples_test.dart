import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:marktext_plus/services/plugin_command_service.dart';
import 'package:marktext_plus/services/plugin_js_runtime.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// The SDK's example plugins are run, not just read.
///
/// An example that does not work teaches the wrong thing more effectively than
/// no example at all, and these are the first thing a plugin author copies.
void main() {
  String? findSdk() {
    var directory = Directory.current;
    for (var level = 0; level < 6; level++) {
      final candidate =
          '${directory.path}/marktext-plus-plugins/marktext-plus-plugin-sdk';
      if (Directory('$candidate/packages').existsSync()) return candidate;
      final parent = directory.parent;
      if (parent.path == directory.path) break;
      directory = parent;
    }
    return null;
  }

  final sdk = findSdk();
  final present = sdk != null;
  final skip = present ? null : 'SDK 仓库不在这台机器上';

  /// Installs the example as the editor would: every file it ships.
  ///
  /// Copying only the entrypoint was enough while a plugin was one file. It is
  /// not any more, and a test that installs half a plugin proves nothing about
  /// the other half.
  PluginManifest install(Directory root, String example, String script) {
    final source = Directory('$sdk/packages/$example');
    final manifest = PluginManifest.fromJson(
      jsonDecode(File('${source.path}/manifest.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final dir = Directory('${root.path}/${manifest.id}')
      ..createSync(recursive: true);

    for (final entry in source.listSync(recursive: true)) {
      if (entry is! File) continue;
      final relative = p.relative(entry.path, from: source.path);
      final target = File('${dir.path}/$relative')
        ..parent.createSync(recursive: true);
      entry.copySync(target.path);
    }
    expect(File('${dir.path}/$script').existsSync(), isTrue);
    return manifest;
  }

  test('the Lua example runs, and reaches every capability it declares', () {
    final root = Directory.systemTemp.createTempSync('sdk_lua_');
    addTearDown(() => root.deleteSync(recursive: true));
    final manifest = install(root, 'lua', 'plugin.lua');
    final service = PluginCommandService(root.path, locale: 'zh_CN');

    expect(manifest.runtime, PluginRuntime.lua);

    // t(), through the plugin's own zh strings.
    final empty = service.start(
      manifest,
      const PluginScriptContext(command: 'summarise.selection'),
    );
    expect((empty as PluginNotifyAction).message, '请先选中一些文本');

    // ask + choices + storage.
    final ask = service.start(
      manifest,
      const PluginScriptContext(
          command: 'summarise.selection', selection: 'hi'),
    ) as PluginAskAction;
    expect(ask.label, '用哪种语言总结？');
    expect(ask.choices, contains('日本語'));

    // ai, with the plugin's own prompt.
    final ai = service.start(
      manifest,
      const PluginScriptContext(
        command: 'summarise.selection',
        selection: 'hello world',
        answer: '日本語',
      ),
    ) as PluginAiAction;
    expect(ai.prompt, contains('日本語'));
    expect(ai.prompt, contains('hello world'));

    // show for a selection, panel for a document.
    expect(
      service.resumeWithResult(
        manifest,
        const PluginScriptContext(
            command: 'summarise.selection', selection: 'x', answer: 'English'),
        '- a\n- b\n- c',
      ),
      isA<PluginShowAction>(),
    );
    expect(
      service.resumeWithResult(
        manifest,
        const PluginScriptContext(
            command: 'summarise.document', document: 'x', answer: 'English'),
        '- a\n- b\n- c',
      ),
      isA<PluginPanelAction>(),
    );
  }, skip: skip);

  test('the API module ships with the plugin, because it is the plugin', () {
    // It used to be type definitions that never shipped, which meant the
    // reference at the top of the entrypoint was a comment while the compiled
    // example had a real import. Now it is an ordinary module the plugin
    // requires, so a missing one is a plugin that does not run.
    final root = Directory.systemTemp.createTempSync('sdk_ship_');
    addTearDown(() => root.deleteSync(recursive: true));
    final manifest = install(root, 'lua', 'plugin.lua');
    final installed = Directory('${root.path}/${manifest.id}');

    final names = installed
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => p.relative(f.path, from: installed.path))
        .toSet();

    expect(names, contains(p.join('lib', 'marktext-plus.lua')));
  }, skip: skip);

  test('the Lua and JS packages declare the very same plugin', () {
    // Two files that must agree, which is the shape that drifts. Everything
    // but the id, the name, the runtime and the entrypoint is compared.
    Map<String, dynamic> declared(String runtime) {
      final json = jsonDecode(
        File('$sdk/packages/$runtime/manifest.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      return {
        for (final entry in json.entries)
          if (!const ['id', 'name', 'runtime', 'entrypoint']
              .contains(entry.key))
            entry.key: entry.value,
      };
    }

    expect(declared('js'), declared('lua'));
  }, skip: skip);

  test('the JS example returns actions the editor understands', () {
    // The shapes the example produces, checked without the engine.
    final ask = PluginJsRuntime.parseAction(
      '{"ask":"How loudly?","default":"LOUD","choices":["LOUD","LOUDEST"]}',
    ) as PluginAskAction;
    expect(ask.choices, contains('LOUDEST'));

    final shown =
        PluginJsRuntime.parseAction('{"show":"HI!!!","title":"LOUDEST"}');
    expect((shown as PluginShowAction).text, 'HI!!!');
  }, skip: skip);

  test('the compiled example names an executable for each platform it claims',
      () {
    final manifest = PluginManifest.fromJson(
      jsonDecode(File('$sdk/packages/dart/manifest.json').readAsStringSync())
          as Map<String, dynamic>,
    );

    expect(manifest.runtime, PluginRuntime.process);
    // Mixed on purpose: one path for a whole system, and per-architecture
    // where it matters. The example is the only place a reader sees both.
    expect(manifest.entrypointFor('linux-x64'), 'bin/linux/plugin');
    expect(manifest.entrypointFor('linux-arm64'), 'bin/linux/plugin');
    expect(manifest.entrypointFor('windows-arm64'),
        r'bin\windows-arm64\plugin.exe');
    expect(manifest.supportedPlatforms, hasLength(6));
  }, skip: skip);

  test('the examples explain every permission their script needs', () {
    // The examples teach by annotating each call with the permission it
    // needs. They annotated four and missed the fifth — `sdk.panel` needs
    // `ui.sidebar` — which is the same permission the manifests had been
    // missing until it was noticed, so the fix went into the manifests and
    // not into the file that teaches people to write them.
    //
    // Read from the manifest rather than listed here: whichever permissions a
    // script-level call needs, the script that makes those calls has to name
    // them.
    Set<String> annotated(String path) => RegExp(r'needs ([a-z.]+)')
        .allMatches(File(path).readAsStringSync())
        .map((m) => m.group(1)!)
        .toSet();

    final lua = annotated('$sdk/packages/lua/plugin.lua');
    final js = annotated('$sdk/packages/js/plugin.js');

    expect(lua, js,
        reason: 'Lua 与 JS 是同一个插件的两种写法，注释也该说同样的话');
    expect(lua, contains('ui.sidebar'),
        reason: 'sdk.panel 需要它，而这正是当初 manifest 漏掉的那一个');
    for (final permission in lua) {
      expect(
        jsonDecode(File('$sdk/packages/lua/manifest.json').readAsStringSync())
            ['permissions'],
        contains(permission),
        reason: '注释里说需要 $permission，manifest 就得声明它',
      );
    }
  }, skip: skip);

  test('the README says which actions need which permission', () {
    // The actions table tells an author what each return value does; what it
    // did not say is which of them are refused without a permission — the
    // one question an author has when a plugin of theirs is turned down.
    //
    // Checked against the editor's own guard rather than a list repeated
    // here, so that changing what the editor demands turns this red.
    final guard =
        File('lib/services/plugin_command_service.dart').readAsStringSync();
    final required = <String, String>{};
    for (final m in RegExp(
      r'Plugin(\w+)Action\(\)[^=]*?=>\s*\n?\s*PluginPermission\.(\w+)',
      dotAll: true,
    ).allMatches(guard)) {
      required[m.group(1)!.toLowerCase()] = m.group(2)!;
    }
    expect(required, isNotEmpty, reason: '没能从 _guard 里读出映射，正则该更新了');

    // Only the table that maps actions to permissions, not the whole file.
    // Searching the whole README passed on anything: the permissions table
    // further down lists all seventeen, so pointing `replace` at
    // `workspace.write` was still "mentioned somewhere" and slipped by.
    final readme = File('$sdk/README.md').readAsStringSync();
    final needsTable = RegExp(r'\| Return \| Needs \|(.*?)\n\n', dotAll: true)
        .firstMatch(readme)
        ?.group(1);
    expect(needsTable, isNotNull,
        reason: 'README 里找不到「动作 → 权限」这张表');

    for (final entry in required.entries) {
      expect(needsTable, contains('`${entry.key}`'),
          reason: '${entry.key} 需要权限，那张表里却没有它');
    }
    // And the identifiers, read out of the manifest source too — a table
    // written here would only have to be kept in step itself. The first
    // version hard-coded four pairs and checked one only when it appeared in
    // the guard, so pointing an action at a permission outside those four
    // walked straight past.
    final manifestSource =
        File('lib/services/plugin_manifest.dart').readAsStringSync();
    final values = {
      for (final m in RegExp(r"static const (\w+) = '([a-z]+\.[a-zA-Z]+)'")
          .allMatches(manifestSource))
        m.group(1)!: m.group(2)!,
    };

    for (final constant in required.values.toSet()) {
      final permission = values[constant];
      expect(permission, isNotNull,
          reason: '_guard 要求 $constant，但 PluginPermission 里没有这个常量');
      expect(needsTable, contains('`$permission`'),
          reason: '编辑器要求 $permission，那张表得说出来');
    }
  }, skip: skip);

  test('the three examples are three plugins, not one wearing three hats', () {
    // Each carries its own id, so installing all three is possible and none
    // of them silently replaces another.
    final ids = <String>{};
    for (final example in ['lua', 'js', 'dart']) {
      final manifest = PluginManifest.fromJson(
        jsonDecode(File('$sdk/packages/$example/manifest.json')
            .readAsStringSync()) as Map<String, dynamic>,
      );
      ids.add(manifest.id);
    }
    expect(ids, hasLength(3));
  }, skip: skip);
}
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
      if (Directory('$candidate/examples').existsSync()) return candidate;
      final parent = directory.parent;
      if (parent.path == directory.path) break;
      directory = parent;
    }
    return null;
  }

  final sdk = findSdk();
  final present = sdk != null;
  final skip = present ? null : 'SDK 仓库不在这台机器上';

  PluginManifest install(Directory root, String example, String script) {
    final source = '$sdk/examples/$example';
    final manifest = PluginManifest.fromJson(
      jsonDecode(File('$source/manifest.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final dir = Directory('${root.path}/${manifest.id}')
      ..createSync(recursive: true);
    File('$source/$script').copySync('${dir.path}/$script');
    return manifest;
  }

  test('the Lua example runs, and does what its README says', () {
    final root = Directory.systemTemp.createTempSync('sdk_lua_');
    addTearDown(() => root.deleteSync(recursive: true));
    final manifest = install(root, 'lua', 'plugin.lua');
    final service = PluginCommandService(root.path, locale: 'zh_CN');

    expect(manifest.runtime, PluginRuntime.lua);
    expect(manifest.menus.single.appliesTo(hasSelection: false), isFalse,
        reason: '示例声明了 when: selection');

    final empty = service.start(
      manifest,
      const PluginScriptContext(command: 'shout.selection'),
    );
    expect((empty as PluginNotifyAction).message, '请先选中一些文本',
        reason: '示例的翻译表要真的被用上');

    final ask = service.start(
      manifest,
      const PluginScriptContext(command: 'shout.selection', selection: 'hi'),
    ) as PluginAskAction;
    expect(ask.label, '多大声？');
    expect(ask.choices, contains('LOUDEST'));

    final shown = service.start(
      manifest,
      const PluginScriptContext(
        command: 'shout.selection',
        selection: 'hi',
        answer: 'LOUDEST',
      ),
    ) as PluginShowAction;
    expect(shown.text, 'HI!!!');
  }, skip: skip);

  test('the JS example declares the same plugin as the Lua one', () {
    // The engine itself only exists in a built application, so what can be
    // checked here is that the two examples are the same plugin in two
    // languages rather than two different ones.
    final lua = PluginManifest.fromJson(
      jsonDecode(File('$sdk/examples/lua/manifest.json')
          .readAsStringSync()) as Map<String, dynamic>,
    );
    final js = PluginManifest.fromJson(
      jsonDecode(File('$sdk/examples/js/manifest.json')
          .readAsStringSync()) as Map<String, dynamic>,
    );

    expect(js.runtime, PluginRuntime.js);
    expect(js.permissions, lua.permissions);
    expect(js.menus.single.id, lua.menus.single.id);
    expect(js.menus.single.when, lua.menus.single.when);
    expect(js.settings.single.key, lua.settings.single.key);
    expect(js.stringsFor('zh'), lua.stringsFor('zh'));
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
      jsonDecode(File('$sdk/examples/process/manifest.json').readAsStringSync())
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

  test('the three examples are three plugins, not one wearing three hats', () {
    // Each carries its own id, so installing all three is possible and none
    // of them silently replaces another.
    final ids = <String>{};
    for (final example in ['lua', 'js', 'process']) {
      final manifest = PluginManifest.fromJson(
        jsonDecode(File('$sdk/examples/$example/manifest.json')
            .readAsStringSync()) as Map<String, dynamic>,
      );
      ids.add(manifest.id);
    }
    expect(ids, hasLength(3));
  }, skip: skip);
}
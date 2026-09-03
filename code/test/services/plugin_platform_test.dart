import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manager.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

void main() {
  test('the platform key names the os and the architecture', () {
    final key = PluginManager.currentPlatform;
    expect(key, matches(RegExp(r'^(windows|macos|linux)-(x64|arm64)$')),
        reason: '插件 manifest 用这个键声明它编译过哪些平台');
  });

  test('a compiled plugin built for other platforms says so, and does not run',
      () async {
    final root = Directory.systemTemp.createTempSync('plugin_platform_');
    addTearDown(() => root.deleteSync(recursive: true));

    final elsewhere =
        PluginManager.currentPlatform == 'linux-x64' ? 'windows-x64' : 'linux-x64';
    final manifest = PluginManifest.fromJson({
      'id': 'com.example.native',
      'name': 'Native',
      'version': '1.0.0',
      'runtime': 'process',
      'entrypoints': {elsewhere: 'bin/plugin'},
    });
    File(p.join(root.path, 'com.example.native', 'bin', 'plugin'))
      ..createSync(recursive: true)
      ..writeAsStringSync('not this platform');

    await expectLater(
      PluginManager(root.path).startPlugin(manifest),
      throwsA(isA<PluginScriptException>().having(
        (e) => e.message,
        'message',
        allOf(
          contains('no build for ${PluginManager.currentPlatform}'),
          contains(elsewhere),
        ),
      )),
    );
  });

  test('an executable the plugin promised but did not ship is reported',
      () async {
    final root = Directory.systemTemp.createTempSync('plugin_platform_');
    addTearDown(() => root.deleteSync(recursive: true));

    final manifest = PluginManifest.fromJson({
      'id': 'com.example.native',
      'name': 'Native',
      'version': '1.0.0',
      'runtime': 'process',
      'entrypoints': {PluginManager.currentPlatform: 'bin/missing'},
    });

    await expectLater(
      PluginManager(root.path).startPlugin(manifest),
      throwsA(isA<PluginScriptException>().having(
        (e) => e.message,
        'message',
        contains('not in the installed plugin'),
      )),
    );
  });

  test('a script plugin is not started as a process at all', () async {
    final root = Directory.systemTemp.createTempSync('plugin_platform_');
    addTearDown(() => root.deleteSync(recursive: true));

    final manifest = PluginManifest.fromJson({
      'id': 'com.example.lua',
      'name': 'Lua',
      'version': '1.0.0',
      'runtime': 'lua',
      'entrypoint': 'plugin.lua',
    });
    File(p.join(root.path, 'com.example.lua', 'plugin.lua'))
      ..createSync(recursive: true)
      ..writeAsStringSync('-- a script, not a program');

    await expectLater(
      PluginManager(root.path).startPlugin(manifest),
      throwsA(isA<PluginScriptException>().having(
        (e) => e.message,
        'message',
        contains('runs inside the editor'),
      )),
    );
  });
}

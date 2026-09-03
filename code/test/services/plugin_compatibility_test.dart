import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/constants.dart';
import 'package:marktext_plus/services/plugin_command_service.dart';
import 'package:marktext_plus/services/plugin_manager.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// A plugin that needs a newer editor is told so, rather than half-working.
///
/// `minAppVersion` was parsed, stored and written back out, and checked
/// nowhere. A plugin declaring 1.7.0 installed and ran on 1.6.1, reaching for
/// whatever it was written against and failing in whatever way that happened
/// to fail — which is the worst of both, because the author had said plainly
/// what they needed.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('plugin_compat_'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  Map<String, dynamic> json(String minAppVersion) => {
        'id': 'com.example.demo',
        'name': 'Demo',
        'version': '1.0.0',
        'runtime': 'lua',
        'entrypoint': 'plugin.lua',
        if (minAppVersion.isNotEmpty) 'minAppVersion': minAppVersion,
      };

  File zipOf(String minAppVersion) {
    final staging = Directory('${root.path}/staging')..createSync();
    File('${staging.path}/manifest.json')
        .writeAsStringSync(jsonEncode(json(minAppVersion)));
    File('${staging.path}/plugin.lua').writeAsStringSync('');
    final zip = File('${root.path}/plugin.zip');
    Process.runSync('zip', ['-q', '-j', zip.path,
        '${staging.path}/manifest.json', '${staging.path}/plugin.lua']);
    return zip;
  }

  test('a plugin asking for this editor or older is supported', () {
    for (final version in ['', '1.0.0', AppConstants.appVersion]) {
      expect(PluginManifest.fromJson(json(version)).isSupportedBy(
              AppConstants.appVersion), isTrue,
          reason: '$version 应当可用');
    }
  });

  test('a plugin asking for a newer editor is not', () {
    expect(
      PluginManifest.fromJson(json('99.0.0'))
          .isSupportedBy(AppConstants.appVersion),
      isFalse,
    );
  });

  test('the comparison is by number, not by spelling', () {
    // "1.10.0" sorts before "1.9.0" as text and after it as a version.
    final manifest = PluginManifest.fromJson(json('1.9.0'));
    expect(manifest.isSupportedBy('1.10.0'), isTrue);
    expect(manifest.isSupportedBy('1.8.0'), isFalse);
  });

  test('a version nobody can parse does not lock the plugin out', () {
    // The editor's own version is the thing being compared against; if that
    // cannot be read, refusing every plugin is worse than allowing them.
    expect(PluginManifest.fromJson(json('1.0.0')).isSupportedBy('nonsense'),
        isTrue);
    expect(PluginManifest.fromJson(json('nonsense'))
        .isSupportedBy(AppConstants.appVersion), isTrue);
  });

  test('installing a plugin that needs a newer editor is refused', () async {
    await expectLater(
      PluginManager('${root.path}/plugins').installZip(zipOf('99.0.0')),
      throwsA(isA<FormatException>().having((e) => e.message, 'message',
          allOf(contains('99.0.0'), contains(AppConstants.appVersion)))),
      reason: '要说清它要什么、你有什么，而不是只说装不上',
    );
  });

  test('installing one this editor supports still works', () async {
    final manifest = await PluginManager('${root.path}/plugins')
        .installZip(zipOf('1.0.0'));
    expect(manifest.id, 'com.example.demo');
  });

  test('a plugin already installed is still checked before it runs', () async {
    // Installed under a newer editor, then the editor was replaced with an
    // older one — or the plugin directory was copied between machines. The
    // check at install time cannot see either.
    final plugins = Directory('${root.path}/plugins')..createSync();
    final dir = Directory('${plugins.path}/com.example.demo')..createSync();
    File('${dir.path}/manifest.json')
        .writeAsStringSync(jsonEncode(json('99.0.0')));
    File('${dir.path}/plugin.lua').writeAsStringSync(
        'function on_command(ctx) return { notify = "ran" } end');

    final manifest = PluginManifest.fromJson(json('99.0.0'));
    final service = PluginCommandService(
      plugins.path,
      appVersion: AppConstants.appVersion,
    );

    expect(
      () => service.start(
          manifest, const PluginScriptContext(command: 'x')),
      throwsA(isA<PluginScriptException>().having((e) => e.message, 'message',
          allOf(contains('99.0.0'), contains(AppConstants.appVersion)))),
    );
  });

  test('a plugin this editor supports runs as before', () {
    final plugins = Directory('${root.path}/plugins')..createSync();
    final dir = Directory('${plugins.path}/com.example.demo')..createSync();
    File('${dir.path}/plugin.lua').writeAsStringSync(
        'function on_command(ctx) return { notify = "ran" } end');

    final action = PluginCommandService(plugins.path).start(
      PluginManifest.fromJson(json('1.0.0')),
      const PluginScriptContext(command: 'x'),
    );
    expect((action as PluginNotifyAction).message, 'ran');
  });
}
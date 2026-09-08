import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manager.dart';

/// A plugin that cannot run here is refused when it is installed.
///
/// The same story `minAppVersion` had, one field along. That one was "parsed,
/// stored and written back out, and checked nowhere" until it was checked at
/// install; a plugin needing a newer editor now says so once instead of
/// failing later in whatever way it happens to fail.
///
/// `supportsPlatform` was in exactly that state: written, tested, and asked by
/// nothing. A compiled plugin with no build for this machine installed
/// happily and only refused at the moment the reader tried to use it — which
/// is a strange time to learn it was never going to work.
void main() {
  /// A ZIP for a compiled plugin that ships builds for [platforms] only.
  File zipFor(Directory root, List<String> platforms) {
    final entrypoints = <String, Map<String, String>>{};
    for (final platform in platforms) {
      final split = platform.lastIndexOf('-');
      final os = platform.substring(0, split);
      final arch = platform.substring(split + 1);
      (entrypoints[os] ??= {})[arch] = 'bin/$os-$arch/plugin';
    }
    final archive = Archive()
      ..addFile(ArchiveFile.string(
        'manifest.json',
        jsonEncode({
          'id': 'com.example.compiled',
          'name': 'Compiled',
          'version': '1.0.0',
          'runtime': 'process',
          'entrypoint': 'bin/plugin',
          'entrypoints': entrypoints,
        }),
      ));
    for (final platform in platforms) {
      final split = platform.lastIndexOf('-');
      archive.addFile(ArchiveFile.string(
        'bin/${platform.substring(0, split)}-'
        '${platform.substring(split + 1)}/plugin',
        'not really an executable',
      ));
    }
    return File('${root.path}/plugin.zip')
      ..writeAsBytesSync(ZipEncoder().encode(archive));
  }

  test('a compiled plugin with no build for this machine is refused',
      () async {
    final root = await Directory.systemTemp.createTemp('plugin_platform_');
    addTearDown(() => root.delete(recursive: true));

    // Two platforms that cannot both be the one running the tests.
    final elsewhere = PluginManager.currentPlatform.startsWith('linux')
        ? ['macos-arm64', 'windows-x64']
        : ['linux-x64', 'linux-arm64'];
    expect(elsewhere, isNot(contains(PluginManager.currentPlatform)),
        reason: '前提是这些确实不是本机平台，否则测的是另一回事');

    await expectLater(
      PluginManager('${root.path}/installed')
          .installZip(zipFor(root, elsewhere)),
      throwsA(isA<FormatException>().having(
        (e) => e.message,
        'message',
        contains(PluginManager.currentPlatform),
      )),
      reason: '装完才发现跑不起来，比装的时候就说清楚差得远',
    );
  });

  test('a compiled plugin built for this machine still installs', () async {
    final root = await Directory.systemTemp.createTemp('plugin_platform_ok_');
    addTearDown(() => root.delete(recursive: true));

    final manifest = await PluginManager('${root.path}/installed')
        .installZip(zipFor(root, [PluginManager.currentPlatform]));
    expect(manifest.id, 'com.example.compiled');
  });

  test('a script plugin is not asked about platforms at all', () async {
    // `supportsPlatform` answers true for anything that is not a compiled
    // plugin, and the new check has to keep that true — a Lua plugin runs
    // wherever the editor does.
    final root = await Directory.systemTemp.createTemp('plugin_platform_lua_');
    addTearDown(() => root.delete(recursive: true));

    final archive = Archive()
      ..addFile(ArchiveFile.string(
        'manifest.json',
        jsonEncode({
          'id': 'com.example.script',
          'name': 'Script',
          'version': '1.0.0',
          'runtime': 'lua',
          'entrypoint': 'plugin.lua',
        }),
      ))
      ..addFile(ArchiveFile.string('plugin.lua', 'function on_command() end'));
    final zip = File('${root.path}/lua.zip')
      ..writeAsBytesSync(ZipEncoder().encode(archive));

    final manifest =
        await PluginManager('${root.path}/installed').installZip(zip);
    expect(manifest.id, 'com.example.script');
  });
}

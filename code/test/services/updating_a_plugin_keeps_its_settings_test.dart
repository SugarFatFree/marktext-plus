import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manager.dart';

/// What a reader configured survives the plugin being updated.
///
/// A plugin's settings are written to `settings.json` **inside its own
/// directory**, and installing replaces that directory wholesale: unpack
/// beside it, delete the old one, rename. So every update threw away the
/// endpoint, the key, the target language — everything the reader had
/// filled in — and the plugin came back looking freshly installed.
///
/// It was survivable while updating meant a person deliberately downloading a
/// ZIP. `install_plugin` over MCP exists to make updating routine, which is
/// what makes this worth fixing rather than documenting.
void main() {
  File zipFor(Directory root, String version, {String name = 'demo.zip'}) {
    final archive = Archive()
      ..addFile(ArchiveFile.string(
        'manifest.json',
        jsonEncode({
          'id': 'com.example.demo',
          'name': 'Demo',
          'version': version,
          'entrypoint': 'plugin.lua',
          'runtime': 'lua',
        }),
      ))
      ..addFile(ArchiveFile.string('plugin.lua', '-- $version'));
    return File('${root.path}/$name')
      ..writeAsBytesSync(ZipEncoder().encode(archive));
  }

  test('an update keeps the settings the reader filled in', () async {
    final root = await Directory.systemTemp.createTemp('plugins_');
    addTearDown(() => root.delete(recursive: true));
    final manager = PluginManager('${root.path}/installed');

    await manager.installZip(zipFor(root, '1.0.0'));
    final settings = File(
      '${root.path}/installed/com.example.demo/settings.json',
    );
    settings.writeAsStringSync(jsonEncode({
      'endpoint': 'https://ai.example.invalid/v1',
      'language': 'Deutsch',
    }));

    await manager.installZip(zipFor(root, '1.1.0', name: 'demo2.zip'));

    expect(settings.existsSync(), isTrue,
        reason: '更新插件把读者填的设置删掉了');
    expect(
      jsonDecode(settings.readAsStringSync()),
      {'endpoint': 'https://ai.example.invalid/v1', 'language': 'Deutsch'},
    );
    // And the update did happen — otherwise keeping the settings would be
    // trivially true for the wrong reason.
    expect(
      File('${root.path}/installed/com.example.demo/plugin.lua')
          .readAsStringSync(),
      '-- 1.1.0',
    );
  });

  test('a first install with no settings yet is unaffected', () async {
    final root = await Directory.systemTemp.createTemp('plugins_');
    addTearDown(() => root.delete(recursive: true));
    final manager = PluginManager('${root.path}/installed');

    await manager.installZip(zipFor(root, '1.0.0'));

    expect(
      File('${root.path}/installed/com.example.demo/settings.json').existsSync(),
      isFalse,
      reason: '没有设置就不该凭空造一个出来',
    );
  });

  test('settings shipped inside the archive do not overwrite the reader\'s',
      () async {
    // An author who packages a settings.json is shipping their defaults. The
    // reader's copy is the answer to the same question, given later and by
    // the person whose editor it is.
    final root = await Directory.systemTemp.createTemp('plugins_');
    addTearDown(() => root.delete(recursive: true));
    final manager = PluginManager('${root.path}/installed');

    await manager.installZip(zipFor(root, '1.0.0'));
    final settings = File(
      '${root.path}/installed/com.example.demo/settings.json',
    )..writeAsStringSync(jsonEncode({'language': 'Deutsch'}));

    final archive = Archive()
      ..addFile(ArchiveFile.string(
        'manifest.json',
        jsonEncode({
          'id': 'com.example.demo',
          'name': 'Demo',
          'version': '1.1.0',
          'entrypoint': 'plugin.lua',
          'runtime': 'lua',
        }),
      ))
      ..addFile(ArchiveFile.string('plugin.lua', '-- 1.1.0'))
      ..addFile(ArchiveFile.string(
        'settings.json',
        jsonEncode({'language': 'English'}),
      ));
    final zip = File('${root.path}/withsettings.zip')
      ..writeAsBytesSync(ZipEncoder().encode(archive));

    await manager.installZip(zip);

    expect(jsonDecode(settings.readAsStringSync()), {'language': 'Deutsch'});
  });
}

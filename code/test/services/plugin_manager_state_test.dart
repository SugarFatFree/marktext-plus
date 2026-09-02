import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manager.dart';

void main() {
  test('plugin enabled state and uninstall are persisted', () async {
    final root = await Directory.systemTemp.createTemp('plugin_state_');
    addTearDown(() => root.delete(recursive: true));
    final archive = Archive()
      ..addFile(ArchiveFile.string('manifest.json', jsonEncode({
        'id': 'com.example.state',
        'name': 'State',
        'version': '1.0.0',
        'entrypoint': 'bin/plugin',
      })))
      ..addFile(ArchiveFile.string('bin/plugin', 'placeholder'));
    final zip = File('${root.path}/state.zip')
      ..writeAsBytesSync(ZipEncoder().encode(archive));
    final manager = PluginManager('${root.path}/installed');
    await manager.installZip(zip);

    expect(await manager.isEnabled('com.example.state'), isTrue);
    await manager.setEnabled('com.example.state', false);
    expect(await PluginManager('${root.path}/installed').isEnabled('com.example.state'), isFalse);
    await manager.uninstall('com.example.state');
    expect((await manager.loadInstalled()), isEmpty);
  });
}

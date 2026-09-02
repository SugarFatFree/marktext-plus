import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manager.dart';

void main() {
  test('installs a plugin ZIP atomically and reads its manifest', () async {
    final root = await Directory.systemTemp.createTemp('plugins_');
    addTearDown(() => root.delete(recursive: true));
    final archive = Archive()
      ..addFile(ArchiveFile.string(
        'manifest.json',
        jsonEncode({
          'id': 'com.example.demo',
          'name': 'Demo',
          'version': '1.0.0',
          'entrypoint': 'bin/demo',
        }),
      ))
      ..addFile(ArchiveFile.string('bin/demo', 'placeholder'));

    final zip = File('${root.path}/demo.zip')
      ..writeAsBytesSync(ZipEncoder().encode(archive));
    final manager = PluginManager('${root.path}/installed');
    final manifest = await manager.installZip(zip);

    expect(manifest.id, 'com.example.demo');
    expect((await manager.loadInstalled()).single.id, 'com.example.demo');
  });

  test('rejects ZIP entries that escape the plugin directory', () async {
    final root = await Directory.systemTemp.createTemp('plugins_');
    addTearDown(() => root.delete(recursive: true));
    final archive = Archive()
      ..addFile(ArchiveFile.string(
        'manifest.json',
        jsonEncode({
          'id': 'com.example.bad',
          'name': 'Bad',
          'version': '1.0.0',
          'entrypoint': 'bin/bad',
        }),
      ))
      ..addFile(ArchiveFile.string('../escape.txt', 'bad'));
    final zip = File('${root.path}/bad.zip')
      ..writeAsBytesSync(ZipEncoder().encode(archive));

    expect(
      () => PluginManager('${root.path}/installed').installZip(zip),
      throwsFormatException,
    );
    expect(File('${root.path}/escape.txt').existsSync(), isFalse);
  });
}

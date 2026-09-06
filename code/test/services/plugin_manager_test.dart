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

  // The path check above was the only question this asked of an archive. A
  // ZIP is also free to say it unpacks to something enormous, and to be
  // telling the truth: that is what a zip bomb is. 42.zip is 42 KB and 4.5 GB.
  test('rejects a ZIP whose entry claims to unpack to gigabytes', () async {
    final root = await Directory.systemTemp.createTemp('plugins_');
    addTearDown(() => root.delete(recursive: true));
    final archive = Archive()
      ..addFile(ArchiveFile.string(
        'manifest.json',
        jsonEncode({
          'id': 'com.example.bomb',
          'name': 'Bomb',
          'version': '1.0.0',
          'entrypoint': 'bin/bomb',
        }),
      ))
      // Declared size and actual content are independent, which is the whole
      // trick — this archive is a hundred and something bytes.
      ..addFile(ArchiveFile('bin/bomb', 300 * 1024 * 1024, [1, 2, 3]));
    final zip = File('${root.path}/bomb.zip')
      ..writeAsBytesSync(ZipEncoder().encode(archive));

    // Refused before `content` is read, because reading it is what unpacks it
    // into memory.
    expect(
      () => PluginManager('${root.path}/installed').installZip(zip),
      throwsFormatException,
    );
    expect(
      Directory('${root.path}/installed/com.example.bomb').existsSync(),
      isFalse,
      reason: '半个插件目录比没有更糟',
    );
  });

  test('rejects a ZIP with more entries than a plugin could have', () async {
    final root = await Directory.systemTemp.createTemp('plugins_');
    addTearDown(() => root.delete(recursive: true));
    final archive = Archive()
      ..addFile(ArchiveFile.string(
        'manifest.json',
        jsonEncode({
          'id': 'com.example.many',
          'name': 'Many',
          'version': '1.0.0',
          'entrypoint': 'bin/many',
        }),
      ));
    for (var i = 0; i < 10001; i++) {
      archive.addFile(ArchiveFile.string('f$i.txt', 'x'));
    }
    final zip = File('${root.path}/many.zip')
      ..writeAsBytesSync(ZipEncoder().encode(archive));

    expect(
      () => PluginManager('${root.path}/installed').installZip(zip),
      throwsFormatException,
    );
  });
}

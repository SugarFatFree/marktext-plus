import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manager.dart';
import 'package:path/path.dart' as p;

/// Two bounds on an installed archive that nothing was holding.
///
/// The traversal check has a test for `../escape.txt`. It also refuses an
/// entry whose name is absolute, and that half was unprotected: dropping
/// `p.isAbsolute` from the condition left the whole suite green. It matters
/// because `p.join` discards its base when the second part is absolute — an
/// entry named `/etc/cron.d/anything` is not written inside the plugin
/// directory, it is written where it says.
///
/// The archive is also refused before being read into memory if it is larger
/// than the limit. Removing that check was green too, and what it costs is
/// the whole file in memory before anything has looked at it.
void main() {
  test('an entry with an absolute name is refused', () async {
    final root = await Directory.systemTemp.createTemp('plugin_zip_');
    addTearDown(() => root.delete(recursive: true));

    final escaped = p.join(root.path, 'escaped.txt');
    expect(p.isAbsolute(escaped), isTrue,
        reason: '这条测试的前提是这个名字确实是绝对路径');

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
      ..addFile(ArchiveFile.string(escaped, 'bad'));
    final zip = File('${root.path}/bad.zip')
      ..writeAsBytesSync(ZipEncoder().encode(archive));

    await expectLater(
      PluginManager('${root.path}/installed').installZip(zip),
      throwsFormatException,
    );
    expect(File(escaped).existsSync(), isFalse,
        reason: '绝对路径的条目会被写到它自己说的地方，而不是插件目录里');
  });

  test('an archive larger than the limit is refused before it is read',
      () async {
    final root = await Directory.systemTemp.createTemp('plugin_zip_big_');
    addTearDown(() => root.delete(recursive: true));

    // Sparse: the size is set without writing the bytes, so this costs no
    // disk and no time. What is being tested is the check on `length()`,
    // which happens before anything is read.
    final zip = File('${root.path}/huge.zip');
    final handle = zip.openSync(mode: FileMode.write);
    handle.setPositionSync(65 * 1024 * 1024);
    handle.writeByteSync(0);
    handle.closeSync();
    expect(zip.lengthSync(), greaterThan(64 * 1024 * 1024));

    // The message, not just the type. Without the check the bytes are read
    // and the decoder throws about them being no archive at all — which is
    // also a FormatException, so asserting the type alone cannot tell the
    // two apart.
    await expectLater(
      PluginManager('${root.path}/installed').installZip(zip),
      throwsA(isA<FormatException>().having(
        (e) => e.message,
        'message',
        contains('the limit is'),
      )),
      reason: '超过上限的压缩包要在读进内存之前就被拒绝',
    );
  });
}

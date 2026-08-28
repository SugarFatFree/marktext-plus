import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/models/file_encoding.dart';
import 'package:marktext_plus/models/line_ending.dart';
import 'package:marktext_plus/services/file_service.dart';
import 'package:path/path.dart' as p;

/// `saveDocument` used to be a single `writeAsBytes`, which truncates the file
/// and then writes into it. A killed process, a full disk or lost power in
/// between left the reader's document empty or half written, with nothing to
/// recover from. It now writes a scratch file beside the document and swaps it
/// in, so what is on disk is only ever the old text or the new text.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('mtsave'));
  tearDown(() => root.deleteSync(recursive: true));

  String at(String name) => p.join(root.path, name);

  group('saveDocument', () {
    test('writes the text and leaves no scratch file behind', () async {
      final path = at('note.md');
      await FileService.saveDocument(path, 'hello');

      expect(File(path).readAsStringSync(), 'hello');
      final leftovers = root
          .listSync()
          .where((e) => e.path.endsWith(FileService.saveTempSuffix));
      expect(leftovers, isEmpty);
    });

    test('overwrites an existing document', () async {
      final path = at('note.md');
      File(path).writeAsStringSync('old and much longer than the new text');
      await FileService.saveDocument(path, 'new');

      expect(File(path).readAsStringSync(), 'new');
    });

    test('still honours the line ending and the encoding', () async {
      final path = at('crlf.md');
      await FileService.saveDocument(path, 'a\nb',
          lineEnding: LineEnding.crlf);

      expect(File(path).readAsStringSync(), 'a\r\nb');
    });

    test('recreates a parent folder that went away while the file was open',
        () async {
      // The reader moved or deleted the folder in another program. Upstream
      // hit this too (marktext#3509): the autosave simply failed.
      final path = at(p.join('gone', 'deeper', 'note.md'));
      await FileService.saveDocument(path, 'still saved');

      expect(File(path).readAsStringSync(), 'still saved');
    });

    test('writes through a symlink instead of replacing it', () async {
      final real = at('real.md');
      final link = at('link.md');
      File(real).writeAsStringSync('before');
      Link(link).createSync(real);

      await FileService.saveDocument(link, 'after');

      expect(File(real).readAsStringSync(), 'after',
          reason: '内容应该落到链接指向的文件上');
      expect(FileSystemEntity.isLinkSync(link), isTrue,
          reason: '链接本身不能被替换成普通文件');
    }, skip: Platform.isWindows ? 'symlinks need privileges on Windows' : null);

    test('swaps a new file in rather than writing into the old one', () async {
      // The distinguishing test. A hard link shares the inode: if the save
      // wrote into the existing file, the second name would see the new text
      // too. It sees the old text only because the document was replaced
      // wholesale — which is exactly what makes a half-written file
      // impossible.
      final path = at('note.md');
      final alias = at('alias.md');
      File(path).writeAsStringSync('original');
      final ln = await Process.run('ln', [path, alias]);
      expect(ln.exitCode, 0, reason: '硬链接没建起来，这条测试就没有意义了');

      await FileService.saveDocument(path, 'replaced');

      expect(File(path).readAsStringSync(), 'replaced');
      expect(File(alias).readAsStringSync(), 'original',
          reason: '别名还能看到新内容，说明是原地截断重写，不是原子换入');
    }, skip: Platform.isWindows ? 'no ln on Windows' : null);

    test('two saves of the same document in flight do not collide', () async {
      final path = at('busy.md');
      await Future.wait([
        FileService.saveDocument(path, 'aaaa'),
        FileService.saveDocument(path, 'bbbb'),
      ]);

      // Whichever landed last, the file is one of the two whole texts and
      // never a mixture of them.
      expect(File(path).readAsStringSync(), anyOf('aaaa', 'bbbb'));
      expect(
        root.listSync().where((e) => e.path.endsWith(FileService.saveTempSuffix)),
        isEmpty,
      );
    });
  });

  group('renameFile', () {
    test('renames a folder', () async {
      // File.rename refuses a directory outright (EISDIR), so this never
      // worked — and before the sidebar reported failures, it did nothing
      // visible at all.
      final dir = Directory(at('folder'))..createSync();
      File(p.join(dir.path, 'a.md')).writeAsStringSync('x');

      await FileService().renameFile(dir.path, at('renamed'));

      expect(Directory(at('renamed')).existsSync(), isTrue);
      expect(File(at(p.join('renamed', 'a.md'))).readAsStringSync(), 'x');
      expect(Directory(at('folder')).existsSync(), isFalse);
    });

    test('still renames a file', () async {
      File(at('a.md')).writeAsStringSync('x');
      await FileService().renameFile(at('a.md'), at('b.md'));

      expect(File(at('b.md')).readAsStringSync(), 'x');
      expect(File(at('a.md')).existsSync(), isFalse);
    });
  });

  group('listDirectory', () {
    test('hides a scratch file left by a save in flight', () async {
      File(at('note.md')).writeAsStringSync('x');
      File(at('note.md.1234_0${FileService.saveTempSuffix}'))
          .writeAsStringSync('half written');

      final nodes = await FileService().listDirectory(root.path);

      expect(nodes.map((n) => n.name), ['note.md']);
    });
  });
}

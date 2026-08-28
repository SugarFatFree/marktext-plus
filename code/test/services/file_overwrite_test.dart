import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/file_service.dart';

/// Nothing gets written over without being asked for.
///
/// `File.rename` replaces its destination and `writeAsString` truncates, both
/// without a word. Renaming a note to a name already in use destroyed the
/// note that had it, and asking for a new note under a name already in use
/// replaced that note with an empty document — no prompt, no undo, and
/// nothing on screen to say it had happened.
void main() {
  late Directory root;
  final service = FileService();

  setUp(() => root = Directory.systemTemp.createTempSync('overwrite'));
  tearDown(() => root.deleteSync(recursive: true));

  File write(String name, String content) =>
      File('${root.path}/$name')..writeAsStringSync(content);

  group('renaming', () {
    test('refuses a name another file already has', () async {
      write('a.md', 'the one being renamed');
      final taken = write('b.md', 'the one that would be lost');

      await expectLater(
        service.renameFile('${root.path}/a.md', taken.path),
        throwsA(isA<PathExistsException>()),
      );
      expect(taken.readAsStringSync(), 'the one that would be lost');
      expect(File('${root.path}/a.md').existsSync(), isTrue,
          reason: '被拒绝之后原文件应当原封不动');
    });

    test('refuses a name a folder already has', () async {
      write('a.md', 'x');
      Directory('${root.path}/taken').createSync();

      await expectLater(
        service.renameFile('${root.path}/a.md', '${root.path}/taken'),
        throwsA(isA<PathExistsException>()),
      );
    });

    test('allows a free name', () async {
      write('a.md', 'moved');

      await service.renameFile('${root.path}/a.md', '${root.path}/b.md');

      expect(File('${root.path}/b.md').readAsStringSync(), 'moved');
      expect(File('${root.path}/a.md').existsSync(), isFalse);
    });

    test('renaming a file to its own name is not an error', () async {
      final same = write('a.md', 'unchanged');

      await service.renameFile(same.path, same.path);

      expect(same.readAsStringSync(), 'unchanged');
    });

    test('overwrite: true is still available for callers that mean it',
        () async {
      write('a.md', 'winner');
      final taken = write('b.md', 'loser');

      await service.renameFile('${root.path}/a.md', taken.path,
          overwrite: true);

      expect(taken.readAsStringSync(), 'winner');
    });
  });

  group('creating', () {
    test('refuses to empty a file that is already there', () async {
      final taken = write('c.md', 'not to be lost');

      await expectLater(
        service.createFile(taken.path, ''),
        throwsA(isA<PathExistsException>()),
      );
      expect(taken.readAsStringSync(), 'not to be lost');
    });

    test('writes a file that is not there', () async {
      await service.createFile('${root.path}/new.md', 'hello');

      expect(File('${root.path}/new.md').readAsStringSync(), 'hello');
    });
  });
}

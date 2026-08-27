import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/file_service.dart';

void main() {
  late Directory tempDir;
  late FileService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('file_test_');
    service = FileService();
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('FileService', () {
    test('readFile returns content of existing file', () async {
      final path = '${tempDir.path}/test.md';
      File(path).writeAsStringSync('# Hello');
      final content = await service.readFile(path);
      expect(content, '# Hello');
    });

    test('writeFile creates and writes file', () async {
      final path = '${tempDir.path}/output.md';
      await service.writeFile(path, '# World');
      expect(File(path).readAsStringSync(), '# World');
    });

    test('listDirectory returns file nodes', () async {
      File('${tempDir.path}/a.md').writeAsStringSync('');
      Directory('${tempDir.path}/sub').createSync();
      File('${tempDir.path}/sub/b.md').writeAsStringSync('');
      final nodes = await service.listDirectory(tempDir.path);
      expect(nodes.length, 2);
      expect(nodes.any((n) => n.name == 'a.md'), true);
      expect(nodes.any((n) => n.name == 'sub' && n.isDirectory), true);
    });

    test('listDirectory does not descend into subdirectories', () async {
      Directory('${tempDir.path}/sub/deeper').createSync(recursive: true);
      File('${tempDir.path}/sub/deeper/c.md').writeAsStringSync('');

      final nodes = await service.listDirectory(tempDir.path);
      final sub = nodes.firstWhere((n) => n.name == 'sub');

      // Reading the whole tree up front is what made opening a folder slow.
      expect(sub.children, isEmpty);
    });

    test('listDirectory sorts directories first, then by name', () async {
      File('${tempDir.path}/b.md').writeAsStringSync('');
      File('${tempDir.path}/A.md').writeAsStringSync('');
      Directory('${tempDir.path}/zdir').createSync();

      final names = (await service.listDirectory(tempDir.path))
          .map((n) => n.name)
          .toList();

      expect(names, ['zdir', 'A.md', 'b.md']);
    });

    test('listDirectory returns empty for a path it cannot read', () async {
      expect(await service.listDirectory('${tempDir.path}/missing'), isEmpty);
    });
  });
}

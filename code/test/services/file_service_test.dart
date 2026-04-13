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
  });
}

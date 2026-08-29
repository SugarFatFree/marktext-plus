import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/image_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
import 'package:path/path.dart' as p;

/// An image stored by the editor can be found again by the editor.
///
/// Two halves written separately: one decides where the file goes and what
/// link to write, the other reads that link back and resolves it against the
/// document. They have disagreed before — the preview resolved a relative
/// path against the process's working directory, so every image stored beside
/// its document showed as red alt text (BUG-143). Storing and finding are one
/// contract and this is the test of it.
void main() {
  late Directory root;
  late Directory docDir;
  late String docPath;
  late String sharedDir;
  late File source;

  setUp(() {
    root = Directory.systemTemp.createTempSync('imgtrip');
    docDir = Directory(p.join(root.path, 'notes'))..createSync();
    docPath = p.join(docDir.path, 'note.md');
    File(docPath).writeAsStringSync('# note\n');
    sharedDir = p.join(root.path, 'shared');
    Directory(sharedDir).createSync();
    // A space in the name, which is what makes the link need angle brackets.
    source = File(p.join((Directory(p.join(root.path, 'src'))..createSync()).path,
        'pic ture.png'))
      ..writeAsBytesSync([0x89, 0x50, 0x4E, 0x47]);
  });
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  /// Resolves [href] the way the preview does: absolute as written, relative
  /// against the document's own folder.
  String resolve(String href) => p.isAbsolute(href)
      ? href
      : p.normalize(p.join(p.dirname(docPath), href));

  for (final mode in ImageStorageMode.values) {
    test('an image stored in ${mode.name} mode is found again', () async {
      final link = await ImageService.storeImage(source.path, docPath,
          mode: mode, folder: sharedDir);
      final markdown = '![x](${ImageService.markdownDestination(link)})\n';

      final nodes = MarkdownParser().parse(markdown);
      final images = (nodes.single as ParagraphNode)
          .inlineSpans
          .where((s) => s.type == InlineType.image)
          .toList();
      expect(images, hasLength(1),
          reason: '${mode.name} 写出的 markdown 没有被解析成图片：$markdown');

      final href = images.single.href;
      expect(href, isNotNull);
      expect(File(resolve(href!)).existsSync(), isTrue,
          reason: '${mode.name}：链接 "$href" 指向的文件不存在');
    });
  }

  test('a document with no path still gets a usable link', () async {
    // Nothing to be relative to, so the link has to be absolute or the image
    // could never be found again.
    for (final mode in ImageStorageMode.values) {
      final link = await ImageService.storeImage(source.path, null,
          mode: mode, folder: sharedDir);
      expect(p.isAbsolute(link), isTrue, reason: mode.name);
      expect(File(link).existsSync(), isTrue, reason: mode.name);
    }
  });

  test('several images stored in the same millisecond all survive', () async {
    // Dropping a handful at once copies them faster than the clock ticks.
    final links = <String>[];
    for (var i = 0; i < 5; i++) {
      links.add(await ImageService.storeImage(source.path, docPath,
          mode: ImageStorageMode.copy));
    }
    expect(links.toSet(), hasLength(5), reason: '有链接重复，图片互相覆盖了');
    for (final link in links) {
      expect(File(resolve(link)).existsSync(), isTrue, reason: link);
    }
  });
}

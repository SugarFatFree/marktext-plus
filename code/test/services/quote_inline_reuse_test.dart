import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// What a quotation carries, and who reads it.
///
/// A quote's own `inlineSpans` held the whole of its text parsed a second
/// time: once for the quote and once for the paragraph inside it, which the
/// AST walk already visits. On a document full of quotations that was a third
/// of the parse, and on a deeply nested one it was quadratic — every level
/// parsed everything below it again.
///
/// These are the behaviours the duplicate was standing in for.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('quote_inline'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('an image inside a quote is still found and inlined', () async {
    // The reason the export scans quotes at all: a picture written inside one
    // has to be embedded, or the exported file points at a path that means
    // nothing on another machine.
    final image = File('${dir.path}/pic.png')
      ..writeAsBytesSync([0x89, 0x50, 0x4E, 0x47, 13, 10, 26, 10]);
    final source = File('${dir.path}/doc.md')..writeAsStringSync('x');
    final out = '${dir.path}/out.html';

    await ExportService.exportToHtml(
      '> 引用里的图：\n>\n> ![图](${image.uri.pathSegments.last})\n',
      out,
      sourcePath: source.path,
    );

    final html = File(out).readAsStringSync();
    expect(html, contains('data:image/png;base64'),
        reason: '引用里的图片没有被内联');
  });

  test('a link inside a quote is still a link', () {
    final html = MarkdownParser()
        .parse('> 见 [链接](/url) 这里\n')
        .map(ExportService.nodeToHtml)
        .join();
    expect(html, contains('<a href="/url">'));
  });

  test('the text of a quote is read from the blocks inside it', () {
    // Where the emphasis in `> **bold**` is now found.
    final quote = MarkdownParser().parse('> **bold**\n').single as BlockquoteNode;
    final paragraph = quote.children.single as ParagraphNode;
    expect(paragraph.inlineSpans.first.type, InlineType.bold);
  });
}

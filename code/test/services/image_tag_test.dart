import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// A picture written as `<img …>` rather than `![…](…)`.
///
/// The only way markdown has of saying how big a picture should be, so a
/// document that needs to say it falls back to the tag — upstream MarkText's
/// own documentation does so sixty times. Read as a block of HTML, every one
/// of them opened here as a line of angle brackets in a grey box.
void main() {
  late MarkdownParser parser;
  setUp(() => parser = MarkdownParser());

  InlineSpan imageIn(String source) {
    final node = parser.parse(source).first as ParagraphNode;
    return node.inlineSpans.single;
  }

  String htmlOf(String source) =>
      parser.parse(source).map(ExportService.nodeToHtml).join();

  group('a tag alone on its line is the picture it describes', () {
    test('src, alt and width are all read', () {
      final span = imageIn('<img src="a.png" alt="Red" width="400"/>\n');
      expect(span.type, InlineType.image);
      expect(span.href, 'a.png');
      expect(span.text, 'Red');
      expect(span.width, 400);
      expect(span.height, isNull, reason: '没写的尺寸不该被猜出来');
    });

    test('the attributes may be in any order and any quoting', () {
      // All three spellings appear in real documents.
      for (final tag in [
        "<img alt='Red' src='a.png' width='400'>",
        '<img width=400 src=a.png alt=Red>',
        '<img src="a.png" width="400" alt="Red">',
      ]) {
        final span = imageIn('$tag\n');
        expect(span.href, 'a.png', reason: tag);
        expect(span.width, 400, reason: tag);
      }
    });

    test('a height on its own is read too', () {
      expect(imageIn('<img src="a.png" height="120">\n').height, 120);
    });

    test('the export says the size the document asked for', () {
      expect(
        htmlOf('<img src="a.png" alt="Red" width="400">\n'),
        contains('<img src="a.png" alt="Red" width="400">'),
      );
    });

    test('an ordinary markdown image is unchanged', () {
      // The guard: nothing about `![alt](src)` moves.
      final span = imageIn('![alt](a.png)\n');
      expect(span.type, InlineType.image);
      expect(span.width, isNull);
      expect(htmlOf('![alt](a.png)\n'), contains('<img src="a.png" alt="alt">'));
    });
  });

  group('what is left as a block of HTML', () {
    test('a tag with text after it on the same line', () {
      // Not alone on its line, so it is a paragraph with inline HTML in it —
      // which is the inline-HTML switch's business, not this one's.
      final nodes = parser.parse('<img src="a.png"> 后面还有字\n');
      expect(nodes.single.type, NodeType.paragraph);
      expect(htmlOf('<img src="a.png"> 后面还有字\n'), contains('&lt;img'));
    });

    test('a tag inside a table cell', () {
      // A picture in a table is part of a block that would have to be
      // rendered whole. This project's own README writes its screenshots that
      // way, and they stay as they were.
      final nodes = parser.parse('<table>\n<tr><td><img src="a.png"></td></tr>\n</table>\n');
      expect(nodes.single.type, NodeType.htmlBlock);
    });

    test('some other tag alone on its line', () {
      expect(parser.parse('<div>x</div>\n').single.type, NodeType.htmlBlock);
    });

    test('a tag with no src is not a picture', () {
      expect(parser.parse('<img alt="nothing">\n').single.type,
          NodeType.htmlBlock);
    });
  });
}

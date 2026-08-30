import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// Emphasis whose content is itself marked up.
///
/// The span model was flat, so `**bold with a [link](/url)**` could only be a
/// bold run holding the characters `[link](/url)`: the brackets showed on
/// screen and the link was not a link. Every consumer — preview, HTML, Word,
/// PDF — was given the same flat list, so the loss was the same everywhere.
void main() {
  late MarkdownParser parser;
  setUp(() => parser = MarkdownParser());

  List<InlineSpan> spansOf(String source) {
    final node = parser.parse(source).single as ParagraphNode;
    return node.inlineSpans;
  }

  String htmlOf(String source) =>
      parser.parse(source).map(ExportService.nodeToHtml).join();

  group('the parser nests', () {
    test('a link inside bold', () {
      final span = spansOf('**bold with a [link](/url) in it**').single;
      expect(span.type, InlineType.bold);
      final link = span.children.firstWhere((c) => c.type == InlineType.link);
      expect(link.text, 'link');
      expect(link.href, '/url');
    });

    test('bold inside italic', () {
      final span = spansOf('*outer **inner** rest*').single;
      expect(span.type, InlineType.italic);
      expect(
        span.children.map((c) => c.type).toList(),
        contains(InlineType.bold),
      );
    });

    test('code inside bold', () {
      final span = spansOf('**see `code` here**').single;
      final code = span.children.firstWhere((c) => c.type == InlineType.code);
      expect(code.text, 'code');
    });

    test('plain emphasis carries no children', () {
      // The guard on the change: the flat path is what almost every span still
      // takes, and a second parse of every emphasis would be paid on every
      // keystroke.
      final span = spansOf('**just bold**').single;
      expect(span.type, InlineType.bold);
      expect(span.children, isEmpty);
      expect(span.text, 'just bold');
    });

    test('an escaped marker inside emphasis stays literal', () {
      // The recursion runs before escapes are put back, so `\*` cannot open a
      // nested emphasis. Running it afterwards would have read the restored
      // asterisks as markup.
      final span = spansOf(r'**a \*b\* c**').single;
      expect(span.type, InlineType.bold);
      expect(span.children, isEmpty);
      expect(span.text, 'a *b* c');
    });

    test('the source text is kept alongside the children', () {
      final span = spansOf('**bold with a [link](/url)**').single;
      expect(span.text, contains('[link](/url)'));
    });
  });

  group('a link nests too', () {
    test('bold link text is bold, and still a link', () {
      // `[**Download**](/url)` is how a button is written in a README; the
      // asterisks used to be shown as written.
      final span = spansOf('[**下载**](/url)').single;
      expect(span.type, InlineType.link);
      expect(span.href, '/url');
      expect(span.children.single.type, InlineType.bold);
      expect(span.children.single.text, '下载');
    });

    test('code inside link text', () {
      final span = spansOf('[带 `代码` 的链接](/url)').single;
      expect(
        span.children.map((c) => c.type).toList(),
        contains(InlineType.code),
      );
    });

    test('plain link text carries no children', () {
      final span = spansOf('[普通链接](/url)').single;
      expect(span.children, isEmpty);
    });

    test('HTML puts the strong inside the anchor', () {
      expect(
        htmlOf('[**下载**](/url)'),
        '<p><a href="/url"><strong>下载</strong></a></p>',
      );
    });

    test('HTML leaves a plain link exactly as before', () {
      expect(htmlOf('[普通链接](/url)'), '<p><a href="/url">普通链接</a></p>');
    });
  });

  group('the exports nest', () {
    test('HTML puts the link inside the strong', () {
      expect(
        htmlOf('**bold with a [link](/url)**'),
        '<p><strong>bold with a <a href="/url">link</a></strong></p>',
      );
    });

    test('HTML nests emphasis inside emphasis', () {
      expect(
        htmlOf('*outer **inner** rest*'),
        '<p><em>outer <strong>inner</strong> rest</em></p>',
      );
    });

    test('markers that run together are still not separated', () {
      // A known limitation left untouched by this change, recorded so a later
      // fix has something to move: `*outer **inner***` ends in three asterisks
      // that the flat pattern reads as one bold closing, so the outer italic
      // never forms. Nesting is about what happens once emphasis is found —
      // this is about finding it.
      expect(htmlOf('*outer **inner***'), isNot(contains('<em>')));
    });

    test('HTML leaves plain emphasis exactly as before', () {
      expect(htmlOf('**just bold**'), '<p><strong>just bold</strong></p>');
    });
  });
}

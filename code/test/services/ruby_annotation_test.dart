import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// `<ruby>漢<rt>hàn</rt></ruby>` — text with its pronunciation above it.
///
/// How Japanese furigana and Chinese pinyin are written, and the one inline
/// tag upstream MarkText gives a renderer of its own. Here it was escaped and
/// shown as angle brackets, so a document annotated this way read as its own
/// source.
void main() {
  late MarkdownParser parser;
  setUp(() => parser = MarkdownParser(enableHtml: true));

  List<InlineSpan> spansOf(String source) =>
      (parser.parse(source).first as ParagraphNode).inlineSpans;

  String htmlOf(String source) =>
      parser.parse(source).map(ExportService.nodeToHtml).join();

  group('the parser reads it', () {
    test('the text and the reading are one span', () {
      // Two spans would come apart at a line break, and be read aloud as two
      // separate words.
      final span = spansOf('<ruby>漢<rt>hàn</rt></ruby>').single;
      expect(span.type, InlineType.ruby);
      expect(span.text, '漢');
      expect(span.title, 'hàn');
    });

    test('it sits in the middle of a sentence', () {
      final spans = spansOf('汉字<ruby>漢<rt>hàn</rt></ruby>注音');
      expect(spans.map((s) => s.type).toList(), [
        InlineType.text,
        InlineType.ruby,
        InlineType.text,
      ]);
      expect(spans.last.text, '注音');
    });

    test('furigana over a whole word', () {
      final span = spansOf('<ruby>東京<rt>とうきょう</rt></ruby>').single;
      expect(span.text, '東京');
      expect(span.title, 'とうきょう');
    });

    test('the <rp> fallback brackets are dropped', () {
      // `<rp>` exists for readers that cannot draw ruby; this one draws it.
      final span =
          spansOf('<ruby>漢<rp>(</rp><rt>hàn</rt><rp>)</rp></ruby>').single;
      expect(span.type, InlineType.ruby);
      expect(span.text, '漢');
      expect(span.title, 'hàn');
    });

    test('with HTML turned off it stays as written', () {
      // The guard: this is the inline-HTML switch's business, like every
      // other tag.
      final plain = MarkdownParser()
          .parse('<ruby>漢<rt>hàn</rt></ruby>')
          .map(ExportService.nodeToHtml)
          .join();
      expect(plain, contains('&lt;ruby&gt;'));
    });
  });

  group('the exports keep the reading', () {
    test('HTML emits ruby, with brackets for readers that cannot draw it', () {
      expect(
        htmlOf('<ruby>漢<rt>hàn</rt></ruby>'),
        contains('<ruby>漢<rp>(</rp><rt>hàn</rt><rp>)</rp></ruby>'),
      );
    });

    test('HTML escapes a reading that looks like markup', () {
      expect(htmlOf('<ruby>x<rt>a&b</rt></ruby>'), contains('a&amp;b'));
    });
  });
}

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
    final node = parser.parse(source).first as ParagraphNode;
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

    test('plain emphasis reads as its own words', () {
      // Emphasis is resolved by the delimiter pass now, which always builds
      // the content as children. What matters to every consumer is that the
      // words come out — `text` still carries them.
      final span = spansOf('**just bold**').single;
      expect(span.type, InlineType.bold);
      expect(span.text, 'just bold');
      expect(span.children.single.text, 'just bold');
    });

    test('an escaped marker inside emphasis stays literal', () {
      // The recursion runs before escapes are put back, so `\*` cannot open a
      // nested emphasis. Running it afterwards would have read the restored
      // asterisks as markup.
      final span = spansOf(r'**a \*b\* c**').single;
      expect(span.type, InlineType.bold);
      expect(span.text, 'a *b* c');
      expect(
        span.children.map((c) => c.type).toList(),
        everyElement(InlineType.text),
        reason: '被转义的星号成了强调',
      );
    });

    test('the text reads as the words, not as the markup', () {
      // With emphasis resolved from delimiters, the span's own text is what
      // the reader sees rather than what was typed — which is what the plain
      // projection used for copying wants anyway.
      final span = spansOf('**bold with a [link](/url)**').single;
      expect(span.text, contains('link'));
      expect(span.text, isNot(contains('](')));
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

    test('a link inside a link is not a link', () {
      // An `<a>` inside an `<a>` is not valid HTML and is not what a browser
      // draws. Parsing the text of a link made this possible where before the
      // inner one was plain text, so the inner destination is dropped and its
      // text kept.
      final html = htmlOf('[foo [bar](/two)](/one)');
      expect(html, isNot(contains('/two')));
      expect('<a'.allMatches(html).length, 1, reason: '出现了嵌套锚点');
      expect(html, contains('foo'));
      expect(html, contains('bar'));
    });

    test('emphasis inside a link may not smuggle a link in either', () {
      final html = htmlOf('[foo *bar [baz](/two)* qux](/one)');
      expect('<a'.allMatches(html).length, 1, reason: '出现了嵌套锚点');
      expect(html, contains('<em>'));
      expect(html, contains('baz'));
    });

    test('a link inside emphasis is still a link', () {
      // The guard: the rule is about links inside links, not about emphasis.
      expect(
        htmlOf('*看 [链接](/url) 这里*'),
        contains('<a href="/url">链接</a>'),
      );
    });

    test('HTML leaves a plain link exactly as before', () {
      expect(htmlOf('[普通链接](/url)'), '<p><a href="/url">普通链接</a></p>');
    });
  });

  group('a reference link nests too', () {
    // The second of the two link branches. The first learned to read markup in
    // its text; this one was left reading it as characters.
    const definition = '\n\n[dl]: https://example.com\n';

    test('bold reference link text is bold', () {
      final span = spansOf('[**下载**][dl]$definition');
      expect(span.single.type, InlineType.link);
      expect(span.single.href, 'https://example.com');
      expect(span.single.children.single.type, InlineType.bold);
    });

    test('HTML puts the strong inside the anchor', () {
      expect(
        htmlOf('[**下载**][dl]$definition'),
        contains('<a href="https://example.com"><strong>下载</strong></a>'),
      );
    });

    test('a plain reference link is unchanged', () {
      expect(spansOf('[普通][dl]$definition').single.children, isEmpty);
    });

    test('an unresolved reference keeps its brackets but reads its text', () {
      // marked, the parser upstream MarkText uses, gives the same:
      // `[<strong>下载</strong>][missing]`. The label is not a link, but what
      // is written inside it is still markup.
      final html = htmlOf('[**下载**][missing]\n');
      expect(html, contains('[<strong>下载</strong>][missing]'));
    });
  });

  group('an image describes itself in words', () {
    test('alt text drops the markers', () {
      // Alt text is what is read out when the picture does not appear, which
      // is no place for asterisks.
      expect(
        htmlOf('![一张 **重要** 的图](/img.png)'),
        contains('alt="一张 重要 的图"'),
      );
    });

    test('a link inside alt text becomes its label', () {
      expect(htmlOf('![见 [这里](/x)](/img.png)'), contains('alt="见 这里"'));
    });

    test('a reference image drops them too', () {
      expect(
        htmlOf('![**重要**][img]\n\n[img]: /a.png\n'),
        contains('alt="重要"'),
      );
    });

    test('plain alt text is unchanged', () {
      expect(htmlOf('![一张图](/img.png)'), contains('alt="一张图"'));
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

    test('markers that run together are separated correctly', () {
      // This was a recorded limitation of the flat pattern: `*outer
      // **inner***` ends in three asterisks that it read as one bold closing,
      // so the outer italic never formed. The delimiter pass decides it from
      // the whole paragraph, and gets what marked gets.
      expect(
        htmlOf('*outer **inner***'),
        contains('<em>outer <strong>inner</strong></em>'),
      );
    });

    test('HTML leaves plain emphasis exactly as before', () {
      expect(htmlOf('**just bold**'), '<p><strong>just bold</strong></p>');
    });
  });
}

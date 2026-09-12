import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/html_to_markdown.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// A destination ends at the `)` that closes it and a label at the `]`, so a
/// URL or a label holding one of those has to say it does not mean it.
///
/// `<a href="http://x/a)b">` was written as `[text](http://x/a)b)`, which came
/// back as a link to `http://x/a` with `b)` leaking into the paragraph as text.
/// A label holding a `]` was worse: `[a ] b](http://x)` is not a link at all, so
/// the whole thing arrived as literal characters with the address showing.
///
/// This parser reads both of the format's answers — angle brackets around a
/// destination, a backslash before a bracket in a label — which was checked
/// before relying on them.
void main() {
  String md(String html) => HtmlToMarkdown.convert(html) ?? '';
  String rendered(String html) => MarkdownParser()
      .parse(md(html))
      .map(ExportService.nodeToHtml)
      .join()
      .trim();

  group('a link destination', () {
    const urls = [
      'http://x/a)b',
      'http://x/a(b',
      'http://x/a b',
      'http://x/a(b)c',
      'http://x/plain',
      'http://x/a<b',
    ];

    for (final url in urls) {
      test(url, () {
        final html = '<p><a href="${url.replaceAll('<', '&lt;')}">text</a></p>';
        final out = rendered(html);
        expect(out, startsWith('<p><a href='), reason: 'wrote "${md(html)}"');
        expect(out, endsWith('>text</a></p>'), reason: 'wrote "${md(html)}"');
      });
    }

    test('a balanced url is left as it is, without brackets', () {
      expect(md('<p><a href="http://x/a(b)c">t</a></p>').trim(),
          '[t](http://x/a(b)c)');
    });

    test('an unbalanced one is wrapped', () {
      expect(md('<p><a href="http://x/a)b">t</a></p>').trim(),
          '[t](<http://x/a)b>)');
    });
  });

  group('a link label', () {
    test('a closing bracket in the label keeps it a link', () {
      final out = rendered('<p><a href="http://x">a ] b</a></p>');
      expect(out, '<p><a href="http://x">a ] b</a></p>',
          reason: 'wrote "${md('<p><a href="http://x">a ] b</a></p>')}"');
    });

    test('both brackets survive', () {
      expect(rendered('<p><a href="http://x">see [1] here</a></p>'),
          '<p><a href="http://x">see [1] here</a></p>');
    });
  });

  /// The reason the escaping is done to the text tokens and not to the finished
  /// label: a linked thumbnail is `[![alt](src)](href)`, whose inner brackets
  /// mean something. Escaping the whole label turned the image into four
  /// literal characters.
  group('an image inside a link', () {
    test('stays an image and stays linked', () {
      final out = rendered(
          '<p><a href="http://x"><img src="http://y" alt="pic"></a></p>');
      expect(out, contains('<a href="http://x"'));
      expect(out, contains('<img src="http://y"'));
    });

    test('a bracket in the alt text does not take the link apart', () {
      final out = rendered(
          '<p><a href="http://x"><img src="http://y" alt="a ] b"></a></p>');
      expect(out, contains('<a href="http://x"'));
      expect(out, contains('<img src="http://y"'));
    });

    test('emphasis in the label keeps its own markers', () {
      final out = rendered('<p><a href="http://x"><strong>a ] b</strong></a></p>');
      expect(out, contains('<a href="http://x"'));
      expect(out, contains('<strong>a ] b</strong>'),
          reason: 'wrote "${md('<p><a href="http://x"><strong>a ] b</strong></a></p>')}"');
    });
  });

  group('an image', () {
    test('an unbalanced bracket in the source keeps it an image', () {
      final out = rendered('<p><img src="http://x/a)b" alt="pic"></p>');
      expect(out, contains('<img src="http://x/a)b"'),
          reason: 'wrote "${md('<p><img src="http://x/a)b" alt="pic"></p>')}"');
      expect(out, isNot(contains('b)</p>')));
    });

    test('a closing bracket in the alt text keeps it an image', () {
      final out = rendered('<p><img src="http://x" alt="a ] b"></p>');
      expect(out, contains('<img '),
          reason: 'wrote "${md('<p><img src="http://x" alt="a ] b"></p>')}"');
      expect(out, contains('alt="a ] b"'));
    });
  });
}

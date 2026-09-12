import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/html_to_markdown.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// An emphasis ends at the run that closes it, so a literal asterisk inside one
/// closes it early.
///
/// `<em>a*b</em>` was written as `*a*b*`, which came back as `<em>a</em>b*`: the
/// italic stopped at the reader's own asterisk and the rest of it became a stray
/// character. `<strong>a**b</strong>` went the same way.
///
/// The other wrapping tags answer this by dropping the outer marking, but that
/// cannot be the answer here: `<em>` around a `<strong>` is an everyday shape and
/// the markup for the inner one is asterisks, so refusing on "the content has an
/// asterisk" would lose the italic from every nested emphasis. The asterisks in
/// the *text* are escaped instead, which loses nothing.
///
/// Text inside a `<code>` is not escaped, because a backslash in a code span is
/// a backslash.
void main() {
  String md(String html) => HtmlToMarkdown.convert(html) ?? '';
  String rendered(String html) => MarkdownParser()
      .parse(md(html))
      .map(ExportService.nodeToHtml)
      .join()
      .trim();

  group('a literal asterisk inside an emphasis', () {
    const shapes = {
      '<p><em>a*b</em></p>': '<p><em>a*b</em></p>',
      '<p><strong>a**b</strong></p>': '<p><strong>a**b</strong></p>',
      '<p><em>*lead</em></p>': '<p><em>*lead</em></p>',
      '<p><em>trail*</em></p>': '<p><em>trail*</em></p>',
      '<p><strong>a*b</strong></p>': '<p><strong>a*b</strong></p>',
      '<p><i>3*4 and 5*6</i></p>': '<p><em>3*4 and 5*6</em></p>',
    };

    shapes.forEach((html, expected) {
      test(html, () {
        expect(rendered(html), expected, reason: 'wrote "${md(html)}"');
      });
    });
  });

  group('nesting is untouched', () {
    test('italic around bold keeps both', () {
      expect(rendered('<p><em>a <strong>b</strong> c</em></p>'),
          '<p><em>a <strong>b</strong> c</em></p>',
          reason: 'wrote "${md('<p><em>a <strong>b</strong> c</em></p>')}"');
    });

    test('bold around italic keeps both', () {
      expect(rendered('<p><strong>a <em>b</em> c</strong></p>'),
          '<p><strong>a <em>b</em> c</strong></p>');
    });

    test('a whole emphasis inside another still nests', () {
      expect(rendered('<p><strong><em>x</em></strong></p>'),
          '<p><em><strong>x</strong></em></p>');
    });
  });

  group('a code span inside an emphasis', () {
    test('an asterisk in the code is left as it is', () {
      final html = '<p><em><code>a*b</code></em></p>';
      expect(rendered(html), '<p><em><code>a*b</code></em></p>',
          reason: 'wrote "${md(html)}"');
    });

    test('no backslash is smuggled into the code', () {
      expect(md('<p><em><code>a*b</code></em></p>'), isNot(contains(r'\*')));
    });
  });
}

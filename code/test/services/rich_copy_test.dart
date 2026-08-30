import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
import 'package:marktext_plus/services/rich_copy_service.dart';

/// Copying out of the preview and pasting into Word.
///
/// The preview renders markdown, so a selection returns the *rendered* text:
/// a heading comes back as `My Heading`, without the `#`. The first attempt
/// fed that back through the markdown parser, which could only produce
/// `<p>My Heading</p>` — every heading and every bold run was already gone
/// before the conversion began, and that is what arrived in Word.
void main() {
  List<MarkdownNode> parse(String source) => MarkdownParser().parse(source);

  String? htmlFor(String document, String selection) =>
      RichCopyService.htmlForSelection(parse(document), selection);

  group('what a selection returns', () {
    test('a heading is drawn without its hashes', () {
      final node = parse('## My Heading\n').single;
      expect(RichCopyService.plainTextOf(node), 'My Heading');
    });

    test('bold and italic are drawn without their markers', () {
      final node = parse('a **bold** and *soft* word\n').single;
      expect(RichCopyService.plainTextOf(node), 'a bold and soft word');
    });
  });

  group('html for the selection', () {
    test('a whole heading comes back as a heading', () {
      expect(htmlFor('# Title\n\nbody\n', 'Title'), '<h1>Title</h1>');
      expect(htmlFor('### Third\n', 'Third'), '<h3>Third</h3>');
    });

    test('a bold run inside a paragraph keeps its bold', () {
      final html = htmlFor('a **bold** word\n', 'a bold word');
      expect(html, contains('<strong>bold</strong>'));
      expect(html, startsWith('<p>'));
    });

    test('a link keeps its target', () {
      final html = htmlFor('see [the docs](https://example.com)\n',
          'see the docs');
      expect(html, contains('href="https://example.com"'));
    });

    test('several blocks come back as several blocks', () {
      final html = htmlFor(
        '# Title\n\nFirst para.\n\nSecond para.\n',
        'Title\nFirst para.\nSecond para.',
      );
      expect(html, contains('<h1>Title</h1>'));
      expect(html, contains('First para.'));
      expect(html, contains('Second para.'));
    });

    test('a list comes back as a list', () {
      final html = htmlFor('- one\n- two\n', 'one\ntwo');
      expect(html, contains('<li>'));
      expect(html, anyOf(contains('<ul>'), contains('<ol>')));
    });

    test('part of a heading is still a heading', () {
      // Half a heading pasted as a paragraph is the bug in miniature.
      expect(htmlFor('# The Long Title\n', 'Long Title'),
          '<h1>Long Title</h1>');
    });

    test('part of a paragraph is just that part', () {
      // Not the whole paragraph: copying two words should paste two words.
      final html = htmlFor('one two three four\n', 'two three');
      expect(html, '<p>two three</p>');
    });

    test('angle brackets in the copied text are escaped', () {
      final html = htmlFor('use <div> here please\n', '<div> here');
      expect(html, isNot(contains('<div>')));
      expect(html, contains('&lt;div&gt;'));
    });

    test('a selection that is not in the document gives nothing', () {
      // Better than inventing HTML for text this preview never drew: the
      // plain text is already on the clipboard and is correct.
      expect(htmlFor('# Title\n', 'something else entirely'), isNull);
    });

    test('an empty selection gives nothing', () {
      expect(htmlFor('# Title\n', '   '), isNull);
    });

    test('a code block keeps being code', () {
      final html = htmlFor('```\nvoid main() {}\n```\n', 'void main() {}');
      expect(html, contains('<pre>'));
      expect(html, contains('<code'));
    });
  });

  group('the text a selection returns matches what is drawn', () {
    // plainTextOf is what a selection is matched against. Emphasis holding
    // markup keeps its own source text alongside the spans that text became,
    // so reading the source here reported `[link](/url)` for a paragraph the
    // preview draws as `link` — and the copy silently degraded to plain text.
    final parser = MarkdownParser();

    String textOf(String source) =>
        RichCopyService.plainTextOf(parser.parse(source).single);

    test('a link inside bold reads as its label', () {
      expect(textOf('**加粗里的 [链接](/url)**'), '加粗里的 链接');
    });

    test('bold link text reads as its label', () {
      expect(textOf('[**下载**](/url)'), '下载');
    });

    test('plain emphasis is unchanged', () {
      expect(textOf('普通 **加粗** 文字'), '普通 加粗 文字');
    });
  });
}

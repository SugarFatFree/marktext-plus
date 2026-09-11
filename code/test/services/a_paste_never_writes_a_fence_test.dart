import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/html_to_markdown.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// What the converter writes, the parser beside it has to read back.
///
/// `<del><sub>x</sub></del>` was written as `~~~x~~~`, and three tildes at the
/// start of a line open a fenced code block: the pasted paragraph and
/// everything after it disappeared inside one. `del` was the only one of the
/// five wrapping tags with no guard on what it was wrapping, and the guard the
/// other four use would not have caught this one either — `~x~` does not
/// contain `~~`, it only has to touch it.
///
/// Asterisks do not have this problem: a run of three is strong around
/// emphasis, which is exactly what `<strong><em>` means, so those nest.
void main() {
  String md(String html) => HtmlToMarkdown.convert(html) ?? '';
  String rendered(String markdown) =>
      MarkdownParser().parse(markdown).map(ExportService.nodeToHtml).join();

  group('a run of markers is never lengthened into a fence', () {
    const shapes = [
      '<p><del><sub>x</sub></del></p>',
      '<p><del><sub>x</sub></del> and more text after it</p>',
      '<p><del>~x~</del></p>',
      '<p><del><sub>x</sub></del></p><p>a second paragraph</p>',
      '<p><mark><sub>x</sub></mark></p>',
      '<p><u><sub>x</sub></u></p>',
    ];

    for (final html in shapes) {
      test(html, () {
        final markdown = md(html);
        expect(
          rendered(markdown),
          isNot(contains('<pre><code')),
          reason: 'wrote "$markdown", which opens a code block',
        );
      });
    }

    test('the text pasted after it survives', () {
      final markdown = md('<p><del><sub>x</sub></del> and more after</p>');
      expect(rendered(markdown), contains('and more after'));
      expect(rendered(markdown), isNot(contains('<pre><code')));
    });
  });

  group('what is kept when the two cannot both be written', () {
    /// One of the two has to go, and the four tags that already had a guard
    /// drop the outer one and keep what is inside. `del` does the same now.
    test('the inner marking is the one kept', () {
      expect(md('<p><del><sub>x</sub></del></p>').trim(), '~x~');
    });

    test('strikethrough alone is still written', () {
      expect(md('<p><del>x</del></p>').trim(), '~~x~~');
    });

    test('a tilde in the middle of the text is not a reason to refuse', () {
      expect(md('<p><del>a~b</del></p>').trim(), '~~a~b~~');
    });
  });

  group('asterisks nest, because a run of three means both', () {
    test('strong around em', () {
      expect(md('<p><strong><em>x</em></strong></p>').trim(), '***x***');
      expect(rendered('***x***'), contains('<em><strong>x</strong></em>'));
    });

    test('em around strong', () {
      expect(md('<p><em><strong>x</strong></em></p>').trim(), '***x***');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/html_to_markdown.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// A run of backticks ends at the next run of the same length, so a delimiter
/// has to be longer than anything it is quoting.
///
/// The converter wrote one backtick around whatever a `<code>` held, and three
/// around whatever a `<pre>` held. A snippet holding a backtick — a JavaScript
/// template literal is the everyday one — came apart into pieces with the
/// backticks it was quoting gone, and a block holding a fence of its own was
/// split into a code block, a paragraph and an empty code block.
///
/// This is the same reading as the emphasis runs: measure what is there instead
/// of assuming the delimiter is as long as the usual one.
void main() {
  String md(String html) => HtmlToMarkdown.convert(html) ?? '';
  String rendered(String markdown) =>
      MarkdownParser().parse(markdown).map(ExportService.nodeToHtml).join();

  group('an inline code span survives the backticks inside it', () {
    const snippets = [
      'a`b',
      '`lead',
      'trail`',
      r'const s = `hi ${name}`;',
      '``two``',
      'no backticks at all',
    ];

    // Leading and trailing spaces are not in this list: HTML collapses
    // whitespace inside `<code>` — only `<pre>` preserves it — so a space there
    // is not something the paste can be asked to carry.
    for (final snippet in snippets) {
      test('<code>$snippet</code>', () {
        final markdown = md('<p><code>${snippet.replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')}</code></p>');
        expect(
          rendered(markdown),
          contains('<code>$snippet</code>'),
          reason: 'wrote "$markdown"',
        );
      });
    }
  });

  group('a fenced block survives a fence inside it', () {
    test('three backticks in the middle of the code', () {
      final markdown = md('<pre><code>a\n```\nb</code></pre>');
      final out = rendered(markdown);
      expect(out, contains('a\n```\nb'), reason: 'wrote "$markdown"');
      // One block, not a block and a paragraph and another block.
      expect(RegExp('<pre>').allMatches(out), hasLength(1),
          reason: 'the block was split: "$out"');
    });

    test('four backticks in the middle of the code', () {
      final markdown = md('<pre><code>a\n````\nb</code></pre>');
      expect(rendered(markdown), contains('a\n````\nb'),
          reason: 'wrote "$markdown"');
    });

    test('a block with no fence inside keeps the usual three', () {
      final markdown = md('<pre><code>line one\nline two</code></pre>');
      expect(markdown.trim().startsWith('```'), isTrue, reason: markdown);
      expect(markdown.trim().startsWith('````'), isFalse, reason: markdown);
      expect(rendered(markdown), contains('line one\nline two'));
    });

    test('the language on the element is still carried', () {
      final markdown =
          md('<pre><code class="language-dart">a\n```\nb</code></pre>');
      expect(markdown, contains('dart'), reason: markdown);
      expect(rendered(markdown), contains('a\n```\nb'));
    });
  });
}

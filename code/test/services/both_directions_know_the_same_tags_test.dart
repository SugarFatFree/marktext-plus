import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/html_to_markdown.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// What the editor writes as HTML, it has to be able to read back.
///
/// The two directions are separate tables of tags and nothing joined them. That
/// was written down once, when the export knew `<mark>`, `<u>`, `<sup>` and
/// `<sub>` and the paste path knew none of them — and then it happened again,
/// to link titles, to maths and to footnotes, because the fix was four tags and
/// not a way of noticing.
///
/// This is the way of noticing. Every member of both enums needs either a sample
/// that survives the round trip or an exemption saying why it cannot, so a kind
/// added to either enum fails until somebody has decided which it is.
///
/// The samples are checked to actually produce the kind they are filed under,
/// because a sample that parses as something else would make its row pass while
/// testing nothing.
void main() {
  String htmlOf(String markdown) => MarkdownParser(enableHtml: true)
      .parse('$markdown\n')
      .map(ExportService.nodeToHtml)
      .join();
  String rendered(String markdown) => htmlOf(markdown).trim();
  String roundTrip(String markdown) =>
      HtmlToMarkdown.convert(htmlOf(markdown)) ?? '';

  /// Every span in a document, however deeply the blocks nest.
  List<InlineSpan> spansOf(String markdown) {
    final spans = <InlineSpan>[];
    void walk(List<MarkdownNode> nodes) {
      for (final node in nodes) {
        switch (node) {
          case ParagraphNode():
            spans.addAll(node.inlineSpans);
          case HeadingNode():
            spans.addAll(node.inlineSpans);
          case BlockquoteNode():
            spans.addAll(node.inlineSpans);
          case FootnoteDefinitionNode():
            spans.addAll(node.inlineSpans);
          case ListNode():
            for (final item in node.items) {
              spans.addAll(item.inlineSpans);
            }
          default:
            break;
        }
      }
    }

    walk(MarkdownParser(enableHtml: true).parse('$markdown\n'));
    return spans;
  }

  // --- spans ---

  const inlineSamples = <InlineType, String>{
    InlineType.text: 'just some words',
    InlineType.bold: 'a **bold** word',
    InlineType.italic: 'a *soft* word',
    InlineType.code: 'call `doThing()` now',
    InlineType.link: 'read [the manual](https://example.com "the tip") first',
    InlineType.image: 'see ![a picture](https://example.com/p.png) here',
    InlineType.strikethrough: 'a ~~gone~~ word',
    InlineType.mathInline: r'the sum $a + b$ here',
    InlineType.highlight: 'see ==the point== here',
    InlineType.superscript: 'area 5cm^2^ total',
    InlineType.subscript: 'water H~2~O only',
    InlineType.underline: 'see ++the line++ here',
    InlineType.footnoteRef: 'a claim[^src] here\n\n[^src]: the source',
  };

  /// The kinds whose HTML cannot come back as the same markdown, with the
  /// reason. An exemption is a decision, not a shrug.
  const inlineExempt = <InlineType, String>{
    InlineType.ruby:
        'the reading comes back as `漢(hàn)`, which is what the `<rp>` '
            'parentheses in the exported HTML exist to say — the fallback a '
            'reader without ruby support gets. Writing `<ruby>` back would need '
            'inline HTML, which is off by default, so the reader would see tags.',
  };

  test('every span kind is round-tripped or exempt for a stated reason', () {
    expect(
      {...inlineSamples.keys, ...inlineExempt.keys},
      InlineType.values.toSet(),
      reason: 'a span kind is in neither table. Add a sample that survives '
          'export and paste, or an exemption saying why it cannot.',
    );
    expect(
      inlineSamples.keys.toSet().intersection(inlineExempt.keys.toSet()),
      isEmpty,
      reason: 'a span kind is in both tables',
    );
  });

  inlineSamples.forEach((type, markdown) {
    group('$type', () {
      test('the sample really makes one', () {
        expect(spansOf(markdown).map((span) => span.type), contains(type),
            reason: 'the sample parses as '
                '${spansOf(markdown).map((s) => s.type).toSet()}');
      });

      test('survives export and paste', () {
        expect(rendered(roundTrip(markdown)), rendered(markdown),
            reason: 'came back as "${roundTrip(markdown)}"');
      });
    });
  });

  // --- blocks ---

  const blockSamples = <NodeType, String>{
    NodeType.heading: '## A title',
    NodeType.paragraph: 'A sentence.',
    NodeType.codeBlock: '```dart\nvar a = 1;\n```',
    NodeType.orderedList: '1. first\n2. second',
    NodeType.unorderedList: '- one\n- two',
    NodeType.blockquote: '> a quoted line',
    NodeType.horizontalRule: '***',
    NodeType.table: '| h1 | h2 |\n|---|---|\n| a | b |',
    NodeType.mathBlock: '\$\$\nE = mc^2\n\$\$',
    NodeType.footnoteDefinition: 'a claim[^src] here\n\n[^src]: the source',
  };

  const blockExempt = <NodeType, String>{
    NodeType.frontMatter:
        'front matter is only front matter at the very start of a document, '
            'and the converter is handed a fragment with no notion of where it '
            'sits. Writing `---` anywhere else is a thematic break, which is '
            'worse than the code block it becomes.',
    NodeType.htmlBlock:
        'the converter turns HTML into markdown, so a block of HTML with no '
            'markdown equivalent keeps its content and loses its wrapper. '
            'Keeping the wrapper would need inline HTML, off by default.',
  };

  test('every block kind is round-tripped or exempt for a stated reason', () {
    expect(
      {...blockSamples.keys, ...blockExempt.keys},
      NodeType.values.toSet(),
      reason: 'a block kind is in neither table. Add a sample that survives '
          'export and paste, or an exemption saying why it cannot.',
    );
    expect(
      blockSamples.keys.toSet().intersection(blockExempt.keys.toSet()),
      isEmpty,
      reason: 'a block kind is in both tables',
    );
  });

  blockSamples.forEach((type, markdown) {
    group('$type', () {
      test('the sample really makes one', () {
        final types = MarkdownParser(enableHtml: true)
            .parse('$markdown\n')
            .map((node) => node.type);
        expect(types, contains(type),
            reason: 'the sample parses as ${types.toSet()}');
      });

      test('survives export and paste', () {
        expect(rendered(roundTrip(markdown)), rendered(markdown),
            reason: 'came back as "${roundTrip(markdown)}"');
      });
    });
  });
}

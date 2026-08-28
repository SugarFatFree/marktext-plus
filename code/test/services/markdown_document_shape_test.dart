import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// One document exercising several constructs at once.
///
/// Every change is checked against a corpus of single constructs, and each
/// came back byte-identical — which proves the change broke nothing, not that
/// the behaviour was right. Parsing one document that mixes them is what
/// caught two lists of different kinds being collected into one node, and
/// that is the gap this file exists to keep covered.
const _document =
    '## Heading with closing hashes ##\n'
    '\n'
    'Write to foo@example.com or <bar@example.com>.\n'
    '\n'
    '[see [1] here](https://example.com) and ![alt [x]](img.png)\n'
    '\n'
    '<kbd>Ctrl</kbd>+<kbd>C</kbd>\n'
    '\n'
    '<img src="a.png">\n'
    '\n'
    '3. third\n'
    '4. fourth\n'
    '\n'
    '- loose one\n'
    '\n'
    '- loose two\n'
    '\n'
    '1. step\n'
    '\n'
    '   ```dart\n'
    '   void main() {}\n'
    '   ```\n';

void main() {
  final parser = MarkdownParser();

  group('A document mixing constructs', () {
    test('splits into the blocks each construct asks for', () {
      final types = parser.parse(_document).map((n) => n.type).toList();

      expect(types, [
        NodeType.heading,
        NodeType.paragraph, // the two addresses
        NodeType.paragraph, // the bracketed link and image
        NodeType.paragraph, // inline HTML, which is not a block
        NodeType.htmlBlock, // a tag alone on its line, which is
        NodeType.orderedList,
        NodeType.unorderedList,
        // One list, not a list and a stray fence: the code block written
        // under the step is carried by the step.
        NodeType.orderedList,
      ]);
    });

    test('each list keeps its own kind, numbering and looseness', () {
      final lists = parser.parse(_document).whereType<ListNode>().toList();

      expect(lists, hasLength(3));
      expect(MarkdownParser.listMarkers(lists[0].items), ['3. ', '4. ']);
      // Tight: the gap after it belongs to the list that follows, not to this
      // one. Recording it here because the first attempt got that wrong.
      expect(lists[0].isLoose, isFalse);
      expect(lists[1].ordered, isFalse);
      expect(lists[1].isLoose, isTrue, reason: 'written with a gap');
      expect(MarkdownParser.listMarkers(lists[2].items), ['1. ']);
      expect(lists[2].items.single.children.map((c) => c.type).toList(),
          [NodeType.codeBlock],
          reason: '写在步骤下面的代码块应当属于那个步骤');
    });

    test('the heading drops its closing hashes', () {
      final heading = parser.parse(_document).first as HeadingNode;

      expect(heading.content, 'Heading with closing hashes');
    });

    test('both spellings of an address are linked', () {
      final spans = (parser.parse(_document)[1] as ParagraphNode).inlineSpans;
      final links = spans.where((s) => s.type == InlineType.link).toList();

      expect(links.map((s) => s.href).toList(), [
        'mailto:foo@example.com',
        'mailto:bar@example.com',
      ]);
    });

    test('brackets inside link and image text survive', () {
      final spans = (parser.parse(_document)[2] as ParagraphNode).inlineSpans;

      expect(spans.first.type, InlineType.link);
      expect(spans.first.text, 'see [1] here');
      expect(spans.last.type, InlineType.image);
      expect(spans.last.text, 'alt [x]');
    });

    test('the indented fence loses the list indentation', () {
      // Reached through the item that carries it, and dedented on the way, so
      // it is the fence the author wrote rather than indented code.
      final list = parser.parse(_document).whereType<ListNode>().last;
      final code = list.items.single.children.single as CodeBlockNode;

      expect(code.code, 'void main() {}');
      expect(code.language, 'dart');
    });

    test('every block round-trips through the preview editor', () {
      // Taking a block's source and putting it straight back must leave the
      // document untouched; that is what block editing does on a cancel.
      for (final node in parser.parse(_document)) {
        expect(
          MarkdownParser.replaceBlock(
            _document,
            node,
            MarkdownParser.sourceOfBlock(_document, node),
          ),
          _document,
          reason: 'block ${node.type.name}',
        );
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

void main() {
  late MarkdownParser parser;
  setUp(() => parser = MarkdownParser());

  _sourceSpanTests();
  _htmlBlockTests();

  group('Block parsing', () {
    test('parses heading levels 1-6', () {
      for (var level = 1; level <= 6; level++) {
        final prefix = '#' * level;
        final nodes = parser.parse('$prefix Hello');
        expect(nodes.length, 1);
        expect(nodes.first.type, NodeType.heading);
        expect((nodes.first as HeadingNode).level, level);
        expect((nodes.first as HeadingNode).content, 'Hello');
      }
    });

    test('parses paragraph', () {
      final nodes = parser.parse('Hello world');
      expect(nodes.length, 1);
      expect(nodes.first.type, NodeType.paragraph);
      expect((nodes.first as ParagraphNode).content, 'Hello world');
    });

    test('parses multi-line paragraph', () {
      final nodes = parser.parse('Line one\nLine two');
      expect(nodes.length, 1);
      expect(nodes.first.type, NodeType.paragraph);
    });

    test('parses unordered list with dash', () {
      final nodes = parser.parse('- item1\n- item2');
      expect(nodes.length, 1);
      expect(nodes.first.type, NodeType.unorderedList);
      final list = nodes.first as ListNode;
      expect(list.items.length, 2);
      expect(list.items[0].content, 'item1');
      expect(list.items[1].content, 'item2');
    });

    test('parses unordered list with asterisk', () {
      final nodes = parser.parse('* item1\n* item2');
      expect(nodes.first.type, NodeType.unorderedList);
    });
    test('parses ordered list', () {
      final nodes = parser.parse('1. first\n2. second\n3. third');
      expect(nodes.length, 1);
      expect(nodes.first.type, NodeType.orderedList);
      final list = nodes.first as ListNode;
      expect(list.ordered, true);
      expect(list.items.length, 3);
    });

    test('parses fenced code block', () {
      final nodes = parser.parse('```dart\nprint("hi");\n```');
      expect(nodes.length, 1);
      expect(nodes.first.type, NodeType.codeBlock);
      final code = nodes.first as CodeBlockNode;
      expect(code.language, 'dart');
      expect(code.code, 'print("hi");');
    });

    test('parses code block without language', () {
      final nodes = parser.parse('```\nsome code\n```');
      expect(nodes.first.type, NodeType.codeBlock);
      expect((nodes.first as CodeBlockNode).language, '');
    });

    test('parses blockquote', () {
      final nodes = parser.parse('> quote text');
      expect(nodes.length, 1);
      expect(nodes.first.type, NodeType.blockquote);
      expect((nodes.first as BlockquoteNode).content, 'quote text');
    });

    test('parses multi-line blockquote', () {
      final nodes = parser.parse('> line1\n> line2');
      expect(nodes.first.type, NodeType.blockquote);
      expect((nodes.first as BlockquoteNode).content, 'line1\nline2');
    });

    test('parses horizontal rule with dashes', () {
      final nodes = parser.parse('---');
      expect(nodes.length, 1);
      expect(nodes.first.type, NodeType.horizontalRule);
    });

    test('parses horizontal rule with asterisks', () {
      final nodes = parser.parse('***');
      expect(nodes.first.type, NodeType.horizontalRule);
    });

    test('parses horizontal rule with underscores', () {
      final nodes = parser.parse('___');
      expect(nodes.first.type, NodeType.horizontalRule);
    });

    test('parses GFM table', () {
      final md = '| A | B |\n| --- | --- |\n| 1 | 2 |\n| 3 | 4 |';
      final nodes = parser.parse(md);
      expect(nodes.length, 1);
      expect(nodes.first.type, NodeType.table);
      final table = nodes.first as TableNode;
      expect(table.headers, ['A', 'B']);
      expect(table.rows.length, 2);
      expect(table.rows[0], ['1', '2']);
    });

    test('parses mixed content', () {
      final md = '# Title\n\nSome text\n\n- item1\n- item2\n\n---';
      final nodes = parser.parse(md);
      expect(nodes.length, 4);
      expect(nodes[0].type, NodeType.heading);
      expect(nodes[1].type, NodeType.paragraph);
      expect(nodes[2].type, NodeType.unorderedList);
      expect(nodes[3].type, NodeType.horizontalRule);
    });

    test('parses empty input', () {
      final nodes = parser.parse('');
      expect(nodes, isEmpty);
    });
  });

  group('Inline parsing', () {
    test('parses bold with double asterisks', () {
      final spans = parser.parseInline('**bold**');
      expect(spans.any((s) => s.type == InlineType.bold && s.text == 'bold'), true);
    });

    test('parses bold with double underscores', () {
      final spans = parser.parseInline('__bold__');
      expect(spans.any((s) => s.type == InlineType.bold && s.text == 'bold'), true);
    });

    test('parses italic with single asterisk', () {
      final spans = parser.parseInline('*italic*');
      expect(spans.any((s) => s.type == InlineType.italic && s.text == 'italic'), true);
    });

    test('parses italic with single underscore', () {
      final spans = parser.parseInline('_italic_');
      expect(spans.any((s) => s.type == InlineType.italic && s.text == 'italic'), true);
    });

    test('parses inline code', () {
      final spans = parser.parseInline('`code`');
      expect(spans.any((s) => s.type == InlineType.code && s.text == 'code'), true);
    });

    test('parses link', () {
      final spans = parser.parseInline('[text](url)');
      expect(spans.any((s) => s.type == InlineType.link && s.text == 'text' && s.href == 'url'), true);
    });

    test('parses image', () {
      final spans = parser.parseInline('![alt](url)');
      expect(spans.any((s) => s.type == InlineType.image && s.text == 'alt' && s.href == 'url'), true);
    });

    test('parses strikethrough', () {
      final spans = parser.parseInline('~~deleted~~');
      expect(spans.any((s) => s.type == InlineType.strikethrough && s.text == 'deleted'), true);
    });

    test('parses mixed inline', () {
      final spans = parser.parseInline('Hello **bold** and *italic*');
      expect(spans.length, 4); // text, bold, text, italic
      expect(spans[0].type, InlineType.text);
      expect(spans[1].type, InlineType.bold);
      expect(spans[2].type, InlineType.text);
      expect(spans[3].type, InlineType.italic);
    });

    test('parses plain text', () {
      final spans = parser.parseInline('just text');
      expect(spans.length, 1);
      expect(spans.first.type, InlineType.text);
      expect(spans.first.text, 'just text');
    });
  });
}

void _htmlBlockTests() {
  group('HTML blocks', () {
    late MarkdownParser parser;
    setUp(() => parser = MarkdownParser());

    test('a tag opening and closing on one line ends there', () {
      // The bug this guards: the opening line was consumed before the search
      // for the closing tag began, so a self-contained tag found no close and
      // swallowed every block after it.
      const doc = '# Before\n'
          '\n'
          '<div class="note">inline</div>\n'
          '\n'
          '# After\n';

      final nodes = parser.parse(doc);
      final types = nodes.map((n) => n.type).toList();

      expect(types, contains(NodeType.htmlBlock));
      expect(
        types.where((t) => t == NodeType.heading).length,
        2,
        reason: 'the heading after the html block went missing',
      );
    });

    test('a void element ends on its own line', () {
      const doc = 'text\n\n<br>\n\n# After\n';
      final nodes = parser.parse(doc);
      expect(
        nodes.where((n) => n.type == NodeType.heading).length,
        1,
        reason: '<br> has no closing tag and must not consume the rest',
      );
    });

    test('a self-closing tag ends on its own line', () {
      const doc = 'text\n\n<img src="a.png" />\n\n# After\n';
      final nodes = parser.parse(doc);
      expect(nodes.where((n) => n.type == NodeType.heading).length, 1);
    });

    test('an unclosed tag costs one line, not the document', () {
      const doc = 'text\n\n<div>\n\n# After\n';
      final nodes = parser.parse(doc);
      expect(
        nodes.where((n) => n.type == NodeType.heading).length,
        1,
        reason: 'an unclosed tag must not swallow what follows',
      );
    });

    test('a genuine multi-line block still spans to its closing tag', () {
      const doc = '<div>\n  <span>one</span>\n</div>\n\n# After\n';
      final nodes = parser.parse(doc);
      final html = nodes.firstWhere((n) => n.type == NodeType.htmlBlock);
      expect(html.rawContent, contains('<span>one</span>'));
      expect(html.rawContent, contains('</div>'));
      expect(nodes.where((n) => n.type == NodeType.heading).length, 1);
    });
  });
}

void _sourceSpanTests() {
  group('Source spans', () {
    late MarkdownParser parser;
    setUp(() => parser = MarkdownParser());

    test('records line ranges for consecutive blocks', () {
      const doc = '# Title\n'
          '\n'
          'A paragraph\n'
          'spanning two lines.\n'
          '\n'
          '- one\n'
          '- two\n';

      final nodes = parser.parse(doc);
      expect(nodes.length, 3);

      // Line 0 is the heading; the blank line 1 belongs to no block.
      expect(nodes[0].sourceStart, 0);
      expect(nodes[0].sourceEnd, 1);

      expect(nodes[1].sourceStart, 2);
      expect(nodes[1].sourceEnd, 4);

      expect(nodes[2].sourceStart, 5);
      expect(nodes[2].sourceEnd, 7);
    });

    test('spans a fenced code block including both fences', () {
      const doc = 'intro\n'
          '\n'
          '```dart\n'
          'void main() {}\n'
          '```\n';

      final nodes = parser.parse(doc);
      final code = nodes.firstWhere((n) => n.type == NodeType.codeBlock);
      expect(code.sourceStart, 2);
      expect(code.sourceEnd, 5);
      expect(
        MarkdownParser.sourceOfBlock(doc, code),
        '```dart\nvoid main() {}\n```',
      );
    });

    test('sourceOfBlock returns markup that rawContent has stripped', () {
      const doc = '## Heading text\n';
      final node = parser.parse(doc).single;
      expect(node.rawContent, 'Heading text');
      expect(MarkdownParser.sourceOfBlock(doc, node), '## Heading text');
    });

    test('replaceBlock swaps only the target block', () {
      const doc = '# Title\n'
          '\n'
          'Old paragraph.\n'
          '\n'
          '# Trailing\n';

      final nodes = parser.parse(doc);
      final paragraph = nodes.firstWhere((n) => n.type == NodeType.paragraph);
      final updated = MarkdownParser.replaceBlock(doc, paragraph, 'New text.');

      expect(updated, '# Title\n\nNew text.\n\n# Trailing\n');
    });

    test('replaceBlock accepts multi-line replacements', () {
      const doc = 'one\n\ntwo\n';
      final nodes = parser.parse(doc);
      final updated =
          MarkdownParser.replaceBlock(doc, nodes.last, 'a\nb\nc');
      expect(updated, 'one\n\na\nb\nc\n');
    });

    test('replaceBlock with empty text deletes the block', () {
      const doc = 'keep\n\ndrop\n';
      final nodes = parser.parse(doc);
      final updated = MarkdownParser.replaceBlock(doc, nodes.last, '');
      expect(updated, 'keep\n\n');
    });

    test('replaceBlock preserves CRLF line endings', () {
      const doc = '# Title\r\n\r\nBody.\r\n';
      final nodes = parser.parse(doc);
      final paragraph = nodes.firstWhere((n) => n.type == NodeType.paragraph);
      final updated = MarkdownParser.replaceBlock(doc, paragraph, 'Changed.');
      expect(updated, '# Title\r\n\r\nChanged.\r\n');
    });

    test('replaceBlock preserves a BOM', () {
      const doc = '﻿# Title\n\nBody.\n';
      final nodes = parser.parse(doc);
      final paragraph = nodes.firstWhere((n) => n.type == NodeType.paragraph);
      final updated = MarkdownParser.replaceBlock(doc, paragraph, 'Changed.');
      expect(updated, '﻿# Title\n\nChanged.\n');
    });

    test('replaceBlock does not add a trailing newline that was absent', () {
      const doc = 'only paragraph';
      final node = parser.parse(doc).single;
      final updated = MarkdownParser.replaceBlock(doc, node, 'replaced');
      expect(updated, 'replaced');
    });

    test('front matter spans from the opening delimiter', () {
      const doc = '---\ntitle: x\n---\n\nBody\n';
      final nodes = parser.parse(doc);
      expect(nodes.first.type, NodeType.frontMatter);
      expect(nodes.first.sourceStart, 0);
      expect(nodes.first.sourceEnd, 3);
      expect(
        MarkdownParser.sourceOfBlock(doc, nodes.first),
        '---\ntitle: x\n---',
      );
    });
  });
}

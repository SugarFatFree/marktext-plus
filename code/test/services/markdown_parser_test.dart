import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

void main() {
  late MarkdownParser parser;
  setUp(() => parser = MarkdownParser());

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

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

void main() {
  late MarkdownParser parser;
  setUp(() => parser = MarkdownParser());

  _sourceSpanTests();
  _setextAndIndentedCodeTests();
  _nestedListTests();
  _inlineEdgeCaseTests();
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

void _inlineEdgeCaseTests() {
  group('Inline edge cases', () {
    late MarkdownParser parser;
    setUp(() => parser = MarkdownParser());

    List<InlineType> typesOf(String text) =>
        parser.parseInline(text).map((s) => s.type).toList();

    String textOf(String input) =>
        parser.parseInline(input).map((s) => s.text).join();

    test('a backslash escapes the character after it', () {
      expect(typesOf(r'literal \*asterisks\* here'), [InlineType.text]);
      // The backslashes themselves must not survive into the output.
      expect(textOf(r'literal \*asterisks\* here'), 'literal *asterisks* here');
    });

    test('underscores inside a word are not emphasis', () {
      // snake_case identifiers and file names are ordinary text.
      expect(typesOf('a snake_case_name stays plain'), [InlineType.text]);
      // The boundary has to exclude `_` too: here the second underscore of
      // the pair is not alphanumeric, so a looser check let `_me_` through.
      expect(typesOf('read__me__now'), [InlineType.text]);
    });

    test('a leading double underscore is emphasis, as CommonMark says', () {
      // `__init__ method` renders as bold on GitHub and in Typora: the run
      // starts at a boundary and ends before a space. Deliberately not
      // special-cased for dunder names.
      expect(typesOf('__init__ method'), contains(InlineType.bold));
    });

    test('underscores around a word still are', () {
      expect(typesOf('_real italic_'), contains(InlineType.italic));
      expect(typesOf('__real bold__'), contains(InlineType.bold));
    });

    test('currency is not inline maths', () {
      expect(typesOf(r'price is $5 and $10 today'), [InlineType.text]);
    });

    test('real inline maths still parses', () {
      expect(typesOf(r'math $E = mc^2$ inline'),
          contains(InlineType.mathInline));
    });

    test('superscript and subscript do not span spaces', () {
      expect(typesOf('x^2 and y^3 separately'), [InlineType.text]);
      expect(typesOf('a^2^ here'), contains(InlineType.superscript));
      expect(typesOf('H~2~O'), contains(InlineType.subscript));
    });

    test('markers inside inline code stay literal', () {
      final spans = parser.parseInline('`code with **bold** inside`');
      expect(spans.single.type, InlineType.code);
      expect(spans.single.text, 'code with **bold** inside');
    });
  });
}

void _nestedListTests() {
  group('Nested lists', () {
    late MarkdownParser parser;
    setUp(() => parser = MarkdownParser());

    test('records a depth for indented items', () {
      // Indentation used to be matched and then discarded, so a sub-list
      // rendered flush with its parent.
      const doc = '- one\n'
          '  - nested\n'
          '    - deeper\n'
          '- two\n';

      final list = parser.parse(doc).single as ListNode;
      expect(list.items.map((i) => i.depth).toList(), [0, 1, 2, 0]);
      expect(list.items.map((i) => i.content).toList(),
          ['one', 'nested', 'deeper', 'two']);
    });

    test('four-space indentation gives the same depths as two-space', () {
      const twoSpace = '- one\n  - nested\n';
      const fourSpace = '- one\n    - nested\n';

      List<int> depths(String doc) =>
          (parser.parse(doc).single as ListNode).items.map((i) => i.depth).toList();

      expect(depths(twoSpace), [0, 1]);
      expect(depths(fourSpace), [0, 1],
          reason: 'depth is the rank among indent widths, not a space count');
    });

    test('ordered lists nest too', () {
      const doc = '1. one\n  2. nested\n3. two\n';
      final list = parser.parse(doc).single as ListNode;
      expect(list.ordered, isTrue);
      expect(list.items.map((i) => i.depth).toList(), [0, 1, 0]);
    });

    test('a wrapped item stays one item', () {
      // The continuation line used to fall out of the list, splitting it into
      // list / paragraph / list.
      const doc = '- item that continues\n'
          '  on the next line\n'
          '- second\n';

      final nodes = parser.parse(doc);
      expect(nodes.length, 1, reason: 'the list was split up');

      final list = nodes.single as ListNode;
      expect(list.items.length, 2);
      expect(list.items.first.content, 'item that continues on the next line');
    });

    test('a blank line between items does not split the list', () {
      const doc = '- one\n\n- two\n';
      final nodes = parser.parse(doc);
      expect(nodes.length, 1, reason: 'a loose list became two lists');
      expect((nodes.single as ListNode).items.length, 2);
    });

    test('a paragraph after the list is still its own block', () {
      const doc = '- one\n\nA new paragraph.\n';
      final nodes = parser.parse(doc);
      expect(nodes.length, 2);
      expect(nodes.last.type, NodeType.paragraph);
    });

    test('nested task items keep their checkbox state', () {
      const doc = '- [ ] top\n  - [x] nested\n';
      final list = parser.parse(doc).single as ListNode;
      expect(list.items[1].depth, 1);
      expect(list.items[1].isTask, isTrue);
      expect(list.items[1].isChecked, isTrue);
    });
  });
}

void _setextAndIndentedCodeTests() {
  group('Setext headings', () {
    late MarkdownParser parser;
    setUp(() => parser = MarkdownParser());

    test('=== underlines a level 1 heading', () {
      final nodes = parser.parse('Title\n=====\n\nbody\n');
      final heading = nodes.first as HeadingNode;
      expect(heading.level, 1);
      expect(heading.content, 'Title');
      expect(nodes.last.type, NodeType.paragraph);
    });

    test('--- underlines a level 2 heading when text precedes it', () {
      final nodes = parser.parse('Subtitle\n---\n');
      final heading = nodes.single as HeadingNode;
      expect(heading.level, 2);
      expect(heading.content, 'Subtitle');
    });

    test('--- on its own is still a horizontal rule', () {
      // The ambiguity that matters: only a preceding paragraph line turns
      // `---` into a heading underline.
      final nodes = parser.parse('text\n\n---\n\nmore\n');
      expect(nodes.map((n) => n.type).toList(), [
        NodeType.paragraph,
        NodeType.horizontalRule,
        NodeType.paragraph,
      ]);
    });

    test('a list followed by --- keeps both', () {
      final nodes = parser.parse('- item\n---\n');
      expect(nodes.first.type, NodeType.unorderedList);
      expect(nodes.last.type, NodeType.horizontalRule);
    });
  });

  group('Indented code blocks', () {
    late MarkdownParser parser;
    setUp(() => parser = MarkdownParser());

    test('four spaces after a blank line is code', () {
      final nodes = parser.parse('text\n\n    code line\n    more\n\nafter\n');
      final code = nodes.firstWhere((n) => n.type == NodeType.codeBlock)
          as CodeBlockNode;
      expect(code.code, 'code line\nmore');
      expect(code.language, isEmpty);
      expect(nodes.last.type, NodeType.paragraph);
    });

    test('a tab indents code too', () {
      final nodes = parser.parse('text\n\n\tcode\n');
      final code = nodes.firstWhere((n) => n.type == NodeType.codeBlock)
          as CodeBlockNode;
      expect(code.code, 'code');
    });

    test('an indented line continuing a paragraph is not code', () {
      // CommonMark: indented code cannot interrupt a paragraph.
      final nodes = parser.parse('paragraph\n    still the paragraph\n');
      expect(nodes.single.type, NodeType.paragraph);
    });

    test('an indented list item is a nested list, not code', () {
      final nodes = parser.parse('- one\n    - nested\n');
      expect(nodes.single.type, NodeType.unorderedList);
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

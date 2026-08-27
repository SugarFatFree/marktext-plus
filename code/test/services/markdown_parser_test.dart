import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

void main() {
  group('An image used as a link', () {
    final parser = MarkdownParser();

    List<InlineSpan> spansOf(String source) =>
        (parser.parse(source).single as ParagraphNode).inlineSpans;

    const badge =
        '[![build](https://img.shields.io/b.svg)](https://ci.example.com)';

    test('a badge is one image that knows where it links', () {
      // The commonest thing at the top of a README. Parsed as separate
      // constructs it came out as a broken link, the characters "](", and a
      // second link.
      final spans = spansOf(badge);

      expect(spans, hasLength(1));
      expect(spans.single.type, InlineType.image);
      expect(spans.single.text, 'build');
      expect(spans.single.href, 'https://img.shields.io/b.svg');
      expect(spans.single.linkHref, 'https://ci.example.com');
    });

    test('both destinations may use angle brackets', () {
      final span = spansOf('[![a](<my img.png>)](<my page.html>)').single;
      expect(span.href, 'my img.png');
      expect(span.linkHref, 'my page.html');
    });

    test('a plain image has no link', () {
      expect(spansOf('![a](i.png)').single.linkHref, isNull);
    });

    test('two badges in a row stay separate', () {
      final images = spansOf('$badge $badge')
          .where((s) => s.type == InlineType.image);
      expect(images, hasLength(2));
    });

    test('the field survives escape and entity processing', () {
      // Both of those rebuild the span, and a field left out of either is
      // silently lost.
      final span = spansOf('[![a &amp; b](i.png)](http://x.com)').single;
      expect(span.text, 'a & b');
      expect(span.linkHref, 'http://x.com');
    });
  });

  group('Link destinations and titles', () {
    final parser = MarkdownParser();

    InlineSpan spanOf(String source) =>
        (parser.parse(source).single as ParagraphNode).inlineSpans.single;

    test('a destination may be wrapped in angle brackets', () {
      // The way to write a path containing a space, which matters for a
      // local editor: [doc](<my file.md>). It fell apart into literal text.
      final span = spanOf('[a](<http://x.com/a b>)');

      expect(span.type, InlineType.link);
      expect(span.href, 'http://x.com/a b');
    });

    test('a title may use single quotes', () {
      expect(spanOf("[a](http://x.com 't')").title, 't');
      expect(spanOf('[a](http://x.com "t")').title, 't');
    });

    test('images take both forms too', () {
      expect(spanOf('![alt](<my file.png>)').href, 'my file.png');
      expect(spanOf("![alt](i.png 'cap')").title, 'cap');
    });

    test('the plain forms are unchanged', () {
      expect(spanOf('[a](http://x.com)').href, 'http://x.com');
      expect(spanOf('[a](./doc.md)').href, './doc.md');
      expect(spanOf('[a](#section)').href, '#section');
      // A URL may still contain one level of balanced parentheses.
      expect(spanOf('[a](http://x.com/a_(b))').href, 'http://x.com/a_(b)');
    });

    test('a code span still closes on its own run of backticks', () {
      // The code span closes with a backreference by absolute group number,
      // which moves whenever a group is added ahead of it.
      expect(spanOf('`code`').text, 'code');
      expect(spanOf('``code with ` tick``').text, 'code with ` tick');
    });
  });

  group('Mixed and nested lists', () {
    final parser = MarkdownParser();

    ListNode listOf(String source) =>
        parser.parse(source).whereType<ListNode>().first;

    String markersOf(String source) =>
        MarkdownParser.listMarkers(listOf(source).items).join();

    test('a bulleted sub-point under a numbered step is its own item', () {
      // Collected with the parent's marker only, the sub-point was absorbed
      // into the parent's text: "a - b".
      final items = listOf('1. a\n   - b').items;

      expect(items, hasLength(2));
      expect(items[0].content, 'a');
      expect(items[1].content, 'b');
      expect(items[1].depth, 1);
    });

    test('an item remembers its own marker', () {
      final items = listOf('1. a\n   - b').items;
      expect(items[0].ordered, isTrue);
      expect(items[1].ordered, isFalse);
    });

    test('a numbered sub-list under a bullet works too', () {
      final items = listOf('- a\n  1. b').items;
      expect(items, hasLength(2));
      expect(items[1].ordered, isTrue);
    });

    test('numbering restarts at each level', () {
      // Counted over the flat list this read 1. 2. 3. 4.
      expect(markersOf('1. a\n   1. x\n   2. y\n2. b'), '1. 1. 2. 2. ');
    });

    test('a bulleted sub-list does not consume a number', () {
      expect(markersOf('1. a\n   - x\n   - y\n2. b'), '1. • • 2. ');
    });

    test('each parent starts its sub-list from one', () {
      expect(markersOf('1. a\n   1. x\n2. b\n   1. y'), '1. 1. 2. 1. ');
    });
  });

  group('Blockquotes hold blocks', () {
    final parser = MarkdownParser();

    BlockquoteNode quoteOf(String source) =>
        parser.parse(source).whereType<BlockquoteNode>().first;

    test('a quoted list is a list', () {
      // Rendered from the inline spans alone, this showed the characters
      // "- a" rather than a bulleted item.
      final children = quoteOf('> - a\n> - b').children;

      expect(children, hasLength(1));
      expect(children.single, isA<ListNode>());
      expect((children.single as ListNode).items, hasLength(2));
    });

    test('a quoted heading is a heading', () {
      final children = quoteOf('> # Title').children;
      expect((children.single as HeadingNode).level, 1);
    });

    test('a quoted code block keeps its code', () {
      final children = quoteOf('> ```\n> x\n> ```').children;
      expect((children.single as CodeBlockNode).code, 'x');
    });

    test('a quote inside a quote nests', () {
      final children = quoteOf('> outer\n> > inner').children;
      expect(children.last, isA<BlockquoteNode>());
    });

    test('blank quote lines separate paragraphs', () {
      expect(quoteOf('> one\n>\n> two').children, hasLength(2));
    });

    test('a plain quote is still one paragraph', () {
      final children = quoteOf('> just text').children;
      expect(children.single, isA<ParagraphNode>());
    });

    test('content and spans are still populated', () {
      // Anything still reading them keeps working.
      expect(quoteOf('> just text').content, 'just text');
      expect(quoteOf('> **bold**').inlineSpans.first.type, InlineType.bold);
    });
  });

  group('Tables', () {
    final parser = MarkdownParser();

    TableNode? tableOf(String source) =>
        parser.parse(source).whereType<TableNode>().firstOrNull;

    test('the outer pipes are optional', () {
      // GFM makes them optional; requiring them turned the table into a
      // paragraph.
      final table = tableOf('a | b\n--- | ---\n1 | 2')!;

      expect(table.headers, ['a', 'b']);
      expect(table.rows, [
        ['1', '2'],
      ]);
    });

    test('an escaped pipe stays inside its cell', () {
      // The only way to put a pipe in a cell. Splitting on it broke the cell
      // in two and left the backslash behind.
      final table = tableOf(
        r'| a \| b | c |'
        '\n|---|---|\n| x | y |',
      )!;

      expect(table.headers, ['a | b', 'c']);
    });

    test('rows are padded and truncated to the header width', () {
      expect(tableOf('| a | b |\n|---|---|\n| 1 |')!.rows, [
        ['1', ''],
      ]);
      expect(tableOf('| a | b |\n|---|---|\n| 1 | 2 | 3 |')!.rows, [
        ['1', '2'],
      ]);
    });

    test('the dashes row must have as many cells as the header', () {
      // Otherwise, with the outer pipes optional, a line of prose containing
      // a pipe followed by a horizontal rule reads as a one-column table.
      expect(tableOf('a | b\n---\nmore'), isNull);
      expect(tableOf('| a | b | c |\n|---|---|\n| 1 | 2 | 3 |'), isNull);
    });

    test('alignment markers are read', () {
      final table = tableOf('| a | b | c |\n|:--|:-:|--:|\n| 1 | 2 | 3 |')!;
      expect(table.alignments, ['left', 'center', 'right']);
    });

    test('a line of prose with a pipe is not a table', () {
      expect(tableOf('see a | b in prose'), isNull);
    });
  });

  group('Hard line breaks', () {
    final parser = MarkdownParser();

    String contentOf(String source) =>
        (parser.parse(source).single as ParagraphNode).content;

    test('trailing spaces do not survive into the text', () {
      // Every newline already breaks the line here, so the marker is not
      // needed — and it travelled into the copied text and every export.
      expect(contentOf('line one  \nline two'), 'line one\nline two');
    });

    test('a trailing backslash does not survive into the text', () {
      // This one was visible: a stray backslash at the end of the line.
      expect(contentOf('line one\\\nline two'), 'line one\nline two');
    });

    test('a plain newline is unchanged', () {
      expect(contentOf('line one\nline two'), 'line one\nline two');
    });

    test('the last line keeps its trailing characters', () {
      // Nothing follows it, so there is no break being asked for.
      expect(contentOf('line one\nline two  '), 'line one\nline two  ');
    });

    test('the source keeps the markers, so editing round-trips', () {
      // Block editing reads the source through sourceOfBlock, not the parsed
      // content, so what the user typed is what they get back.
      const source = 'line one  \nline two';
      final node = parser.parse(source).single;
      expect(MarkdownParser.sourceOfBlock(source, node), source);
    });
  });

  group('Code spans', () {
    final parser = MarkdownParser();

    List<InlineSpan> spansOf(String source) =>
        (parser.parse(source).single as ParagraphNode).inlineSpans;

    test('a longer delimiter lets the code contain a backtick', () {
      // Matched as a single pair, this truncated at the inner tick and left
      // the rest of the line as text.
      final span = spansOf('``code with ` tick``').single;
      expect(span.type, InlineType.code);
      expect(span.text, 'code with ` tick');
    });

    test('two double-delimited spans do not run together', () {
      // `([^`]+)` matched a..a, then the text between, then b..b: three spans
      // where there are two.
      final spans = spansOf('``a`` and ``b``');
      final code = spans.where((s) => s.type == InlineType.code).toList();

      expect(code, hasLength(2));
      expect(code[0].text, 'a');
      expect(code[1].text, 'b');
    });

    test('one space each side is dropped, so `` ` `` is a backtick', () {
      expect(spansOf('`` ` ``').single.text, '`');
      // Only when both sides have one.
      expect(spansOf('` x`').single.text, ' x');
      // And never when that would leave nothing.
      expect(spansOf('`  `').single.text, '  ');
    });

    test('ordinary code spans are unaffected', () {
      expect(spansOf('`code`').single.text, 'code');
      expect(spansOf('`*not italic*`').single.type, InlineType.code);
      expect(spansOf('`unclosed').single.type, InlineType.text);
    });
  });

  group('Code fences', () {
    final parser = MarkdownParser();

    CodeBlockNode codeOf(String source) =>
        parser.parse(source).first as CodeBlockNode;

    test('tildes open a fence too', () {
      // CommonMark allows ~~~; matching only backticks left the block as an
      // ordinary paragraph with the code as prose.
      expect(codeOf('~~~\nx\n~~~').code, 'x');
      expect(codeOf('~~~python\nx\n~~~').language, 'python');
    });

    test('a longer fence can contain a shorter one', () {
      // This is how a document shows ``` inside a code block. Read as a
      // three-backtick fence it became two empty blocks and the contents were
      // lost.
      expect(codeOf('````\n```\n````').code, '```');
      expect(codeOf('````\n```\nstill\n````').code, '```\nstill');
    });

    test('a fence is closed only by its own character', () {
      expect(codeOf('~~~\n```\nstill\n~~~').code, '```\nstill');
    });

    test('a closing fence may be longer than the opening one', () {
      expect(codeOf('```\nx\n`````').code, 'x');
    });

    test('an info string may contain punctuation', () {
      expect(codeOf('```objective-c\nx\n```').language, 'objective-c');
      expect(codeOf('```c++\nx\n```').language, 'c++');
    });

    test('an unclosed fence takes the rest of the document', () {
      expect(codeOf('```\nx').code, 'x');
    });

    test('the outline skips both kinds of fence', () {
      expect(
        MarkdownParser.headingOutline('# A\n~~~\n# B\n~~~\n# C')
            .map((h) => h.text)
            .toList(),
        ['A', 'C'],
      );
    });
  });

  group('Emphasis needs no space just inside the delimiters', () {
    final parser = MarkdownParser();

    List<InlineSpan> spansOf(String source) =>
        (parser.parse(source).single as ParagraphNode).inlineSpans;

    test('multiplication is not emphasis', () {
      // "2 * 3 * 4" used to italicise the 3.
      final spans = spansOf('2 * 3 * 4');
      expect(spans, hasLength(1));
      expect(spans.single.type, InlineType.text);
      expect(spans.single.text, '2 * 3 * 4');
    });

    test('a stray asterisk in prose stays literal', () {
      expect(spansOf('a * b * c').single.type, InlineType.text);
      expect(spansOf('foo _ bar _ baz').single.type, InlineType.text);
      expect(spansOf('_ spaced _').single.type, InlineType.text);
    });

    test('a delimiter closing after a space does not close', () {
      expect(spansOf('*trailing space *').single.type, InlineType.text);
    });

    test('ordinary emphasis is unaffected', () {
      expect(spansOf('*italic*').single.type, InlineType.italic);
      expect(spansOf('*multi word here*').single.text, 'multi word here');
      expect(spansOf('_italic_').single.type, InlineType.italic);
      // A single character between delimiters still counts.
      expect(spansOf('*a*').single.type, InlineType.italic);
      // Intraword asterisks are emphasis in CommonMark, unlike underscores.
      expect(spansOf('a*b*c')[1].type, InlineType.italic);
    });
  });

  group('Bold italic', () {
    final parser = MarkdownParser();

    List<InlineSpan> spansOf(String source) =>
        (parser.parse(source).single as ParagraphNode).inlineSpans;

    test('*** is bold and italic, not bold with a stray asterisk', () {
      // Read as the bold branch, `***x***` matched `**` + `*x` + `**` and left
      // the last asterisk behind as text.
      final spans = spansOf('***bold italic***');

      expect(spans, hasLength(1));
      expect(spans.single.type, InlineType.boldItalic);
      expect(spans.single.text, 'bold italic');
    });

    test('___ is bold and italic too', () {
      final spans = spansOf('___bold italic___');

      expect(spans, hasLength(1));
      expect(spans.single.type, InlineType.boldItalic);
      expect(spans.single.text, 'bold italic');
    });

    test('plain bold and italic still parse as before', () {
      expect(spansOf('**bold**').single.type, InlineType.bold);
      expect(spansOf('__bold__').single.type, InlineType.bold);
      expect(spansOf('*italic*').single.type, InlineType.italic);
      expect(spansOf('_italic_').single.type, InlineType.italic);
    });

    test('underscores inside a word are still not emphasis', () {
      expect(spansOf('snake_case_name').single.type, InlineType.text);
      expect(spansOf('read__me__now').single.type, InlineType.text);
    });
  });

  group('List syntax the editor already accepted', () {
    final parser = MarkdownParser();

    test('a task written with a capital X is a task', () {
      // GFM treats [x] and [X] alike, and the editor's prefix handling
      // accepted both — only the parser did not, so `- [X] done` rendered as
      // a bullet with the brackets showing.
      final list =
          parser.parse('- [X] done\n- [x] also\n- [ ] not yet').single
              as ListNode;

      expect(list.items, hasLength(3));
      expect(list.items[0].isTask, isTrue);
      expect(list.items[0].isChecked, isTrue);
      expect(list.items[0].content, 'done');
      expect(list.items[1].isChecked, isTrue);
      expect(list.items[2].isTask, isTrue);
      expect(list.items[2].isChecked, isFalse);
    });

    test('a bracket that is not a task marker stays text', () {
      final list = parser.parse('- [y] nope').single as ListNode;
      expect(list.items.single.isTask, isFalse);
    });

    test('an ordered list may use ) as well as .', () {
      // CommonMark allows both; the editor's prefix handling already did.
      final list = parser.parse('1) one\n2) two').single as ListNode;

      expect(list.ordered, isTrue);
      expect(list.items.map((i) => i.content).toList(), ['one', 'two']);
    });

    test('a number without a space is not a list', () {
      expect(parser.parse('1.no space').single, isA<ParagraphNode>());
    });
  });

  group('Bracketed link and image text', () {
    final parser = MarkdownParser();

    List<InlineSpan> spansOf(String source) =>
        (parser.parse(source).first as ParagraphNode).inlineSpans;

    test('link text may hold a bracketed run', () {
      final span = spansOf('[see [1] here](https://x.com)').single;

      expect(span.type, InlineType.link);
      expect(span.text, 'see [1] here');
      expect(span.href, 'https://x.com');
    });

    test('image alt text may hold one too', () {
      // Without the same rule on the image branch, this fell through to the
      // link branch, which matched from the `[` and left a stray `!` in front
      // of what was now a link.
      final span = spansOf('![alt [x]](img.png)').single;

      expect(span.type, InlineType.image);
      expect(span.text, 'alt [x]');
      expect(span.href, 'img.png');
    });

    test('brackets with no destination after them are still plain text', () {
      final spans = spansOf('[a [b] c] and (not a link)');

      expect(spans.single.type, InlineType.text);
    });

    test('a badge still keeps both its image and its link', () {
      final span = spansOf('[![img](a.png)](https://x.com)').single;

      expect(span.type, InlineType.image);
      expect(span.href, 'a.png');
      expect(span.linkHref, 'https://x.com');
    });
  });

  group('Email autolinks', () {
    final parser = MarkdownParser();

    List<InlineSpan> spansOf(String source) =>
        (parser.parse(source).first as ParagraphNode).inlineSpans;

    test('an address in angle brackets becomes a mailto link', () {
      final spans = spansOf('<foo@example.com>');

      expect(spans.single.type, InlineType.link);
      expect(spans.single.text, 'foo@example.com');
      expect(spans.single.href, 'mailto:foo@example.com');
    });

    test('a bare address in prose is linked', () {
      final spans = spansOf('mail me at foo@example.com');

      expect(spans.last.type, InlineType.link);
      expect(spans.last.href, 'mailto:foo@example.com');
    });

    test('a full stop ends the sentence, not the address', () {
      final spans = spansOf('mail me at foo@example.com.');

      expect(spans[1].text, 'foo@example.com');
      expect(spans.last.type, InlineType.text);
      expect(spans.last.text, '.');
    });

    test('something that is not an address is left alone', () {
      // No dot in the domain, no local part, and a number pair that only
      // looks like one.
      for (final source in ['a@b is not', '@mention only', '5@2 each']) {
        final spans = spansOf(source);
        expect(
          spans.every((s) => s.type != InlineType.link),
          isTrue,
          reason: source,
        );
      }
    });

    test('an address inside a code span or a link stays where it is', () {
      expect(spansOf('see `foo@example.com` here')[1].type, InlineType.code);

      final linked = spansOf('[text](mailto:foo@example.com)').single;
      expect(linked.text, 'text');
      expect(linked.href, 'mailto:foo@example.com');
    });

    test('the address survives escape and entity restoration', () {
      // Both rebuild every span field by field, and have dropped a new field
      // on the floor before.
      expect(
        spansOf(r'mail \*me\* at foo@example.com').last.href,
        'mailto:foo@example.com',
      );
      expect(
        spansOf('entity &amp; then foo@example.com').last.href,
        'mailto:foo@example.com',
      );
    });
  });

  group('ATX heading closing sequence', () {
    final parser = MarkdownParser();

    test('trailing hashes are a closing sequence, not content', () {
      for (final source in ['# Title #', '## Title ##', '### Title ###   ']) {
        final heading = parser.parse(source).first as HeadingNode;
        expect(heading.content, 'Title', reason: source);
      }
    });

    test('a hash with no space before it stays in the text', () {
      // `# C#` is a heading about C#, not a heading called C with a closing
      // sequence — CommonMark requires whitespace in front of the run.
      expect((parser.parse('# C#').first as HeadingNode).content, 'C#');
      expect((parser.parse('# foo#').first as HeadingNode).content, 'foo#');
    });

    test('only a run at the very end closes the heading', () {
      expect((parser.parse('# a # b').first as HeadingNode).content, 'a # b');
      expect((parser.parse('# a # b #').first as HeadingNode).content, 'a # b');
    });

    test('the outline drops the closing sequence too', () {
      // The outline and the rendered heading read the same regex, so this is
      // the assertion that keeps them from drifting apart again.
      final outline = MarkdownParser.headingOutline('# A #\n## B ##\n');

      expect(outline.map((h) => h.text).toList(), ['A', 'B']);
    });
  });

  group('MarkdownParser.headingOutline', () {
    test('reports level, text and 1-based line', () {
      final outline = MarkdownParser.headingOutline('# One\n\n## Two\n');

      expect(outline, hasLength(2));
      expect(outline[0].level, 1);
      expect(outline[0].text, 'One');
      expect(outline[0].line, 1);
      expect(outline[1].level, 2);
      expect(outline[1].line, 3);
    });

    test('a # inside a fenced block is not a heading', () {
      // "# install deps" in a shell snippet is a comment. Counting it filled
      // the outline with entries that scrolled somewhere unrelated — and,
      // because the preview maps its Nth heading to the Nth entry, pushed
      // every later entry onto the wrong line.
      final outline = MarkdownParser.headingOutline('''
# Title

```bash
# install deps
```

## Section
''');

      expect(outline.map((h) => h.text).toList(), ['Title', 'Section']);
    });

    test('a fence left unclosed swallows the rest', () {
      final outline = MarkdownParser.headingOutline('# A\n```\n# B\n');
      expect(outline.map((h) => h.text).toList(), ['A']);
    });

    test('an indented fence still counts', () {
      final outline = MarkdownParser.headingOutline('  ```\n# X\n  ```\n# Y');
      expect(outline.map((h) => h.text).toList(), ['Y']);
    });

    test('a byte order mark does not hide the first heading', () {
      // The outline panel read the raw text and the preview stripped the BOM,
      // so they disagreed about whether the file started with a heading.
      expect(MarkdownParser.headingOutline('\uFEFF# Title'), hasLength(1));
    });

    test('trailing spaces are trimmed from the text', () {
      expect(MarkdownParser.headingOutline('#  Title   ').single.text, 'Title');
    });

    test('a document with no headings has an empty outline', () {
      expect(MarkdownParser.headingOutline(''), isEmpty);
      expect(MarkdownParser.headingOutline('plain text'), isEmpty);
    });
  });

  late MarkdownParser parser;
  setUp(() => parser = MarkdownParser());

  _sourceSpanTests();
  _linkSyntaxTests();
  _nestedQuoteTests();
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
      expect(
        spans.any((s) => s.type == InlineType.bold && s.text == 'bold'),
        true,
      );
    });

    test('parses bold with double underscores', () {
      final spans = parser.parseInline('__bold__');
      expect(
        spans.any((s) => s.type == InlineType.bold && s.text == 'bold'),
        true,
      );
    });

    test('parses italic with single asterisk', () {
      final spans = parser.parseInline('*italic*');
      expect(
        spans.any((s) => s.type == InlineType.italic && s.text == 'italic'),
        true,
      );
    });

    test('parses italic with single underscore', () {
      final spans = parser.parseInline('_italic_');
      expect(
        spans.any((s) => s.type == InlineType.italic && s.text == 'italic'),
        true,
      );
    });

    test('parses inline code', () {
      final spans = parser.parseInline('`code`');
      expect(
        spans.any((s) => s.type == InlineType.code && s.text == 'code'),
        true,
      );
    });

    test('parses link', () {
      final spans = parser.parseInline('[text](url)');
      expect(
        spans.any(
          (s) =>
              s.type == InlineType.link && s.text == 'text' && s.href == 'url',
        ),
        true,
      );
    });

    test('parses image', () {
      final spans = parser.parseInline('![alt](url)');
      expect(
        spans.any(
          (s) =>
              s.type == InlineType.image && s.text == 'alt' && s.href == 'url',
        ),
        true,
      );
    });

    test('parses strikethrough', () {
      final spans = parser.parseInline('~~deleted~~');
      expect(
        spans.any(
          (s) => s.type == InlineType.strikethrough && s.text == 'deleted',
        ),
        true,
      );
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
      const doc =
          '# Before\n'
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

    test('a void block element ends on its own line', () {
      const doc = 'text\n\n<hr>\n\n# After\n';
      final nodes = parser.parse(doc);
      expect(nodes.where((n) => n.type == NodeType.htmlBlock).length, 1);
      expect(
        nodes.where((n) => n.type == NodeType.heading).length,
        1,
        reason: '<hr> has no closing tag and must not consume the rest',
      );
    });

    test('a self-closing block element ends on its own line', () {
      const doc = 'text\n\n<col />\n\n# After\n';
      final nodes = parser.parse(doc);
      expect(nodes.where((n) => n.type == NodeType.heading).length, 1);
    });

    test('an inline tag leaves the line a paragraph', () {
      // An html block is drawn as a grey monospace box, so a line of
      // `<kbd>Ctrl</kbd>+<kbd>C</kbd>` came out looking like a code sample.
      // CommonMark only starts a block on a block-level tag name.
      for (final line in [
        '<kbd>Ctrl</kbd>+<kbd>C</kbd>',
        '<span class="x">text</span>',
        '<img src="a.png">',
        '<br>',
      ]) {
        final nodes = parser.parse('text\n\n$line\n\n# After\n');
        expect(
          nodes.where((n) => n.type == NodeType.htmlBlock),
          isEmpty,
          reason: line,
        );
        expect(nodes.where((n) => n.type == NodeType.heading).length, 1);
      }
    });

    test('a block tag inside a centred wrapper still spans the wrapper', () {
      // The README shape: a div around an img. The div starts the block, and
      // the img inside it is carried along rather than ending it.
      const doc =
          '<div align="center">\n  <img src="logo.png">\n</div>\n\n# After\n';
      final nodes = parser.parse(doc);
      final html = nodes.firstWhere((n) => n.type == NodeType.htmlBlock);

      expect(html.rawContent, contains('<img src="logo.png">'));
      expect(html.rawContent, contains('</div>'));
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
      expect(
        typesOf(r'math $E = mc^2$ inline'),
        contains(InlineType.mathInline),
      );
    });

    test('superscript and subscript do not span spaces', () {
      expect(typesOf('x^2 and y^3 separately'), [InlineType.text]);
      expect(typesOf('a^2^ here'), contains(InlineType.superscript));
      expect(typesOf('H~2~O'), contains(InlineType.subscript));
    });

    test('a title is separated from the image path', () {
      // The path used to swallow the title, so an image written with one
      // never loaded: src became `pic.png "the title"`.
      final span = parser.parseInline('![alt](pic.png "the title")').single;
      expect(span.type, InlineType.image);
      expect(span.href, 'pic.png');
      expect(span.title, 'the title');
    });

    test('a link keeps parentheses inside its URL', () {
      // Wikipedia links routinely end in (disambiguation); `[^)]+` stopped at
      // the first bracket and truncated them.
      final span = parser
          .parseInline('[wiki](https://en.wikipedia.org/wiki/Foo_(bar))')
          .single;
      expect(span.type, InlineType.link);
      expect(span.href, 'https://en.wikipedia.org/wiki/Foo_(bar)');
    });

    test('a link title is separated from its URL', () {
      final span = parser.parseInline('[t](https://x.com "hi")').single;
      expect(span.href, 'https://x.com');
      expect(span.title, 'hi');
    });

    test('character entities resolve to their characters', () {
      // `&amp;` used to show as `&amp;` in the preview, and export escaped the
      // ampersand a second time into `&amp;amp;`.
      expect(textOf('A &amp; B'), 'A & B');
      expect(textOf('x &lt; y &gt; z'), 'x < y > z');
      expect(textOf('&copy; 2026'), '© 2026');
      expect(textOf('&#65;&#x42;'), 'AB');
    });

    test('a lone ampersand and unknown entities are left alone', () {
      expect(textOf('a & b'), 'a & b');
      expect(textOf('&notanentity;'), '&notanentity;');
      // Out of range for Unicode, so not a character at all.
      expect(textOf('&#999999999;'), '&#999999999;');
    });

    test('entities inside inline code stay literal', () {
      // CommonMark treats code spans as verbatim.
      final span = parser.parseInline('`&amp;`').single;
      expect(span.type, InlineType.code);
      expect(span.text, '&amp;');
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
      const doc =
          '- one\n'
          '  - nested\n'
          '    - deeper\n'
          '- two\n';

      final list = parser.parse(doc).single as ListNode;
      expect(list.items.map((i) => i.depth).toList(), [0, 1, 2, 0]);
      expect(list.items.map((i) => i.content).toList(), [
        'one',
        'nested',
        'deeper',
        'two',
      ]);
    });

    test('four-space indentation gives the same depths as two-space', () {
      const twoSpace = '- one\n  - nested\n';
      const fourSpace = '- one\n    - nested\n';

      List<int> depths(String doc) => (parser.parse(doc).single as ListNode)
          .items
          .map((i) => i.depth)
          .toList();

      expect(depths(twoSpace), [0, 1]);
      expect(depths(fourSpace), [
        0,
        1,
      ], reason: 'depth is the rank among indent widths, not a space count');
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
      const doc =
          '- item that continues\n'
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
      final code = nodes.firstWhere(
        (n) => n.type == NodeType.codeBlock,
      ) as CodeBlockNode;
      expect(code.code, 'code line\nmore');
      expect(code.language, isEmpty);
      expect(nodes.last.type, NodeType.paragraph);
    });

    test('a tab indents code too', () {
      final nodes = parser.parse('text\n\n\tcode\n');
      final code = nodes.firstWhere(
        (n) => n.type == NodeType.codeBlock,
      ) as CodeBlockNode;
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

void _nestedQuoteTests() {
  group('Nested blockquotes', () {
    late MarkdownParser parser;
    setUp(() => parser = MarkdownParser());

    test('a deeper quote becomes its own node', () {
      // Stripping one `>` and keeping the rest as text left the inner marker
      // showing as a literal `>` in the rendered quote.
      final nodes = parser.parse('> outer\n>> inner\n> outer again\n');

      expect(nodes.length, 3);
      final quotes = nodes.cast<BlockquoteNode>();
      expect(quotes.map((q) => q.depth).toList(), [0, 1, 0]);
      expect(quotes[1].content, 'inner');
      expect(quotes[1].content, isNot(contains('>')));
    });

    test('consecutive lines at one depth stay a single quote', () {
      final nodes = parser.parse('> a\n> b\n');
      final quote = nodes.single as BlockquoteNode;
      expect(quote.depth, 0);
      expect(quote.content, 'a\nb');
    });
  });
}

void _linkSyntaxTests() {
  group('Autolinks and reference links', () {
    late MarkdownParser parser;
    setUp(() => parser = MarkdownParser());

    List<InlineSpan> spansOf(String doc) {
      final spans = <InlineSpan>[];
      for (final node in parser.parse(doc)) {
        if (node is ParagraphNode) spans.addAll(node.inlineSpans);
      }
      return spans;
    }

    test('an autolink becomes a link', () {
      final span = spansOf('<https://example.com>\n').single;
      expect(span.type, InlineType.link);
      expect(span.href, 'https://example.com');
    });

    test('an autolink at the start of a line is not an HTML block', () {
      // `<https://…>` matched the html block pattern, so the whole line was
      // treated as markup.
      final nodes = parser.parse('<https://example.com>\n');
      expect(nodes.single.type, NodeType.paragraph);
    });

    test('a real HTML element is still a block', () {
      final nodes = parser.parse('<div>x</div>\n');
      expect(nodes.single.type, NodeType.htmlBlock);
    });

    test('a reference link resolves against its definition', () {
      final span = spansOf('[text][ref]\n\n[ref]: https://example.com\n')
          .single;
      expect(span.type, InlineType.link);
      expect(span.text, 'text');
      expect(span.href, 'https://example.com');
    });

    test('a definition may come before the reference', () {
      final spans = spansOf('[r]: https://x.com\n\nuse [t][r] here\n');
      expect(spans.any((s) => s.type == InlineType.link), isTrue);
    });

    test('a collapsed reference uses its text as the label', () {
      final span = spansOf('[ref][]\n\n[ref]: https://example.com\n').single;
      expect(span.href, 'https://example.com');
    });

    test('a definition line is not rendered as content', () {
      // It used to fall through to the paragraph branch and print
      // `[ref]: https://…` in the document.
      final nodes = parser.parse('[ref]: https://example.com\n');
      expect(nodes, isEmpty);
    });

    test('a bare address becomes a link', () {
      final spans = spansOf('visit https://example.com now\n');
      final link = spans.firstWhere((s) => s.type == InlineType.link);
      expect(link.href, 'https://example.com');
    });

    test('trailing punctuation is not part of a bare address', () {
      // "see https://example.com." — the full stop ends the sentence.
      final spans = spansOf('see https://example.com.\n');
      final link = spans.firstWhere((s) => s.type == InlineType.link);
      expect(link.href, 'https://example.com');
      expect(spans.last.text, '.');
    });

    test('an address already inside a markdown link is not doubled', () {
      final spans = spansOf('[t](https://x.com)\n');
      expect(spans.length, 1);
      expect(spans.single.text, 't');
    });

    test('an unresolved reference stays as written', () {
      final span = spansOf('[t][missing]\n').single;
      expect(span.type, InlineType.text);
      expect(span.text, '[t][missing]');
    });
  });
}

void _sourceSpanTests() {
  group('Source spans', () {
    late MarkdownParser parser;
    setUp(() => parser = MarkdownParser());

    test('records line ranges for consecutive blocks', () {
      const doc =
          '# Title\n'
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
      const doc =
          'intro\n'
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
      const doc =
          '# Title\n'
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
      final updated = MarkdownParser.replaceBlock(doc, nodes.last, 'a\nb\nc');
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

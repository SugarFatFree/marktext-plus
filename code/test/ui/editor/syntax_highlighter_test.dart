import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/syntax_highlighter.dart';

void main() {
  group('MarkdownSyntaxHighlighter', () {
    const headingColor = Colors.blue;
    const boldColor = Colors.red;
    const codeColor = Colors.green;
    const linkColor = Colors.purple;
    const defaultColor = Colors.black;

    test('a quoted line is painted with the quote colour', () {
      // The themes have carried a quote colour all along with nothing
      // painting in it.
      const quoteColor = Colors.teal;
      for (final source in ['> quoted', '  > indented', '>> nested']) {
        final result = MarkdownSyntaxHighlighter.highlight(
          source,
          headingColor: headingColor,
          boldColor: boldColor,
          codeColor: codeColor,
          linkColor: linkColor,
          defaultColor: defaultColor,
          quoteColor: quoteColor,
        );

        final spans = result.children!.cast<TextSpan>();
        expect(spans.map((s) => s.text).join(), source, reason: source);
        expect(spans.first.style?.color, quoteColor, reason: source);
      }
    });

    test('a greater-than sign inside a line is not a quote', () {
      const quoteColor = Colors.teal;
      final result = MarkdownSyntaxHighlighter.highlight(
        'a > b',
        headingColor: headingColor,
        boldColor: boldColor,
        codeColor: codeColor,
        linkColor: linkColor,
        defaultColor: defaultColor,
        quoteColor: quoteColor,
      );

      expect(
        result.children!.cast<TextSpan>().any(
          (s) => s.style?.color == quoteColor,
        ),
        isFalse,
      );
    });

    test('a comment is painted whole, emphasis inside it and all', () {
      // The comment pattern is tried before the emphasis ones, or the `*b*`
      // in `<!-- a *b* c -->` would take half of it.
      const commentColor = Colors.brown;
      const source = '<!-- a *b* c -->';
      final result = MarkdownSyntaxHighlighter.highlight(
        source,
        headingColor: headingColor,
        boldColor: boldColor,
        codeColor: codeColor,
        linkColor: linkColor,
        defaultColor: defaultColor,
        commentColor: commentColor,
      );

      final spans = result.children!.cast<TextSpan>();
      expect(spans.map((s) => s.text).join(), source);
      expect(spans.single.style?.color, commentColor);
    });

    test('the two new colours take part in the equality that caches spans', () {
      // The cached spans were painted with them, so leaving them out of the
      // comparison would keep stale colours after a theme change.
      const a = HighlightColors(
        heading: Colors.red,
        bold: Colors.green,
        code: Colors.blue,
        link: Colors.purple,
        defaultColor: Colors.black,
        quote: Colors.teal,
      );
      const b = HighlightColors(
        heading: Colors.red,
        bold: Colors.green,
        code: Colors.blue,
        link: Colors.purple,
        defaultColor: Colors.black,
        quote: Colors.orange,
      );

      expect(a == b, isFalse);
    });

    test('preserves original text length and content for markdown markers', () {
      const source = '**bold** end\n`code` tail';
      final result = MarkdownSyntaxHighlighter.highlight(
        source,
        headingColor: headingColor,
        boldColor: boldColor,
        codeColor: codeColor,
        linkColor: linkColor,
        defaultColor: defaultColor,
      );

      final renderedText = result.children!
          .cast<TextSpan>()
          .map((span) => span.text ?? '')
          .join();

      expect(renderedText, source);
      expect(renderedText.length, source.length);
    });

    test('highlights heading', () {
      final result = MarkdownSyntaxHighlighter.highlight(
        '# Heading',
        headingColor: headingColor,
        boldColor: boldColor,
        codeColor: codeColor,
        linkColor: linkColor,
        defaultColor: defaultColor,
      );

      expect(result.children, isNotNull);
      expect(result.children!.length, greaterThan(0));
      final firstSpan = result.children!.first as TextSpan;
      expect(firstSpan.style?.color, headingColor);
      expect(firstSpan.text, '# Heading');
    });

    test('highlights bold text', () {
      final result = MarkdownSyntaxHighlighter.highlight(
        '**bold**',
        headingColor: headingColor,
        boldColor: boldColor,
        codeColor: codeColor,
        linkColor: linkColor,
        defaultColor: defaultColor,
      );

      expect(result.children, isNotNull);
      final spans = result.children!.cast<TextSpan>();
      final boldSpan = spans.firstWhere((s) => s.style?.color == boldColor);
      expect(boldSpan.text, '**bold**');
      expect(boldSpan.style?.fontWeight, FontWeight.bold);
    });

    test('highlights inline code', () {
      final result = MarkdownSyntaxHighlighter.highlight(
        '`code`',
        headingColor: headingColor,
        boldColor: boldColor,
        codeColor: codeColor,
        linkColor: linkColor,
        defaultColor: defaultColor,
      );

      expect(result.children, isNotNull);
      final spans = result.children!.cast<TextSpan>();
      final codeSpan = spans.firstWhere((s) => s.style?.color == codeColor);
      expect(codeSpan.text, '`code`');
      expect(codeSpan.style?.fontFamily, 'monospace');
    });

    test('highlights link', () {
      final result = MarkdownSyntaxHighlighter.highlight(
        '[link](url)',
        headingColor: headingColor,
        boldColor: boldColor,
        codeColor: codeColor,
        linkColor: linkColor,
        defaultColor: defaultColor,
      );

      expect(result.children, isNotNull);
      final spans = result.children!.cast<TextSpan>();
      final linkSpan = spans.firstWhere((s) => s.style?.color == linkColor);
      expect(linkSpan.text, '[link](url)');
    });

    test('plain text uses default color', () {
      final result = MarkdownSyntaxHighlighter.highlight(
        'plain text',
        headingColor: headingColor,
        boldColor: boldColor,
        codeColor: codeColor,
        linkColor: linkColor,
        defaultColor: defaultColor,
      );

      expect(result.children, isNotNull);
      final spans = result.children!.cast<TextSpan>();
      final plainSpan = spans.firstWhere((s) => s.text == 'plain text');
      expect(plainSpan.style?.color, defaultColor);
    });

    // --- TextSpan text consistency tests ---

    /// Helper: extract concatenated text from a TextSpan tree.
    String extractText(TextSpan root) {
      final buf = StringBuffer();
      void visit(InlineSpan span) {
        if (span is TextSpan) {
          if (span.text != null) buf.write(span.text);
          span.children?.forEach(visit);
        }
      }

      visit(root);
      return buf.toString();
    }

    TextSpan hl(String source) => MarkdownSyntaxHighlighter.highlight(
      source,
      headingColor: headingColor,
      boldColor: boldColor,
      codeColor: codeColor,
      linkColor: linkColor,
      defaultColor: defaultColor,
    );

    test('text consistency: multiline plain text', () {
      const source = 'line one\nline two\nline three';
      expect(extractText(hl(source)), source);
    });

    test('text consistency: empty lines', () {
      const source = 'hello\n\nworld';
      expect(extractText(hl(source)), source);
    });

    test('text consistency: multiple consecutive empty lines', () {
      const source = 'a\n\n\nb';
      expect(extractText(hl(source)), source);
    });

    test('text consistency: trailing newline', () {
      const source = 'hello\n';
      expect(extractText(hl(source)), source);
    });

    test('text consistency: only newlines', () {
      const source = '\n\n\n';
      expect(extractText(hl(source)), source);
    });

    test('text consistency: mixed markdown with empty lines', () {
      const source = '# Heading\n\n**bold** text\n\n`code`\n\n[link](url)';
      expect(extractText(hl(source)), source);
    });

    test('text consistency: line ending with spaces', () {
      const source = 'hello   \nworld';
      expect(extractText(hl(source)), source);
    });

    test('text consistency: consecutive markdown markers', () {
      const source = '****\n`````';
      expect(extractText(hl(source)), source);
    });

    test('text consistency: single character lines', () {
      const source = 'a\nb\nc';
      expect(extractText(hl(source)), source);
    });

    test('text consistency: empty string', () {
      const source = '';
      expect(extractText(hl(source)), source);
    });

    test('no span has null text in children list', () {
      const source = '# Heading\n\n**bold** and `code`\nplain\n';
      final result = hl(source);
      for (final child in result.children!) {
        if (child is TextSpan) {
          expect(
            child.text,
            isNotNull,
            reason: 'TextSpan with null text found',
          );
          expect(
            child.text,
            isNot(''),
            reason: 'TextSpan with empty text found',
          );
        }
      }
    });

    test('newline is attached to preceding span, not standalone', () {
      // Newline characters must share the same TextStyle as the preceding
      // visible text.  Orphan unstyled '\n' spans cause Flutter's
      // EditableText to extend the selection highlight across the full
      // remaining width of the line (selection overflow bug).
      const source = 'hello\nworld\n\nend';
      final result = hl(source);
      final spans = result.children!.cast<TextSpan>();
      for (int i = 0; i < spans.length; i++) {
        final text = spans[i].text ?? '';
        if (text == '\n') {
          // A standalone '\n' is only acceptable for blank lines where
          // there is no preceding visible text to attach to.  In that
          // case the span must still carry a TextStyle.
          expect(
            spans[i].style,
            isNotNull,
            reason: 'Standalone newline span must have a style',
          );
        }
      }
    });

    test('line-ending newline shares style with preceding text', () {
      const source = '# Heading\nplain text\n**bold**\nend';
      final result = hl(source);
      final spans = result.children!.cast<TextSpan>();
      for (final span in spans) {
        final text = span.text ?? '';
        // If a span ends with '\n' and has visible text before it,
        // it must have a non-null style (proving the newline shares
        // the style of the preceding text).
        if (text.endsWith('\n') && text.length > 1) {
          expect(
            span.style,
            isNotNull,
            reason: 'Span "$text" ends with newline but has no style',
          );
        }
      }
    });
  });

  group('Long lines', () {
    const headingColor = Colors.blue;
    const boldColor = Colors.red;
    const codeColor = Colors.green;
    const linkColor = Colors.purple;
    const defaultColor = Colors.black;

    List<TextSpan> spansOf(String source) =>
        MarkdownSyntaxHighlighter.highlight(
          source,
          headingColor: headingColor,
          boldColor: boldColor,
          codeColor: codeColor,
          linkColor: linkColor,
          defaultColor: defaultColor,
        ).children!.cast<TextSpan>();

    /// Every one of these used to take seconds — 46 of them for the first —
    /// with the editor frozen for the whole time. They now run in tens of
    /// milliseconds; the two-second bar is loose enough not to flake on a
    /// loaded runner and still fails by two orders of magnitude if the
    /// quadratic scan or the backtracking comes back.
    void expectFast(String label, String line) {
      final watch = Stopwatch()..start();
      final spans = spansOf(line);
      watch.stop();

      expect(
        spans.map((s) => s.text ?? '').join(),
        line,
        reason: '$label lost or duplicated text',
      );
      expect(
        watch.elapsedMilliseconds,
        lessThan(2000),
        reason: '$label took ${watch.elapsedMilliseconds}ms',
      );
    }

    test('a line of unmatched brackets does not hang the editor', () {
      expectFast('open brackets', '[' * 20000);
      expectFast('brackets then one close', '${'[' * 20000}]');
    });

    test('a line of unclosed link destinations does not hang the editor', () {
      expectFast('open parens', '[a](' * 5000);
      expectFast('unclosed link', '[a](b' * 5000);
      expectFast('image flood', '![a](' * 5000);
    });

    test('a line of emphasis markers does not hang the editor', () {
      expectFast('asterisks', '*' * 20000);
      expectFast('alternating asterisks', '*a' * 10000);
      expectFast('alternating backticks', '`a' * 10000);
      expectFast('bold flood', '**b** ' * 5000);
    });

    // The five patterns added in v1.6.2 — `==`, `++`, `_`/`__`, `$` and the
    // footnote marker. Every marker already here got this treatment after one
    // of them froze the editor for the better part of a minute; a new one is
    // not exempt because it is new.
    test('the markers added later do not hang the editor either', () {
      expectFast('equals', '=' * 20000);
      expectFast('marked flood', '==m== ' * 5000);
      expectFast('unclosed mark', '==m ' * 5000);

      expectFast('plus signs', '+' * 20000);
      expectFast('underline flood', '++u++ ' * 5000);

      expectFast('underscores', '_' * 20000);
      expectFast('alternating underscores', '_a' * 10000);
      expectFast('snake case', 'read_me_now ' * 5000);

      expectFast('dollars', r'$' * 20000);
      expectFast('maths flood', r'$x$ ' * 5000);
      expectFast('prices', r'it cost $5 and $10 ' * 2000);

      expectFast('footnote openers', '[^' * 10000);
      expectFast('footnote flood', '[^1] ' * 5000);
    });

    test('ordinary long lines stay fast', () {
      expectFast('prose', 'the quick brown fox ' * 2000);
      expectFast('csv', List.generate(8000, (i) => 'c$i').join(','));
    });

    test('a link destination may contain a balanced pair of parentheses', () {
      // The parser reads `…/wiki/A_(b)` as one destination, and the editor
      // now agrees with it.
      final spans = spansOf('[W](https://en.wikipedia.org/wiki/A_(b))');
      final link = spans.firstWhere((s) => s.style?.color == linkColor);
      expect(link.text, '[W](https://en.wikipedia.org/wiki/A_(b))');
    });

    test('link text may contain a bracketed run', () {
      final spans = spansOf('[see [1] here](u)');
      final link = spans.firstWhere((s) => s.style?.color == linkColor);
      expect(link.text, '[see [1] here](u)');
    });
  });

  group('Fenced code blocks', () {
    const headingColor = Colors.blue;
    const boldColor = Colors.red;
    const codeColor = Colors.green;
    const linkColor = Colors.purple;
    const defaultColor = Colors.black;
    const quoteColor = Colors.teal;

    List<TextSpan> spansOf(String source) => MarkdownSyntaxHighlighter.highlight(
          source,
          headingColor: headingColor,
          boldColor: boldColor,
          codeColor: codeColor,
          linkColor: linkColor,
          defaultColor: defaultColor,
          quoteColor: quoteColor,
        ).children!.cast<TextSpan>();

    test('markdown inside a fence is not styled as markdown', () {
      // Styling is decided a line at a time, and a line on its own cannot tell
      // that it sits inside a fence — so `**bold**`, `[a](b)`, `# comment` and
      // `> arrow` in a snippet were all coloured as markdown.
      for (final body in ['**bold**', '[a](b)', '# comment', '> arrow']) {
        final spans = spansOf('```\n$body\n```');
        expect(spans.map((s) => s.text ?? '').join(), '```\n$body\n```');
        expect(
          spans.every((s) => s.style?.color == codeColor),
          isTrue,
          reason: body,
        );
      }
    });

    test('styling resumes after the closing fence', () {
      final spans = spansOf('```\nx\n```\n**bold**');
      expect(spans.last.style?.color, boldColor);
    });

    test('a tilde fence works like a backtick one', () {
      final spans = spansOf('~~~\n**bold**\n~~~');
      expect(spans.every((s) => s.style?.color == codeColor), isTrue);
    });

    test('a fence closes only on its own character and length', () {
      // ```` ``` ```` cannot close a fence opened with ````` ~~~ `````, and a
      // shorter run cannot close a longer one.
      final mixed = spansOf('~~~\n```\n**bold**\n~~~');
      expect(mixed.every((s) => s.style?.color == codeColor), isTrue);

      final shorter = spansOf('`````\n```\n**bold**\n`````');
      expect(shorter.every((s) => s.style?.color == codeColor), isTrue);
    });

    test('a run carrying an info string does not close a fence', () {
      final spans = spansOf('```\n**a**\n```dart\n**b**');
      expect(spans.every((s) => s.style?.color == codeColor), isTrue);
    });

    test('an unclosed fence runs to the end of the document', () {
      final spans = spansOf('```\n**bold**\n# heading');
      expect(spans.every((s) => s.style?.color == codeColor), isTrue);
    });

    test('four spaces is not a fence', () {
      // That is an indented code block, which this highlighter leaves alone.
      final spans = spansOf('    ```\n**bold**');
      expect(spans.last.style?.color, boldColor);
    });
  });

  group('IncrementalMarkdownHighlighter', () {
    const colors = HighlightColors(
      heading: Colors.blue,
      bold: Colors.red,
      code: Colors.green,
      link: Colors.purple,
      defaultColor: Colors.black,
    );

    List<TextSpan> full(String text) {
      if (text.isEmpty) return const <TextSpan>[];
      return MarkdownSyntaxHighlighter.highlight(
        text,
        headingColor: colors.heading,
        boldColor: colors.bold,
        codeColor: colors.code,
        linkColor: colors.link,
        defaultColor: colors.defaultColor,
      ).children!.cast<TextSpan>();
    }

    void expectSameAsFull(List<TextSpan> lineNodes, String text) {
      // build() now returns one span per line, each holding its runs, because
      // rebuilding a flat list of every run on every keystroke was what made
      // typing in a large file cost tens of milliseconds. What the incremental
      // path has to produce is unchanged once the lines are laid end to end,
      // which is exactly what this compares.
      final incremental = IncrementalMarkdownHighlighter.flatten(lineNodes);
      final reference = full(text);
      expect(
        incremental.map((s) => s.text).toList(),
        reference.map((s) => s.text).toList(),
      );
      expect(
        incremental.map((s) => s.style).toList(),
        reference.map((s) => s.style).toList(),
      );
      expect(incremental.map((s) => s.text ?? '').join(), text);
    }

    test('matches a full re-highlight through a run of edits', () {
      // The cache reuses the head and tail of the previous line list, so
      // insertions, deletions and in-place edits each have to keep it honest.
      final highlighter = IncrementalMarkdownHighlighter();
      final steps = [
        '# Title\n\nplain **bold** text\n`code`',
        '# Title\n\nplain **bold** texts\n`code`',
        '# Title\n\ninserted line\nplain **bold** texts\n`code`',
        '# Title\n\nplain **bold** texts\n`code`',
        '# Title changed\n\nplain **bold** texts\n`code`',
        '# Title changed\n\nplain **bold** texts\n`code`\n',
        '',
        'single',
      ];

      for (final step in steps) {
        expectSameAsFull(highlighter.build(step, colors), step);
      }
    });

    test('reuses spans for lines an edit did not touch', () {
      final highlighter = IncrementalMarkdownHighlighter();
      final first = highlighter.build('aaa\nbbb\nccc', colors);
      final second = highlighter.build('aaX\nbbb\nccc', colors);

      // build() returns one span per line. A line the edit did not touch is
      // handed back as the very same object — that reuse is the whole point of
      // this class. The last line is the exception: its span carries no
      // newline, and which line is last can change, so it is always rebuilt.
      expect(identical(first[1], second[1]), isTrue,
          reason: '没被改动的行应该原样复用');
      expect(identical(first[0], second[0]), isFalse,
          reason: '被改动的行必须重新扫描');
    });

    test('handles blank lines and a trailing newline', () {
      final highlighter = IncrementalMarkdownHighlighter();
      for (final source in ['\n', '\n\n\n', 'hello\n', 'a\n\nb']) {
        expectSameAsFull(highlighter.build(source, colors), source);
      }
    });

    test('a colour change rebuilds everything', () {
      final highlighter = IncrementalMarkdownHighlighter();
      highlighter.build('# Title', colors);

      const other = HighlightColors(
        heading: Colors.orange,
        bold: Colors.red,
        code: Colors.green,
        link: Colors.purple,
        defaultColor: Colors.black,
      );
      final recoloured = highlighter.build('# Title', other);

      // One line, one span, holding the heading's runs.
      final runs = IncrementalMarkdownHighlighter.flatten(recoloured);
      expect(runs.single.style?.color, Colors.orange);
    });

    test('opening a fence restyles every line below it', () {
      // The cache reuses lines whose text did not change; typing the opening
      // ``` leaves every line below textually identical while changing how
      // all of them are drawn, so the reuse has to key on fence state too.
      final highlighter = IncrementalMarkdownHighlighter();
      const plain = '**bold**\n# heading\n';

      expectSameAsFull(highlighter.build(plain, colors), plain);

      const fenced = '```\n**bold**\n# heading\n';
      final inside = highlighter.build(fenced, colors);
      expectSameAsFull(inside, fenced);
      expect(
        IncrementalMarkdownHighlighter.flatten(inside)
            .every((s) => s.style?.color == colors.code),
        isTrue,
        reason: 'everything between the fences is code',
      );

      // And closing it again puts the styling back.
      expectSameAsFull(highlighter.build(plain, colors), plain);
    });

    test('the last line has no newline however the document changes size', () {
      // Each line's spans are cached with the newline already attached, since
      // allocating one string per line was the most expensive part of a
      // keystroke on a large document. The final line is the one place that
      // form cannot be used, and it moves as the document grows and shrinks.
      final highlighter = IncrementalMarkdownHighlighter();
      const steps = [
        '**a**\n**b**\n**c**',
        '**a**\n**b**\n**c**\n',
        '**a**\n**b**\n**c**\n**d**',
        '**a**\n**b**',
        '**a**',
        '',
        '# h',
        '\n\n\n',
      ];
      for (final text in steps) {
        expectSameAsFull(highlighter.build(text, colors), text);
      }
    });

    test('gives up on documents past the size limit but keeps the text', () {
      final highlighter = IncrementalMarkdownHighlighter();
      final huge =
          '# h\n' *
          (IncrementalMarkdownHighlighter.maxHighlightedLength ~/ 4 + 1);

      final spans = highlighter.build(huge, colors);

      expect(highlighter.isSuspended, isTrue);
      expect(spans, hasLength(1));
      expect(spans.single.text, huge);

      // And it starts highlighting again once the document is small.
      final back = highlighter.build('# h', colors);
      expect(highlighter.isSuspended, isFalse);
      expect(
        IncrementalMarkdownHighlighter.flatten(back).single.style?.color,
        colors.heading,
      );
    });
  });
}

String repr(String s) => s.replaceAll('\n', '\\n').replaceAll('\t', '\\t');

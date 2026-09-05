import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
import 'package:marktext_plus/ui/editor/syntax_highlighter.dart';

/// What the source pane paints and what the preview draws, line by line.
///
/// Colouring is a claim: a line painted as a quote says "the pane beside this
/// one will draw a quote here". The heading rule was moved into the parser
/// for exactly this reason — `startsWith('#')` coloured `#tag` as a heading
/// the preview would not draw — but the quote rule was left hand-written
/// beside it, and it is looser than the parser's.
void main() {
  final parser = MarkdownParser();

  // Every role a distinct colour, so what a span claims is unambiguous.
  const colors = HighlightColors(
    heading: Color(0xFF000001),
    bold: Color(0xFF000002),
    code: Color(0xFF000003),
    link: Color(0xFF000004),
    defaultColor: Color(0xFF000005),
    quote: Color(0xFF000006),
    comment: Color(0xFF000007),
  );

  bool drawnAsQuote(String line) =>
      parser.parse(line).any((node) => node is BlockquoteNode);

  bool paintedAsQuote(String line) {
    final spans = MarkdownSyntaxHighlighter.highlightLine(line, colors);
    return spans.any((s) => s.style?.color == colors.quote);
  }

  void agree(String name, String line) {
    test(name, () {
      expect(paintedAsQuote(line), drawnAsQuote(line), reason: '「$line」');
    });
  }

  group('a line painted as a quote is one the preview quotes', () {
    agree('a plain quote', '> quoted');
    agree('one column of indent', ' > quoted');
    agree('three columns, the most the format allows', '   > quoted');
    // Four columns is where an indented block starts, so this is not a quote
    // however much it looks like one.
    agree('four columns is no longer a quote', '    > quoted');
    agree('eight columns', '        > quoted');
    agree('nested', '>> quoted');
    agree('nested with a space, as CommonMark writes it', '> > quoted');
    agree('an arrow in prose is not a quote', 'a -> b');
    agree('a greater-than mid-line', 'if a > b then');
  });

  // Agreement alone cannot catch the two of them being wrong together: they
  // read the same rule now, so loosening it loosens both and the comparison
  // still passes. These pin the rule itself.
  group('the rule itself', () {
    test('three columns is the most a marker may sit behind', () {
      expect(MarkdownParser.blockquoteDepthOf('   > quoted'), 1);
      expect(
        MarkdownParser.blockquoteDepthOf('    > quoted'),
        isNull,
        reason: '四列起是缩进块，不是引用',
      );
    });

    test('nesting counts the markers, spaced or not', () {
      expect(MarkdownParser.blockquoteDepthOf('>> deep'), 2);
      expect(
        MarkdownParser.blockquoteDepthOf('> > deep'),
        2,
        reason: 'CommonMark 写作 `> > inner`，和 `>>inner` 是同一件事',
      );
      expect(MarkdownParser.blockquoteDepthOf('> shallow'), 1);
    });

    test('a greater-than in prose is not a quote', () {
      expect(MarkdownParser.blockquoteDepthOf('if a > b'), isNull);
      expect(MarkdownParser.blockquoteDepthOf('a -> b'), isNull);
    });

    test('an empty quote is still a quote', () {
      expect(
        MarkdownParser.blockquoteDepthOf('>'),
        1,
        reason: '一行只有标记，是一段空引用，不是普通文字',
      );
    });
  });

  group('emphasis written with underscores', () {
    /// The kinds of emphasis the preview draws on this line.
    Set<InlineType> drawn(String line) => {
      for (final span in parser.parseInline(line))
        if (span.type != InlineType.text) span.type,
    };

    List<TextSpan> spansOf(String line) =>
        MarkdownSyntaxHighlighter.highlightLine(line, colors);

    /// Whether the source pane slants anything on this line.
    ///
    /// Asked by `fontStyle`, not by colour: italic is painted in the plain
    /// colour and slanted, so a test that only compares colours reports every
    /// italic run as unpainted — this one did, and blamed the highlighter for
    /// a hole that was in the test.
    bool paintedItalic(String line) =>
        spansOf(line).any((s) => s.style?.fontStyle == FontStyle.italic);

    bool paintedBold(String line) =>
        spansOf(line).any((s) => s.style?.color == colors.bold);

    test('_this_ is drawn as italic', () {
      expect(drawn('_slanted_'), contains(InlineType.italic));
    });

    test('and painted as italic too', () {
      // CommonMark gives `_` the same standing as `*`. The source pane knew
      // only about asterisks, so a document written with underscores — which
      // is most of them, outside this project — was left grey while the pane
      // beside it drew every one of them slanted.
      expect(paintedItalic('_slanted_'), isTrue, reason: '预览画了斜体，源码窗格却什么也没染');
    });

    test('__this__ is drawn as bold', () {
      expect(drawn('__heavy__'), contains(InlineType.bold));
    });

    test('and painted as bold too', () {
      expect(paintedBold('__heavy__'), isTrue);
    });

    test('a name with underscores is neither', () {
      // The whole reason `_` is harder than `*`: it may not sit inside a word,
      // or every snake_case identifier in a document turns slanted.
      expect(drawn('read_me_now'), isEmpty);
      expect(
        paintedItalic('read_me_now'),
        isFalse,
        reason: '标识符里的下划线不是强调，染了比不染更糟',
      );
      expect(paintedBold('read_me_now'), isFalse);
    });

    test('every inline marker still paints', () {
      // A line is scanned once for the characters the patterns open with, and
      // any pattern whose character is absent is skipped. That skip is a
      // silent one: get the character wrong and the rule simply stops
      // working, with nothing to say so. One line per marker, here.
      expect(paintedBold('**heavy**'), isTrue, reason: '**');
      expect(paintedBold('__heavy__'), isTrue, reason: '__');
      expect(paintedItalic('*slanted*'), isTrue, reason: '*');
      expect(paintedItalic('_slanted_'), isTrue, reason: '_');
      expect(
        spansOf('`snippet`').any((s) => s.style?.color == colors.code),
        isTrue,
        reason: '`',
      );
      expect(
        spansOf('[text](/url)').any((s) => s.style?.color == colors.link),
        isTrue,
        reason: '[',
      );
      // The *first* span, not just any: without the image pattern the link
      // pattern still matches `[alt](/img)` and leaves the `!` in front of it
      // plain, so "some span is link-coloured" cannot tell the two apart.
      expect(
        spansOf('![alt](/img)').first.style?.color,
        colors.link,
        reason: '![',
      );
      expect(
        spansOf(
          'a <!-- note --> b',
        ).any((s) => s.style?.color == colors.comment),
        isTrue,
        reason: '<!--',
      );
      expect(
        spansOf(
          '~~gone~~',
        ).any((s) => s.style?.decoration == TextDecoration.lineThrough),
        isTrue,
        reason: '~~',
      );
    });

    test('a full stop before the closing run is not emphasis', () {
      // The same flanking rule the asterisk patterns already ask about.
      expect(paintedItalic('_倾斜。_后面'), isFalse);
      expect(drawn('_倾斜。_后面'), isEmpty, reason: '两边都得说它不是强调，否则只是换了一种不一致');
    });
  });
}

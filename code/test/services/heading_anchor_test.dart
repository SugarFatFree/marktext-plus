import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// `[see below](#conclusion)` should go to that heading.
///
/// A link whose target starts with `#` names a heading in this document. The
/// preview treated it as a relative path, resolved it against the document's
/// folder, found no such file and returned — so clicking one did nothing at
/// all, with nothing said. Every other kind of link works: http opens a
/// browser, mailto opens mail, a path opens a tab.
///
/// The scrolling already exists — the outline uses it — so what was missing
/// was only the step from an anchor to a line.
void main() {
  const doc = '''
# Getting Started

See [the rules](#the-rules) and [Q & A](#q--a).

## The Rules

Text.

## Q & A

More.

### 中文标题

Text.

## Trailing Hashes ##
''';

  test('an anchor finds the heading GitHub would give it', () {
    // Lines are numbered from one, the way `headingOutline` numbers them and
    // `scrollToLine` reads them — this answer is handed straight to that.
    expect(MarkdownParser.lineForAnchor(doc, '#the-rules'), 5);
    expect(MarkdownParser.lineForAnchor(doc, '#getting-started'), 1);
  });

  test('punctuation is dropped rather than replaced', () {
    // "Q & A" has two spaces around an ampersand: the ampersand goes, both
    // spaces become hyphens, and the result keeps them both.
    expect(MarkdownParser.lineForAnchor(doc, '#q--a'), 9);
  });

  test('a percent-encoded anchor is decoded first', () {
    // An editor that writes these for you encodes non-ASCII. Decoding throws
    // on anything that is not valid encoding — including the unencoded form,
    // which is what a person types — so both spellings have to work.
    expect(
      MarkdownParser.lineForAnchor(doc, '#%E4%B8%AD%E6%96%87%E6%A0%87%E9%A2%98'),
      13,
    );
    expect(MarkdownParser.lineForAnchor(doc, '#100%-done'), isNull);
  });

  test('a heading in another script keeps its characters', () {
    // Nothing to lower-case and nothing to drop: the rule must not strip what
    // it does not recognise, or every non-Latin heading becomes unreachable.
    expect(MarkdownParser.lineForAnchor(doc, '#中文标题'), 13);
  });

  test('closing hashes are not part of the name', () {
    expect(MarkdownParser.lineForAnchor(doc, '#trailing-hashes'), 17);
  });

  test('an anchor naming nothing answers null', () {
    expect(MarkdownParser.lineForAnchor(doc, '#nowhere'), isNull);
    expect(MarkdownParser.lineForAnchor(doc, '#'), isNull);
  });

  test('a link that is not an anchor is not one', () {
    // The caller decides what to do with these; this answers only about
    // anchors, and must not claim a file path or a URL is one.
    expect(MarkdownParser.lineForAnchor(doc, 'notes.md'), isNull);
    expect(MarkdownParser.lineForAnchor(doc, 'https://e.invalid/#x'), isNull);
  });

  test('the first of two headings with one name wins', () {
    // GitHub appends -1, -2 to later duplicates. Going to the first is the
    // behaviour worth having without that: a reader clicking "#notes" in a
    // document with two of them lands on one of them rather than nowhere.
    const twice = '# Notes\n\ntext\n\n# Notes\n';
    expect(MarkdownParser.lineForAnchor(twice, '#notes'), 1);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// A footnote marker should go to its note.
///
/// `[^1]` is drawn raised, in the link colour, and was a plain piece of text
/// with nothing behind it — it looks clickable and was not. The note it names
/// is usually at the far end of the document, which is the one place scrolling
/// there by hand is most annoying.
///
/// Built the same way as `lineForAnchor`: the parse already knows where every
/// definition starts, so this asks it rather than reading the source again.
void main() {
  const doc = '''
# Notes

A claim[^1] and another[^method].

Text.

[^1]: The first source.

[^method]: How it was measured.
''';

  test('a marker finds the line its note is on', () {
    expect(MarkdownParser.lineForFootnote(doc, '1'), 7);
    expect(MarkdownParser.lineForFootnote(doc, 'method'), 9);
  });

  test('labels are matched exactly, not folded', () {
    // Unlike a heading anchor, a footnote label is an identifier the author
    // chose: `[^Method]` and `[^method]` are two different notes, and
    // lower-casing one into the other would send a reader to the wrong note
    // rather than to none.
    expect(MarkdownParser.lineForFootnote(doc, 'Method'), isNull);
    expect(MarkdownParser.lineForFootnote(doc, 'METHOD'), isNull);
  });

  test('a marker with no note answers null', () {
    // Writing the marker before the note is how footnotes get written.
    expect(MarkdownParser.lineForFootnote(doc, '2'), isNull);
    expect(MarkdownParser.lineForFootnote(doc, ''), isNull);
  });

  test('the first definition wins when a label is repeated', () {
    const twice = '[^a] here.\n\n[^a]: One.\n\n[^a]: Two.\n';
    expect(MarkdownParser.lineForFootnote(twice, 'a'), 3);
  });

  test('a definition inside a fence is not one', () {
    // Documentation about footnotes shows them in code blocks, and jumping
    // into the example rather than to the note would be wrong.
    const fenced = '''
Text[^1].

```
[^1]: not a definition, an example
```

[^1]: The real one.
''';
    expect(MarkdownParser.lineForFootnote(fenced, '1'), 7);
  });
}

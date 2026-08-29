/// How wide a string is, in multiples of the font size.
///
/// Used where text has to be fitted into something before it is laid out for
/// real: a markdown table's column padding, and the box a mermaid node is
/// drawn in. Both need an answer without a `TextPainter` — the table because
/// it is aligning characters in a monospaced source file, the diagram because
/// its layout runs before there is a canvas to measure against.
///
/// A leaf function with no imports, so the mermaid package using it does not
/// give up the independence it keeps for translations and app state.
library;

/// Whether [rune] occupies two columns in a monospaced font, and about one
/// full em in a proportional one.
///
/// The CJK blocks, Hangul, and the fullwidth forms. Everything else is
/// treated as narrow.
bool isWideCharacter(int rune) =>
    (rune >= 0x1100 && rune <= 0x115F) || // Hangul Jamo
    (rune >= 0x2E80 && rune <= 0xA4CF) || // CJK radicals through Yi
    (rune >= 0xAC00 && rune <= 0xD7A3) || // Hangul syllables
    (rune >= 0xF900 && rune <= 0xFAFF) || // CJK compatibility ideographs
    (rune >= 0xFE30 && rune <= 0xFE6F) || // CJK compatibility forms
    (rune >= 0xFF00 && rune <= 0xFF60) || // Fullwidth forms
    (rune >= 0xFFE0 && rune <= 0xFFE6) ||
    (rune >= 0x20000 && rune <= 0x3FFFD); // CJK extensions B and beyond

/// The width of [text] in columns, counting a wide character as two.
int displayWidth(String text) {
  var width = 0;
  for (final rune in text.runes) {
    width += isWideCharacter(rune) ? 2 : 1;
  }
  return width;
}

/// The width [text] will take at [fontSize] in a proportional font, near
/// enough to lay out a box around it.
///
/// A CJK glyph is one em wide; Latin averages a little over half of one. A
/// single ratio for both — which is what this replaced — makes a box that a
/// Chinese label overflows by about forty per cent, and the label is drawn at
/// its natural width, so it hangs out over the border of its own node.
double estimatedTextWidth(String text, double fontSize) {
  var ems = 0.0;
  for (final rune in text.runes) {
    ems += isWideCharacter(rune) ? 1.0 : 0.6;
  }
  return ems * fontSize;
}

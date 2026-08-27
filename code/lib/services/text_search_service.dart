import 'package:flutter/services.dart' show TextRange;

/// Finds where a search pattern occurs in a piece of text.
///
/// One implementation for the whole app. The find bar and the preview's
/// highlighter each had their own, and they had drifted: the find bar advanced
/// past each hit while the preview advanced a single character, so a repeating
/// pattern like `aa` in `aaaa` was counted twice by one and three times by the
/// other — and the preview, splicing overlapping ranges into spans, drew more
/// characters than the document contains.
class TextSearch {
  const TextSearch._();

  /// Scans [text] for [pattern], returning non-overlapping ranges in document
  /// order.
  ///
  /// The ranges are spliced back into the document by replace-all, where an
  /// off-by-one costs the user text.
  static List<TextRange> matches(
    String text,
    String pattern, {
    bool caseSensitive = false,
    bool wholeWord = false,
    bool useRegex = false,
  }) {
    final found = <TextRange>[];
    if (pattern.isEmpty) return found;

    if (useRegex) {
      try {
        final regex = RegExp(pattern, caseSensitive: caseSensitive);
        var lastEnd = -1;
        for (final match in regex.allMatches(text)) {
          // A pattern that can match nothing — `x*` — reports a hit at every
          // position. Keeping them would highlight empty ranges and inflate
          // the counter the "next match" button steps through.
          if (match.end == match.start) continue;
          if (match.start < lastEnd) continue;
          found.add(TextRange(start: match.start, end: match.end));
          lastEnd = match.end;
        }
      } catch (_) {
        // Invalid regex: report nothing rather than a partial scan.
      }
      return found;
    }

    final searchText = caseSensitive ? text : text.toLowerCase();
    final searchPattern = caseSensitive ? pattern : pattern.toLowerCase();

    var index = 0;
    var lastEnd = 0;
    while (index < searchText.length) {
      final pos = searchText.indexOf(searchPattern, index);
      if (pos == -1) break;

      final accepted = !wholeWord || _isWholeWordAt(text, pos, pattern.length);
      // Overlapping hits inflate the counter and make replace-all splice
      // ranges that overlap, which destroys text instead of replacing it.
      if (accepted && pos >= lastEnd) {
        found.add(TextRange(start: pos, end: pos + pattern.length));
        lastEnd = pos + pattern.length;
      }

      // One character at a time, not a whole match: with whole-word on, a
      // rejected hit can still overlap an acceptable one just after it.
      index = pos + 1;
    }
    return found;
  }

  static bool _isWholeWordAt(String text, int start, int length) {
    final before = start == 0 || !_isWordChar(text[start - 1]);
    final after =
        start + length >= text.length || !_isWordChar(text[start + length]);
    return before && after;
  }

  /// Whether [char] can sit inside a word.
  ///
  /// ASCII only, deliberately: scripts written without spaces have no word
  /// boundaries to find, so treating them as boundaries is what lets a
  /// whole-word search match at all there.
  static bool _isWordChar(String char) =>
      RegExp(r'[a-zA-Z0-9_]').hasMatch(char);
}

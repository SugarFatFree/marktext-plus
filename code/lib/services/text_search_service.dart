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
        // `^` and `$` anchor to lines, not to the whole document. `^#+ ` is
        // the most natural thing to type into a regular-expression search
        // here — find every heading — and without this it found the first
        // heading only if the document opened with one.
        //
        // What this gives up is an anchor to the very start of the document,
        // which Dart's flavour has no `\A` to offer instead. In a search box
        // that anchor is close to useless: the match it finds is the one
        // already on screen. Every editor offering this search makes the same
        // trade.
        //
        // `dotAll` stays off, so `.` does not cross a line — also what the
        // others do.
        final regex = RegExp(
          pattern,
          caseSensitive: caseSensitive,
          multiLine: true,
        );
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

  /// [replacement] with what the pattern captured at [start] filled in.
  ///
  /// This is what a regular-expression search and replace is for: rewriting a
  /// shape rather than a string. Without it, turning `[text](url)` into
  /// `url: text` had to be done by hand, one link at a time.
  ///
  /// The spelling is the one every other editor uses, which is JavaScript's:
  /// `$1`…`$99` for a group, `$&` for the whole match, `$$` for a literal
  /// dollar. A `$` before anything else is left as it stands, so a replacement
  /// of `$5.00` is still `$5.00`, and so is a group number the pattern does not
  /// have — quietly turning `$7` into nothing would lose text without saying so.
  /// A group that matched nothing becomes nothing, which is what it captured.
  ///
  /// Only for a regular-expression search: somebody replacing `cost` with `$5`
  /// in a literal search has not asked for a group.
  ///
  /// The groups are taken by matching the pattern again at [start] rather than
  /// carried along from the scan. The range came from that same pattern, so the
  /// match is the same one; and a replacement with no `$` in it — which is most
  /// of them — costs nothing at all.
  static String expandReplacement(
    String text,
    int start,
    String pattern,
    String replacement, {
    required bool caseSensitive,
    required bool useRegex,
  }) {
    if (!useRegex || !replacement.contains(r'$')) return replacement;

    Match? found;
    try {
      found = RegExp(pattern, caseSensitive: caseSensitive, multiLine: true)
          .matchAsPrefix(text, start);
    } catch (_) {
      // An invalid pattern cannot have captured anything.
      return replacement;
    }
    if (found == null) return replacement;
    final match = found;

    final out = StringBuffer();
    for (var i = 0; i < replacement.length; i++) {
      if (replacement.codeUnitAt(i) != _dollar ||
          i + 1 == replacement.length) {
        out.write(replacement[i]);
        continue;
      }

      final next = replacement[i + 1];
      if (next == r'$') {
        out.write(r'$');
        i++;
        continue;
      }
      if (next == '&') {
        out.write(match[0] ?? '');
        i++;
        continue;
      }

      // Two digits before one, so `$11` is group eleven wherever there is one
      // and group one followed by a `1` wherever there is not.
      var group = 0;
      var digits = 0;
      for (var width = 2; width >= 1; width--) {
        if (i + 1 + width > replacement.length) continue;
        final value = int.tryParse(replacement.substring(i + 1, i + 1 + width));
        if (value == null || value < 1 || value > match.groupCount) continue;
        group = value;
        digits = width;
        break;
      }
      if (group == 0) {
        out.write(r'$');
        continue;
      }
      out.write(match[group] ?? '');
      i += digits;
    }
    return out.toString();
  }

  static const _dollar = 0x24;

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
  /// Compared by code unit rather than with a pattern: this is asked twice per
  /// candidate hit, and building a `RegExp` each time cost 770 ms to run a
  /// whole-word search over a 1.2 MiB document.
  static bool _isWordChar(String char) {
    if (char.isEmpty) return false;
    final unit = char.codeUnitAt(0);
    return (unit >= 0x30 && unit <= 0x39) || // 0-9
        (unit >= 0x41 && unit <= 0x5A) || // A-Z
        (unit >= 0x61 && unit <= 0x7A) || // a-z
        unit == 0x5F; // _
  }
}

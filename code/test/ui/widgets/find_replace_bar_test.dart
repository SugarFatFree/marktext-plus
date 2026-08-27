import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/widgets/find_replace_bar.dart';

/// Splices matches back into the document the way replace-all does, so a
/// regression in the scan shows up as corrupted text rather than a count.
String replaceAll(String text, List<TextRange> matches, String replacement) {
  var out = text;
  for (var i = matches.length - 1; i >= 0; i--) {
    out = out.substring(0, matches[i].start) +
        replacement +
        out.substring(matches[i].end);
  }
  return out;
}

List<int> starts(List<TextRange> matches) => matches.map((m) => m.start).toList();

void main() {
  group('FindReplaceBar.findMatches', () {
    test('returns nothing for an empty pattern', () {
      expect(FindReplaceBar.findMatches('hello', ''), isEmpty);
    });

    test('finds plain matches in document order', () {
      expect(starts(FindReplaceBar.findMatches('abab', 'ab')), [0, 2]);
    });

    test('ignores case unless asked', () {
      expect(starts(FindReplaceBar.findMatches('AbAb', 'ab')), [0, 2]);
      expect(
        FindReplaceBar.findMatches('AbAb', 'ab', caseSensitive: true),
        isEmpty,
      );
    });

    test('matches never overlap', () {
      // "aa" in "aaaa" is two matches, not three: a one-character advance made
      // replace-all splice overlapping ranges and eat the surrounding text.
      final matches = FindReplaceBar.findMatches('aaaa', 'aa');
      expect(starts(matches), [0, 2]);
      expect(replaceAll('aaaa', matches, 'b'), 'bb');
    });

    test('whole word skips matches inside longer words', () {
      expect(
        starts(FindReplaceBar.findMatches('aaa aa', 'aa', wholeWord: true)),
        [4],
      );
      expect(
        starts(FindReplaceBar.findMatches('cat cats', 'cat', wholeWord: true)),
        [0],
      );
      expect(
        starts(FindReplaceBar.findMatches('_cat cat', 'cat', wholeWord: true)),
        [5],
      );
    });

    test('regex matches respect the case flag', () {
      expect(
        starts(FindReplaceBar.findMatches(r'a1 b22', r'\d+', useRegex: true)),
        [1, 4],
      );
      expect(
        FindReplaceBar.findMatches('ABC', 'abc', useRegex: true, caseSensitive: true),
        isEmpty,
      );
    });

    test('an invalid regex reports no matches instead of throwing', () {
      expect(FindReplaceBar.findMatches('abc', '([a-', useRegex: true), isEmpty);
    });

    test('a zero-width regex does not loop forever', () {
      expect(
        FindReplaceBar.findMatches('abc', 'x*', useRegex: true).length,
        lessThanOrEqualTo(4),
      );
    });

    test('replace-all over a real document keeps unmatched text intact', () {
      const doc = 'foo bar foo baz foofoo';
      final matches = FindReplaceBar.findMatches(doc, 'foo');
      expect(matches, hasLength(4));
      expect(replaceAll(doc, matches, 'X'), 'X bar X baz XX');
    });
  });
}

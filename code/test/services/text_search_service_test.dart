import 'package:flutter/services.dart' show TextRange;
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/text_search_service.dart';

/// Splices the matches back into the text with brackets around each.
///
/// Whatever the pattern, the characters outside the brackets plus the ones
/// inside must add back up to the original: that is the invariant the
/// preview's own scanner broke, drawing six characters where there were four.
String annotate(String text, List<TextRange> matches) {
  final out = StringBuffer();
  var last = 0;
  for (final match in matches) {
    out.write(text.substring(last, match.start));
    out.write('[${text.substring(match.start, match.end)}]');
    last = match.end;
  }
  out.write(text.substring(last));
  return out.toString();
}

void main() {
  group('TextSearch.matches', () {
    test('a repeating pattern gives non-overlapping matches', () {
      final matches = TextSearch.matches('aaaa', 'aa');

      expect(matches, hasLength(2));
      expect(annotate('aaaa', matches), '[aa][aa]');
    });

    test('every result splices back to the original text', () {
      for (final (text, pattern) in [
        ('aaaa', 'aa'),
        ('the cat sat on the mat', 'at'),
        ('很好很好很好', '很好'),
        ('abc', 'z'),
      ]) {
        final matches = TextSearch.matches(text, pattern);
        expect(
          annotate(text, matches).replaceAll('[', '').replaceAll(']', ''),
          text,
          reason: 'searching "$pattern" in "$text"',
        );
      }
    });

    test('case sensitivity is honoured', () {
      expect(TextSearch.matches('Cat cat CAT', 'cat'), hasLength(3));
      expect(
        TextSearch.matches('Cat cat CAT', 'cat', caseSensitive: true),
        hasLength(1),
      );
    });

    test('whole word skips a hit inside a longer word', () {
      final matches = TextSearch.matches(
        'cat category cat',
        'cat',
        wholeWord: true,
      );

      expect(annotate('cat category cat', matches), '[cat] category [cat]');
    });

    test('whole word still matches where a script has no word breaks', () {
      // CJK is written without spaces, so treating it as a boundary is the
      // only reading that lets a whole-word search find anything at all.
      expect(TextSearch.matches('猫科猫', '猫', wholeWord: true), hasLength(2));
    });

    test('a regex reports its matches', () {
      final matches = TextSearch.matches('a1b22c333', r'\d+', useRegex: true);

      expect(annotate('a1b22c333', matches), 'a[1]b[22]c[333]');
    });

    test('a regex that can match nothing reports nothing', () {
      // `x*` hits at every position; keeping those would highlight empty
      // ranges and inflate the counter the next-match button steps through.
      expect(TextSearch.matches('abc', 'x*', useRegex: true), isEmpty);
    });

    test('an invalid regex reports nothing rather than a partial scan', () {
      expect(TextSearch.matches('abc', '[', useRegex: true), isEmpty);
    });

    test('an empty pattern matches nothing', () {
      expect(TextSearch.matches('abc', ''), isEmpty);
    });
  });
}

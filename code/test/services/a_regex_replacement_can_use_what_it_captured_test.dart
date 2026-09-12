import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/text_search_service.dart';

/// A regular-expression replacement can put back what the pattern captured.
///
/// It could not, so the one thing a regular-expression search and replace is for
/// — rewriting a shape rather than a string — was out of reach. Turning
/// `[text](url)` into `url: text`, or `- item` into `* item` while keeping the
/// item, meant doing it by hand.
///
/// The spelling is the one every other editor uses, which is JavaScript's:
/// `$1`…`$99` for a group, `$&` for the whole match, `$$` for a literal dollar.
/// Anything else after a `$` is left as it stands, so a replacement of `$5.00`
/// is still `$5.00` — and a group number the pattern does not have is left alone
/// too, rather than quietly becoming nothing.
///
/// Only for a regular-expression search. A literal search replaces literally:
/// somebody replacing `cost` with `$5` has not asked for a group.
void main() {
  String expand(
    String text,
    String pattern,
    String replacement, {
    bool caseSensitive = false,
    bool useRegex = true,
  }) {
    final hits = TextSearch.matches(text, pattern,
        caseSensitive: caseSensitive, useRegex: useRegex);
    expect(hits, isNotEmpty, reason: 'the sample found nothing to replace');
    return TextSearch.expandReplacement(
      text,
      hits.first.start,
      pattern,
      replacement,
      caseSensitive: caseSensitive,
      useRegex: useRegex,
    );
  }

  group('a group by number', () {
    test('one group', () {
      expect(expand('[the manual](https://x)', r'\[(.+?)\]\((.+?)\)', r'$2: $1'),
          'https://x: the manual');
    });

    test('a group that captured nothing becomes nothing', () {
      expect(expand('ab', r'a(x)?(b)', r'[$1][$2]'), '[][b]');
    });

    test('two digits are read as one number where the group exists', () {
      const pattern = r'(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)';
      expect(expand('abcdefghijk', pattern, r'$11'), 'k');
      expect(expand('abcdefghijk', pattern, r'$1'), 'a');
    });

    test('a group the pattern does not have is left as it stands', () {
      expect(expand('ab', r'(a)b', r'$1$7'), r'a$7');
    });

    test('a zero is not a group', () {
      expect(expand('ab', r'(a)b', r'$0$1'), r'$0a');
    });
  });

  group('the other two spellings', () {
    test('the whole match', () {
      expect(expand('hello', 'ell', r'[$&]'), '[ell]');
    });

    test('a literal dollar', () {
      expect(expand('cost', 'cost', r'$$5'), r'$5');
    });

    test('a dollar before something that is not a group stays a dollar', () {
      expect(expand('cost', 'cost', r'$5.00'), r'$5.00');
      expect(expand('cost', 'cost', r'costs $'), r'costs $');
    });
  });

  group('a literal search replaces literally', () {
    test('a dollar is a dollar', () {
      expect(
        expand('cost', 'cost', r'$1 and $& and $$', useRegex: false),
        r'$1 and $& and $$',
      );
    });
  });

  group('nothing to expand', () {
    test('a replacement with no dollar comes back unchanged', () {
      expect(expand('[a](b)', r'\[(.+?)\]\((.+?)\)', 'plain'), 'plain');
    });

    test('an invalid pattern gives the replacement back as it stands', () {
      expect(
        TextSearch.expandReplacement('x', 0, '(', r'$1', caseSensitive: false,
            useRegex: true),
        r'$1',
      );
    });

    test('a position where the pattern does not start gives it back too', () {
      expect(
        TextSearch.expandReplacement('abc', 2, '(a)', r'$1',
            caseSensitive: false, useRegex: true),
        r'$1',
      );
    });
  });

  group('case folding and anchors still hold', () {
    test('an insensitive match still captures', () {
      expect(expand('HELLO', '(ell)', r'[$1]'), '[ELL]');
    });

    test('a line anchor still matches at a line start', () {
      const document = 'one\n## Two\n';
      final hits = TextSearch.matches(document, r'^## (\w+)', useRegex: true);
      expect(hits, hasLength(1));
      expect(
        TextSearch.expandReplacement(document, hits.first.start, r'^## (\w+)',
            r'### $1', caseSensitive: false, useRegex: true),
        '### Two',
      );
    });
  });
}

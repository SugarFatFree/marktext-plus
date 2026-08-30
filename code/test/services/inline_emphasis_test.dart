import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/inline_emphasis.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// The delimiter algorithm on its own, away from the rest of the parser.
///
/// What emphasis means cannot be decided where it starts: `*foo **bar***` is
/// an italic holding a bold and `***foo** bar*` is the reverse, yet both are a
/// run of asterisks beside a run of asterisks. The answer comes from every run
/// in the paragraph, so the format describes an algorithm rather than a
/// pattern — and a single regular expression, however carefully written, was
/// always going to get some of these the wrong way round.
void main() {
  String render(List<InlineSpan> spans) {
    final buffer = StringBuffer();
    for (final span in spans) {
      switch (span.type) {
        case InlineType.bold:
          buffer.write('<strong>${render(span.children)}</strong>');
        case InlineType.italic:
          buffer.write('<em>${render(span.children)}</em>');
        default:
          buffer.write(span.text);
      }
    }
    return buffer.toString();
  }

  String resolve(String source) => render(
        resolveEmphasis([InlineSpan(type: InlineType.text, text: source)]),
      );

  group('what a single pattern could not decide', () {
    // Every one of these is what marked — the parser upstream MarkText uses —
    // produces, checked against it directly.
    const cases = <String, String>{
      '*foo **bar***': '<em>foo <strong>bar</strong></em>',
      '***foo** bar*': '<em><strong>foo</strong> bar</em>',
      '_foo _bar_ baz_': '<em>foo <em>bar</em> baz</em>',
      '__foo, __bar__, baz__': '<strong>foo, <strong>bar</strong>, baz</strong>',
      '*foo *bar**': '<em>foo <em>bar</em></em>',
      '*(*foo*)*': '<em>(<em>foo</em>)</em>',
      'foo***bar***baz': 'foo<em><strong>bar</strong></em>baz',
      '*foo **bar *baz* bim** bop*':
          '<em>foo <strong>bar <em>baz</em> bim</strong> bop</em>',
    };
    cases.forEach((source, expected) {
      test(source, () => expect(resolve(source), expected));
    });
  });

  group('what is not emphasis', () {
    const cases = <String, String>{
      // A delimiter with punctuation on one side and a letter on the other
      // neither opens nor closes.
      r'*$*alpha.': r'*$*alpha.',
      '*(*foo)': '*(*foo)',
      // Spaces on the inside.
      'a * b * c': 'a * b * c',
      // Underscores inside a word are part of the word — a file name, an
      // identifier — and this is why `_` and `*` have different rules.
      'snake_case_name': 'snake_case_name',
      '未闭合 *星号': '未闭合 *星号',
      '': '',
    };
    cases.forEach((source, expected) {
      test(source.isEmpty ? '(empty)' : source,
          () => expect(resolve(source), expected));
    });
  });

  test('an atom between the markers is carried through', () {
    // Code spans and links are already resolved when this runs, so they are
    // opaque here — emphasis may wrap one, and its text can no longer be
    // mistaken for a delimiter.
    final spans = resolveEmphasis([
      const InlineSpan(type: InlineType.text, text: '*看 '),
      const InlineSpan(type: InlineType.code, text: 'a*b'),
      const InlineSpan(type: InlineType.text, text: ' 这里*'),
    ]);
    expect(spans.single.type, InlineType.italic);
    expect(
      spans.single.children.map((c) => c.type).toList(),
      contains(InlineType.code),
    );
  });
}

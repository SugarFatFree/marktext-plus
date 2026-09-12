import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/text_search_service.dart';

/// One way of saying which line an offset is on.
///
/// Four places had their own: the pane caches line starts and searches them,
/// the find bar cut the text at the offset and split the prefix into lines,
/// and two commands counted the newlines. The cut-and-split one is the reason
/// this exists — it copied the prefix and allocated a string per line to read
/// one number — so the oracle here is that very expression: the replacement
/// has to agree with it everywhere, including the ends and the empty cases.
///
/// This checks the answer, not the cost. The cost is the point of the change,
/// but a mutation back to cut-and-split is only four times slower, which no
/// honest bound separates from noise; what a bound *can* catch lives in
/// `the_pane_measures_where_a_match_is_test`.
int oracle(String text, int offset) =>
    text.substring(0, offset.clamp(0, text.length)).split('\n').length - 1;

void main() {
  final texts = <String>[
    '',
    'one line',
    'two\nlines',
    '\n',
    '\n\n\n',
    'trailing\n',
    '\nleading',
    'a\r\nb\r\nc', // CRLF: the break is still the \n
    'ends with text\nafter a break',
    List.generate(50, (i) => 'line $i').join('\n'),
  ];

  test('every offset of every text agrees with cutting and splitting', () {
    for (final text in texts) {
      // Past both ends as well: the find bar hands over a match offset, and a
      // stale match after an edit can be past the end of the new text.
      for (var offset = -3; offset <= text.length + 3; offset++) {
        expect(
          TextSearch.lineIndexOf(text, offset),
          oracle(text, offset),
          reason: 'offset $offset of ${text.length} in ${text.hashCode}',
        );
      }
    }
  });

  test('the line index is zero-based', () {
    expect(TextSearch.lineIndexOf('a\nb', 0), 0);
    expect(TextSearch.lineIndexOf('a\nb', 1), 0);
    expect(TextSearch.lineIndexOf('a\nb', 2), 1, reason: 'just past the break');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/syntax_highlighter.dart';

/// A pattern is skipped on a line that cannot contain it, and the test for that
/// has to be cheaper than the pattern.
///
/// `_Pattern.marker` rules out the lines with none of the opening character,
/// which is most lines. It cannot rule out a line that has the character but
/// not enough of them: adding `***(.+?)***` cost every ordinary line carrying a
/// single `*` an 11% scan for a triple run that was not there — 6837 µs became
/// 7622 µs over 400 lines, and asking `contains('***')` once put it back to
/// 6836.
///
/// So a pattern built on a run longer than one character has to name that run.
/// This reconciles the two: the shape of the pattern against the cheap test
/// standing in front of it. It reads only one direction — a pattern that names
/// a run it does not need is not caught, and does no harm.
void main() {
  /// The leading run of one repeated literal character in a regex source, with
  /// the escaping taken off: `\*\*\*(.+?)\*\*\*` opens on three asterisks.
  String leadingRun(String pattern) {
    final literal = pattern.replaceAll(r'\', '');
    if (literal.isEmpty) return '';
    final first = literal[0];
    var length = 0;
    while (length < literal.length && literal[length] == first) {
      length++;
    }
    return first * length;
  }

  test('a pattern built on a run of three or more names that run', () {
    for (final shape in MarkdownSyntaxHighlighter.shapesForTest) {
      final run = leadingRun(shape.pattern);
      if (run.length < 3) continue;
      expect(
        shape.requires,
        run,
        reason: '${shape.pattern} opens on "$run", which _Pattern.marker '
            'cannot rule out on its own. Give it requires: "$run" or every '
            'line carrying ${run[0]} pays a scan for a run that is not there.',
      );
    }
  });

  test('the comment pattern still names the closing sequence it needs', () {
    final comment = MarkdownSyntaxHighlighter.shapesForTest
        .where((shape) => shape.pattern.contains('<!--'));
    expect(comment, isNotEmpty, reason: 'the comment pattern is gone');
    expect(
      comment.single.requires,
      '-->',
      reason: 'without this the pattern scans to the end of the line from '
          'every `<!--`: twenty thousand openers took twelve seconds',
    );
  });

  test('a named run is longer than one character', () {
    for (final shape in MarkdownSyntaxHighlighter.shapesForTest) {
      final needed = shape.requires;
      if (needed == null) continue;
      expect(needed.length, greaterThan(1),
          reason: '${shape.pattern} names "$needed", which is what '
              '_Pattern.marker already does more cheaply');
    }
  });
}

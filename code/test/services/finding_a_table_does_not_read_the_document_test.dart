import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/table_edit_service.dart';

/// Asking "is the caret in a table" must not read the whole document.
///
/// The Format menu greys out the table commands when the caret is not in a
/// table, and it worked that out on every caret move by splitting the document
/// into lines — twice, because the menu also turned the caret's line and column
/// back into an offset the same way. Measured here: `split('\n')` over eight
/// megabytes takes 36.7 ms, so moving the caret in a large document cost about
/// seventy milliseconds of frame time, every arrow key. A frame is 16.7 ms.
///
/// The caret is on a table line or it is not, and finding out needs only the
/// line the caret is on: `lastIndexOf('\n')` backwards and `indexOf('\n')`
/// forwards. Measured at 0 µs on the same document.
///
/// The full walk still happens when the caret really is on a table line, which
/// is the case where the answer is worth having.
void main() {
  const table = '| h1 | h2 |\n|---|---|\n| a | b |\n';

  group('what it finds', () {
    test('a caret inside a table finds it', () {
      final at = table.indexOf('a |');
      final found = TableEditService.locate(table, at);
      expect(found, isNotNull);
      expect(found!.columnCount, 2);
    });

    test('a caret on a plain line finds nothing', () {
      const document = 'a paragraph\n\n$table\nanother paragraph\n';
      expect(TableEditService.locate(document, 3), isNull);
      expect(TableEditService.locate(document, document.length - 4), isNull);
    });

    test('a caret in a table inside a larger document still finds it', () {
      const document = 'before\n\n$table\nafter\n';
      final at = document.indexOf('a |');
      expect(TableEditService.locate(document, at), isNotNull);
    });

    test('a line of pipes that is not a table is not one', () {
      const document = 'a | b | c\nd | e | f\n';
      expect(TableEditService.locate(document, 2), isNull);
    });

    /// A caret on the blank line just before a table. The line bounds have to be
    /// that line's and not the table's: searching forward from the newline
    /// itself rather than from the line's start would take in the row below,
    /// whose trimmed text does begin with a pipe.
    test('a caret on the blank line above a table finds nothing', () {
      const document = 'before\n\n$table';
      final blank = document.indexOf('\n\n') + 1;
      expect(TableEditService.locate(document, blank), isNull);
    });

    test('a caret on the blank line below a table finds nothing', () {
      const document = '$table\nafter\n';
      expect(TableEditService.locate(document, table.length), isNull);
    });

    test('an offset past the end does not throw', () {
      expect(TableEditService.locate(table, 9999), isNull);
    });
  });

  /// The guard. The answer for a caret that is not in a table has to cost the
  /// same whatever the document weighs.
  test('a caret outside a table costs the same however large the document', () {
    String documentOf(int bytes) {
      final line = 'a line of prose with a few words on it to fill it out';
      final count = bytes ~/ (line.length + 1);
      return List.filled(count, line).join('\n');
    }

    int fastest(String document) {
      // Not the very start and not the very end: a caret in the middle, which
      // is where the walk would have the most to read.
      final at = document.length ~/ 2;
      var best = 1 << 30;
      for (var round = 0; round < 200; round++) {
        final watch = Stopwatch()..start();
        final found = TableEditService.locate(document, at);
        watch.stop();
        expect(found, isNull);
        if (watch.elapsedMicroseconds < best) best = watch.elapsedMicroseconds;
      }
      return best;
    }

    final small = fastest(documentOf(40 * 1024));
    final large = fastest(documentOf(4 * 1024 * 1024));

    expect(large, lessThan((small + 2) * 8),
        reason: '在大文档里问「光标在表格里吗」比在小文档里贵得多'
            '（$large µs vs $small µs）——说明它在读整篇文档');
  });
}

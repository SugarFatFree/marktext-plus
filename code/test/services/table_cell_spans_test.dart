import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// A table cell is parsed once, with the document.
///
/// Cells were the one construct kept as source: every reader parsed them
/// again — the preview on each rebuild, and each of the three exporters at
/// export time. That cost twice over.
///
/// It was wrong: the exporters shared a static parser built with the default
/// settings, so a cell's `<br>` appeared in the preview and not in the file.
/// And it was slow: the preview re-parsed every cell on every rebuild, which
/// is every caret move.
void main() {
  String htmlOf(String md, {bool enableHtml = false}) =>
      MarkdownParser(enableHtml: enableHtml)
          .parse(md)
          .map(ExportService.nodeToHtml)
          .join();

  TableNode tableOf(String md, {bool enableHtml = false}) =>
      MarkdownParser(enableHtml: enableHtml)
          .parse(md)
          .whereType<TableNode>()
          .single;

  const withBreak = '| 键 | 值 |\n|---|---|\n| A | 甲<br>乙 |\n';

  group('the export reads the cell the way the document was parsed', () {
    test('inline HTML on', () {
      // The line break inside the cell is the commonest use of `<br>` there
      // is, and it reached the preview and not the file.
      // `<br>` becomes the line break the renderer already draws for a
      // newline, so the cell reads `甲<br>\n乙`.
      final out = htmlOf(withBreak, enableHtml: true);
      expect(out, contains('甲<br>'));
      expect(out, isNot(contains('&lt;br&gt;')));
    });

    test('inline HTML off', () {
      expect(htmlOf(withBreak), contains('甲&lt;br&gt;乙'));
    });
  });

  group('cells carry their parsed content', () {
    test('every header and every cell has spans', () {
      final table = tableOf('| 甲 | 乙 |\n|---|---|\n| **粗** | `码` |\n'
          '| [链](/u) | 文 |\n');
      expect(table.headerSpans, hasLength(table.headers.length));
      expect(table.rowSpans, hasLength(table.rows.length));
      for (final row in table.rowSpans) {
        expect(row, hasLength(2));
      }
    });

    test('the markup inside a cell is resolved, not left as characters', () {
      final table = tableOf('| 甲 |\n|---|\n| **粗** |\n');
      expect(table.cellSpans(0, 0).single.type, InlineType.bold);
    });

    test('a short row is padded, and asking past the end is empty', () {
      // GFM pads a short row to the header's width, so the missing cell is
      // an empty one rather than absent. Asking beyond the table answers
      // empty rather than throwing — the guard used to be written out again
      // at each of the four call sites.
      final table = tableOf('| 甲 | 乙 |\n|---|---|\n| 一 |\n');
      expect(table.rowSpans.single, hasLength(2));
      expect(table.cellSpans(0, 1).single.text, '');
      expect(table.cellSpans(0, 9), isEmpty);
      expect(table.cellSpans(9, 0), isEmpty);
      expect(table.headerSpansAt(9), isEmpty);
    });
  });

  test('reading a large table costs nothing to read again', () {
    // Re-parsing 500 x 5 cells took 23 ms — more than a frame, on every
    // rebuild — against 5 ms to parse the whole document once. Reading the
    // stored spans is 0.1 ms. The budget is far above the one and far below
    // the other, so it catches a return to re-parsing without being timing
    // sensitive.
    final source = StringBuffer('| 甲 | 乙 | 丙 | 丁 | 戊 |\n'
        '|---|---|---|---|---|\n');
    for (var r = 0; r < 500; r++) {
      source.write('| **项目$r** | `代码$r` | [链接](/u$r) | 文字$r | ~~删$r~~ |\n');
    }
    final table = tableOf(source.toString());

    var seen = 0;
    final watch = Stopwatch()..start();
    for (var pass = 0; pass < 100; pass++) {
      for (var r = 0; r < table.rows.length; r++) {
        for (var c = 0; c < 5; c++) {
          seen += table.cellSpans(r, c).length;
        }
      }
    }
    watch.stop();

    expect(seen, greaterThan(0));
    expect(watch.elapsedMilliseconds, lessThan(300),
        reason: '单元格看起来又在每次读取时重新解析了');
  });
}

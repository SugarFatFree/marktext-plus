import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/table_edit_service.dart';

/// Editing a table from the source text.
///
/// Upstream MarkText offers these operations through a WYSIWYG grid — insert
/// and delete rows and columns, set a column's alignment — across four of its
/// end-to-end specs. This editor works on the markdown, so the same operations
/// rewrite the table under the caret.
void main() {
  const table = '| A | B |\n'
      '| --- | --- |\n'
      '| 1 | 2 |\n'
      '| 3 | 4 |\n';

  /// The offset of the first character of line [line].
  int startOfLine(String text, int line) {
    var offset = 0;
    final lines = text.split('\n');
    for (var i = 0; i < line; i++) {
      offset += lines[i].length + 1;
    }
    return offset;
  }

  String? edit(String text, int offset, TableEdit what) =>
      TableEditService.apply(text, offset, what)?.text;

  group('finding the table under the caret', () {
    test('a caret in a body row finds it', () {
      final at = TableEditService.locate(table, startOfLine(table, 2) + 2);
      expect(at, isNotNull);
      expect(
        at!.rows.map((r) => r.map((c) => c.trim()).toList()),
        [
          ['A', 'B'],
          ['1', '2'],
          ['3', '4'],
        ],
      );
      expect(at.row, 1, reason: '第 2 行是第一条数据行');
    });

    test('a caret on the delimiter row counts as the header', () {
      final at = TableEditService.locate(table, startOfLine(table, 1) + 1);
      expect(at?.row, 0);
    });

    test('a caret outside any table finds nothing', () {
      const text = 'just a paragraph\n';
      expect(TableEditService.locate(text, 3), isNull);
    });

    test('lines with pipes but no delimiter row are not a table', () {
      // `a | b` is how a person writes an alternative in prose, and two such
      // lines in a row must not be mistaken for a table.
      const text = '| a | b |\n| c | d |\n';
      expect(TableEditService.locate(text, 2), isNull);
    });

    test('the column is taken from where the caret is', () {
      final line2 = startOfLine(table, 2);
      expect(TableEditService.locate(table, line2 + 2)?.column, 0);
      expect(TableEditService.locate(table, line2 + 6)?.column, 1);
    });
  });

  group('rows', () {
    test('insert below adds an empty row after the caret', () {
      expect(
        edit(table, startOfLine(table, 2) + 2, TableEdit.insertRowBelow),
        '| A   | B   |\n'
        '| --- | --- |\n'
        '| 1   | 2   |\n'
        '|     |     |\n'
        '| 3   | 4   |\n',
      );
    });

    test('insert above adds an empty row before the caret', () {
      expect(
        edit(table, startOfLine(table, 3) + 2, TableEdit.insertRowAbove),
        '| A   | B   |\n'
        '| --- | --- |\n'
        '| 1   | 2   |\n'
        '|     |     |\n'
        '| 3   | 4   |\n',
      );
    });

    test('insert above from the header inserts below it instead', () {
      // A blank row put before the header would become the header, and the
      // table would lose its column names.
      expect(
        edit(table, 2, TableEdit.insertRowAbove),
        '| A   | B   |\n'
        '| --- | --- |\n'
        '|     |     |\n'
        '| 1   | 2   |\n'
        '| 3   | 4   |\n',
      );
    });

    test('delete removes the caret\'s row', () {
      expect(
        edit(table, startOfLine(table, 2) + 2, TableEdit.deleteRow),
        '| A   | B   |\n| --- | --- |\n| 3   | 4   |\n',
      );
    });

    test('the header row cannot be deleted', () {
      expect(TableEditService.locate(table, 2)!.can(TableEdit.deleteRow),
          isFalse);
      expect(edit(table, 2, TableEdit.deleteRow), isNull);
    });
  });

  group('columns', () {
    test('insert left', () {
      expect(
        edit(table, startOfLine(table, 2) + 6, TableEdit.insertColumnLeft),
        '| A   |     | B   |\n'
        '| --- | --- | --- |\n'
        '| 1   |     | 2   |\n'
        '| 3   |     | 4   |\n',
      );
    });

    test('insert right', () {
      expect(
        edit(table, 2, TableEdit.insertColumnRight),
        '| A   |     | B   |\n'
        '| --- | --- | --- |\n'
        '| 1   |     | 2   |\n'
        '| 3   |     | 4   |\n',
      );
    });

    test('delete', () {
      expect(
        edit(table, 2, TableEdit.deleteColumn),
        '| B   |\n| --- |\n| 2   |\n| 4   |\n',
      );
    });

    test('the last column cannot be deleted', () {
      const single = '| A |\n| --- |\n| 1 |\n';
      expect(
          TableEditService.locate(single, 2)!.can(TableEdit.deleteColumn),
          isFalse);
    });
  });

  group('alignment', () {
    test('centre writes :---: in the delimiter row', () {
      expect(
        edit(table, 2, TableEdit.alignCenter),
        '| A   | B   |\n| :-: | --- |\n| 1   | 2   |\n| 3   | 4   |\n',
      );
    });

    test('right writes ---:', () {
      expect(
        edit(table, 2, TableEdit.alignRight),
        '| A   | B   |\n| --: | --- |\n| 1   | 2   |\n| 3   | 4   |\n',
      );
    });

    test('left writes :---', () {
      expect(
        edit(table, 2, TableEdit.alignLeft),
        '| A   | B   |\n| :-- | --- |\n| 1   | 2   |\n| 3   | 4   |\n',
      );
    });

    test('none takes it back off', () {
      const centred = '| A | B |\n| :-: | --- |\n| 1 | 2 |\n';
      expect(
        edit(centred, 2, TableEdit.alignNone),
        '| A   | B   |\n| --- | --- |\n| 1   | 2   |\n',
      );
      expect(TableEditService.locate(centred, 2)?.aligns.first,
          ColumnAlign.center);
    });

    test('an existing alignment survives an unrelated edit', () {
      const centred = '| A | B |\n| :-: | --: |\n| 1 | 2 |\n';
      expect(
        edit(centred, 2, TableEdit.insertRowBelow),
        '| A   | B   |\n| :-: | --: |\n|     |     |\n| 1   | 2   |\n',
      );
    });
  });

  group('the table is laid out readably', () {
    test('columns are padded to their widest cell', () {
      const ragged = '|a|bbbbb|\n|-|-|\n|cc|d|\n';
      expect(
        edit(ragged, 2, TableEdit.alignNone),
        '| a   | bbbbb |\n| --- | ----- |\n| cc  | d     |\n',
      );
    });

    test('a CJK cell is measured by the width it takes up', () {
      // A Chinese character occupies two columns in a monospaced font. Padding
      // by code units leaves every table with CJK in it ragged.
      const cjk = '| 名称 | x |\n| --- | --- |\n| a | b |\n';
      final out = edit(cjk, 2, TableEdit.alignNone)!;
      final lines = out.split('\n');
      expect(lines[0], '| 名称 | x   |');
      expect(lines[1], '| ---- | --- |');
      expect(lines[2], '| a    | b   |');
    });

    test('an escaped pipe stays inside its cell', () {
      // `\|` is a literal pipe in GFM. Splitting on it would cut the cell in
      // two and shift every column after it.
      const escaped = r'| a \| b | c |' '\n| --- | --- |\n| 1 | 2 |\n';
      final at = TableEditService.locate(escaped, 2);
      expect(at?.columnCount, 2);
      expect(at?.rows.first.first.trim(), r'a \| b');
    });
  });

  test('the caret lands in the cell the command was about', () {
    final result =
        TableEditService.apply(table, startOfLine(table, 2) + 2,
            TableEdit.insertRowBelow)!;
    // The new row is line 3; the caret should be inside its first cell.
    final line = result.text.split('\n')[3];
    expect(line, '|     |     |');
    expect(result.offset, startOfLine(result.text, 3) + 2);
  });
}

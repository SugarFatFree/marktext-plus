/// Editing an existing GFM table from the source text.
///
/// Upstream MarkText edits tables through a WYSIWYG grid with hover toolbars
/// and drag bars — four of its end-to-end specs are about that. This editor
/// works on the markdown itself, so the same operations are offered as
/// commands that rewrite the table under the caret: add or remove a row or a
/// column, and set a column's alignment.
///
/// Deliberately free of Flutter and of the app's state so it can be tested
/// directly, and so the same answer serves the menu (which needs to know
/// whether a command applies) and the editor (which performs it).
library;

import '../utils/text_width.dart';

/// What a column's `---` row says about alignment.
enum ColumnAlign { none, left, center, right }

/// One operation on the table under the caret.
enum TableEdit {
  insertRowAbove,
  insertRowBelow,
  deleteRow,
  insertColumnLeft,
  insertColumnRight,
  deleteColumn,
  alignLeft,
  alignCenter,
  alignRight,
  alignNone,
}

/// A table found in the source, and where the caret sits inside it.
class TableLocation {
  const TableLocation({
    required this.startLine,
    required this.endLine,
    required this.rows,
    required this.aligns,
    required this.row,
    required this.column,
  });

  /// First and last line of the table, inclusive, as indices into the
  /// document's lines.
  final int startLine;
  final int endLine;

  /// Every row's cells, header first. The delimiter row is not among them —
  /// it is held as [aligns] instead, since it carries no content.
  final List<List<String>> rows;

  /// One entry per column.
  final List<ColumnAlign> aligns;

  /// Where the caret is: row 0 is the header, and the delimiter row counts as
  /// the header for the purpose of a command aimed at "this row".
  final int row;
  final int column;

  int get columnCount => aligns.length;

  /// The header row cannot be removed on its own — a GFM table without one is
  /// not a table — and a table needs at least one column.
  bool can(TableEdit edit) => switch (edit) {
        TableEdit.deleteRow => row > 0,
        TableEdit.deleteColumn => columnCount > 1,
        _ => true,
      };
}

/// Finds and rewrites the GFM table the caret is inside.
class TableEditService {
  const TableEditService._();

  /// The table containing [offset] in [text], or null if the caret is not in
  /// one.
  ///
  /// A GFM table is a header line, a delimiter line, and any number of body
  /// lines. The delimiter is what makes it a table rather than lines that
  /// happen to contain pipes, so it is required.
  static TableLocation? locate(String text, int offset) {
    final lines = text.split('\n');
    final caret = _lineOf(lines, offset);
    if (caret.line >= lines.length) return null;

    // Walk out from the caret over lines that could belong to one table.
    var start = caret.line;
    while (start > 0 && _isTableLine(lines[start - 1])) {
      start--;
    }
    var end = caret.line;
    while (end + 1 < lines.length && _isTableLine(lines[end + 1])) {
      end++;
    }
    if (!_isTableLine(lines[caret.line])) return null;
    if (end - start < 1) return null;

    // The delimiter must be the second line of the run; anything else is a
    // run of pipe-bearing paragraph lines.
    final delimiter = start + 1;
    if (delimiter > end) return null;
    final aligns = _parseDelimiter(lines[delimiter]);
    if (aligns == null) return null;

    final rows = <List<String>>[];
    final rowLines = <int>[];
    for (var i = start; i <= end; i++) {
      if (i == delimiter) continue;
      rows.add(_splitCells(lines[i]));
      rowLines.add(i);
    }
    if (rows.isEmpty) return null;

    // The caret on the delimiter line belongs to the header: that is the row
    // a command like "insert row below" should act relative to.
    var row = rowLines.indexOf(caret.line);
    if (row == -1) row = 0;

    return TableLocation(
      startLine: start,
      endLine: end,
      rows: rows,
      aligns: aligns,
      row: row,
      column: _columnAt(lines[caret.line], caret.column, aligns.length),
    );
  }

  /// Applies [edit] to the table at [offset], returning the new document and
  /// where the caret should end up, or null if the edit does not apply.
  static ({String text, int offset})? apply(
    String text,
    int offset,
    TableEdit edit,
  ) {
    final table = locate(text, offset);
    if (table == null || !table.can(edit)) return null;

    final rows = [for (final r in table.rows) [...r]];
    final aligns = [...table.aligns];
    var row = table.row;
    var column = table.column;

    switch (edit) {
      case TableEdit.insertRowAbove:
        // Never above the header: a table's first row is its header, and a
        // blank row put before it would become one.
        final at = row == 0 ? 1 : row;
        rows.insert(at, List.filled(aligns.length, ''));
        row = at;
      case TableEdit.insertRowBelow:
        rows.insert(row + 1, List.filled(aligns.length, ''));
        row = row + 1;
      case TableEdit.deleteRow:
        rows.removeAt(row);
        if (row >= rows.length) row = rows.length - 1;
      case TableEdit.insertColumnLeft:
        for (final r in rows) {
          r.insert(column, '');
        }
        aligns.insert(column, ColumnAlign.none);
      case TableEdit.insertColumnRight:
        for (final r in rows) {
          r.insert(column + 1, '');
        }
        aligns.insert(column + 1, ColumnAlign.none);
        column += 1;
      case TableEdit.deleteColumn:
        for (final r in rows) {
          if (column < r.length) r.removeAt(column);
        }
        aligns.removeAt(column);
        if (column >= aligns.length) column = aligns.length - 1;
      case TableEdit.alignLeft:
        aligns[column] = ColumnAlign.left;
      case TableEdit.alignCenter:
        aligns[column] = ColumnAlign.center;
      case TableEdit.alignRight:
        aligns[column] = ColumnAlign.right;
      case TableEdit.alignNone:
        aligns[column] = ColumnAlign.none;
    }

    final rendered = render(rows, aligns);
    final lines = text.split('\n');
    final before = lines.sublist(0, table.startLine);
    final after = lines.sublist(table.endLine + 1);
    final newText = [...before, ...rendered, ...after].join('\n');

    // Put the caret in the cell the command was about, so a run of commands
    // stays where the reader is looking.
    final caretLine = table.startLine + (row == 0 ? 0 : row + 1);
    return (
      text: newText,
      offset: _offsetOfCell(
        [...before, ...rendered, ...after],
        caretLine,
        column,
      ),
    );
  }

  /// Lays the table out with every column padded to its widest cell.
  ///
  /// Any edit reformats the whole table, not just the part that changed. That
  /// is deliberate: a table is read in the source as well as in the preview,
  /// and a column that no longer lines up after a cell grows is worse than a
  /// larger diff. The shape is the conventional one — Prettier's markdown
  /// formatter writes tables this way — with at least three dashes in the
  /// delimiter row even where the column is narrower.
  ///
  /// A narrower delimiter is legal GFM (`| - |` parses, here and in `marked`),
  /// so the minimum is a matter of convention rather than correctness.
  static List<String> render(
    List<List<String>> rows,
    List<ColumnAlign> aligns,
  ) {
    // Three, so the delimiter row reads as `---`. An alignment marker needs
    // its own room on top of that: `:-:` cannot be written in fewer than
    // three characters, `:-` and `-:` in fewer than two.
    final widths = List.filled(aligns.length, 3);
    for (final row in rows) {
      for (var c = 0; c < aligns.length && c < row.length; c++) {
        final w = _displayWidth(row[c].trim());
        if (w > widths[c]) widths[c] = w;
      }
    }

    String cell(String value, int column) {
      final v = value.trim();
      return ' $v${' ' * (widths[column] - _displayWidth(v))} ';
    }

    String line(List<String> row) =>
        '|${[for (var c = 0; c < aligns.length; c++) cell(c < row.length ? row[c] : '', c)].join('|')}|';

    String delimiterCell(int column) {
      final w = widths[column];
      return switch (aligns[column]) {
        ColumnAlign.left => ' :${'-' * (w - 1)} ',
        ColumnAlign.right => ' ${'-' * (w - 1)}: ',
        ColumnAlign.center => ' :${'-' * (w - 2)}: ',
        ColumnAlign.none => ' ${'-' * w} ',
      };
    }

    return [
      line(rows.first),
      '|${[for (var c = 0; c < aligns.length; c++) delimiterCell(c)].join('|')}|',
      for (final row in rows.skip(1)) line(row),
    ];
  }

  /// A CJK character occupies two columns in a monospaced font, so padding
  /// by code units alone leaves a table that is ragged everywhere it is read.
  ///
  /// Shared with the diagram layout, which needs the same answer about the
  /// same characters for the box it draws around a label.
  static int _displayWidth(String s) => displayWidth(s);

  static bool _isTableLine(String line) => line.trim().startsWith('|');

  static List<ColumnAlign>? _parseDelimiter(String line) {
    final cells = _splitCells(line);
    if (cells.isEmpty) return null;
    final aligns = <ColumnAlign>[];
    for (final raw in cells) {
      final cell = raw.trim();
      if (!RegExp(r'^:?-+:?$').hasMatch(cell)) return null;
      final left = cell.startsWith(':');
      final right = cell.endsWith(':');
      aligns.add(left && right
          ? ColumnAlign.center
          : left
              ? ColumnAlign.left
              : right
                  ? ColumnAlign.right
                  : ColumnAlign.none);
    }
    return aligns;
  }

  /// The cells of one row, without the leading and trailing pipes.
  ///
  /// A `\|` is an escaped pipe inside a cell, not a separator — splitting on
  /// every pipe would cut a cell in half and shift every column after it.
  static List<String> _splitCells(String line) {
    var s = line.trim();
    if (s.startsWith('|')) s = s.substring(1);
    if (s.endsWith('|') && !s.endsWith(r'\|')) {
      s = s.substring(0, s.length - 1);
    }
    final cells = <String>[];
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      if (ch == r'\' && i + 1 < s.length && s[i + 1] == '|') {
        buffer.write(r'\|');
        i++;
        continue;
      }
      if (ch == '|') {
        cells.add(buffer.toString());
        buffer.clear();
        continue;
      }
      buffer.write(ch);
    }
    cells.add(buffer.toString());
    return cells;
  }

  /// Which column [column] characters into [line] falls in.
  static int _columnAt(String line, int column, int columnCount) {
    var index = 0;
    var seen = 0;
    final trimmedStart = line.length - line.trimLeft().length;
    for (var i = trimmedStart; i < line.length && i < column; i++) {
      if (line[i] == r'\' && i + 1 < line.length && line[i + 1] == '|') {
        i++;
        continue;
      }
      if (line[i] == '|') {
        seen++;
        // The leading pipe opens the first cell rather than closing one.
        index = seen - 1;
      }
    }
    if (index < 0) index = 0;
    return index >= columnCount ? columnCount - 1 : index;
  }

  static ({int line, int column}) _lineOf(List<String> lines, int offset) {
    var remaining = offset;
    for (var i = 0; i < lines.length; i++) {
      if (remaining <= lines[i].length) return (line: i, column: remaining);
      remaining -= lines[i].length + 1;
    }
    return (line: lines.length - 1, column: 0);
  }

  /// The offset of the start of the first cell on [line].
  static int _offsetOfCell(List<String> lines, int line, int column) {
    var offset = 0;
    for (var i = 0; i < line && i < lines.length; i++) {
      offset += lines[i].length + 1;
    }
    if (line >= lines.length) return offset;
    // Land just inside the target cell rather than on the pipe.
    final text = lines[line];
    var seen = -1;
    for (var i = 0; i < text.length; i++) {
      if (text[i] == r'\' && i + 1 < text.length && text[i + 1] == '|') {
        i++;
        continue;
      }
      if (text[i] == '|') {
        seen++;
        if (seen == column) return offset + i + 2;
      }
    }
    return offset;
  }
}

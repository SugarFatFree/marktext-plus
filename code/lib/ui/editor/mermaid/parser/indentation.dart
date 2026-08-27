/// Leading-whitespace measurement shared by the indentation-driven parsers.
///
/// Mindmap and kanban both take their structure from how far a line is
/// indented, and both had their own copy of this. The copies disagreed — one
/// advanced a tab to the next tab stop, the other did not handle tabs at all —
/// which is exactly how a board written with tabs came out with every task
/// promoted to a column.
library;

/// Columns of leading whitespace in [line], a tab advancing to the next
/// multiple of [tabWidth].
int indentColumns(String line, {int tabWidth = 4}) {
  var columns = 0;
  for (final rune in line.runes) {
    if (rune == 0x20) {
      columns++;
    } else if (rune == 0x09) {
      columns += tabWidth - (columns % tabWidth);
    } else {
      break;
    }
  }
  return columns;
}

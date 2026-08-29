import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// GFM tables, as GitHub actually renders them.
///
/// CommonMark has no tables, so the corpus in `commonmark_spec_test.dart`
/// says nothing about them. The expectations here were checked against
/// `marked` — a reference implementation of the same extension — rather than
/// written from memory: two of the cases below behave the opposite of what
/// looked obvious.
void main() {
  List<MarkdownNode> parse(String source) => MarkdownParser().parse(source);
  TableNode tableIn(String source) =>
      parse(source).whereType<TableNode>().single;

  test('the ordinary shapes all parse', () {
    expect(tableIn('| a | b |\n|---|---|\n| 1 | 2 |\n').headers, ['a', 'b']);
    // Outer pipes are optional.
    expect(tableIn('a | b\n--- | ---\n1 | 2\n').headers, ['a', 'b']);
    expect(tableIn('| a |\n|---|\n| 1 |\n').rows, [
      ['1']
    ]);
    expect(tableIn('| 名称 | 说明 |\n|---|---|\n| 甲 | 乙 |\n').rows, [
      ['甲', '乙']
    ]);
  });

  test('alignment is read from the delimiter row', () {
    final table = tableIn('| l | c | r |\n|:--|:-:|--:|\n| 1 | 2 | 3 |\n');
    expect(table.alignments, ['left', 'center', 'right']);
  });

  test('a short row is padded and a long one is trimmed', () {
    expect(tableIn('| a | b | c |\n|---|---|---|\n| 1 |\n').rows, [
      ['1', '', '']
    ]);
    expect(tableIn('| a | b |\n|---|---|\n| 1 | 2 | 3 |\n').rows, [
      ['1', '2']
    ]);
  });

  test('a table may follow a paragraph with no blank line between', () {
    // Written this way it used to be swallowed into the paragraph and never
    // drawn at all. GitHub breaks the paragraph and renders the table, and
    // so does `marked`.
    final ast = parse('文字\n| a | b |\n|---|---|\n| 1 | 2 |\n');
    expect(ast.map((n) => n.type).toList(),
        [NodeType.paragraph, NodeType.table]);
    expect((ast.first as ParagraphNode).content, '文字');
    expect((ast.last as TableNode).rows, [
      ['1', '2']
    ]);
  });

  test('an escaped pipe stays inside its cell', () {
    expect(tableIn('| a | b |\n|---|---|\n| x \\| y | 2 |\n').rows, [
      ['x | y', '2']
    ]);
  });

  test('an unescaped pipe splits the cell, even inside backticks', () {
    // This one looks wrong and is right: GFM splits on the raw pipe first and
    // only then reads inline markup, so a code span cannot protect it. Both
    // `marked` and this parser produce two cells here.
    expect(tableIn('| a | b |\n|---|---|\n| `x|y` | 2 |\n').rows, [
      ['`x', 'y`']
    ]);
  });

  test('a delimiter row with the wrong number of cells is not a table', () {
    final ast = parse('| a | b |\n|---|\n| 1 | 2 |\n');
    expect(ast.whereType<TableNode>(), isEmpty);
    expect(ast.single.type, NodeType.paragraph);
  });

  test('a header with no rows under it is still a table', () {
    final table = tableIn('| a | b |\n|---|---|\n');
    expect(table.headers, ['a', 'b']);
    expect(table.rows, isEmpty);
  });

  test('inline markup inside a cell is kept for the renderer', () {
    expect(tableIn('| a | b |\n|---|---|\n| **粗** | `码` |\n').rows, [
      ['**粗**', '`码`']
    ]);
  });
}

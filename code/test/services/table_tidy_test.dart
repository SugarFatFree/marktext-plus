import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
import 'package:marktext_plus/services/table_edit_service.dart';
import 'package:marktext_plus/utils/text_width.dart';

/// Laying a table's source out again without changing what it says.
///
/// Every other table command reformats the table as a side effect of what it
/// does. Editing a cell's text by hand — fixing a typo — has no such side
/// effect, so from then on the columns do not line up in the source and
/// nothing puts them back. A table is read in the source as well as in the
/// preview, which is why the other commands bother.
void main() {
  const ragged = '正文\n\n'
      '|键|值|说明|\n'
      '|:-|-:|-|\n'
      '|A|甲|一个中文说明|\n'
      '| B |乙|短|\n\n'
      '尾巴\n';

  /// Tidies the table the given text sits in. The anchor is cell content
  /// rather than punctuation, because punctuation is exactly what moves.
  String? tidied(String source, {String at = '甲'}) {
    final offset = source.indexOf(at);
    expect(offset, greaterThanOrEqualTo(0), reason: '锚点 $at 不在文档里');
    return TableEditService.apply(source, offset, TableEdit.tidy)?.text;
  }

  List<List<String>> cellsOf(String source) {
    final table =
        MarkdownParser().parse(source).whereType<TableNode>().single;
    return [table.headers, ...table.rows];
  }

  List<String> tableLines(String source) => source
      .split('\n')
      .where((line) => line.trimLeft().startsWith('|'))
      .toList();

  test('the columns line up, counting a CJK character as two', () {
    final out = tidied(ragged)!;
    final widths = tableLines(out).map(displayWidth).toSet();
    expect(widths, hasLength(1),
        reason: '各行宽度不一致：${tableLines(out).join('\n')}');
  });

  test('nothing the table says changes', () {
    expect(cellsOf(tidied(ragged)!), cellsOf(ragged));
  });

  test('the text around the table is left alone', () {
    final out = tidied(ragged)!;
    expect(out, startsWith('正文\n\n'));
    expect(out, endsWith('尾巴\n'));
  });

  test('the column alignments are kept', () {
    final out = tidied(ragged)!;
    final delimiter = tableLines(out)[1];
    expect(delimiter, contains(':--'));
    expect(delimiter, contains('--:'));
  });

  test('doing it twice changes nothing the second time', () {
    final once = tidied(ragged)!;
    expect(tidied(once), once);
  });

  test('an escaped pipe stays escaped, and stays in its own cell', () {
    const source = '| 键 | 值 |\n|---|---|\n| a\\|b | 乙 |\n';
    final out = tidied(source, at: '乙')!;
    expect(out, contains(r'a\|b'));
    expect(cellsOf(out)[1], ['a|b', '乙'],
        reason: '转义竖线被当成了分隔符');
  });

  test('the caret stays on the row it was on', () {
    final result = TableEditService.apply(
      ragged,
      ragged.indexOf('一个中文说明'),
      TableEdit.tidy,
    )!;
    final before = result.text.substring(0, result.offset).split('\n');
    final caretLine = result.text.split('\n')[before.length - 1];
    expect(caretLine, contains('一个中文说明'),
        reason: '整理之后光标跑到了别的行');
  });

  test('a caret outside any table is not a table command', () {
    expect(TableEditService.apply(ragged, 0, TableEdit.tidy), isNull);
  });
}

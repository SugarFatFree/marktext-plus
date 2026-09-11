import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/html_to_markdown.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// A table row ends at a line ending, so a cell cannot hold one.
///
/// `<td>a<br>b</td><td>c</td>` was written with the `<br>` as `  \n`, which
/// ended the row inside the first cell: what came back was a row holding `a` and
/// nothing, then a row holding `b` and `c` — every cell after the break shifted
/// one column left and the header no longer described the columns under it.
///
/// GFM writes a break inside a cell as an inline `<br>`, which this editor reads
/// only when HTML is turned on, and it is off by default — the reader would see
/// the tag as text. A space keeps the table and loses only the break.
void main() {
  String md(String html) => HtmlToMarkdown.convert(html) ?? '';
  List<List<String>> cells(String html) {
    final out = MarkdownParser()
        .parse(md(html))
        .map(ExportService.nodeToHtml)
        .join();
    return RegExp(r'<tr>(.*?)</tr>', dotAll: true)
        .allMatches(out)
        .map((row) => RegExp(r'<t[hd]>(.*?)</t[hd]>', dotAll: true)
            .allMatches(row.group(1)!)
            .map((cell) => cell.group(1)!)
            .toList())
        .toList();
  }

  test('a break inside a cell does not end the row', () {
    const html = '<table><tr><th>h1</th><th>h2</th></tr>'
        '<tr><td>a<br>b</td><td>c</td></tr></table>';
    expect(
      cells(html),
      [
        ['h1', 'h2'],
        ['a b', 'c'],
      ],
      reason: 'wrote "${md(html)}"',
    );
  });

  test('two breaks in one cell still leave one row', () {
    const html = '<table><tr><th>h</th></tr>'
        '<tr><td>a<br>b<br>c</td></tr></table>';
    expect(cells(html), [
      ['h'],
      ['a b c'],
    ], reason: 'wrote "${md(html)}"');
  });

  /// What a word processor puts on the clipboard: each line of a cell its own
  /// paragraph. Concatenating them ran the words together.
  test('paragraphs inside a cell become separate words', () {
    const html = '<table><tr><th>h</th></tr>'
        '<tr><td><p>one</p><p>two</p></td></tr></table>';
    expect(cells(html), [
      ['h'],
      ['one two'],
    ], reason: 'wrote "${md(html)}"');
  });

  /// `contains('one')` and `contains('two')` both hold of `onetwo`, so they
  /// would have passed before the fix as well. The whole string is what
  /// separates the two answers.
  test('a list inside a cell becomes separate words too', () {
    const html = '<table><tr><th>h</th></tr>'
        '<tr><td><ul><li>one</li><li>two</li></ul></td></tr></table>';
    expect(cells(html), [
      ['h'],
      ['one two'],
    ], reason: 'wrote "${md(html)}"');
  });

  test('the pipe is still escaped', () {
    const html = '<table><tr><th>h</th></tr><tr><td>a|b</td></tr></table>';
    expect(cells(html), [
      ['h'],
      ['a|b'],
    ]);
  });

  test('an ordinary cell is unchanged', () {
    const html = '<table><tr><th>h1</th><th>h2</th></tr>'
        '<tr><td>plain</td><td><strong>bold</strong></td></tr></table>';
    expect(cells(html).first, ['h1', 'h2']);
    expect(cells(html).last.first, 'plain');
    expect(cells(html).last.last, contains('bold'));
  });
}

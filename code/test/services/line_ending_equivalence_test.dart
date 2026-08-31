import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// The line ending must not change what a document means.
///
/// Windows is a supported platform, so half the documents this editor opens
/// end their lines with CRLF. Everything decided per line — where a list item
/// stops, whether a quotation carries on, how far a raw-text tag reaches —
/// is a place where a stray `\r` can be counted as content or lose a match.
///
/// Asserted as a property over shapes rather than as expected output, so it
/// keeps holding as the rules themselves change.
void main() {
  String htmlOf(String source) => MarkdownParser()
      .parse(source)
      .map(ExportService.nodeToHtml)
      .join();

  void sameEitherWay(String name, String lf) {
    test(name, () {
      expect(htmlOf(lf.replaceAll('\n', '\r\n')), htmlOf(lf),
          reason: 'CRLF 与 LF 解析结果不同');
    });
  }

  group('the shapes that are decided line by line', () {
    sameEitherWay('a bullet continued on the next line',
        '- 很长的一条，\n在下一行继续。\n');
    sameEitherWay('a quotation continued on the next line',
        '> 引用第一行\n引用续行\n');
    sameEitherWay('an empty item in the middle', '- 甲\n-\n- 乙\n');
    sameEitherWay('emphasis across a line break', '*强调跨了\n一行*\n');
    sameEitherWay('a setext heading over two lines', '标题上半\n标题下半\n---\n');
    sameEitherWay(
        'a raw-text tag holding a blank line', '<pre>\n甲\n\n乙\n</pre>\n后记\n');
    sameEitherWay('an indented code block under a step', '- foo\n\n      bar\n');
    sameEitherWay('a link definition inside a fence',
        '```\n[foo]: /url\n```\n\n[foo]\n');
    sameEitherWay('a table', '| 甲 | 乙 |\n|---|---|\n| 1 | 2 |\n');
    sameEitherWay('a document that is one long paragraph',
        '第一行\n第二行\n第三行\n');
  });

  test('a lone carriage return is a line ending too', () {
    // Old Mac documents, and anything that has been through a broken
    // conversion. LineSplitter treats it as a break; so must everything built
    // on top of it.
    expect(htmlOf('- 甲\r- 乙\r'), htmlOf('- 甲\n- 乙\n'));
  });
}

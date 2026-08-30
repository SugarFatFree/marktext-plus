import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// Emphasis whose opening and closing markers are on different lines.
///
/// A paragraph wrapped at some column — by hand, or by whatever wrote the
/// file — puts the two halves of an emphasis on two lines. The pattern could
/// not cross a newline, so the same sentence emphasised or did not depending
/// on where it happened to wrap.
void main() {
  late MarkdownParser parser;
  setUp(() => parser = MarkdownParser());

  String htmlOf(String source) =>
      parser.parse(source).map(ExportService.nodeToHtml).join();

  group('a wrapped paragraph emphasises the same as an unwrapped one', () {
    test('italic across the wrap', () {
      expect(htmlOf('*强调跨了\n一行*\n'), contains('<em>'));
    });

    test('bold across the wrap', () {
      expect(htmlOf('**加粗跨了\n一行**\n'), contains('<strong>'));
    });

    test('underscores across the wrap', () {
      expect(htmlOf('_强调跨了\n一行_\n'), contains('<em>'));
    });

    test('a single character still emphasises on its own', () {
      // The content pattern offers a one-character form and a longer one.
      // With the longer one tried first, a lone `*甲*` could not match it
      // within the line and fell back — but once the pattern could cross a
      // newline, the longer form reached a marker further down the paragraph
      // and swallowed everything between. The short form is tried first now.
      final html = htmlOf('这里 *甲*，\n下一行 *乙*。\n');
      expect(html, contains('<em>甲</em>'));
      expect(html, contains('<em>乙</em>'));
    });

    test('the nearest closing marker still wins', () {
      // Two emphases, one per line: the first must close on its own line, not
      // reach across to the second one's marker.
      final html = htmlOf('一段里有 *甲*，\n下一行是 *乙*。\n');
      expect('<em>'.allMatches(html).length, 2);
      expect(html, contains('<em>甲</em>'));
      expect(html, contains('<em>乙</em>'));
    });
  });

  group('what still stops it', () {
    test('a blank line', () {
      // Two paragraphs are parsed separately, so a marker in one cannot pair
      // with a marker in the other.
      final html = htmlOf('第一段有个星号 *\n\n第二段也有个星号 *\n');
      expect(html, isNot(contains('<em>')));
    });

    test('a code span keeps its own asterisk', () {
      expect(htmlOf('`代码里的\n星号 *` 和后面的 *\n'), isNot(contains('<em>')));
    });

    test('two list items are two blocks', () {
      final html = htmlOf('- 第一项 *斜体\n- 第二项 斜体*\n');
      expect(html, isNot(contains('<em>')));
    });
  });

  test('wrapping a line no longer changes what it means', () {
    // The point of the change, stated as the property it restores. Two
    // asterisks between digits pair on one line — they did before this change
    // too — and now do the same when the sentence is wrapped between them.
    // Whether that pairing is desirable is a separate question; what was
    // surprising was that it depended on where the line broke.
    const oneLine = '价格 3*4 元，另一行 5*6 元。\n';
    const wrapped = '价格 3*4 元，\n另一行 5*6 元。\n';
    expect(htmlOf(oneLine).contains('<em>'), isTrue);
    expect(htmlOf(wrapped).contains('<em>'), isTrue);
  });
}

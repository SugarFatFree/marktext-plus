import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// A delimiter appearing inside the thing it delimits.
///
/// This is where parsers go wrong, and it has twice in this project's diagram
/// code — an arrow inside a node's label deleted the node, and a colon inside
/// a Gantt task's name truncated it. These are the markdown equivalents.
///
/// The table cases are the interesting ones because the answer is
/// counter-intuitive: GFM makes `|` a cell separator even inside a code span,
/// so `` `a|b` `` really is two cells. That was checked against `marked`
/// rather than assumed, and it agrees with this parser character for
/// character. The tests are here to keep it agreeing.
void main() {
  final parser = MarkdownParser();

  String html(String markdown) =>
      parser.parse(markdown).map(ExportService.nodeToHtml).join();

  int cellsIn(String markdown) => '<td>'.allMatches(html(markdown)).length;

  group('a table cell', () {
    test('splits on an unescaped pipe, even inside a code span', () {
      // Verified against marked: two cells, `a and b`.
      expect(cellsIn('| a | b |\n| --- | --- |\n| `a|b` | z |\n'), 2);
    });

    test('splits on an unescaped pipe inside a link too', () {
      expect(
        cellsIn('| a | b |\n| --- | --- |\n| [t](http://x.com/a|b) | z |\n'),
        2,
      );
    });

    test('keeps an escaped pipe as text', () {
      final out = html('| a | b |\n| --- | --- |\n| x \\| y | z |\n');
      expect(cellsIn('| a | b |\n| --- | --- |\n| x \\| y | z |\n'), 2);
      expect(out, contains('x | y'));
    });
  });

  group('other delimiters inside their own content', () {
    test('a link destination may hold balanced parentheses', () {
      expect(html('[t](http://x.com/a_(b))\n'),
          contains('href="http://x.com/a_(b)"'));
    });

    test('a link title may hold escaped quotes', () {
      expect(html('[t](http://x.com "他说\\"好\\"")\n'),
          contains('title="他说&quot;好&quot;"'));
    });

    test('a doubled backtick lets a code span hold a backtick', () {
      expect(html('``a ` b``\n'), contains('<code>a ` b</code>'));
    });

    test('a lone asterisk inside strong emphasis is text', () {
      expect(html('**a * b**\n'), contains('<strong>a * b</strong>'));
    });

    test('an image alt may hold brackets', () {
      expect(html('![a[b]c](x.png)\n'), contains('alt="a[b]c"'));
    });

    test('front matter ends at its own fence, not at one in the text', () {
      final nodes = parser.parse('---\ntitle: a---b\n---\n\n正文\n');
      expect(nodes.map((n) => n.type),
          [NodeType.frontMatter, NodeType.paragraph]);
      expect((nodes.first as FrontMatterNode).content, contains('a---b'));
    });

    test('a longer fence may hold a shorter one', () {
      final nodes = parser.parse('````\n```\nnested\n```\n````\n');
      expect(nodes.single.type, NodeType.codeBlock);
      expect((nodes.single as CodeBlockNode).code, contains('```'));
    });

    test('a hash inside a heading is not a closing sequence', () {
      expect(html('# 标题 # 不是结尾\n'), contains('<h1>标题 # 不是结尾</h1>'));
    });
  });
}

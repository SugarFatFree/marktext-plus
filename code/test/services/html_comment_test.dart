import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
import 'package:marktext_plus/services/rich_copy_service.dart';

/// An HTML comment is invisible, and a closing tag closes its section.
///
/// `<!-- TODO -->` is a note to whoever reads the source next; it was drawn in
/// the preview as a paragraph of escaped angle brackets, which is the one
/// thing a comment must not be. And `</details>`, which is how every
/// collapsible section in a README ends, was left as a paragraph under the
/// section it was supposed to close.
void main() {
  String html(String md) =>
      MarkdownParser().parse(md).map(ExportService.nodeToHtml).join();
  List<MarkdownNode> parse(String md) => MarkdownParser().parse(md);

  group('a comment on its own line', () {
    test('is not a paragraph', () {
      final nodes = parse('正文一\n\n<!-- 这是注释 -->\n\n正文二\n');
      expect(nodes.map((n) => n.type),
          [NodeType.paragraph, NodeType.htmlBlock, NodeType.paragraph]);
      expect((nodes[1] as HtmlBlockNode).isComment, isTrue);
    });

    test('spanning several lines is one block', () {
      final nodes = parse('正文\n\n<!--\nTODO: 待办\n-->\n\n尾\n');
      expect(nodes.map((n) => n.type),
          [NodeType.paragraph, NodeType.htmlBlock, NodeType.paragraph]);
      expect((nodes[1] as HtmlBlockNode).html, contains('TODO'));
    });

    test('ends at the first `-->`, wherever on the line it falls', () {
      final nodes = parse('正文\n\n<!-- a --> b -->\n\n尾\n');
      expect(nodes, hasLength(3));
      expect((nodes[1] as HtmlBlockNode).isComment, isTrue);
    });

    test('survives into the HTML export as a comment', () {
      // Passing it through is what keeps it a comment; every other output
      // drops it.
      expect(html('<!-- 注释 -->\n'), contains('<!-- 注释 -->'));
    });

    test('carries no text to paste', () {
      expect(RichCopyService.plainTextOf(parse('<!-- 注释 -->\n').single), '');
    });
  });

  group('what must not change', () {
    test('an unclosed comment stays a paragraph', () {
      // A live editor: `<!--` is a state every comment passes through while
      // it is being typed. Swallowing the rest of the document would blank
      // the page below the caret.
      final nodes = parse('正文\n\n<!-- 还没写完\n\n更多正文\n');
      expect(nodes.every((n) => n.type == NodeType.paragraph), isTrue,
          reason: '未闭合的注释吞掉了后面的内容');
      expect(nodes, hasLength(3));
    });

    test('a comment inside a code fence is code', () {
      final out = html('```html\n<!-- 示例 -->\n```\n');
      expect(out, contains('<pre><code'));
      expect(out, contains('&lt;!--'));
    });
  });

  group('a closing tag closes its section', () {
    test('details survives whole', () {
      final out = html('<details>\n<summary>点击展开</summary>\n\n'
          '内容\n\n</details>\n');
      expect(out, contains('</details>'));
      expect(out, isNot(contains('&lt;/details&gt;')),
          reason: '收尾标签漏成了文字');
    });

    test('and the gap between the tags is still read as markdown', () {
      // What the closing tag must not do is swallow what sits above it.
      final nodes = parse('<a href="x">\n\n# 中间\n\nprose\n\n</a>\n');
      expect(nodes.where((n) => n.type == NodeType.heading).length, 1);
      expect(nodes.last.type, NodeType.htmlBlock);
    });
  });
}

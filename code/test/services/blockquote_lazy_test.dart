import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// A quoted paragraph carried on without repeating the `>`.
///
/// Anyone quoting more than a line writes it this way — the `>` goes on the
/// first line and the rest of the sentence follows. The remainder used to fall
/// out of the quote and stand beside it as an ordinary paragraph, so half the
/// quotation was inside the box and half outside. Every answer here is what
/// marked, the parser upstream MarkText uses, gives for the same input.
void main() {
  late MarkdownParser parser;
  setUp(() => parser = MarkdownParser());

  String htmlOf(String source) =>
      parser.parse(source).map(ExportService.nodeToHtml).join();

  group('the rest of the sentence stays in the quote', () {
    test('one continuation line', () {
      // Asserted on the shape rather than the exact HTML: a newline inside a
      // paragraph is a line break in this editor, so a `<br>` sits between
      // the two halves. What matters is that both are inside the quote.
      final nodes = parser.parse('> 引用第一行\n引用续行\n');
      expect(nodes, hasLength(1));
      final quote = nodes.single as BlockquoteNode;
      expect(quote.content, contains('引用第一行'));
      expect(quote.content, contains('引用续行'));
      final html = htmlOf('> 引用第一行\n引用续行\n');
      expect(html.indexOf('引用续行'), lessThan(html.indexOf('</blockquote>')),
          reason: '续行落在引用外面');
    });

    test('several', () {
      final nodes = parser.parse('> 甲\n乙\n丙\n');
      expect(nodes, hasLength(1));
      expect(nodes.single.type, NodeType.blockquote);
    });

    test('after a heading inside the quote', () {
      final nodes = parser.parse('> # 标题\n> 正文\n续行\n');
      expect(nodes, hasLength(1), reason: '续行掉出了引用');
    });

    test('a nested quote is continued too', () {
      // The line below a paragraph continues it whatever depth of markers it
      // carries, so this one belongs to the inner quote.
      final outer = parser.parse('> outer\n>> inner\n> outer again\n').single
          as BlockquoteNode;
      final inner = outer.children[1] as BlockquoteNode;
      expect(inner.content, 'inner\nouter again');
    });
  });

  group('what still ends a quote', () {
    test('a blank line', () {
      final nodes = parser.parse('> 引用\n\n普通段落\n');
      expect(nodes.map((n) => n.type).toList(),
          [NodeType.blockquote, NodeType.paragraph]);
    });

    test('a heading on the next line', () {
      final nodes = parser.parse('> 引用\n# 标题\n');
      expect(nodes.map((n) => n.type).toList(),
          [NodeType.blockquote, NodeType.heading]);
    });

    test('a list on the next line', () {
      final nodes = parser.parse('> 引用\n- 项目\n');
      expect(nodes.map((n) => n.type).toList(),
          [NodeType.blockquote, NodeType.unorderedList]);
    });

    test('a fence on the next line', () {
      final nodes = parser.parse('> 引用\n```\ncode\n```\n');
      expect(nodes.first.type, NodeType.blockquote);
      expect(nodes.last.type, NodeType.codeBlock);
    });

    test('a blank quoted line, then text', () {
      // The `>` line with nothing on it ends the paragraph, so what follows
      // has nothing to carry on.
      final nodes = parser.parse('> 引用\n>\n普通段落\n');
      expect(nodes.map((n) => n.type).toList(),
          [NodeType.blockquote, NodeType.paragraph]);
    });
  });
}

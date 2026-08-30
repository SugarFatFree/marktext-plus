import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// Two shapes a list takes while it is being written.
///
/// A bullet long enough to wrap is written over two lines with no indentation
/// on the second, and pressing Enter in the middle of a list leaves a marker
/// with nothing after it. Both used to end the list: the first turned the rest
/// of the sentence into a paragraph under the bullet, the second broke one
/// list into two with a line reading `-` between them.
void main() {
  late MarkdownParser parser;
  setUp(() => parser = MarkdownParser());

  List<String> itemsOf(String source) {
    final list = parser.parse(source).first as ListNode;
    return [for (final item in list.items) item.content];
  }

  group('a wrapped item stays one item', () {
    test('a bullet continued on the next line', () {
      expect(
        itemsOf('- 这是很长的一条，\n在源文件里换了行。\n'),
        ['这是很长的一条， 在源文件里换了行。'],
      );
    });

    test('a numbered step continued on the next line', () {
      expect(itemsOf('1. 第一条，\n换行续写。\n').single, contains('换行续写'));
    });

    test('a blank line still ends the list', () {
      final nodes = parser.parse('- foo\n\n这是列表后面的段落。\n');
      expect(nodes.map((n) => n.type).toList(),
          [NodeType.unorderedList, NodeType.paragraph]);
    });

    test('a heading on the next line still ends the list', () {
      final nodes = parser.parse('- foo\n# 标题\n');
      expect(nodes.map((n) => n.type).toList(),
          [NodeType.unorderedList, NodeType.heading]);
    });

    test('a rule on the next line still ends the list', () {
      final nodes = parser.parse('- foo\n---\n');
      expect(nodes.map((n) => n.type).toList(),
          [NodeType.unorderedList, NodeType.horizontalRule]);
    });
  });

  group('an empty item keeps the list together', () {
    test('a marker with a trailing space', () {
      // What the editor leaves behind the instant Enter is pressed.
      expect(itemsOf('- foo\n- \n- bar\n'), ['foo', '', 'bar']);
    });

    test('a marker with nothing after it at all', () {
      // Differs from the case above by one space, and used to behave
      // differently: the marker was unreadable without a space after it, so
      // the line looked like the start of a second list.
      expect(itemsOf('- foo\n-\n- bar\n'), ['foo', '', 'bar']);
    });

    test('an empty numbered step', () {
      expect(itemsOf('1. foo\n2.\n3. bar\n'), ['foo', '', 'bar']);
    });

    test('an empty item does not crash the item builder', () {
      // The item patterns require content, so there is no match to read the
      // text out of; reading one anyway threw on a null.
      expect(() => parser.parse('- foo\n-\n'), returnsNormally);
    });

    test('a stray marker on its own is not a list', () {
      // The guard: an empty marker continues a list, it does not start one.
      // A lone dash in prose stays what it was.
      expect(parser.parse('-\n').single.type, NodeType.paragraph);
    });

    test('a rule is still a rule, not an empty item', () {
      final nodes = parser.parse('- foo\n* * *\n- bar\n');
      expect(nodes.map((n) => n.type).toList(), [
        NodeType.unorderedList,
        NodeType.horizontalRule,
        NodeType.unorderedList,
      ]);
    });

    test('switching marker still starts a new list', () {
      final nodes = parser.parse('- foo\n+ bar\n');
      expect(nodes.length, 2, reason: '换了标记字符应是两个列表');
    });
  });

  group('what an item carries', () {
    test('an indented code block under a step stays code', () {
      // A code sample written under a step by indenting it, rather than with
      // a fence. The item's own indentation comes off; the four columns that
      // make it code stay on.
      final list = parser.parse('- foo\n\n      bar\n').first as ListNode;
      final blocks = list.items.single.children;
      expect(blocks.map((b) => b.type).toList(), contains(NodeType.codeBlock));
      expect((blocks.firstWhere((b) => b.type == NodeType.codeBlock)
              as CodeBlockNode)
          .code
          .trim(), 'bar');
    });

    test('a fence under a step is still a fence', () {
      // The guard: taking off the item's indentation is what lets the fence be
      // seen at all, and that must keep working.
      final list = parser.parse('1. 步骤\n\n   ```\n   code\n   ```\n').first
          as ListNode;
      expect(list.items.single.children.map((b) => b.type).toList(),
          contains(NodeType.codeBlock));
    });
  });

  group('a long number is not a step', () {
    test('eleven digits before a full stop is a paragraph', () {
      // A phone number, an order reference. Read as a step it renumbered the
      // document from thirteen billion.
      expect(parser.parse('13800138000. 联系人\n').single.type,
          NodeType.paragraph);
    });

    test('nine digits is still a step', () {
      // The boundary the format draws.
      expect(parser.parse('123456789. 步骤\n').single.type,
          NodeType.orderedList);
    });

    test('an ordinary number is unaffected', () {
      expect(parser.parse('1. 第一步\n2. 第二步\n').single.type,
          NodeType.orderedList);
    });
  });
}

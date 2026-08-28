import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// A list item can carry blocks: a code fence under a numbered step, a second
/// paragraph, a quote.
///
/// The list used to break in three around them — the fence came out at the
/// document's left margin, outside the step it explains, and the steps became
/// two separate lists.
void main() {
  final parser = MarkdownParser();

  ListNode listOf(String source) =>
      parser.parse(source).whereType<ListNode>().single;

  group('the item carries the block written under it', () {
    test('a fenced code block', () {
      const doc = '1. step\n\n   ```bash\n   run me\n   ```\n\n2. next\n';
      final list = listOf(doc);

      expect(list.items, hasLength(2), reason: '列表被代码块拆开了');
      final code = list.items.first.children.single as CodeBlockNode;
      expect(code.code, 'run me');
      expect(code.language, 'bash');
      expect(list.items.last.children, isEmpty);
    });

    test('a second paragraph', () {
      final list = listOf('- one\n\n  two\n\n- next\n');
      expect(list.items.first.children.single.type, NodeType.paragraph);
    });

    test('a quote', () {
      final list = listOf('- one\n\n  > quoted\n\n- next\n');
      expect(list.items.first.children.single.type, NodeType.blockquote);
    });

    test('a table', () {
      final list = listOf('- one\n\n  | a | b |\n  |---|---|\n  | 1 | 2 |\n');
      expect(list.items.single.children.single.type, NodeType.table);
    });

    test('the block is dedented, so a fence is a fence', () {
      // Left indented it would parse as indented code and lose its language.
      final list = listOf('1. step\n\n   ```dart\n   void main() {}\n   ```\n');
      final code = list.items.single.children.single as CodeBlockNode;
      expect(code.language, 'dart');
    });
  });

  group('what this must not have changed', () {
    test('a lazy continuation still joins the item text', () {
      final list = listOf('- first line\n  and more\n- second\n');
      expect(list.items.first.content, 'first line and more');
      expect(list.items.first.children, isEmpty);
    });

    test('a gap between plain items still only makes the list loose', () {
      final list = listOf('- one\n\n- two\n');
      expect(list.isLoose, isTrue);
      expect(list.items.every((i) => i.children.isEmpty), isTrue);
    });

    test('an unindented line after a gap ends the list', () {
      // It is not the item's content, however close it looks.
      final nodes = parser.parse('- one\n\nplain paragraph\n');
      expect(nodes.map((n) => n.type).toList(),
          [NodeType.unorderedList, NodeType.paragraph]);
    });

    test('a list of a different kind after a gap is still its own list', () {
      // The item's content column was once measured as zero, which let this
      // be swallowed as content belonging to the item above.
      final lists = parser.parse('3. third\n4. fourth\n\n- bullet\n')
          .whereType<ListNode>()
          .toList();

      expect(lists, hasLength(2));
      expect(lists.first.isLoose, isFalse);
      expect(lists.first.items.every((i) => i.children.isEmpty), isTrue);
    });
  });

  group('the exports put the block inside the item', () {
    test('HTML nests it in the <li>', () {
      final html = parser
          .parse('1. step\n\n   ```bash\n   run me\n   ```\n')
          .map(ExportService.nodeToHtml)
          .join();

      final li = html.indexOf('<li>');
      expect(html.indexOf('<pre>', li), greaterThan(li));
      expect(html.indexOf('<pre>', li), lessThan(html.indexOf('</li>', li)));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// An item left blank does not push the rest of the list inwards.
///
/// Depth is decided by the column an item's *text* starts at, and an item with
/// no text has no such column. `_contentColumn` answered zero for it, and zero
/// is below every real indentation — so nothing was ever popped, and the item
/// after the blank one was read as being inside it.
///
/// Every blank item added another level: two of them in a row nested three
/// deep. And `- ` with nothing after it is exactly what the editor leaves
/// behind when it continues a list for you, so the writer does not have to
/// type anything unusual to reach this.
void main() {
  int listDepth(String markdown) {
    final html = MarkdownParser()
        .parse(markdown)
        .map(ExportService.nodeToHtml)
        .join();
    return '<ul'.allMatches(html).length + '<ol'.allMatches(html).length;
  }

  test('a blank item in the middle keeps the list flat', () {
    expect(listDepth('- foo\n-\n- bar\n'), 1,
        reason: '留空一条，后面的条目不该被吞进去缩进一层');
  });

  test('a blank numbered step keeps the list flat', () {
    expect(listDepth('1. foo\n2.\n3. bar\n'), 1);
  });

  test('a blank item written as the editor leaves it', () {
    // `- ` — the marker and a space, which is what pressing Enter after an
    // item inserts.
    expect(listDepth('- foo\n- \n- bar\n'), 1);
  });

  test('two blank items do not nest three deep', () {
    expect(listDepth('- foo\n-\n-\n- bar\n'), 1,
        reason: '每个空条目多嵌一层，两个就是三层');
  });

  test('a real sub-list still nests', () {
    // The point is not to stop nesting, only to stop nesting on nothing.
    expect(listDepth('- foo\n  - under it\n- bar\n'), 2);
  });

  test('a blank item is as wide as the same marker with text after it', () {
    // What nests under an item is decided by the column its text starts at.
    // A blank item has no text, so the column has to be worked out — and the
    // only answer that is not a guess is the one the same marker would give
    // if something had been typed after it.
    //
    // One space of indentation is where the two answers differ: it is inside
    // a column of 1 and outside a column of 2. Pinned by comparing the two
    // rather than by writing a number down, because the number is not the
    // rule.
    expect(
      listDepth('- foo\n-\n - bar\n'),
      listDepth('- foo\n- x\n - bar\n'),
      reason: '空条目和有内容的条目，底下能挂什么应该是一样的',
    );
  });

  test('the items after a blank one are still there', () {
    final html = MarkdownParser()
        .parse('- foo\n-\n- bar\n')
        .map(ExportService.nodeToHtml)
        .join();
    expect(html, contains('foo'));
    expect(html, contains('bar'));
  });
}

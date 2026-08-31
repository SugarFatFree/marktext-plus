import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// Content indented with a tab under a list item.
///
/// The width of an indent is measured with a tab counted as four columns, and
/// that many *characters* were then cut off the front of the line. A tab is
/// four columns and one character, so three characters of the reader's own
/// writing were deleted along with it — silently, in the preview and in every
/// export. Under a numbered step, where the item's text starts a column
/// further in, it was more.
void main() {
  String html(String md) =>
      MarkdownParser().parse(md).map(ExportService.nodeToHtml).join();

  /// The same HTML with its layout whitespace folded away — the shape of the
  /// document, not how the exporter chose to lay the tags out.
  String shape(String md) =>
      html(md).replaceAll(RegExp(r'>\s+<'), '><').trim();

  group('a tab is four columns and one character', () {
    test('a second paragraph under a bullet keeps all of its text', () {
      expect(shape('- 甲\n\n\t乙丙丁戊\n'),
          shape('- 甲\n\n  乙丙丁戊\n'),
          reason: '用制表符缩进与用空格缩进应当得到同一篇文档');
      expect(html('- 甲\n\n\t乙丙丁戊\n'), contains('乙丙丁戊'));
    });

    test('under a numbered step, where the indent is wider', () {
      // `1. ` is three columns, so three characters used to go.
      expect(html('1. 甲\n\n\t乙丙丁戊\n'), contains('乙丙丁戊'));
    });

    test('a fence under an item is still a fence, with its code intact', () {
      final out = html('- 甲\n\n\t```dart\n\tvar x = 1;\n\t```\n');
      expect(out, contains('<pre><code'), reason: '围栏没被认出来');
      expect(out, contains('var'), reason: '代码开头的字符被吃掉了');
    });

    test('a continuation line with no blank line before it', () {
      expect(html('- 甲\n\t乙丙丁戊\n'), contains('乙丙丁戊'));
    });
  });

  group('what must not change', () {
    test('space-indented content is untouched', () {
      expect(shape('- 甲\n\n  乙丙丁戊\n'),
          '<ul><li><p>甲</p><p>乙丙丁戊</p></li></ul>');
    });

    test('a tab-indented sub-list is still a sub-list', () {
      final out = html('- 甲\n\t- 乙\n');
      expect('<ul>'.allMatches(out).length, 2);
      expect(out, contains('乙'));
    });

    test('four columns of indent is still code, tab or spaces', () {
      expect(html('正文\n\n\tvar x = 1;\n'), contains('<pre><code'));
      expect(html('正文\n\n    var x = 1;\n'), contains('<pre><code'));
    });
  });
}

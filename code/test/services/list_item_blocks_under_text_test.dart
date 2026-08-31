import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// A block written under a list item, with no blank line before it.
///
/// This is how install steps are written everywhere:
///
///     - install the dependencies
///       ```bash
///       npm i
///       ```
///
/// The item's own text used to run to the first blank line, so with no blank
/// line the fence was folded into the sentence and read as inline markup: the
/// block came out as a code *span* holding the language name and the code
/// flattened onto one line. Leaving a blank line worked, which is what made
/// it look like a formatting preference rather than a bug.
void main() {
  String html(String md) =>
      MarkdownParser().parse(md).map(ExportService.nodeToHtml).join();

  group('a fence under an item is a code block', () {
    test('under a bullet', () {
      final out = html('- 安装依赖\n  ```bash\n  npm i\n  ```\n- 完成\n');
      expect(out, contains('<pre><code'));
      expect(out, contains('npm i'));
      expect(out, isNot(contains('`')), reason: '围栏漏成了文字');
      expect(out, isNot(contains('>bash')), reason: '语言名混进了正文');
    });

    test('under a numbered step', () {
      final out = html('1. 安装依赖\n   ```bash\n   npm i\n   ```\n2. 完成\n');
      expect(out, contains('<pre><code'));
      expect(out, contains('npm i'));
    });

    test('under a task', () {
      final out = html('- [ ] 待办\n  ```sh\n  cmd\n  ```\n');
      expect(out, contains('<pre><code'));
      expect(out, contains('cmd'));
    });

    test('under an item that is itself nested', () {
      final out = html('- 甲\n  - 乙\n    ```js\n    x\n    ```\n');
      expect(out, contains('<pre><code'));
      expect(out, contains('>x<'));
    });

    test('and still does with a blank line, as it always did', () {
      final out = html('- 安装依赖\n\n  ```bash\n  npm i\n  ```\n');
      expect(out, contains('<pre><code'));
    });
  });

  group('the other blocks an item can carry', () {
    test('a quote keeps its quoting', () {
      final out = html('- 注意\n  > 这里有坑\n- 继续\n');
      expect(out, contains('<blockquote>'));
      expect(out, isNot(contains('&gt;')), reason: '引用标记漏成了文字');
    });

    test('a heading is a heading', () {
      expect(html('- 步骤\n  # 小标题\n- 完成\n'), contains('<h1>小标题</h1>'));
    });
  });

  group('what must not change', () {
    test('a hard-wrapped item is still one sentence', () {
      // The commonest continuation of all: the rest of the sentence on the
      // next line. It must not be cut off into a block.
      expect(html('- 这是一句很长的话\n  继续写在下一行\n- 第二项\n'),
          contains('这是一句很长的话 继续写在下一行'));
    });

    test('a nested list is still nested', () {
      final out = html('- 甲\n  - 乙\n  - 丙\n');
      expect('<ul>'.allMatches(out).length, 2);
      expect('<li>'.allMatches(out).length, 3);
    });

    test('a plain list is untouched', () {
      expect(html('- 甲\n- 乙\n'), '<ul>\n  <li>甲</li>\n  <li>乙</li>\n</ul>');
    });
  });
}

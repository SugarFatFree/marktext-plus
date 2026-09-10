import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// A code fence written under a list item, holding something that looks like
/// a list item.
///
/// The list collector asked one question of every line — "does this start an
/// item?" — and a line inside a fence can answer yes. So a step explaining
/// list syntax in a code block came apart: the fence became two empty code
/// blocks and its contents were promoted to real items. Everything else
/// inside such a fence was already safe, because the branch that swallows an
/// indented line into the current item catches a heading or a quote; only a
/// list marker reached the branch above it.
///
/// The visible half is on a task list. The preview drew a tickable box for a
/// line of code, and ticking it rewrote the code block instead of the task —
/// see `task_toggle_test`.
///
/// Documenting Markdown inside Markdown is ordinary; this project's own README
/// does it on every page.
void main() {
  final parser = MarkdownParser();

  /// The items of the first list, and the raw text of each item's own blocks.
  (List<String>, List<String>) shapeOf(String source) {
    for (final node in parser.parse(source)) {
      if (node is ListNode) {
        return (
          [for (final item in node.items) item.content],
          [
            for (final item in node.items)
              for (final child in item.children) child.rawContent,
          ],
        );
      }
    }
    return (const [], const []);
  }

  test('a fenced list marker stays code', () {
    final (items, blocks) = shapeOf('- 一\n  ```\n  - 假的\n  ```\n- 二\n');
    expect(items, ['一', '二'], reason: '围栏里的那一行不是列表项');
    expect(blocks, ['- 假的'], reason: '它是第一项底下那个代码块的内容');
  });

  test('a fenced task marker stays code', () {
    final (items, blocks) =
        shapeOf('- [ ] 一\n  ```\n  - [ ] 假的\n  ```\n- [ ] 二\n');
    expect(items, ['一', '二']);
    expect(blocks, ['- [ ] 假的']);
  });

  test('what already worked still works', () {
    // A heading and a quote inside the same fence were never at risk: they do
    // not start a list item, so they fell through to the branch that keeps an
    // indented line with its item. Here so that a future fix to the branch
    // above does not take them with it.
    expect(shapeOf('- 一\n  ```\n  # 假标题\n  ```\n- 二\n').$2, ['# 假标题']);
    expect(shapeOf('- 一\n  ```\n  > 假引用\n  ```\n- 二\n').$2, ['> 假引用']);
    expect(shapeOf('- 一\n  ```\n  code\n  ```\n- 二\n').$2, ['code']);
  });

  test('a real nested item is still an item', () {
    // The other way to get this wrong: swallowing every indented line and
    // losing nesting altogether.
    final (items, _) = shapeOf('- 一\n  - 真的嵌套\n- 二\n');
    expect(items, ['一', '真的嵌套', '二']);
  });

  test('the closing rule is the same one the rest of the parser uses', () {
    // Same character, at least as long, nothing after it — so a shorter run
    // inside a longer fence is content, and a fence with an info string does
    // not close anything.
    expect(
      shapeOf('- 一\n  ````\n  ```\n  - 假的\n  ```\n  ````\n- 二\n').$2,
      ['```\n- 假的\n```'],
    );
    expect(shapeOf('- 一\n  ~~~\n  - 假的\n  ~~~\n- 二\n').$2, ['- 假的']);
  });

  test('a fence at the left margin is left to the block parser', () {
    // Not this function's business, and not changed by the fix: only an
    // indented opener belongs to an item.
    final nodes = parser.parse('```\n- 假的\n```\n');
    expect(nodes.single, isA<CodeBlockNode>());
    expect(nodes.single.rawContent, '- 假的');
  });
}

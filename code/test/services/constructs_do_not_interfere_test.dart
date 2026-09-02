import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// Each construct still works with the others around it.
///
/// The specification's corpus is one construct to an example, and a parser can
/// pass all of it while a document that puts two of them together comes out
/// wrong. That is not hypothetical: a quotation anywhere above a reference
/// link used to wipe every link definition in the document, because a quote's
/// contents are parsed by asking the parser to parse again and the nested call
/// emptied what the outer one had collected. The corpus scored the same before
/// and after that fix — 493 — because no example holds both.
///
/// So: every construct beside every other, and beside every other pair.
void main() {
  String html(String md) =>
      MarkdownParser().parse(md).map(ExportService.nodeToHtml).join();

  /// Each construct's source, and something its output must contain.
  ///
  /// The marks are deliberately loose — the text a construct carries rather
  /// than the exact tags around it — because two adjacent lists join into one
  /// loose list, which is correct and changes `<li>x</li>` into
  /// `<li><p>x</p></li>`. A mark that tight would fail on correct output.
  const pieces = <String, (String, String)>{
    '标题': ('# 标题甲\n', '<h1>标题甲</h1>'),
    '段落': ('一段普通正文。\n', '<p>一段普通正文。</p>'),
    '引用': ('> 引用一句。\n', '<blockquote>'),
    '引用带续行': ('> 引用第一行\n引用续行。\n', '<blockquote>'),
    '无序列表': ('- 项甲\n- 项乙\n', '项甲'),
    '有序列表': ('1. 步甲\n2. 步乙\n', '步甲'),
    '任务列表': ('- [ ] 待办甲\n', 'type="checkbox"'),
    '列表带块': ('- 项甲\n\n  第二段\n', '第二段'),
    '围栏代码': ('```dart\nvar y = 2;\n```\n', '<pre><code'),
    '缩进代码': ('正文\n\n    var z = 3;\n', '<pre><code'),
    '表格': ('| 甲 | 乙 |\n|---|---|\n| a | b |\n', '<table>'),
    '分隔线': ('---\n', '<hr>'),
    '行内链接': ('见 [行内](/inline)。\n', 'href="/inline"'),
    '引用式链接': ('见 [引用式][refx]。\n\n[refx]: /refx\n', 'href="/refx"'),
    '图片': ('![图](/img.png)\n', '<img src="/img.png"'),
    '脚注': ('正文[^n1]\n\n[^n1]: 脚注内容\n', '脚注内容'),
    '数学块': (r'$$' '\n' r'x^2' '\n' r'$$' '\n', 'math-block'),
    'HTML 注释': ('<!-- 注释 -->\n', '<!-- 注释 -->'),
    '设置式标题': ('标题乙\n===\n', '<h1>标题乙</h1>'),
  };

  final names = pieces.keys.toList();

  test('every construct beside every other, and every other pair', () {
    final broken = <String>[];
    for (final a in names) {
      for (final b in names) {
        for (final c in names) {
          if (a == b || b == c || a == c) continue;
          final out = html('${pieces[a]!.$1}\n${pieces[b]!.$1}\n'
              '${pieces[c]!.$1}');
          for (final piece in [a, b, c]) {
            if (!out.contains(pieces[piece]!.$2)) {
              broken.add('$a + $b + $c 里，「$piece」不见了');
            }
          }
        }
      }
    }
    expect(broken.take(10), isEmpty,
        reason: '${broken.length} 个组合里有构件被旁边的构件弄坏了');
  });

  test('front matter opens the document, and lets the rest through', () {
    // It is front matter only at the very top, which is why it is not in the
    // sweep above: anywhere else it is a rule and a paragraph, correctly.
    const frontMatter = '---\ntitle: 甲\n---\n';
    for (final name in names) {
      final out = html('$frontMatter\n${pieces[name]!.$1}');
      expect(out, contains('front-matter'), reason: '$name 之前的前置元数据没了');
      expect(out, contains(pieces[name]!.$2),
          reason: '前置元数据把后面的「$name」弄坏了');
    }
  });

  test('front matter written lower down is not front matter', () {
    final out = html('一段正文。\n\n---\ntitle: 甲\n---\n');
    expect(out, isNot(contains('front-matter')));
  });
}

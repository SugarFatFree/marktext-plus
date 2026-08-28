import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

void main() {
  test('nested', () {
    const cases = {
      '项内代码块': '1. 第一步\n\n   ```bash\n   run me\n   ```\n\n2. 第二步\n',
      '项内多段落': '- 一段\n\n  二段\n\n- 下一项\n',
      '项内引用': '- 项目\n\n  > 引用\n\n- 下一项\n',
      '项内表格': '- 项目\n\n  | a | b |\n  |---|---|\n  | 1 | 2 |\n',
      '项内续行': '- 第一行\n  接着写\n- 第二项\n',
      '普通松散': '- 一\n\n- 二\n',
      '普通紧凑': '- 一\n- 二\n',
      '嵌套子列表': '- 一\n  - 甲\n- 二\n',
    };
    for (final e in cases.entries) {
      final ast = MarkdownParser().parse(e.value);
      final desc = ast.map((n) {
        if (n is ListNode) {
          return 'List(${n.items.map((i) => '"${i.content}"'
              '${i.children.isEmpty ? "" : "+[${i.children.map((c) => c.type.name).join(",")}]"}').join(" ")})';
        }
        return n.type.name;
      }).join(' | ');
      debugPrint('${e.key.padRight(10)} → $desc');
    }
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('edit menu copy and cut publish the rich clipboard flavour', () {
    final source = File('lib/ui/widgets/app_menu_bar.dart').readAsStringSync();
    expect(
      'RichCopyService.htmlForMarkdownSelection(selected)'.allMatches(source),
      hasLength(2),
      reason: '复制和剪切菜单必须都保留 Markdown 的富文本格式',
    );
    expect(
      'ClipboardService.copyWithHtml(selected, html)'.allMatches(source),
      hasLength(2),
    );
  });
}

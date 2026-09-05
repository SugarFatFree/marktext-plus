import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('edit menu copy and cut publish the rich clipboard flavour', () {
    final source = File('lib/ui/widgets/app_menu_bar.dart').readAsStringSync();
    // The call and its arguments, not a literal spelling of them: pinning the
    // exact text made this fail the moment the argument list wrapped onto
    // more than one line, which says nothing about whether copy still copies.
    final calls = RegExp(
      r'RichCopyService\.htmlForMarkdownSelection\((?:[^()]|\([^()]*\))*\)',
    ).allMatches(source).toList();
    expect(
      calls,
      hasLength(2),
      reason: '复制和剪切菜单必须都保留 Markdown 的富文本格式',
    );
    // The reader's own switch, at both call sites. This asked for inline HTML
    // unconditionally, so with the switch off `<b>x</b>` was literal text in
    // the preview and arrived in Word as bold.
    for (final call in calls) {
      final text = call.group(0)!;
      expect(text, contains('enableHtml:'),
          reason: '两处都要把读者的设置传下去');
      // Present is not enough — `enableHtml: true` is exactly the bug this
      // guards against, and it contains the word. What it may not be is a
      // literal.
      expect(text, isNot(matches(RegExp(r'enableHtml:\s*(true|false)'))),
          reason: '写死任一字面值都等于无视读者的开关');
    }
    expect(
      'ClipboardService.copyWithHtml(selected, html)'.allMatches(source),
      hasLength(2),
    );
  });
}

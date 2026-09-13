import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Copy and cut both publish the rich flavour, with the reader's own switch.
///
/// A cut that pastes as plain text where a copy pastes as rich text is one
/// editor with two clipboards. And asking for inline HTML unconditionally made
/// `<b>x</b>` literal text in the preview and bold in Word, whatever the reader
/// had set.
///
/// Both files, because cut moved: the Edit menu carried out its own cut — its
/// own rich copy, its own splice, and no restore point — and now asks the
/// editor, where the one implementation lives. This guard was pinned to the
/// menu alone and went red when the code moved, which is the guard working.
/// Pinning it to *where* the call is would make it fail again on the next move;
/// pinning it to *every* call, and then to the two places that must have one,
/// does not.
void main() {
  const files = [
    'lib/ui/widgets/app_menu_bar.dart',
    'lib/ui/editor/source_editor.dart',
  ];

  /// Every `htmlForMarkdownSelection(...)` call in [path], arguments included.
  ///
  /// The call and its arguments, not a literal spelling of them: pinning the
  /// exact text made this fail the moment the argument list wrapped onto more
  /// than one line, which says nothing about whether copy still copies.
  List<String> richCalls(String path) => RegExp(
        r'RichCopyService\.htmlForMarkdownSelection\((?:[^()]|\([^()]*\))*\)',
      )
          .allMatches(File(path).readAsStringSync())
          .map((m) => m.group(0)!)
          .toList();

  test('every rich copy passes the reader\'s inline-HTML switch', () {
    final calls = [for (final f in files) ...richCalls(f)];
    expect(calls, isNotEmpty, reason: '一个调用都没扫到，这条守卫已失效');

    for (final call in calls) {
      expect(call, contains('enableHtml:'),
          reason: '每一处都要把读者的设置传下去：$call');
      // Present is not enough — `enableHtml: true` is exactly the bug this
      // guards against, and it contains the word. What it may not be is a
      // literal.
      expect(call, isNot(matches(RegExp(r'enableHtml:\s*(true|false)'))),
          reason: '写死任一字面值都等于无视读者的开关：$call');
    }
  });

  test('the menu still copies richly', () {
    final menu = File(files.first).readAsStringSync();
    expect(richCalls(files.first), hasLength(1),
        reason: '菜单里的复制不再发布富文本了');
    expect('ClipboardService.copyWithHtml(selected, html)'.allMatches(menu),
        hasLength(1));
  });

  test('cut copies richly before it takes anything out', () {
    // The `cut` case of the editor's own switch, from its label to the next
    // one: the rich copy has to be inside it, or cutting publishes plain text.
    final editor = File(files.last).readAsStringSync();
    final start = editor.indexOf('case FormatAction.cut:');
    expect(start, greaterThan(-1), reason: '找不到 cut 分支，取法要跟着改');
    final body = editor.substring(
      start,
      editor.indexOf('case FormatAction.', start + 10),
    );

    expect(body, contains('RichCopyService.htmlForMarkdownSelection'),
        reason: '剪切没有发布富文本，粘贴到 Word 里会变成纯文本');
    expect(body, contains('ClipboardService.copyWithHtml'),
        reason: '剪切没有把两种格式都放上剪贴板');
    expect(body, contains('pushHistory'),
        reason: '剪切没有压还原点，一次 Ctrl+Z 会退过它');
  });
}

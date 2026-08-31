import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// The line numbers beside the source, and the lines they number.
///
/// The gutter was a scrolling list of equal-height rows, one per line of
/// source. That is only right while no line wraps — and a paragraph in
/// Markdown is normally a single long line, so it wraps as a matter of
/// course. One wrapped paragraph put the numbers 153 pixels out of step with
/// the text, and there is no setting to turn the gutter off.
void main() {
  late Directory configDir;

  setUp(() {
    // createTempSync, not the async form: testWidgets runs inside a FakeAsync
    // zone where a dart:io future never completes.
    configDir = Directory.systemTemp.createTempSync('gutter_alignment');
  });
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<void> show(WidgetTester tester, String content) async {
    tester.view.physicalSize = const Size(700, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith((ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(),
          )),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SourceEditor(tabId: 't', initialContent: content),
          ),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// Where the text of [needle] is drawn, on screen.
  double textTop(WidgetTester tester, String content, String needle) {
    final field = tester.renderObject<RenderBox>(find.byType(EditableText));
    final rendered =
        tester.state<EditableTextState>(find.byType(EditableText)).renderEditable;
    final caret = rendered.getLocalRectForCaret(
      TextPosition(offset: content.indexOf(needle)),
    );
    return field.localToGlobal(Offset(0, caret.top)).dy;
  }

  /// Where the number [n] is drawn, on screen.
  double gutterTop(WidgetTester tester, String n) {
    final found = find.text(n);
    expect(found, findsOneWidget, reason: '行号 $n 不在屏幕上');
    return tester.renderObject<RenderBox>(found).localToGlobal(Offset.zero).dy;
  }

  testWidgets('a wrapped paragraph does not shift the numbers under it',
      (tester) async {
    final long = '这是一段很长的中文段落，' * 20;
    final content = ['第一行', long, '第三行', '第四行'].join('\n');
    await show(tester, content);

    // The wrapped line is line 2; what matters is everything after it.
    for (final probe in [('第一行', '1'), ('第三行', '3'), ('第四行', '4')]) {
      expect(gutterTop(tester, probe.$2),
          closeTo(textTop(tester, content, probe.$1), 1.0),
          reason: '${probe.$1} 与行号 ${probe.$2} 没有对齐');
    }
  });

  testWidgets('and neither does a document where nothing wraps',
      (tester) async {
    final content = List.generate(12, (i) => '第 ${i + 1} 行').join('\n');
    await show(tester, content);

    for (final n in [1, 5, 12]) {
      expect(gutterTop(tester, '$n'),
          closeTo(textTop(tester, content, '第 $n 行'), 1.0));
    }
  });

  testWidgets('they stay lined up after scrolling', (tester) async {
    final long = '这是一段很长的中文段落，' * 12;
    final content = [
      for (var i = 1; i <= 40; i++) i % 4 == 0 ? long : '第 $i 行',
    ].join('\n');
    await show(tester, content);

    await tester.drag(find.byType(EditableText), const Offset(0, -400));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Whichever plain lines are on screen now must still be beside their
    // numbers.
    var checked = 0;
    for (var i = 1; i <= 40; i++) {
      if (i % 4 == 0) continue;
      if (find.text('$i').evaluate().length != 1) continue;
      expect(gutterTop(tester, '$i'),
          closeTo(textTop(tester, content, '第 $i 行'), 1.0),
          reason: '滚动后第 $i 行与它的行号错开了');
      checked++;
    }
    expect(checked, greaterThan(2), reason: '滚动后几乎没有行号在屏幕上，这条没测到东西');
  });

  testWidgets('a long document only draws the numbers on screen',
      (tester) async {
    final content = List.generate(5000, (i) => '第 ${i + 1} 行').join('\n');
    await show(tester, content);

    final numbers = find.descendant(
      of: find.byType(Stack),
      matching: find.byType(Text),
    );
    expect(numbers.evaluate().length, lessThan(120),
        reason: '五千行的文档把所有行号都建出来了');
  });
}

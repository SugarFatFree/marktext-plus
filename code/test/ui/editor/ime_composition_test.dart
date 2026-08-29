import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';
import 'package:marktext_plus/ui/widgets/slash_menu.dart';

/// Typing through an input method.
///
/// A pinyin or kana IME rewrites the text on every keystroke while the reader
/// is still choosing a candidate — `hao`, `hao,`, `hao,s` — and only the final
/// choice is what they meant to type. Upstream MarkText states the rule as
/// "commits text only after compositionend", and gives it three tests.
///
/// This matters here beyond history: every feature that watches the text was
/// watching the candidates too.
void main() {
  late Directory configDir;
  late ProviderContainer container;
  var tabCounter = 0;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('ime');
    container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          AppConfig(),
        ),
      ),
    ]);
  });
  tearDown(() {
    container.dispose();
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<TextEditingController> editor(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SourceEditor(tabId: 'tab-${tabCounter++}')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.widget<TextField>(find.byType(TextField)).controller!;
  }

  /// Types [candidates] as an IME does — each with a composing range — and
  /// then commits [committed].
  Future<void> compose(
    WidgetTester tester,
    TextEditingController controller,
    List<String> candidates,
    String committed,
  ) async {
    for (final candidate in candidates) {
      controller.value = TextEditingValue(
        text: candidate,
        selection: TextSelection.collapsed(offset: candidate.length),
        composing: TextRange(start: 0, end: candidate.length),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    controller.value = TextEditingValue(
      text: committed,
      selection: TextSelection.collapsed(offset: committed.length),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('undo offers what was committed, not the candidates',
      (tester) async {
    final controller = await editor(tester);
    // A candidate string containing punctuation, which is what made the
    // word-boundary rule record it.
    await compose(tester, controller, ['h', 'ha', 'hao', 'hao,'], '你好');
    expect(controller.text, '你好');

    container.read(editorProvider.notifier).undo();
    await tester.pump();
    expect(controller.text, '',
        reason: '撤销拿回了一段输入法候选串，那不是读者打出来的东西');
  });

  testWidgets('a pause mid-composition does not record the half-word',
      (tester) async {
    final controller = await editor(tester);
    // The reader stops to look at the candidate list; the debounce fires.
    controller.value = const TextEditingValue(
      text: 'nihao',
      selection: TextSelection.collapsed(offset: 5),
      composing: TextRange(start: 0, end: 5),
    );
    await tester.pump(const Duration(milliseconds: 500));

    controller.value = const TextEditingValue(
      text: '你好',
      selection: TextSelection.collapsed(offset: 2),
    );
    await tester.pump(const Duration(milliseconds: 400));

    container.read(editorProvider.notifier).undo();
    await tester.pump();
    expect(controller.text, isNot('nihao'));
  });

  testWidgets('a slash among the candidates does not open the insert menu',
      (tester) async {
    final controller = await editor(tester);
    controller.value = const TextEditingValue(
      text: '/',
      selection: TextSelection.collapsed(offset: 1),
      composing: TextRange(start: 0, end: 1),
    );
    await tester.pump();

    expect(find.byType(SlashMenu), findsNothing,
        reason: '正在选字时弹出插入菜单，会把候选窗口挡住');
  });

  testWidgets('committed text still behaves normally afterwards',
      (tester) async {
    // The suppression must not outlive the composition, or nothing typed
    // after an IME word would ever be recorded again.
    final controller = await editor(tester);
    await compose(tester, controller, ['ni', 'nihao'], '你好');

    controller.value = const TextEditingValue(
      text: '你好，世界',
      selection: TextSelection.collapsed(offset: 5),
    );
    await tester.pump(const Duration(milliseconds: 400));

    container.read(editorProvider.notifier).undo();
    await tester.pump();
    expect(controller.text, '你好');
  });
}

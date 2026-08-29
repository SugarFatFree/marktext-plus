import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// Which blocks are left out of the preview's double-tap-to-edit wrapper.
///
/// The wrapper puts a double-tap recogniser in the gesture arena, and a
/// recogniser there holds on for the double-tap timeout before conceding — so
/// anything with tap targets of its own (a checkbox, a diagram's toolbar) sits
/// dead for about 300 ms, which reads as a click that did nothing.
///
/// The rule was written twice as "the node *is* a task list" and "the node
/// *is* a diagram", and both times a quote or a list item carrying one was
/// still wrapped: the same fix, made and then not carried to the block one
/// level up. Hence a test on the shapes rather than on the two nodes.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('tap_exempt'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<int> wrappedBlocks(WidgetTester tester, String markdown) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(
              ConfigService(configDir: configDir.path),
              AppConfig(),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MarkdownRenderer(
              markdown: markdown,
              onSourceChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return find.byType(PreviewEditableBlock).evaluate().length;
  }

  testWidgets('a task list is exempt wherever it is written', (tester) async {
    for (final source in [
      '- [ ] 一\n- [x] 二\n',
      '> - [ ] 一\n> - [x] 二\n',
      '- 步骤\n\n  - [ ] 子任务\n',
    ]) {
      expect(await wrappedBlocks(tester, source), 0, reason: source);
    }
  });

  testWidgets('a diagram is exempt wherever it is written', (tester) async {
    for (final source in [
      '```mermaid\ngraph TD\n  A-->B\n```\n',
      '> ```mermaid\n> graph TD\n>   A-->B\n> ```\n',
      '- 步骤\n\n  ```mermaid\n  graph TD\n    A-->B\n  ```\n',
    ]) {
      expect(await wrappedBlocks(tester, source), 0, reason: source);
    }
  });

  testWidgets('ordinary blocks are still wrapped, or nothing is editable',
      (tester) async {
    // The exemption has to stay narrow: if it grew to cover everything, the
    // preview would quietly stop being editable at all.
    expect(await wrappedBlocks(tester, '一段文字\n'), 1);
    expect(await wrappedBlocks(tester, '# 标题\n\n一段文字\n'), 2);
    expect(await wrappedBlocks(tester, '> 引用的话\n'), 1);
    expect(await wrappedBlocks(tester, '- 普通项\n- 另一项\n'), 1);
    expect(await wrappedBlocks(tester, '```dart\nvoid main() {}\n```\n'), 1);
  });

  testWidgets('a document with both keeps each rule to itself', (tester) async {
    // One paragraph wrapped, the task list and the diagram left alone.
    expect(
      await wrappedBlocks(
        tester,
        '一段文字\n\n- [ ] 任务\n\n```mermaid\ngraph TD\n  A-->B\n```\n',
      ),
      1,
    );
  });
}

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

/// Ticking a checkbox in the preview, which rewrites the document.
///
/// The item's line is found by counting list-item lines in the block's own
/// source. A list inside a quote arrives with its `>` markers still attached —
/// they have to be written back — and testing those lines as they stood found
/// no list items at all, so the index stayed at -1 and ticking a box inside a
/// quote did nothing: no change, no error, no sign anything had been asked.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('task_toggle'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<List<String>> tapCheckbox(
    WidgetTester tester,
    String markdown,
    int which,
  ) async {
    final writes = <String>[];
    tester.view.physicalSize = const Size(1000, 900);
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
              onSourceChanged: writes.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boxes = find.byType(Checkbox);
    expect(boxes, findsWidgets, reason: '没有渲染出复选框');
    await tester.tap(boxes.at(which));
    // Settled only — no extra time granted. A checkbox that needs the
    // double-tap timeout to expire before it answers is one the reader has
    // already clicked twice.
    await tester.pumpAndSettle();
    return writes;
  }

  testWidgets('ticking a plain task writes the box back', (tester) async {
    final writes = await tapCheckbox(tester, '- [ ] 一\n- [ ] 二\n', 0);
    expect(writes, ['- [x] 一\n- [ ] 二\n']);
  });

  testWidgets('the second item is the one that changes', (tester) async {
    final writes = await tapCheckbox(tester, '- [ ] 一\n- [ ] 二\n', 1);
    expect(writes, ['- [ ] 一\n- [x] 二\n']);
  });

  testWidgets('unticking writes an empty box back', (tester) async {
    final writes = await tapCheckbox(tester, '- [x] 一\n', 0);
    expect(writes, ['- [ ] 一\n']);
  });

  testWidgets('a task inside a quote can be ticked', (tester) async {
    final writes = await tapCheckbox(tester, '> - [ ] 一\n> - [ ] 二\n', 1);
    expect(writes, ['> - [ ] 一\n> - [x] 二\n'],
        reason: '引用里的复选框点了没反应，而且没有任何提示');
  });

  testWidgets('a nested task is found by its own position', (tester) async {
    final writes = await tapCheckbox(tester, '- [ ] 父\n  - [ ] 子\n', 1);
    expect(writes, ['- [ ] 父\n  - [x] 子\n']);
  });

  testWidgets('brackets in the text are not mistaken for the box',
      (tester) async {
    final writes = await tapCheckbox(tester, '- [ ] 修 [ ] 的显示\n', 0);
    expect(writes, ['- [x] 修 [ ] 的显示\n'],
        reason: '改到了正文里的方括号');
  });

  testWidgets('the rest of the document is untouched', (tester) async {
    final writes = await tapCheckbox(
      tester,
      '# 标题\n\n- [ ] 一\n\n正文段落\n',
      0,
    );
    expect(writes.single, '# 标题\n\n- [x] 一\n\n正文段落\n');
  });
}

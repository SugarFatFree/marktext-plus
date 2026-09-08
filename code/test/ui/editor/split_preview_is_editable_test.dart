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
import 'package:marktext_plus/ui/editor/split_editor.dart';

/// The preview half of a split is the preview, not a picture of it.
///
/// It renders the same widget as preview mode but was handed no way to write
/// back, so a checkbox there did nothing and a block could not be opened for
/// editing — the same document, the same click, a different answer depending
/// on which mode the reader was in. The comment in `split_editor.dart` records
/// exactly that.
///
/// It was fixed by passing `onSourceChanged`, and nothing held it: removing
/// that one argument put the pane back to read-only with the whole suite
/// green. `task_toggle_test` covers the ticking itself in preview mode; this
/// covers the half that was left out.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('split_edit'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  testWidgets('ticking a box in the split preview rewrites the document', (
    tester,
  ) async {
    final writes = <String>[];
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(editMode: EditMode.split),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

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
          home: Scaffold(
            body: SplitEditor(
              initialContent: '- [ ] 一\n- [ ] 二\n',
              tabId: 'split-edit',
              onChanged: writes.add,
            ),
          ),
        ),
      ),
    );
    // Pumped rather than settled: the preview fills itself in from post-frame
    // callbacks and never goes quiet.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final boxes = find.byType(Checkbox);
    expect(boxes, findsWidgets, reason: '分屏里的预览没有画出复选框');

    await tester.tap(boxes.first, warnIfMissed: false);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(
      writes.last,
      contains('- [x] 一'),
      reason: '分屏模式下点了复选框没有写回文档——这个窗格又变回只读了',
    );

    // The source half hears about the change from a post-frame callback,
    // because telling it inline is the lifecycle violation described above.
    // If that callback stops running, the source pane holds the new text
    // while the editor state never hears of it: the status bar keeps showing
    // the old caret position, and the tick is missing from the undo history,
    // so Ctrl+Z steps past it to somewhere the reader never was.
    expect(
      container.read(editorProvider).canUndo,
      isTrue,
      reason: '在预览里勾掉一项之后 Ctrl+Z 撤不回来——这一步没有进历史',
    );
  });
}

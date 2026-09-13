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
import 'package:marktext_plus/ui/widgets/find_replace_bar.dart';

/// One replacement, one undo.
///
/// Both Replace buttons write straight to the editor's controller, which is the
/// path typing takes, and that path records history on a 300 ms debounce. So a
/// run of replacements faster than that arrived as a single entry — and only the
/// last state — so one Ctrl+Z took back the whole run. Pressing Replace over and
/// over is the designed way to walk a document, which is precisely when the
/// window is open.
///
/// Two other bulk edits in the editor already do this and one of them says why
/// beside it: `_moveBlock` and the table edits push the text before writing the
/// new one. This was the sibling that did not.
///
/// What these cannot show: that the snapshot is of the text *before* the
/// replacement rather than after it. Without the editor's debounce in the tree
/// the two are provably the same — each push closes the step either way, and the
/// value one push records is the value the next one would have — so mutating
/// `before` to `after` leaves these green. The difference is only in the
/// debounce window: text typed within 300 ms has not been recorded, and only the
/// before-text preserves it. Showing that needs a real [SourceEditor] beside the
/// bar, and the bar wants a `rawContent` that keeps step with the controller,
/// which the two of them only do inside the screen that builds both. Written
/// down rather than half-tested.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('replace_undo'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  /// The bar, aimed at a source pane holding [text], with the history pointed
  /// at the same place a source editor would point it.
  Future<(ProviderContainer, TextEditingController)> pump(
    WidgetTester tester,
    String text,
  ) async {
    final controller = TextEditingController(text: text);
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(editorProvider.notifier).setSearchTarget(SearchTarget.source);
    // What the source editor does when it is built: the document's first state
    // is on the stack, and the controller is the thing holding the text.
    container.read(editorProvider.notifier)
      ..setController(controller)
      ..pushHistory(text);

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
            body: FindReplaceBar(
              textController: controller,
              rawContent: text,
              isSplitMode: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return (container, controller);
  }

  /// Types [what] in the find field and opens the replace row.
  Future<void> searchFor(WidgetTester tester, String what, String with_) async {
    await tester.enterText(find.byType(TextField).first, what);
    await tester.pump();
    final toggle = find.byIcon(Icons.expand_more);
    if (toggle.evaluate().isNotEmpty) {
      await tester.tap(toggle);
      await tester.pump();
    }
    await tester.enterText(find.byType(TextField).at(1), with_);
    await tester.pump();
  }

  Future<void> press(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(TextButton, label));
    await tester.pump();
  }

  /// Undo the way the editor does: the controller holds the newest text, so the
  /// notifier restores into it and answers null.
  void undo(ProviderContainer c) =>
      c.read(editorProvider.notifier).undo();

  testWidgets('three quick replacements come back one at a time',
      (tester) async {
    final (c, controller) = await pump(tester, 'one one one\n');
    await searchFor(tester, 'one', 'two');

    // No pump between them, which is the case: the debounce that would have
    // recorded each state has not fired for any of them.
    await press(tester, 'Replace');
    await press(tester, 'Replace');
    expect(controller.text, 'two two one\n', reason: '替换本身没生效，这条测不到撤销');

    undo(c);
    expect(controller.text, 'two one one\n', reason: '一次退回了两处替换');
    undo(c);
    expect(controller.text, 'one one one\n');
  });

  testWidgets('replace all is one step of its own', (tester) async {
    final (c, controller) = await pump(tester, 'one one one\n');
    await searchFor(tester, 'one', 'two');

    await press(tester, 'Replace All');
    expect(controller.text, 'two two two\n');

    undo(c);
    expect(controller.text, 'one one one\n', reason: '全部替换退不回来');
  });

  testWidgets('a replacement after one all at once still steps back twice',
      (tester) async {
    // The realistic run: replace one term everywhere, then another, quickly.
    final (c, controller) = await pump(tester, 'a b\n');
    await searchFor(tester, 'a', 'x');
    await press(tester, 'Replace All');
    await tester.enterText(find.byType(TextField).first, 'b');
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), 'y');
    await tester.pump();
    await press(tester, 'Replace All');
    expect(controller.text, 'x y\n');

    undo(c);
    expect(controller.text, 'x b\n', reason: '两次全部替换被并成了一步');
    undo(c);
    expect(controller.text, 'a b\n');
  });
}

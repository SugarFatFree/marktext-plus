import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// Where the pane goes when something asks for a line.
///
/// Six things ask: the outline, the sidebar's search results, a click in the
/// preview, and the find bar when the preview is the target. All of them hand
/// over a line number, which the pane turned into a pixel by multiplying by
/// `fontSize * lineHeight`. A pane narrower than its longest line — split
/// view, always — draws one document line as several visual ones, so the
/// answer is short by one line for every wrap above the target.
///
/// Typewriter mode has the same sum in it, and centres on the same number.
void main() {
  late Directory configDir;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('jumpline');
  });
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  // Every line is several times wider than the pane.
  const wide = 'wide text that will not fit inside this pane at all, no ';
  final document = List.generate(30, (i) => 'line $i $wide$wide').join('\n');

  Future<(ProviderContainer, ScrollableState)> open(
    WidgetTester tester, {
    bool typewriter = false,
  }) async {
    tester.view.physicalSize = const Size(700, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          AppConfig(editMode: EditMode.source, typewriterMode: typewriter),
        ),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SourceEditor(tabId: 'tab-a', initialContent: document),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (
      container,
      tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(SourceEditor),
              matching: find.byType(Scrollable),
            )
            .first,
      ),
    );
  }

  /// Where the first character of [line] (0-based) has actually been drawn,
  /// relative to the top of the viewport.
  double drawnTopOf(WidgetTester tester, int line) {
    final editable =
        tester.state<EditableTextState>(find.byType(EditableText)).renderEditable;
    var at = 0;
    for (var i = 0; i < line; i++) {
      at = document.indexOf('\n', at) + 1;
    }
    final caret = editable.getLocalRectForCaret(TextPosition(offset: at));
    final viewport = tester.getRect(find.byType(Scrollable).first);
    return editable.localToGlobal(Offset(0, caret.top)).dy - viewport.top;
  }

  testWidgets('a line asked for lands at the top of the viewport', (
    tester,
  ) async {
    final (container, scrollable) = await open(tester);
    // The outline hands over 1-based line numbers.
    container.read(editorProvider.notifier).scrollToLine(20);
    await tester.pumpAndSettle();

    expect(
      drawnTopOf(tester, 19),
      closeTo(0, 30),
      reason: 'line 20 was drawn ${drawnTopOf(tester, 19)} pixels from the '
          'top of the viewport, at scroll ${scrollable.position.pixels}',
    );
  });

  testWidgets('typewriter mode centres the line the caret is on', (
    tester,
  ) async {
    final (_, scrollable) = await open(tester, typewriter: true);
    final controller =
        tester.widget<TextField>(find.byType(TextField)).controller!;
    var at = 0;
    for (var i = 0; i < 19; i++) {
      at = document.indexOf('\n', at) + 1;
    }
    controller.selection = TextSelection.collapsed(offset: at);
    await tester.pumpAndSettle();

    final middle = scrollable.position.viewportDimension / 2;
    expect(
      drawnTopOf(tester, 19),
      closeTo(middle, 40),
      reason: 'the caret line was drawn ${drawnTopOf(tester, 19)} pixels down '
          'a viewport of ${scrollable.position.viewportDimension}',
    );
  });
  testWidgets('typewriter mode keeps the caret on screen on the last line', (
    tester,
  ) async {
    // Typewriter mode now stands in for `_showCaret`, so it has to do that job
    // too. The last line cannot be centred — there is nothing below it to
    // scroll — and the clamp is what has to leave the caret visible instead of
    // somewhere below the window.
    final (_, scrollable) = await open(tester, typewriter: true);
    final controller =
        tester.widget<TextField>(find.byType(TextField)).controller!;
    controller.selection =
        TextSelection.collapsed(offset: document.length);
    await tester.pumpAndSettle();

    final drawn = drawnTopOf(tester, 29);
    expect(drawn, greaterThanOrEqualTo(0));
    expect(
      drawn,
      lessThan(scrollable.position.viewportDimension),
      reason: 'the last line was drawn $drawn pixels down a viewport of '
          '${scrollable.position.viewportDimension}',
    );
  });
}

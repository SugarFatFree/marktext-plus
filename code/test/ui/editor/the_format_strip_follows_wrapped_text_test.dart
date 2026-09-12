import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';
import 'package:marktext_plus/ui/widgets/format_toolbar.dart';

/// Where the formatting strip lands when the lines above it wrap.
///
/// Its position was worked out as `line * lineHeight`, which counts document
/// lines. A pane narrower than its longest line — split view, always — turns
/// one document line into several visual ones, so every line below a wrapped
/// one is further down the screen than its number says. The strip is supposed
/// to sit just above the selection it belongs to.
void main() {
  late Directory configDir;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('fmtwrap');
  });
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<TextEditingController> open(WidgetTester tester, String initial) async {
    tester.view.physicalSize = const Size(700, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          AppConfig(editMode: EditMode.source),
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
            body: SourceEditor(tabId: 'tab-a', initialContent: initial),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // At a point, not at the field's centre: a document of several hundred
    // lines makes the field taller than the window, and its centre is off
    // screen — the tap lands nowhere and the field never takes focus, which
    // the strip requires.
    await tester.tapAt(const Offset(100, 40));
    await tester.pumpAndSettle();
    return tester.widget<TextField>(find.byType(TextField)).controller!;
  }

  testWidgets('the strip sits over the selection, not over its line number', (
    tester,
  ) async {
    // Three lines, each far wider than the pane, then the line to select on.
    const wide = 'wide text that will not fit inside the pane at all ';
    final document = '${'$wide$wide$wide\n' * 3}pick me up\n';
    final controller = await open(tester, document);

    final start = document.indexOf('pick me up');
    controller.selection =
        TextSelection(baseOffset: start, extentOffset: start + 4);
    await tester.pumpAndSettle();
    expect(find.byType(FormatToolbar), findsOneWidget);

    // Where that text has actually been drawn, asked of the field drawing it.
    final editable = tester
        .state<EditableTextState>(find.byType(EditableText))
        .renderEditable;
    final caret = editable.getLocalRectForCaret(TextPosition(offset: start));
    final selectionTop = editable.localToGlobal(Offset(0, caret.top)).dy;

    final strip = tester.getRect(find.byType(FormatToolbar));
    // Just above it: the strip's own height and a small gap, no more.
    expect(
      strip.bottom,
      closeTo(selectionTop, caret.height + 8),
      reason: 'the strip is at ${strip.top}–${strip.bottom} while the text it '
          'belongs to starts at $selectionTop',
    );
  });
  testWidgets('the strip does not drift down a long run of unwrapped lines', (
    tester,
  ) async {
    // Nothing wraps here, and the old arithmetic was still wrong: it worked
    // the vertical position out from the line number and then corrected for
    // the scroll offset by hand. Two things go wrong with that, and this does
    // not try to separate them — `line * fontSize * lineHeight` is 25.6 pixels
    // where the field draws its lines 26.0 apart (measured), and the hand-made
    // scroll correction does not match what the pane did. Together, on line
    // 550 of 600, the strip landed 13 744 pixels away from its selection.
    //
    // Line thirty would not have caught it: four tenths of a pixel a line is
    // 12 pixels there, inside any tolerance a strip this size can have.
    final document = '${List.generate(600, (i) => 'line $i').join('\n')}\n';
    final controller = await open(tester, document);

    final start = document.indexOf('\nline 550') + 1;
    controller.selection =
        TextSelection(baseOffset: start, extentOffset: start + 4);
    await tester.pumpAndSettle();
    expect(find.byType(FormatToolbar), findsOneWidget);

    final editable = tester
        .state<EditableTextState>(find.byType(EditableText))
        .renderEditable;
    final caret = editable.getLocalRectForCaret(TextPosition(offset: start));
    final selectionTop = editable.localToGlobal(Offset(0, caret.top)).dy;
    final strip = tester.getRect(find.byType(FormatToolbar));

    expect(
      strip.bottom,
      closeTo(selectionTop, caret.height + 8),
      reason: 'the strip is at ${strip.top}–${strip.bottom} while line 550 '
          'starts at $selectionTop',
    );
  });
}

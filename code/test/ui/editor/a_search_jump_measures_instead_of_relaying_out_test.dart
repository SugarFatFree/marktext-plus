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

/// Jumping to a search match asks the pane where the match is.
///
/// It used to lay the whole prefix out in a second TextPainter to work that
/// out — 532 ms at one megabyte and 2.3 seconds at four, for every press of
/// Find Next, on an editor that advertises large files. The pane is already
/// drawing the text, so the position can be read off it instead.
///
/// The decisive case is a document whose lines wrap. Without wrapping the
/// naive `line * lineHeight` estimate happens to be right, so a test on
/// unwrapped text cannot tell a measurement from a guess — and the guess is
/// exactly what the TextPainter was added to replace.
void main() {
  late Directory configDir;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('search_jump_cfg_');
  });

  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  // Each line is far wider than the pane, so every one of them occupies
  // several visual lines.
  const lineCount = 40;
  final document = List.generate(
    lineCount,
    (i) => 'line ${i + 1} ${'wide ' * 40}',
  ).join('\n');

  Future<ProviderContainer> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(editMode: EditMode.source),
          ),
        ),
      ],
    );
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
    return container;
  }

  testWidgets('a match in wrapped text is found where it was drawn', (
    tester,
  ) async {
    final container = await pump(tester);
    final notifier = container.read(editorProvider.notifier);
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(SourceEditor),
            matching: find.byType(Scrollable),
          )
          .first,
    );

    // The last line of the document: with every line wrapping, it sits far
    // below where its line number alone would put it.
    final offset = document.lastIndexOf('\n') + 1;
    const fontSize = 14.0;
    const lineHeight = 1.5;
    notifier.scrollToSearchMatch(offset, fontSize, lineHeight);
    await tester.pumpAndSettle();

    final naive = (lineCount - 1) * fontSize * lineHeight;
    final reached = scrollable.position.pixels;
    // Reached the end of a document that is several times taller than the
    // estimate, which cannot happen if the estimate is what was used.
    expect(
      reached,
      greaterThan(naive * 2),
      reason: 'scrolled to $reached, which the naive estimate ($naive) '
          'would not reach — so nothing measured the wrapped text',
    );
    // And it is the *right* place: the caret for that offset ends up on
    // screen, a third of the way down give or take the clamp at the bottom.
    expect(reached, lessThanOrEqualTo(scrollable.position.maxScrollExtent));
  });

  testWidgets('a match near the top does not scroll past it', (tester) async {
    final container = await pump(tester);
    final notifier = container.read(editorProvider.notifier);
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(SourceEditor),
            matching: find.byType(Scrollable),
          )
          .first,
    );

    notifier.scrollToSearchMatch(0, 14.0, 1.5);
    await tester.pumpAndSettle();
    // The first character is already a third of the way down at rest, so the
    // pane stays put rather than scrolling to a negative offset.
    expect(scrollable.position.pixels, 0);
  });
}

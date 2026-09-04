import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// The line numbers, once the pane is what scrolls.
///
/// They are drawn at the positions the text layout reports, and redrawn when
/// the pane moves. The pane moving is a different event from the field moving,
/// which is what used to happen, so this checks the numbers still follow.
void main() {
  late Directory configDir;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('gutter_cfg_');
  });

  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<ScrollableState> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(
              ConfigService(configDir: configDir.path),
              AppConfig(editMode: EditMode.source),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SourceEditor(
              tabId: 'tab-a',
              initialContent: List.generate(
                300,
                (i) => 'line ${i + 1}',
              ).join('\n'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(SourceEditor),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }

  testWidgets('the first line is numbered 1 before anything moves', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('scrolling the pane renumbers the gutter', (tester) async {
    // The numbers are positioned from the text layout and redrawn on scroll.
    // With the pane scrolling instead of the field, that is a different
    // notification — if nothing listens to it, line 1 stays at the top for
    // ever while the text moves away underneath.
    final scrollable = await pump(tester);
    expect(find.text('1'), findsOneWidget);

    scrollable.position.jumpTo(1200);
    await tester.pumpAndSettle();

    expect(find.text('1'), findsNothing, reason: '滚下去之后第 1 行不该还在行号栏里');
    // Some number well down the document is, instead.
    expect(
      find.byType(Text).evaluate().where((e) {
        final text = (e.widget as Text).data;
        final number = int.tryParse(text ?? '');
        return number != null && number > 20;
      }),
      isNotEmpty,
      reason: '行号没有跟着正文一起走',
    );
  });
}

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

/// The Replace buttons put back what the pattern captured.
///
/// `TextSearch.expandReplacement` is tested on its own, which says nothing about
/// whether the buttons call it: an expansion written and never reached is the
/// same as no expansion. This presses them.
///
/// Both buttons, because they are two code paths — Replace splices one range and
/// Replace All splices every range back to front — and a `$1` that worked in one
/// of them would look like it worked.
void main() {
  Future<TextEditingController> bar(
    WidgetTester tester, {
    required String document,
    required String pattern,
    required String replace,
    required bool regex,
  }) async {
    final configDir = Directory.systemTemp.createTempSync('expand_groups');
    addTearDown(() {
      if (configDir.existsSync()) configDir.deleteSync(recursive: true);
    });
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

    final controller = TextEditingController(text: document);
    tester.view.physicalSize = const Size(1400, 600);
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
          home: Scaffold(
            body: FindReplaceBar(
              textController: controller,
              rawContent: document,
              isSplitMode: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The replace row is collapsed until the chevron is pressed, so the second
    // field does not exist before this.
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    if (regex) {
      await tester.tap(find.widgetWithText(InkWell, '.*'));
      await tester.pumpAndSettle();
    }
    await tester.enterText(fields.at(0), pattern);
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(1), replace);
    await tester.pumpAndSettle();
    return controller;
  }

  Future<void> press(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(TextButton, label));
    await tester.pumpAndSettle();
  }

  testWidgets('Replace puts the groups into one hit', (tester) async {
    final controller = await bar(
      tester,
      document: '[one](a) and [two](b)',
      pattern: r'\[(.+?)\]\((.+?)\)',
      replace: r'$2: $1',
      regex: true,
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await press(tester, l10n.editReplace);
    expect(controller.text, 'a: one and [two](b)');
  });

  testWidgets('Replace All puts the groups into every hit', (tester) async {
    final controller = await bar(
      tester,
      document: '[one](a) and [two](b)',
      pattern: r'\[(.+?)\]\((.+?)\)',
      replace: r'$2: $1',
      regex: true,
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await press(tester, l10n.editReplaceAll);
    expect(controller.text, 'a: one and b: two');
  });

  testWidgets('a literal search leaves a dollar alone', (tester) async {
    final controller = await bar(
      tester,
      document: 'the cost here',
      pattern: 'cost',
      replace: r'$1',
      regex: false,
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await press(tester, l10n.editReplaceAll);
    expect(controller.text, r'the $1 here');
  });

  /// A capability nobody can find is the same as no capability. The hint is the
  /// only place the two spellings appear, and it appears only in the mode where
  /// they mean anything.
  testWidgets('the replace field says what a regex replacement understands',
      (tester) async {
    await bar(
      tester,
      document: 'x',
      pattern: '',
      replace: '',
      regex: false,
    );
    expect(find.textContaining(r'$1'), findsNothing,
        reason: 'a literal search has no groups to offer');

    await tester.tap(find.widgetWithText(InkWell, '.*'));
    await tester.pumpAndSettle();
    expect(find.textContaining(r'$1'), findsOneWidget,
        reason: 'nothing tells the reader a group can be put back');
    expect(find.textContaining(r'$&'), findsOneWidget);
  });
}

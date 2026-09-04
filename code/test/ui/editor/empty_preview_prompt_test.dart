import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// What the preview shows for a document with nothing in it.
void main() {
  late Directory configDir;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('prompt_cfg_');
  });

  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<void> pump(
    WidgetTester tester, {
    required bool split,
    String markdown = '',
  }) async {
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MarkdownRenderer(
              markdown: markdown,
              followsSource: split,
              onSourceChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('on its own, an empty preview invites the reader to write', (
    tester,
  ) async {
    // Nowhere else to type: the preview is the whole tab.
    await pump(tester, split: false);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.previewStartWriting), findsOneWidget);
  });

  testWidgets('in split view it says nothing, because the source pane is '
      'right there', (tester) async {
    // Two invitations to start writing, side by side, and pressing the one on
    // the right opens a second editor that takes the caret away from the one
    // the reader was already looking at.
    await pump(tester, split: true);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.previewStartWriting), findsNothing);
  });

  testWidgets('a document with something in it says nothing either way', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await pump(tester, split: false, markdown: '# Title');
    expect(find.text(l10n.previewStartWriting), findsNothing);
    await pump(tester, split: true, markdown: '# Title');
    expect(find.text(l10n.previewStartWriting), findsNothing);
  });
}

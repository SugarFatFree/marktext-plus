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

/// Writing into the preview, rather than only editing what is already there.
///
/// The preview could edit a block by double-tapping it, but there was no way
/// to *add* one: an empty document rendered nothing at all, so there was no
/// target to tap and not one character could be typed into it, and even in a
/// written document a new block at the end meant switching to the source pane.
void main() {
  late String markdown;
  late List<String> writes;
  late Directory configDir;

  setUp(() {
    // createTempSync, not the async form: testWidgets runs inside a FakeAsync
    // zone where a dart:io future never completes.
    configDir = Directory.systemTemp.createTempSync('preview_append_test');
  });

  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<void> pump(WidgetTester tester, String source,
      {bool editable = true}) async {
    markdown = source;
    writes = [];
    tester.view.physicalSize = const Size(1200, 900);
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
              onSourceChanged: editable ? (value) => writes.add(value) : null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> writeAtEnd(WidgetTester tester, String text) async {
    await tester.tap(find.byType(GestureDetector).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), text);
    // Committing is losing focus, the same as every other block editor.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  testWidgets('an empty document offers somewhere to start', (tester) async {
    await pump(tester, '');
    expect(find.text('Start writing…'), findsOneWidget);

    await writeAtEnd(tester, 'first words');
    expect(writes, ['first words']);
  });

  testWidgets('a written document takes a new block at the end',
      (tester) async {
    await pump(tester, '# Title\n\nA paragraph.\n');
    // The invitation is only for a document with nothing in it; a written one
    // just has the space.
    expect(find.text('Start writing…'), findsNothing);

    await writeAtEnd(tester, 'appended');
    expect(writes.single, '# Title\n\nA paragraph.\nappended\n');
  });

  testWidgets('the existing blocks are left exactly as they were',
      (tester) async {
    await pump(tester, 'one\n\ntwo\n');
    await writeAtEnd(tester, 'three');
    expect(writes.single, startsWith('one\n\ntwo\n'));
  });

  testWidgets('committing nothing writes nothing', (tester) async {
    await pump(tester, 'one\n');
    await tester.tap(find.byType(GestureDetector).last);
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(writes, isEmpty, reason: '空提交不该产生一次改动');
  });

  testWidgets('a read-only preview offers no target at all', (tester) async {
    await pump(tester, '', editable: false);
    expect(find.text('Start writing…'), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });
}

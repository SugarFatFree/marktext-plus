import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/locale_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:marktext_plus/ui/editor/syntax_highlighter.dart';
import 'package:marktext_plus/ui/widgets/status_bar.dart';

/// "Syntax highlighting off" is said where there is highlighting to lose.
///
/// The status bar says it for any document past the highlighter's limit, which
/// is right in the two modes that draw a source pane and a sentence about a pane
/// that is not on screen in the third: preview-only mode builds no editor at
/// all, nothing is coloured, and nothing was taken away.
///
/// One of the ways this editor has been wrong before, often enough to be listed
/// in the project's own notes: the status bar telling the reader something that
/// is not so.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('highlight_off'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  /// A status bar over a tab holding [size] characters, in [mode].
  Future<void> pump(WidgetTester tester, EditMode mode, int size) async {
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        localeProvider.overrideWith(
          (ref) => LocaleNotifier(const Locale('en', 'US')),
        ),
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(editMode: mode),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(tabProvider.notifier).addTab(
          TabInfo(id: 'big', fileName: 'big.md', content: 'a' * size),
        );

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
          home: const Scaffold(body: Column(children: [StatusBar()])),
        ),
      ),
    );
    await tester.pump();
    // The word count's debounce, so the test does not end with it pending. Its
    // own count runs on another isolate and never finishes inside FakeAsync,
    // which is a microtask rather than a timer and is not an error.
    await tester.pump(const Duration(milliseconds: 350));
  }

  /// The label, in English, from the same place the bar reads it.
  final said = AppLocalizations.delegate
      .load(const Locale('en', 'US'))
      .then((l10n) => l10n.statusHighlightOff);

  const past = IncrementalMarkdownHighlighter.maxHighlightedLength + 1;
  const under = 1000;

  testWidgets('said in source mode for a document past the limit',
      (tester) async {
    await pump(tester, EditMode.source, past);
    expect(find.text(await said), findsOneWidget);
  });

  testWidgets('said in split mode too', (tester) async {
    await pump(tester, EditMode.split, past);
    expect(find.text(await said), findsOneWidget);
  });

  testWidgets('not said in preview mode, where there is no pane to lose it from',
      (tester) async {
    await pump(tester, EditMode.preview, past);
    expect(find.text(await said), findsNothing,
        reason: '纯预览模式下没有建源码窗格，没有高亮可失去');
  });

  testWidgets('not said for a document under the limit', (tester) async {
    await pump(tester, EditMode.source, under);
    expect(find.text(await said), findsNothing);
  });
}

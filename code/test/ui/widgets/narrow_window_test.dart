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
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:marktext_plus/ui/editor/syntax_highlighter.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/widgets/app_menu_bar.dart';
import 'package:marktext_plus/ui/widgets/editor_tab_bar.dart';
import 'package:marktext_plus/ui/widgets/status_bar.dart';

/// The window has no minimum size, so every width is one someone can drag to.
///
/// The chrome above and below the document was laid out with nothing able to
/// give way, and went striped from about 780 pixels down — the same fault the
/// settings page had, in three more places.
///
/// With a document open as well as without. Every bar here was pumped with no
/// tab at all, which is a state the reader passes through on the way to using
/// the editor and not one they stay in — and it hid a real fault: the status
/// bar's "syntax highlighting off" is only shown for a document past the
/// highlighter's limit, so it was never on screen in this test, and the widths
/// were tuned without it. A 200 KB document striped the bar at 1200 pixels.
void main() {
  /// Roomy, and past the highlighter's limit — so every indicator the bar can
  /// show is showing, which is the widest the bar ever gets.
  final withADocument = 'a' * (IncrementalMarkdownHighlighter.maxHighlightedLength + 1);

  final bars = <String, Widget>{
    'the menu bar': const AppMenuBar(),
    'the tab bar': const EditorTabBar(),
    'the status bar': const StatusBar(),
  };

  for (final bar in bars.entries) {
    for (final width in [1200.0, 900.0, 700.0, 500.0, 360.0]) {
      for (final open in [false, true]) {
      testWidgets(
          '${bar.key} fits at ${width.toInt()} px'
          '${open ? ' with a document open' : ''}', (tester) async {
        final configDir = Directory.systemTemp.createTempSync('narrow');
        addTearDown(() {
          if (configDir.existsSync()) configDir.deleteSync(recursive: true);
        });
        await tester.binding.setSurfaceSize(Size(width, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final container = ProviderContainer(
          overrides: [
            localeProvider.overrideWith(
              (ref) => LocaleNotifier(const Locale('en', 'US')),
            ),
            settingsProvider.overrideWith(
              (ref) => SettingsNotifier(
                ConfigService(configDir: configDir.path),
                // A source pane on screen in the open-document round: the
                // status bar's widest state includes an indicator that is only
                // shown where there is highlighting to lose, and the default
                // mode is preview — so leaving the default here would test the
                // narrow bar without the thing that made it overflow, which is
                // the hole this round exists to close.
                AppConfig(editMode: open ? EditMode.split : EditMode.preview),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);
        if (open) {
          container.read(tabProvider.notifier).addTab(
                TabInfo(
                  id: 'open',
                  fileName: 'a-long-document.md',
                  content: withADocument,
                ),
              );
        }

        final caught = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) =>
            caught.add(details.exceptionAsString().split('\n').first);

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
              home: Scaffold(body: Column(children: [bar.value])),
            ),
          ),
        );
        await tester.pump();
        // The word count debounces by 300 ms; leaving its timer pending fails
        // the test for a reason that has nothing to do with the layout.
        await tester.pump(const Duration(milliseconds: 400));
        FlutterError.onError = previous;

        expect(caught, isEmpty, reason: caught.join(' | '));
        tester.takeException();
      });
      }
    }
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/locale_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/widgets/app_menu_bar.dart';
import 'package:marktext_plus/ui/widgets/editor_tab_bar.dart';
import 'package:marktext_plus/ui/widgets/status_bar.dart';

/// The window has no minimum size, so every width is one someone can drag to.
///
/// The chrome above and below the document was laid out with nothing able to
/// give way, and went striped from about 780 pixels down — the same fault the
/// settings page had, in three more places.
void main() {
  final bars = <String, Widget>{
    'the menu bar': const AppMenuBar(),
    'the tab bar': const EditorTabBar(),
    'the status bar': const StatusBar(),
  };

  for (final bar in bars.entries) {
    for (final width in [1200.0, 900.0, 700.0, 500.0, 360.0]) {
      testWidgets('${bar.key} fits at ${width.toInt()} px', (tester) async {
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
                AppConfig(),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

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

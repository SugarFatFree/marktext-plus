import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marktext_plus/app.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/locale_provider.dart';

void main() {
  testWidgets(
    'App renders correctly',
    (WidgetTester tester) async {
      // A real temp dir per run: HomeScreen's startup update check persists
      // lastUpdateCheck, and a fixed path would leak state between runs and
      // between developers' machines.
      final configDir = await Directory.systemTemp.createTemp('marktext_test');
      addTearDown(() {
        if (configDir.existsSync()) configDir.deleteSync(recursive: true);
      });

      final configService = ConfigService(configDir: configDir.path);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(
              (ref) => SettingsNotifier(configService, AppConfig()),
            ),
            localeProvider.overrideWith(
              (ref) => LocaleNotifier(const Locale('en', 'US')),
            ),
          ],
          child: const MarkTextPlusApp(),
        ),
      );

      // Deliberately not pumpAndSettle(): the home screen renders an
      // indeterminate CircularProgressIndicator, whose animation never stops.
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    },
    // Cut short of flutter_test's 10-minute default. This test has hung twice
    // and the cause is not yet pinned down; a fast failure is worth more than
    // a slow one while that is true.
    timeout: const Timeout(Duration(seconds: 30)),
  );
}

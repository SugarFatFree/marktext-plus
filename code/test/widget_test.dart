import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marktext_plus/app.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/locale_provider.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    final configService = ConfigService(configDir: '/tmp/marktext-test');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => SettingsNotifier(configService, AppConfig())),
          localeProvider.overrideWith((ref) => LocaleNotifier(const Locale('en', 'US'))),
        ],
        child: const MarkTextPlusApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

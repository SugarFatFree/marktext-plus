import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('has 5 built-in themes', () {
      expect(AppTheme.themeNames.length, 5);
    });

    test('redGraphite is a light theme', () {
      final theme = AppTheme.getTheme('redGraphite');
      expect(theme.brightness, Brightness.light);
    });

    test('shibuya is a light theme', () {
      final theme = AppTheme.getTheme('shibuya');
      expect(theme.brightness, Brightness.light);
    });

    test('darkGraphite is a dark theme', () {
      final theme = AppTheme.getTheme('darkGraphite');
      expect(theme.brightness, Brightness.dark);
    });

    test('dieciOLED is a dark theme', () {
      final theme = AppTheme.getTheme('dieciOLED');
      expect(theme.brightness, Brightness.dark);
    });

    test('nord is a dark theme', () {
      final theme = AppTheme.getTheme('nord');
      expect(theme.brightness, Brightness.dark);
    });

    test('unknown theme name returns redGraphite', () {
      final theme = AppTheme.getTheme('nonexistent');
      expect(theme.brightness, Brightness.light);
    });

    test('legacy theme names are migrated', () {
      expect(AppTheme.migrateName('cadmiumLight'), 'redGraphite');
      expect(AppTheme.migrateName('oneDark'), 'darkGraphite');
      expect(AppTheme.migrateName('materialDark'), 'dieciOLED');
      expect(AppTheme.migrateName('graphiteLight'), 'redGraphite');
      expect(AppTheme.migrateName('ulyssesLight'), 'shibuya');
    });

    test('all theme names have tokens', () {
      for (final name in AppTheme.themeNames) {
        final tokens = AppTheme.getTokens(name);
        expect(tokens.colorBg, isNotNull);
        expect(tokens.colorAccent, isNotNull);
      }
    });
  });
}

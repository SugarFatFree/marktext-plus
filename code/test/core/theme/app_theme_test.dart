import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('has 5 built-in themes', () {
      expect(AppTheme.themeNames.length, 5);
    });

    test('snow is a light theme', () {
      final theme = AppTheme.getTheme('snow');
      expect(theme.brightness, Brightness.light);
    });

    test('latte is a light theme', () {
      final theme = AppTheme.getTheme('latte');
      expect(theme.brightness, Brightness.light);
    });

    test('dusk is a dark theme', () {
      final theme = AppTheme.getTheme('dusk');
      expect(theme.brightness, Brightness.dark);
    });

    test('midnight is a dark theme', () {
      final theme = AppTheme.getTheme('midnight');
      expect(theme.brightness, Brightness.dark);
    });

    test('forest is a dark theme', () {
      final theme = AppTheme.getTheme('forest');
      expect(theme.brightness, Brightness.dark);
    });

    test('unknown theme name returns snow', () {
      final theme = AppTheme.getTheme('nonexistent');
      expect(theme.brightness, Brightness.light);
    });

    test('legacy theme names are migrated', () {
      expect(AppTheme.migrateName('cadmiumLight'), 'snow');
      expect(AppTheme.migrateName('oneDark'), 'dusk');
      expect(AppTheme.migrateName('materialDark'), 'midnight');
      expect(AppTheme.migrateName('graphiteLight'), 'snow');
      expect(AppTheme.migrateName('ulyssesLight'), 'latte');
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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('has 5 built-in themes', () {
      expect(AppTheme.themes.length, 5);
    });

    test('cadmiumLight is a light theme', () {
      final theme = AppTheme.getTheme('cadmiumLight');
      expect(theme.brightness, Brightness.light);
    });

    test('oneDark is a dark theme', () {
      final theme = AppTheme.getTheme('oneDark');
      expect(theme.brightness, Brightness.dark);
    });

    test('materialDark is a dark theme', () {
      final theme = AppTheme.getTheme('materialDark');
      expect(theme.brightness, Brightness.dark);
    });

    test('graphiteLight is a light theme', () {
      final theme = AppTheme.getTheme('graphiteLight');
      expect(theme.brightness, Brightness.light);
    });

    test('ulyssesLight is a light theme', () {
      final theme = AppTheme.getTheme('ulyssesLight');
      expect(theme.brightness, Brightness.light);
    });

    test('unknown theme name returns cadmiumLight', () {
      final theme = AppTheme.getTheme('nonexistent');
      expect(theme.brightness, Brightness.light);
    });

    test('all theme names are available', () {
      expect(AppTheme.themeNames, containsAll([
        'cadmiumLight', 'oneDark', 'materialDark', 'graphiteLight', 'ulyssesLight',
      ]));
    });

    test('themeNames matches themes map keys', () {
      expect(AppTheme.themeNames.toSet(), AppTheme.themes.keys.toSet());
    });
  });
}

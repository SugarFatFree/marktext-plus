import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('has 8 built-in themes', () {
      expect(AppTheme.themeNames.length, 8);
    });

    test('redGraphite is a light theme', () {
      final theme = AppTheme.getTheme('redGraphite');
      expect(theme.brightness, Brightness.light);
    });

    test('shibuya is a light theme', () {
      final theme = AppTheme.getTheme('shibuya');
      expect(theme.brightness, Brightness.light);
    });

    test('pinkBlossom is a light theme', () {
      final theme = AppTheme.getTheme('pinkBlossom');
      expect(theme.brightness, Brightness.light);
    });

    test('skyBlue is a light theme', () {
      final theme = AppTheme.getTheme('skyBlue');
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

    test('midnight is a dark theme', () {
      final theme = AppTheme.getTheme('midnight');
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

    test('every theme name resolves to its own tokens', () {
      // Not `expect(tokens.colorBg, isNotNull)`, which is what stood here:
      // colorBg is a non-nullable Color, so that assertion could never fail,
      // and the test's own name promised the one thing it could not check.
      // getTokens ends in `_ => redGraphite`, so a name listed in themeNames
      // but missing from the switch comes back as the default theme and
      // nothing says so. Distinct objects are what proves each name has a
      // branch of its own.
      final seen = <String, AppThemeTokens>{};
      for (final name in AppTheme.themeNames) {
        final tokens = AppTheme.getTokens(name);
        for (final entry in seen.entries) {
          expect(identical(entry.value, tokens), isFalse,
              reason: '$name 和 ${entry.key} 拿到同一份 tokens，'
                  'getTokens 里多半少了 $name 的分支');
        }
        seen[name] = tokens;
      }
      expect(seen.length, AppTheme.themeNames.length);
    });

    test('an unknown name falls back to the default theme', () {
      // Stated rather than assumed: a config written by an older version can
      // name a theme that no longer exists, and falling back beats crashing.
      expect(identical(AppTheme.getTokens('no-such-theme'), AppTheme.redGraphite),
          isTrue);
    });

    test('the light and dark lists partition the themes, and agree with them',
        () {
      final light = AppTheme.lightThemeNames.toSet();
      final dark = AppTheme.darkThemeNames.toSet();

      expect(light.intersection(dark), isEmpty);
      expect({...light, ...dark}, AppTheme.themeNames.toSet(),
          reason: '有主题不在任何一个明暗清单里，或清单里有不存在的主题');

      for (final name in AppTheme.themeNames) {
        final actual = AppTheme.getTokens(name).brightness;
        expect(actual, light.contains(name) ? Brightness.light : Brightness.dark,
            reason: '$name 被列在'
                '${light.contains(name) ? "浅色" : "深色"}清单里，实际却是 $actual');
      }
    });
  });
}

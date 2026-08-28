import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/theme/app_theme.dart';

/// Which theme actually appears.
///
/// Kept as a plain function so the rule can be stated rather than observed:
/// the operating system switching to dark mode is not something a test can
/// arrange by looking at the screen.
void main() {
  String resolve(AppConfig config, Brightness system) =>
      AppTheme.resolveThemeName(
        followSystem: config.followSystemTheme,
        chosen: config.themeName,
        lightChoice: config.lightModeTheme,
        darkChoice: config.darkModeTheme,
        systemBrightness: system,
      );

  test('not following: the system is ignored entirely', () {
    final config = AppConfig(themeName: 'nord', followSystemTheme: false);

    expect(resolve(config, Brightness.light), 'nord');
    expect(resolve(config, Brightness.dark), 'nord',
        reason: '没开跟随时，系统深浅色不该改变主题');
  });

  test('following: the system chooses between the two', () {
    final config = AppConfig(
      themeName: 'shibuya',
      followSystemTheme: true,
      lightModeTheme: 'skyBlue',
      darkModeTheme: 'midnight',
    );

    expect(resolve(config, Brightness.light), 'skyBlue');
    expect(resolve(config, Brightness.dark), 'midnight');
    expect(resolve(config, Brightness.light), isNot('shibuya'),
        reason: '开了跟随之后，单选的那个主题不该再生效');
  });

  test('both defaults resolve to a real theme', () {
    final config = AppConfig(followSystemTheme: true);

    for (final brightness in Brightness.values) {
      final name = resolve(config, brightness);
      expect(AppTheme.themeNames, contains(name),
          reason: '$name 不在主题列表里，getTokens 会静默回退到默认主题');
    }
  });

  test('the defaults are the right way round', () {
    final config = AppConfig(followSystemTheme: true);

    expect(AppTheme.getTokens(resolve(config, Brightness.light)).brightness,
        Brightness.light);
    expect(AppTheme.getTokens(resolve(config, Brightness.dark)).brightness,
        Brightness.dark,
        reason: '系统是深色时给了一个浅色主题，反而更刺眼');
  });

  test('the three settings survive a round trip, and an old config is unchanged',
      () {
    final config = AppConfig(
      followSystemTheme: true,
      lightModeTheme: 'pinkBlossom',
      darkModeTheme: 'nord',
    );
    final restored = AppConfig.fromJson(config.toJson());
    expect(restored.followSystemTheme, isTrue);
    expect(restored.lightModeTheme, 'pinkBlossom');
    expect(restored.darkModeTheme, 'nord');

    // A config written before this existed must not start following the
    // system on its own — that would change how the editor looks without
    // anyone asking.
    final old = AppConfig().toJson()..remove('followSystemTheme');
    expect(AppConfig.fromJson(old).followSystemTheme, isFalse);
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/constants.dart';
import 'package:marktext_plus/providers/settings_provider.dart';

/// How many documents the Open Recent menu remembers.
///
/// `AppConstants.maxRecentFiles` said twenty and was read by nothing at all:
/// the list was trimmed to a hard-coded ten a few files away. Two numbers for
/// one rule, and the one written down as the rule was the dead one — anybody
/// changing it would have watched nothing happen.
///
/// These assertions go through the constant on purpose. That is what makes it
/// the rule rather than a comment about one.
void main() {
  late Directory root;
  late SettingsNotifier settings;

  setUp(() {
    root = Directory.systemTemp.createTempSync('recent_');
    settings = SettingsNotifier(
      ConfigService(configDir: root.path),
      AppConfig(),
    );
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('the newest come first', () async {
    await settings.addRecentFile('/a.md');
    await settings.addRecentFile('/b.md');

    expect(settings.state.recentFiles, ['/b.md', '/a.md']);
  });

  test('opening one again moves it up rather than repeating it', () async {
    await settings.addRecentFile('/a.md');
    await settings.addRecentFile('/b.md');
    await settings.addRecentFile('/a.md');

    expect(settings.state.recentFiles, ['/a.md', '/b.md']);
  });

  test('the list stops at the limit, and the oldest is what goes', () async {
    for (var i = 0; i <= AppConstants.maxRecentFiles; i++) {
      await settings.addRecentFile('/note$i.md');
    }

    expect(settings.state.recentFiles, hasLength(AppConstants.maxRecentFiles));
    expect(
      settings.state.recentFiles.first,
      '/note${AppConstants.maxRecentFiles}.md',
    );
    expect(
      settings.state.recentFiles,
      isNot(contains('/note0.md')),
      reason: '最早打开的那个该被挤掉',
    );
  });

  test('the limit is not unbounded', () async {
    // The point of having one: the list is written into the configuration
    // file, which is read on every launch.
    expect(AppConstants.maxRecentFiles, lessThanOrEqualTo(50));
  });
}

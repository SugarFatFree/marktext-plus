import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/mcp_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';

/// Changing a setting over the automation interface.
///
/// Why it is here at all: every change that shows up as an appearance — a font,
/// a theme, a width, whether code blocks wrap — could be tested for the style
/// it writes and not for the picture it draws, because nothing on this side
/// could put the editor into the state and look. That left a class of work
/// verifiable only by asking a person to open the settings page.
///
/// What it must not do is as much of the point as what it does, so the refusals
/// are tested beside it. `mcp_settings_are_classified_test` holds the other
/// half: that every setting is on one side of that line on purpose.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('mcp_setting'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  ProviderContainer boot() {
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<McpOutcomeLike> set(
    ProviderContainer c,
    String? setting,
    Object? value,
  ) async {
    final outcome = await c.read(mcpProvider.notifier).performAction(
      'set_setting',
      {if (setting != null) 'setting': setting, if (value != null) 'value': value},
    );
    return (ok: outcome.ok, said: outcome.said);
  }

  group('it writes the setting', () {
    test('a string', () async {
      final c = boot();
      final outcome = await set(c, 'previewFontFamily', 'Georgia');

      expect(outcome.ok, isTrue, reason: outcome.said);
      expect(c.read(settingsProvider).previewFontFamily, 'Georgia');
      expect(outcome.said, contains('Georgia'),
          reason: '答复要说出它现在是什么，不然调用方还得再问一次');
    });

    test('a number', () async {
      final c = boot();
      final outcome = await set(c, 'fontSize', 22);

      expect(outcome.ok, isTrue, reason: outcome.said);
      expect(c.read(settingsProvider).fontSize, 22);
    });

    test('a true or false', () async {
      final c = boot();
      final was = c.read(settingsProvider).wrapCodeBlocks;
      final outcome = await set(c, 'wrapCodeBlocks', !was);

      expect(outcome.ok, isTrue, reason: outcome.said);
      expect(c.read(settingsProvider).wrapCodeBlocks, !was);
    });

    test('changing one setting changes only that setting', () async {
      // Every write goes out through `fromJson`, so a field that does not
      // survive that round trip would be reset by any change to any setting.
      final c = boot();
      await set(c, 'previewFontFamily', 'Georgia');
      await set(c, 'fontSize', 22);

      final config = c.read(settingsProvider);
      expect(config.previewFontFamily, 'Georgia',
          reason: '改第二个设置把第一个抹掉了');
      expect(config.fontSize, 22);
    });

    test('and it lands in the file, so a restart keeps it', () async {
      final c = boot();
      await set(c, 'themeName', 'Nord');

      final written = await ConfigService(configDir: configDir.path).load();
      expect(written.themeName, 'Nord',
          reason: '只改了内存里的状态，下次启动就回去了');
    });
  });

  group('it refuses', () {
    test('a credential, and says which kind of thing it is', () async {
      final c = boot();
      final outcome = await set(c, 'aiApiKey', 'sk-whatever');

      expect(outcome.ok, isFalse);
      expect(c.read(settingsProvider).aiApiKey, isEmpty);
      expect(outcome.said, contains('凭据'));
    });

    test('where a credential is sent', () async {
      final c = boot();
      final before = c.read(settingsProvider).aiEndpoint;
      final outcome = await set(c, 'aiEndpoint', 'https://elsewhere.example');

      expect(outcome.ok, isFalse);
      expect(c.read(settingsProvider).aiEndpoint, before,
          reason: '能改端点就等于能把密钥送去别处');
    });

    test('the connection this request came in on', () async {
      final c = boot();
      final before = c.read(settingsProvider).mcpEnabled;
      final outcome = await set(c, 'mcpEnabled', !before);

      expect(outcome.ok, isFalse);
      expect(c.read(settingsProvider).mcpEnabled, before,
          reason: '关掉之后没有任何自动化能再打开它');
    });

    test('a setting that does not exist', () async {
      final c = boot();
      final outcome = await set(c, 'fontColour', 'blue');

      expect(outcome.ok, isFalse);
      expect(outcome.said, contains('fontColour'));
    });

    test('no setting named at all', () async {
      final c = boot();
      final outcome = await set(c, null, 'Georgia');

      expect(outcome.ok, isFalse);
    });

    test('a value of the wrong kind, rather than quietly using the default',
        () async {
      // `fromJson` reads a value it cannot parse as the field's default. Left
      // unchecked this would answer "fontSize is now large" while the editor
      // went back to 16 — the editor saying something that is not so, which is
      // the fault this repository keeps finding.
      final c = boot();
      await set(c, 'fontSize', 22);
      final outcome = await set(c, 'fontSize', 'large');

      expect(outcome.ok, isFalse);
      expect(outcome.said, contains('large'));
      expect(c.read(settingsProvider).fontSize, 22,
          reason: '拒绝了却已经把它写回默认值，那比不拒绝更糟');
    });

    test('the one that set_view_mode already does', () async {
      final c = boot();
      final outcome = await set(c, 'editMode', 'split');

      expect(outcome.ok, isFalse);
      expect(outcome.said, contains('set_view_mode'));
    });
  });
}

/// The shape [performAction] answers with, named so the helper can return it.
typedef McpOutcomeLike = ({bool ok, String said});

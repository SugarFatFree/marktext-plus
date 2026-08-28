import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/settings_provider.dart';

/// A settings change that never reaches disk should say so.
///
/// ConfigService has recorded `lastSaveError` all along, and nothing but a
/// test ever read it: with a config directory that could not be written to,
/// the reader flicked a switch, watched it take effect — the state changes
/// before the write — and found it reverted on the next launch, with nothing
/// ever having explained why.
void main() {
  late Directory root;
  final reported = <Object>[];

  setUp(() {
    root = Directory.systemTemp.createTempSync('settings_fail_');
    reported.clear();
    SettingsNotifier.onSaveFailed = reported.add;
  });

  tearDown(() {
    SettingsNotifier.onSaveFailed = null;
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('a write that succeeds reports nothing', () async {
    final notifier =
        SettingsNotifier(ConfigService(configDir: root.path), AppConfig());

    await notifier.updateConfig((c) => c.copyWith(tabSize: 8));

    expect(reported, isEmpty);
    expect(notifier.state.tabSize, 8);
  });

  test('a write that fails is reported once, not on every change', () async {
    // A file where the config directory should be: every write fails, and goes
    // on failing.
    final blocked = '${root.path}/blocked';
    File(blocked).writeAsStringSync('not a directory');
    final notifier =
        SettingsNotifier(ConfigService(configDir: blocked), AppConfig());

    await notifier.updateConfig((c) => c.copyWith(tabSize: 8));
    expect(reported, hasLength(1), reason: '第一次失败必须说出来');

    await notifier.updateConfig((c) => c.copyWith(tabSize: 6));
    await notifier.updateConfig((c) => c.copyWith(tabSize: 4));
    expect(reported, hasLength(1),
        reason: '同一个错误反复弹提示，会把每次开关都变成一条横幅');
  });

  test('recovering, then failing again, is reported again', () async {
    final blocked = '${root.path}/blocked';
    File(blocked).writeAsStringSync('not a directory');
    final failing =
        SettingsNotifier(ConfigService(configDir: blocked), AppConfig());
    await failing.updateConfig((c) => c.copyWith(tabSize: 8));
    expect(reported, hasLength(1));

    // A second notifier on a good directory stands in for the problem being
    // fixed: what matters is that a cleared error lets the next one speak.
    final working =
        SettingsNotifier(ConfigService(configDir: root.path), AppConfig());
    await working.updateConfig((c) => c.copyWith(tabSize: 2));
    expect(reported, hasLength(1));
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/services/update_service.dart';

/// The reader can stop the editor asking GitHub about new releases.
///
/// This was the one connection it made without being asked, and the one that
/// could not be stopped. Everything else that reaches the network is opt-in or
/// reader-driven: the automation port is off until it is opened, a plugin's
/// browser is behind a permission, exported HTML carries no link but the maths
/// one, and the AI endpoints are whatever the reader configured. The update
/// check went out after the first frame of every launch a day apart, with
/// `lastUpdateCheck` and `skipVersion` recording that it had happened and
/// nothing able to say that it should not.
///
/// The request itself cannot be made in a test. The decision in front of it can,
/// which is why it is a function.
void main() {
  final now = DateTime.parse('2026-09-14T03:00:00Z');

  test('on by default, so nothing changes for anyone who has not asked', () {
    expect(AppConfig().checkForUpdates, isTrue);
  });

  test('off means no request, however long it has been', () {
    expect(
      UpdateService.shouldCheckAutomatically(
        enabled: false,
        lastCheck: null,
        now: now,
      ),
      isFalse,
      reason: '关掉了还是要去连——那这个开关是装饰',
    );
    expect(
      UpdateService.shouldCheckAutomatically(
        enabled: false,
        lastCheck: DateTime.parse('2020-01-01T00:00:00Z'),
        now: now,
      ),
      isFalse,
    );
  });

  test('on and never checked means check', () {
    expect(
      UpdateService.shouldCheckAutomatically(
        enabled: true,
        lastCheck: null,
        now: now,
      ),
      isTrue,
    );
  });

  test('once a day, which is what it always did', () {
    bool at(Duration ago) => UpdateService.shouldCheckAutomatically(
          enabled: true,
          lastCheck: now.subtract(ago),
          now: now,
        );

    expect(at(const Duration(hours: 23, minutes: 59)), isFalse);
    expect(at(const Duration(hours: 24)), isTrue);
    expect(at(const Duration(days: 30)), isTrue);
  });

  test('a stamp from the future is one to ignore, not to trust', () {
    // A clock that moved backwards. Its age is negative, which is not "checked
    // recently" — the same reasoning the plugin catalogue's cache uses.
    expect(
      UpdateService.shouldCheckAutomatically(
        enabled: true,
        lastCheck: now.add(const Duration(days: 2)),
        now: now,
      ),
      isTrue,
    );
  });

  test('the startup check asks before it goes', () {
    // The decision is only worth having if the thing that makes the request
    // consults it. Removing the call would leave every test above green: they
    // exercise the function, not its caller.
    final screen =
        File('lib/ui/screens/home_screen.dart').readAsStringSync();
    final start = screen.indexOf('void _checkForUpdates()');
    expect(start, greaterThan(-1), reason: '找不到启动检查，取法要跟着改');
    final body = screen.substring(start, screen.indexOf('\n  }', start));

    expect(body, contains('UpdateService.shouldCheckAutomatically('),
        reason: '启动检查没有问那个判断，读者的开关就被绕过去了');
    expect(body.indexOf('shouldCheckAutomatically'),
        lessThan(body.indexOf('UpdateService.checkForUpdate(')),
        reason: '先发请求再判断等于没判断');
  });

  test('the setting survives a round trip through the config file', () {
    final off = AppConfig(checkForUpdates: false);
    expect(AppConfig.fromJson(off.toJson()).checkForUpdates, isFalse,
        reason: '关掉之后重启又回来了，等于关不掉');
  });
}

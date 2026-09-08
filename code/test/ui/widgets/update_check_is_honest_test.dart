import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations_en.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations_zh.dart';
import 'package:marktext_plus/services/update_service.dart';
import 'package:marktext_plus/ui/widgets/app_menu_bar.dart';

/// "Check for updates" must not claim an answer it never got.
///
/// `checkForUpdate` reports whether it reached GitHub apart from what it
/// found, and its comment says why: the check on startup stays quiet when the
/// network is down, but a check the reader asked for must not answer "you are
/// on the latest version" when nothing answered.
///
/// The value was read and nothing held it. Saying the happy sentence
/// unconditionally left all 2741 tests green — a reader on a train would have
/// been told they were up to date by an editor that had not asked anyone.
void main() {
  final en = AppLocalizationsEn();
  final zh = AppLocalizationsZh();

  test('an unreachable check says so, in either language', () {
    for (final l10n in [en, zh]) {
      final said = AppMenuBar.updateMessage(
        reachable: false,
        update: null,
        l10n: l10n,
      );
      expect(said, l10n.updateCheckFailed);
      expect(
        said,
        isNot(l10n.updateUpToDate),
        reason: '没连上却说已是最新版本',
      );
    }
  });

  test('an unreachable check says so even when a version is cached', () {
    // `update` can be non-null from an earlier successful check while this
    // one failed. What the reader asked about is *this* check.
    final said = AppMenuBar.updateMessage(
      reachable: false,
      update: UpdateInfo(version: '9.9.9', url: 'https://example.invalid', releaseNotes: ''),
      l10n: en,
    );

    expect(said, en.updateCheckFailed);
  });

  test('a reachable check with a new version names it', () {
    final said = AppMenuBar.updateMessage(
      reachable: true,
      update: UpdateInfo(version: '1.7.0', url: 'https://example.invalid', releaseNotes: ''),
      l10n: en,
    );

    expect(said, contains('1.7.0'));
    expect(said, contains(en.updateAvailable));
  });

  test('a reachable check with nothing new says so', () {
    expect(
      AppMenuBar.updateMessage(reachable: true, update: null, l10n: en),
      en.updateUpToDate,
    );
  });

  test('the three answers are three different sentences', () {
    // Guards the guard: if two of these were the same string, the tests above
    // would pass while the reader could not tell the cases apart.
    expect(
      {en.updateCheckFailed, en.updateAvailable, en.updateUpToDate},
      hasLength(3),
    );
  });
}

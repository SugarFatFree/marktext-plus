import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/ui/widgets/plugin_permission_text.dart';

/// Every permission says what it means, in every language.
///
/// This is the list somebody reads to decide whether to install something from
/// a stranger's repository, and all eighteen sentences were written into the
/// service layer in English — where nothing may reach the translations — so the
/// most consequential page in the editor answered in English whichever of the
/// twelve languages had been chosen. The plugin pages were translated a day
/// earlier and this was missed, because the guard for that reads `lib/ui` and
/// these live in `lib/services`.
void main() {
  test('every permission the editor grants has a sentence to read', () async {
    final english = await AppLocalizations.delegate.load(const Locale('en'));

    for (final permission in PluginPermission.all) {
      final text = describePermission(permission, english);
      expect(text, isNotEmpty, reason: '$permission 没有描述');
      expect(text, isNot(english.permUnknown),
          reason: '$permission 落到了「不认识的权限」——读者会以为它什么也不做');
    }
  });

  test('and says it in each of the twelve', () async {
    // The sentences differ between languages, so a language that had not been
    // translated would answer with English and be caught by comparing.
    final english = await AppLocalizations.delegate.load(const Locale('en'));

    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == 'en') continue;
      final l10n = await AppLocalizations.delegate.load(locale);

      // `document.read` is the one a reader weighs hardest, and no two of the
      // twelve write it the same way.
      expect(
        describePermission(PluginPermission.documentRead, l10n),
        isNot(describePermission(PluginPermission.documentRead, english)),
        reason: '$locale 的「读取文档」还是英文',
      );
      expect(describePermission(PluginPermission.uiWebview, l10n),
          isNot(describePermission(PluginPermission.uiWebview, english)));
    }
  });

  test('a permission the editor does not know says so', () async {
    final english = await AppLocalizations.delegate.load(const Locale('en'));

    expect(describePermission('some.future.capability', english),
        english.permUnknown);
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations_en.dart';
import 'package:marktext_plus/services/keybinding_service.dart';
import 'package:marktext_plus/ui/widgets/action_labels.dart';

/// Every shortcut the app has should be one this service knows about.
///
/// Eleven of them were hard-coded as `SingleActivator`s on their menu items,
/// which meant they fired but did not exist as far as the service was
/// concerned: they never appeared in the settings list, so nobody could see
/// what they were or change them. Two of those silently competed with bindings
/// that *were* in the map — zoom in and zoom out sat on Ctrl+= and Ctrl+-, the
/// same keys as promote and demote heading — and nothing in the app could have
/// shown that.
void main() {
  late String menu;

  setUpAll(() {
    menu = File('lib/ui/widgets/app_menu_bar.dart').readAsStringSync();
  });

  test('no shortcut is written straight onto a menu item', () {
    expect(menu, isNot(contains('shortcut: SingleActivator')));
    expect(menu, isNot(contains('shortcut: const SingleActivator')));
  });

  test('no two actions want the same key', () {
    final byKey = <String, List<String>>{};
    KeybindingService.defaultKeybindings.forEach((action, key) {
      byKey.putIfAbsent(key.toLowerCase(), () => []).add(action);
    });
    final clashes = byKey.entries.where((e) => e.value.length > 1).toList();
    expect(clashes, isEmpty,
        reason: '这些键被多个动作占用：'
            '${clashes.map((e) => '${e.key} → ${e.value}').join('; ')}');
  });

  test('every default parses into a real key combination', () {
    final service = KeybindingService();
    for (final action in KeybindingService.defaultKeybindings.keys) {
      expect(service.activatorFor(action, isMacOS: false), isNotNull,
          reason: '$action 的默认键位解析不出来，设置里会是一条按不动的项');
    }
  });

  test('every action has a name rather than showing its id', () {
    // The switch falls back to the raw action name, so a missing case shows
    // "toggleTabBar" where the menu says "隐藏标签栏". This used to search the
    // settings screen's source for the case; the map is a function of its own
    // now, shared with the command palette, so this calls it.
    final l10n = AppLocalizationsEn();
    for (final action in KeybindingService.defaultKeybindings.keys) {
      expect(actionLabel(action, l10n), isNot(action),
          reason: '$action 会显示成原始动作名');
    }
  });
}

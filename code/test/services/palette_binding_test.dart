import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/keybinding_service.dart';

/// One place decides what opens the command palette.
///
/// The home screen used to test for Ctrl+P itself, with a comment saying the
/// palette's shortcut was not configurable. It became configurable when Print
/// was given Ctrl+P — and the hardcoded test went on answering first, so the
/// palette had two shortcuts and Print had none.
void main() {
  final service = KeybindingService();

  SingleActivator? activator(String action) =>
      service.activatorFor(action, isMacOS: false);

  test('the palette and Print do not want the same key', () {
    final palette = activator('commandPalette');
    final print = activator('print');

    expect(palette, isNotNull);
    expect(print, isNotNull);
    expect(
      palette!.trigger == print!.trigger &&
          palette.control == print.control &&
          palette.shift == print.shift &&
          palette.meta == print.meta &&
          palette.alt == print.alt,
      isFalse,
      reason: '两个动作抢同一个键位',
    );
  });

  test('Print is on Ctrl+P, as it is everywhere else', () {
    final print = activator('print')!;

    expect(print.trigger, LogicalKeyboardKey.keyP);
    expect(print.control, isTrue);
    expect(print.shift, isFalse);
  });

  test('the palette is on Ctrl+Shift+P, as upstream and VS Code have it', () {
    final palette = activator('commandPalette')!;

    expect(palette.trigger, LogicalKeyboardKey.keyP);
    expect(palette.control, isTrue);
    expect(palette.shift, isTrue);
  });

  test('every default binding is claimed by exactly one action', () {
    // The clash above was invisible because one of the two was not in this
    // table at all.
    final byKey = <String, List<String>>{};
    KeybindingService.defaultKeybindings.forEach((action, key) {
      byKey.putIfAbsent(key.toLowerCase(), () => []).add(action);
    });

    expect(byKey.entries.where((e) => e.value.length > 1), isEmpty);
  });
  group('the screen answers to the table, not to keys written out in it', () {
    // Six view shortcuts were compared key by key in the home screen —
    // Ctrl+Alt+1, Ctrl+Shift+B and the rest — which held only while the table
    // agreed. Rebinding one in Settings left the old key working there.
    const answered = [
      'commandPalette',
      'sourceMode',
      'previewMode',
      'splitMode',
      'toggleTabBar',
      'toggleSidebar',
      'focusMode',
    ];

    test('every action it answers to is in the table', () {
      for (final action in answered) {
        expect(KeybindingService.defaultKeybindings.containsKey(action), isTrue,
            reason: '$action 不在表里，改绑就管不到它');
      }
    });

    test('none of them is written out in the screen as a key comparison', () {
      // What this guards is not a behaviour but a shape: keys belong in the
      // table, and the screen should ask the table what was pressed.
      final source = File('lib/ui/screens/home_screen.dart').readAsStringSync();
      final handler = source.substring(source.indexOf('bool _runShortcut'));

      for (final key in ['digit1', 'digit2', 'digit3', 'keyB', 'keyT', 'keyP']) {
        expect(handler.contains('LogicalKeyboardKey.$key'), isFalse,
            reason: '$key 又被写死了一遍');
      }
    });

    test('one place turns a key press into an action', () {
      // Two lookups grew here: one asking the table what a press means, one
      // asking it what each action is bound to. Either works; having both is
      // how they drift.
      final source = File('lib/ui/screens/home_screen.dart').readAsStringSync();

      expect(source.contains('actionForEvent'), isTrue);
      expect(source.contains('activatorFor'), isFalse,
          reason: '主界面里出现了第二套查表方式');
    });
  });

}

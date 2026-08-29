import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/keybinding_service.dart';

/// The default binding for moving a block has to survive being parsed.
///
/// An unparsed binding is indistinguishable from an unbound command: the menu
/// simply shows no shortcut and the key does nothing, with no error anywhere.
/// Arrow keys were missing from the label table, so `Alt+Up` produced exactly
/// that until they were added.
void main() {
  test('Alt+Up and Alt+Down parse to the arrow keys', () {
    expect(KeybindingService.keyForLabel('Up'), LogicalKeyboardKey.arrowUp);
    expect(KeybindingService.keyForLabel('Down'), LogicalKeyboardKey.arrowDown);
    expect(KeybindingService.keyForLabel('Left'), LogicalKeyboardKey.arrowLeft);
    expect(
        KeybindingService.keyForLabel('Right'), LogicalKeyboardKey.arrowRight);
  });

  test('the move commands have a usable default binding', () {
    final service = KeybindingService();
    for (final action in ['moveBlockUp', 'moveBlockDown']) {
      final activator = service.activatorFor(action, isMacOS: false);
      expect(activator, isNotNull, reason: '$action 没有解析出快捷键');
      expect(activator!.alt, isTrue, reason: '$action 的 Alt 修饰键丢了');
      expect(
        activator.trigger,
        action == 'moveBlockUp'
            ? LogicalKeyboardKey.arrowUp
            : LogicalKeyboardKey.arrowDown,
      );
    }
  });

  test('every default binding parses', () {
    // The table and the label list are two places one thing is written down,
    // and this is the check that they still agree — the arrow keys are how
    // they came apart the first time.
    final service = KeybindingService();
    final unparsed = <String>[];
    for (final action in KeybindingService.defaultKeybindings.keys) {
      if (service.activatorFor(action, isMacOS: false) == null) {
        unparsed.add('$action=${KeybindingService.defaultKeybindings[action]}');
      }
    }
    expect(unparsed, isEmpty, reason: '这些默认快捷键解析不出来');
  });
}

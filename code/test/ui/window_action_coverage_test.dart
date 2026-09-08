import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/keybinding_service.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations_en.dart';
import 'package:marktext_plus/ui/widgets/action_labels.dart';
import 'package:marktext_plus/ui/widgets/window_actions.dart';

/// Every shortcut Settings offers to rebind must reach something.
///
/// Three lists used to describe this: the keybinding table (complete), the
/// window handler's switch (fourteen names), and the menu bodies. Eleven
/// actions were in the table and in no handler — Ctrl+Plus was drawn beside
/// "Zoom in", could be rebound, and did nothing at all when pressed. Nothing
/// failed, because nothing compared the lists.
void main() {
  /// What a bound key can actually reach: the window's list, the source
  /// editor's format actions, and the editor's own undo history.
  bool isCarriedOut(String action) =>
      WindowActions.byName(action) != null ||
      FormatAction.values.any((f) => f.name == action) ||
      action == 'undo' ||
      action == 'redo';

  test('every bindable action is carried out by something', () {
    final orphans = KeybindingService.defaultKeybindings.keys
        .where((a) => !isCarriedOut(a))
        .toList();

    expect(
      orphans,
      isEmpty,
      reason:
          'These can be bound in Settings and are drawn in the menus, but no '
          'handler answers them, so pressing the key does nothing: $orphans',
    );
  });

  test('the window list carries no name that cannot be bound', () {
    // The other direction. An action here that Settings does not list is
    // unreachable by keyboard, and its presence suggests otherwise.
    final unbindable = WindowActions.all
        .map((a) => a.name)
        .where((n) => !KeybindingService.defaultKeybindings.containsKey(n))
        .toList();

    expect(unbindable, isEmpty, reason: 'not in the keybinding table: $unbindable');
  });

  test('the eleven that used to do nothing are in the list', () {
    // Named individually so that dropping one is a failure rather than a
    // silently shorter list.
    for (final action in [
      'typewriterMode',
      'zoomIn',
      'zoomOut',
      'resetZoom',
      'newWindow',
      'settings',
      'quit',
      'print',
      'exportPdf',
      'reloadImages',
      'fullScreen',
    ]) {
      expect(WindowActions.byName(action), isNotNull, reason: action);
    }
  });

  test('no name appears twice', () {
    final names = WindowActions.all.map((a) => a.name).toList();
    expect(names.toSet().length, names.length);
  });

  test('every window action has a name to show a reader', () {
    // The palette lists these by name now, so an action with no label would
    // appear in it as its own identifier — 'toggleSidebar' rather than
    // whatever that reads as in the reader's language.
    final l10n = AppLocalizationsEn();
    for (final action in WindowActions.all) {
      expect(
        actionLabel(action.name, l10n),
        isNot(action.name),
        reason: '${action.name} falls through to the identifier',
      );
    }
  });
}

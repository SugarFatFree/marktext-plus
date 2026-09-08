import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../app.dart';
import '../../core/config/app_config.dart';
import '../../core/constants.dart';
import '../../providers/editor_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tab_provider.dart';
import '../screens/settings_screen.dart';
import 'app_menu_bar.dart';
import 'command_palette.dart';
import 'editor_tab_bar.dart';

/// Something a shortcut can do that is not about the text under the caret.
///
/// Editing actions are matched against [FormatAction] by name and carried out
/// by the source editor, so they follow the caret into the find bar or a
/// settings field. These do not: they belong to the window.
class WindowAction {
  const WindowAction(this.name, this.run);

  /// The name the keybinding table and the menus both use.
  final String name;

  final void Function(BuildContext context, WidgetRef ref) run;
}

/// Every window-level action, in one list both the menus and the keyboard read.
///
/// Flutter's `MenuItemButton.shortcut` only *draws* a shortcut — "shortcuts
/// are not automatically handled", says its own documentation — so a menu
/// showing Ctrl+Plus does not make Ctrl+Plus work. The keyboard handler had a
/// switch listing the actions it answered, the menus had their own bodies, and
/// the keybinding table listed more names than either: zoom, typewriter mode,
/// full screen, print, export, settings, new window and quit could all be
/// rebound in Settings, were all drawn with their key beside them, and none of
/// them did anything when that key was pressed.
///
/// One list closes that. `window_action_coverage_test` checks that every
/// bindable name is either a [FormatAction] or in here, so a name that nothing
/// carries out cannot be offered for binding.
abstract final class WindowActions {
  static final List<WindowAction> all = [
    WindowAction('find', (_, ref) => ref.read(editorProvider.notifier).toggleFindReplace()),
    WindowAction('replace', (_, ref) => ref.read(editorProvider.notifier).toggleFindReplace()),
    WindowAction('save', (_, ref) => AppMenuBar.saveFile(ref)),
    WindowAction('open', (_, ref) => AppMenuBar.openFile(ref)),
    WindowAction(
      'findNext',
      (_, ref) => ref.read(editorProvider.notifier).stepToFindMatch(forward: true),
    ),
    WindowAction(
      'findPrevious',
      (_, ref) => ref.read(editorProvider.notifier).stepToFindMatch(forward: false),
    ),
    WindowAction('closeTab', (context, ref) {
      final tab = ref.read(activeTabProvider);
      if (tab != null) EditorTabBar.closeTab(context, ref, tab);
    }),
    WindowAction('commandPalette', (context, _) => CommandPalette.show(context)),
    WindowAction(
      'sourceMode',
      (_, ref) => ref.read(settingsProvider.notifier).setEditMode(EditMode.source),
    ),
    WindowAction(
      'previewMode',
      (_, ref) => ref.read(settingsProvider.notifier).setEditMode(EditMode.preview),
    ),
    WindowAction(
      'splitMode',
      (_, ref) => ref.read(settingsProvider.notifier).setEditMode(EditMode.split),
    ),
    WindowAction('toggleTabBar', (_, ref) => ref.read(settingsProvider.notifier).toggleTabBar()),
    WindowAction('toggleSidebar', (_, ref) => ref.read(settingsProvider.notifier).toggleSideBar()),
    WindowAction('focusMode', (_, ref) => ref.read(settingsProvider.notifier).toggleFocusMode()),

    // Below here: the eleven that could be bound and did nothing.
    WindowAction(
      'typewriterMode',
      (_, ref) => ref.read(settingsProvider.notifier).toggleTypewriterMode(),
    ),
    WindowAction('zoomIn', (_, ref) => _zoomBy(ref, 2)),
    WindowAction('zoomOut', (_, ref) => _zoomBy(ref, -2)),
    WindowAction(
      'resetZoom',
      (_, ref) => ref.read(settingsProvider.notifier).setFontSize(defaultZoom),
    ),
    WindowAction('newWindow', (_, __) => AppMenuBar.newWindow()),
    WindowAction('settings', (_, __) => openSettings()),
    // `close`, not `exit(0)`: the window prevents its own close, so this
    // reaches the handler that asks about unsaved work and saves the geometry.
    WindowAction('quit', (_, __) => windowManager.close()),
    WindowAction('print', (_, ref) => AppMenuBar.printDocument(ref)),
    WindowAction('exportPdf', (_, ref) => AppMenuBar.exportPdf(ref)),
    WindowAction('reloadImages', (_, ref) => ref.read(editorProvider.notifier).reloadImages()),
    WindowAction('fullScreen', (_, ref) => AppMenuBar.toggleFullScreen(ref)),
  ];

  /// The font size "Reset zoom" goes back to.
  static const defaultZoom = 16.0;

  /// The action called [name], or null when nothing here is.
  static WindowAction? byName(String? name) =>
      all.where((a) => a.name == name).firstOrNull;

  static void _zoomBy(WidgetRef ref, double by) {
    final size = ref.read(settingsProvider).fontSize + by;
    ref
        .read(settingsProvider.notifier)
        .setFontSize(size.clamp(AppConstants.minFontSize, AppConstants.maxFontSize));
  }

  /// Slides the settings screen in over the editor.
  ///
  /// Reached from the File menu and from the shortcut bound to `settings`,
  /// which is why it is not written inside the menu item.
  static void openSettings() {
    navigatorKey.currentState?.push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

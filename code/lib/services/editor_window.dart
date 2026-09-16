import 'dart:ui';

import 'package:window_manager/window_manager.dart';

import 'window_placement.dart';

/// How the window is being shown.
enum WindowState {
  /// On screen, neither maximised nor full screen.
  normal,

  /// Filling the work area, with the title bar still there.
  maximized,

  /// In the taskbar. Nothing is drawn, so a screenshot taken now is of
  /// nothing — recoverable by asking for any other state.
  minimized,

  /// Filling the screen with no title bar.
  fullscreen,
}

/// What the window looks like, measured rather than remembered.
class WindowReading {
  const WindowReading({required this.state, required this.size});

  final WindowState state;
  final Size size;

  @override
  String toString() =>
      '${state.name}, ${size.width.round()}×${size.height.round()}';
}

/// The editor's own window, as much of it as can be driven from outside.
///
/// An interface because the automation interface has to be exercised without
/// one: `window_manager` speaks to the platform over a channel, and there is
/// no platform under `flutter test`. The real implementation is below and
/// holds no logic of its own — everything worth testing is in the caller.
abstract interface class EditorWindow {
  /// Puts the window into [state].
  Future<void> apply(WindowState state);

  /// Resizes the window. Callers check [WindowPlacement.minimumSize] first.
  Future<void> resize(Size size);

  /// What the window is now, asked of the platform rather than assumed.
  Future<WindowReading> read();
}

/// [EditorWindow] against the real window.
class PlatformEditorWindow implements EditorWindow {
  const PlatformEditorWindow();

  @override
  Future<void> apply(WindowState state) async {
    // Ordered so that each state is reached from any other. Leaving full
    // screen before maximising matters: a full-screen window that is told to
    // maximise stays full screen on Windows, and nothing would say so.
    switch (state) {
      case WindowState.minimized:
        await windowManager.minimize();
      case WindowState.fullscreen:
        if (await windowManager.isMinimized()) await windowManager.restore();
        await windowManager.setFullScreen(true);
      case WindowState.maximized:
        if (await windowManager.isMinimized()) await windowManager.restore();
        if (await windowManager.isFullScreen()) {
          await windowManager.setFullScreen(false);
        }
        await windowManager.maximize();
      case WindowState.normal:
        if (await windowManager.isMinimized()) await windowManager.restore();
        if (await windowManager.isFullScreen()) {
          await windowManager.setFullScreen(false);
        }
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        }
    }
  }

  @override
  Future<void> resize(Size size) async {
    // A maximised window ignores a resize and stays the size it was, which
    // would make the answer below a lie about a window that never moved.
    if (await windowManager.isMaximized()) await windowManager.unmaximize();
    if (await windowManager.isFullScreen()) {
      await windowManager.setFullScreen(false);
    }
    await windowManager.setSize(size);
  }

  @override
  Future<WindowReading> read() async {
    // Full screen first, then maximised: a full-screen window reports itself
    // maximised on some platforms, and the more specific answer is the true
    // one.
    final state = await windowManager.isMinimized()
        ? WindowState.minimized
        : await windowManager.isFullScreen()
            ? WindowState.fullscreen
            : await windowManager.isMaximized()
                ? WindowState.maximized
                : WindowState.normal;
    return WindowReading(state: state, size: await windowManager.getSize());
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the window is currently full screen.
///
/// Held here only so the menu can show a tick. The window itself stays the
/// authority: every toggle reads the real state from window_manager first, so
/// a drift — the user pressing the system full-screen shortcut, say — corrects
/// itself on the next toggle rather than inverting it.
final fullScreenProvider = StateProvider<bool>((ref) => false);

/// Whether the window is pinned above others. Same arrangement as
/// [fullScreenProvider].
final alwaysOnTopProvider = StateProvider<bool>((ref) => false);

import 'dart:math' as math;
import 'dart:ui';

/// Deciding where a window may reopen.
///
/// The size and position of the window are written down when it closes and
/// put back when it opens. Put back without checking, they reopen the window
/// wherever it was — including on a monitor that is no longer attached. The
/// application then starts, takes focus, and is nowhere on screen: there is
/// nothing to drag back, and no way out but editing the configuration file by
/// hand or deleting it.
///
/// Free of any plugin so it can be tested against arbitrary screen
/// arrangements — which is the whole difficulty, since the machine running
/// the tests has one screen and the failure needs two.
class WindowPlacement {
  const WindowPlacement._();

  /// The smallest window worth reopening. Below this the title bar is not
  /// reliably grabbable.
  static const minimumSize = Size(480, 320);

  /// How much of the window has to be on a screen for it to count as
  /// reachable.
  ///
  /// Not all of it: a window deliberately pushed half off the side should
  /// come back where it was. Enough that the title bar can be grabbed.
  static const _requiredVisible = Size(120, 40);

  /// Where a window of [size] at [position] should actually open, given the
  /// screens that exist now.
  ///
  /// Returns the position unchanged when it is reachable. Otherwise centres
  /// the window on [screens.first], which is the primary display.
  static ({Offset position, Size size}) fit({
    required Offset position,
    required Size size,
    required List<Rect> screens,
  }) {
    // No screens reported — a headless session, or a plugin that answered
    // nothing. Changing the window's place on a guess would be worse than
    // leaving it.
    if (screens.isEmpty) return (position: position, size: size);

    final bounded = Size(
      math.max(size.width, minimumSize.width),
      math.max(size.height, minimumSize.height),
    );

    // A window larger than every screen is shrunk to the primary one rather
    // than left with its controls off the edge.
    final primary = screens.first;
    final fitted = Size(
      math.min(bounded.width, primary.width),
      math.min(bounded.height, primary.height),
    );

    final window = position & fitted;
    for (final screen in screens) {
      final overlap = screen.intersect(window);
      if (overlap.width >= _requiredVisible.width &&
          overlap.height >= _requiredVisible.height) {
        return (position: position, size: fitted);
      }
    }

    return (
      position: Offset(
        primary.left + (primary.width - fitted.width) / 2,
        primary.top + (primary.height - fitted.height) / 2,
      ),
      size: fitted,
    );
  }
}

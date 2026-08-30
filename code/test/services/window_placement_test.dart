import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/window_placement.dart';

/// Where the window is allowed to reopen.
///
/// The window's place is written down when it closes and put back when it
/// opens. Put back unchecked, it reopens on a monitor that may no longer be
/// there: the application starts, takes focus, and is nowhere on screen. There
/// is nothing to drag back and no way out but editing the configuration by
/// hand.
///
/// The arrangements below are the reason this is a plain function rather than
/// something that asks the plugin — the machine running these has one screen,
/// and the failure needs two.
void main() {
  const laptop = Rect.fromLTWH(0, 0, 1920, 1080);
  const secondToTheRight = Rect.fromLTWH(1920, 0, 2560, 1440);

  ({Offset position, Size size}) fit(
    Offset at,
    Size size, [
    List<Rect> screens = const [laptop],
  ]) =>
      WindowPlacement.fit(position: at, size: size, screens: screens);

  test('a window already on screen is left where it is', () {
    final result = fit(const Offset(100, 100), const Size(1200, 800));
    expect(result.position, const Offset(100, 100));
    expect(result.size, const Size(1200, 800));
  });

  test('a window on a monitor that is gone comes back to the middle', () {
    // Closed on the second screen, reopened with only the laptop attached.
    final result = fit(const Offset(2400, 300), const Size(1200, 800));
    expect(result.position, const Offset(360, 140),
        reason: '窗口没有被拉回可见区域，应用会在屏幕外打开');
  });

  test('that same window is left alone while the monitor is still there', () {
    final result = fit(const Offset(2400, 300), const Size(1200, 800),
        [laptop, secondToTheRight]);
    expect(result.position, const Offset(2400, 300));
  });

  test('a window mostly off the left edge still comes back', () {
    expect(fit(const Offset(-1900, 100), const Size(1200, 800)).position,
        const Offset(360, 140));
  });

  test('a window pushed a little off the side is left as it was', () {
    // Deliberate placement, not a lost monitor. Enough of it is reachable.
    final result = fit(const Offset(1800, 100), const Size(1200, 800));
    expect(result.position, const Offset(1800, 100));
  });

  test('a window below the bottom edge comes back', () {
    expect(fit(const Offset(100, 2000), const Size(1200, 800)).position,
        const Offset(360, 140));
  });

  group('the size is made usable too', () {
    test('a window bigger than the screen is brought down to it', () {
      final result = fit(const Offset(0, 0), const Size(4000, 3000));
      expect(result.size, const Size(1920, 1080));
    });

    test('a window too small to grab is grown', () {
      final result = fit(const Offset(100, 100), const Size(50, 20));
      expect(result.size, WindowPlacement.minimumSize);
    });

    test('a stored size of zero — a config never written — is usable', () {
      final result = fit(const Offset(0, 0), Size.zero);
      expect(result.size, WindowPlacement.minimumSize);
    });
  });

  test('with no screens reported, nothing is moved', () {
    // A headless session, or a plugin that answered nothing. Moving the
    // window on a guess would be worse than leaving it.
    final result = fit(const Offset(2400, 300), const Size(1200, 800), const []);
    expect(result.position, const Offset(2400, 300));
    expect(result.size, const Size(1200, 800));
  });

  test('a screen arranged above the primary one counts', () {
    const above = Rect.fromLTWH(0, -1080, 1920, 1080);
    final result =
        fit(const Offset(200, -900), const Size(1200, 800), [laptop, above]);
    expect(result.position, const Offset(200, -900),
        reason: '负坐标在多屏排布里是正常的，不该被当作越界');
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Closing while minimized does not overwrite where the window was.
///
/// A reader lost their window: they closed the editor and the next launch
/// opened it somewhere they could not find and could not drag back. The close
/// had happened while the window was minimized — an update performed it — and
/// Windows does not report a minimized window's place. It reports the corner
/// it parks them in, far off every screen, at a size of a few dozen pixels.
/// That was read back as "where the window is" and written down.
///
/// The restoring side already refuses to reopen off every screen, which is why
/// this is a separate fault rather than the same one: it stored a place that
/// was never anywhere. Guarded at the source, because the only way to know the
/// window is minimized is to ask the platform, and asking the platform is what
/// no test here can do.
void main() {
  test('the geometry of a minimized window is not written down', () {
    final source = File('lib/ui/screens/home_screen.dart').readAsStringSync();
    final opens = source.indexOf('Future<void> _saveWindowGeometry()');
    expect(opens, greaterThan(-1));
    final body = source.substring(opens, source.indexOf('\n  }', opens));

    expect(body, contains('isMinimized()'),
        reason: 'the geometry is stored without asking whether the window is '
            'anywhere, and a minimized one is not');
    // Before the write, not merely somewhere in the method: asking and then
    // storing the answer anyway is the same fault with a question in front.
    expect(body.indexOf('isMinimized()'), lessThan(body.indexOf('saveWindowState')),
        reason: 'the check happens after the values have already been stored');
    expect(body, contains('return;'),
        reason: 'nothing stops the write when the window is minimized');
  });
}

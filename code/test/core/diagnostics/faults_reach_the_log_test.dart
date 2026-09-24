import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The fault reporter is wired to the two places faults arrive from.
///
/// Written and never wired up is this project's most frequent defect, and a
/// diagnostic is the worst place for it: the class can be perfect, its tests
/// green, and the log still silent about every crash — with nothing to notice
/// because nothing was expecting a line. Both handlers are global and are set
/// once during startup, which is a shape no widget test reaches, so this reads
/// the startup itself.
void main() {
  /// Startup with comments removed, so prose about a handler is not mistaken
  /// for the handler.
  String startupCode() => File('lib/main.dart')
      .readAsStringSync()
      .split('\n')
      .map((line) {
        final comment = line.indexOf('//');
        return comment == -1 ? line : line.substring(0, comment);
      })
      .join('\n');

  test('both ways a fault arrives are reported', () {
    final code = startupCode();
    // A throw while the framework builds, lays out or paints.
    expect(code, contains('FlutterError.onError ='),
        reason: 'a widget that throws paints a grey rectangle and says '
            'nothing at all');
    // A throw from a future nobody awaited.
    expect(code, contains('PlatformDispatcher.instance.onError ='),
        reason: 'an unawaited future that throws goes to a console a windowed '
            'program does not have');
    expect(code, contains('Faults('),
        reason: 'the handlers are installed but nothing turns a fault into a '
            'line');
  });

  test('what the framework used to do, it still does', () {
    // These handlers replace the defaults rather than adding to them. Taking
    // the reporting away in order to report it would be a poor trade: the
    // debug console and the error widget are how this is noticed while it is
    // being written.
    final code = startupCode();
    expect(code, contains('FlutterError.presentError(details)'),
        reason: 'installing the handler silently threw away the framework\'s '
            'own reporting');
    // Inside that handler, not anywhere in the file: `return false;` occurs
    // in the startup argument filter too, and a guard that finds it there
    // passes whatever the handler does.
    final opens = code.indexOf('PlatformDispatcher.instance.onError =');
    expect(opens, greaterThan(-1));
    final handler = code.substring(opens, code.indexOf('\n  };', opens));
    expect(handler, contains('return false;'),
        reason: 'the platform handler claims the error is dealt with, which '
            'stops it being reported anywhere else');
  });
}

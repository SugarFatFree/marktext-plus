import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/diagnostics/faults.dart';

/// Faults reach the log, and do not take it over.
///
/// The editor reported no fault it had not gone looking for: a throw while a
/// widget builds paints a grey rectangle in a release build and writes
/// nothing, and a throw from an unawaited future goes to a console a windowed
/// program does not have. Both are invisible in the log a reader can open.
///
/// Saying them has a cost, and it is the reason this is a class rather than a
/// line: a build that throws throws on every frame afterwards, so the naive
/// version replaces five hundred lines of history with four hundred copies of
/// one message — and the history is the part that explains it.
StackTrace traceFrom(String innermost) =>
    StackTrace.fromString('#0      $innermost\n#1      main (file:///m.dart)');

void main() {
  test('it says what threw and where', () {
    final line = Faults().consider(
      error: StateError('no tab'),
      stack: traceFrom('TabNotifier.close (file:///tab.dart:12)'),
      at: Duration.zero,
      while_: 'closing the window',
    );
    expect(line, contains('closing the window'));
    expect(line, contains('no tab'));
    expect(line, contains('TabNotifier.close'));
  });

  test('the same fault every frame is said once and then counted', () {
    final faults = Faults(quiet: const Duration(seconds: 10));
    final stack = traceFrom('MarkdownRenderer.build (file:///r.dart:88)');
    Object boom(int i) => RangeError('index $i out of range');

    // Not the same message: a fault carrying a value is a new message every
    // frame while being the same fault. Keying on the message would defeat
    // the whole thing exactly when it is needed most.
    expect(
        faults.consider(error: boom(0), stack: stack, at: Duration.zero),
        isNotNull);
    for (var frame = 1; frame < 400; frame++) {
      expect(
          faults.consider(
              error: boom(frame),
              stack: stack,
              at: Duration(milliseconds: 16 * frame)),
          isNull,
          reason: 'frame $frame filled the log with a fault already reported');
    }
    // And when it does speak again, it says how much it held back.
    final later = faults.consider(
        error: boom(400), stack: stack, at: const Duration(seconds: 11));
    expect(later, contains('399 more like it'));
  });

  test('a different fault is not silenced by the noisy one', () {
    final faults = Faults();
    faults.consider(
        error: StateError('a'),
        stack: traceFrom('one (file:///a.dart:1)'),
        at: Duration.zero);
    expect(
        faults.consider(
            error: StateError('b'),
            stack: traceFrom('two (file:///b.dart:2)'),
            at: const Duration(milliseconds: 1)),
        isNotNull,
        reason: 'the second fault is the one nobody has heard about yet');
  });

  test('it remembers a bounded number of kinds', () {
    // A message with a changing value in it is a new kind every time, so what
    // grows is not the number of faults but the number of kinds — and that is
    // the thing that has to be bounded, not the count of reports.
    final faults = Faults(remember: 4, quiet: const Duration(seconds: 10));
    for (var i = 0; i < 200; i++) {
      faults.consider(
          error: StateError('x'),
          stack: traceFrom('site$i (file:///f.dart:$i)'),
          at: Duration(milliseconds: i));
    }
    // The most recent four are still quiet; the ones before them were let go.
    expect(
        faults.consider(
            error: StateError('x'),
            stack: traceFrom('site199 (file:///f.dart:199)'),
            at: const Duration(milliseconds: 200)),
        isNull);
    expect(
        faults.consider(
            error: StateError('x'),
            stack: traceFrom('site0 (file:///f.dart:0)'),
            at: const Duration(milliseconds: 201)),
        isNotNull,
        reason: 'forgetting an old fault means saying it again, which is the '
            'right price for not growing without end');
  });

  test('a timebase that restarts does not silence it for the rest of the run',
      () {
    final faults = Faults(quiet: const Duration(seconds: 10));
    final stack = traceFrom('x (file:///x.dart:1)');
    faults.consider(
        error: StateError('a'), stack: stack, at: const Duration(hours: 1));
    expect(
        faults.consider(error: StateError('a'), stack: stack, at: Duration.zero),
        isNotNull,
        reason: 'waiting for ten seconds after an hour that has been rewound '
            'is waiting for a moment that never comes');
  });

  test('a fault with no stack is still worth saying', () {
    expect(Faults().consider(error: 'something went wrong', at: Duration.zero),
        contains('something went wrong'));
  });
}

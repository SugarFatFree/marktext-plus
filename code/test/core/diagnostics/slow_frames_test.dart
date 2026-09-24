import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/diagnostics/slow_frames.dart';

/// The editor notices the frames a reader would call a stutter.
///
/// Everything else here times its own work: the parser says how long it
/// parsed, the preview says how long it drew. A stutter is by definition the
/// part nobody measured — and that is exactly what a report of one ran into.
/// With a 117 KB document open beside a small one, the preview drew in a
/// steady 240-320 ms every time, while switching between the two occasionally
/// took 1153 ms; in source mode, where nothing draws a preview, every switch
/// was 44-62 ms. So the second that went missing was neither in the draw nor
/// in the switch, and nothing anywhere could say where it went.
void main() {
  /// A frame at [at] seconds, costing [ms] in total.
  String? frame(SlowFrames watch, int ms, double at, {int? raster}) => watch.consider(
        build: Duration(milliseconds: raster == null ? ms : ms - raster),
        raster: Duration(milliseconds: raster ?? 0),
        at: Duration(microseconds: (at * 1000000).round()),
      );

  test('a frame nobody would notice is not worth a line', () {
    final watch = SlowFrames();
    expect(frame(watch, 8, 1), isNull);
    expect(frame(watch, 16, 2), isNull);
  });

  test('a frame somebody would notice says how long, and where it went', () {
    // Build and raster separately, because they are different faults: one is
    // this editor doing too much work, the other is the picture being too
    // expensive to put on screen.
    final line = frame(SlowFrames(), 400, 1, raster: 90);
    expect(line, isNotNull);
    expect(line, contains('400'));
    expect(line, contains('310'), reason: '构建耗时要单独说');
    expect(line, contains('90'), reason: '光栅化耗时也要单独说');
  });

  test('a burst is one line, and says how many it stood for', () {
    // A stutter is not one slow frame, it is a run of them. Logging each would
    // push everything else out of a log that keeps five hundred lines.
    final watch = SlowFrames();
    expect(frame(watch, 300, 1.0), isNotNull);
    for (var i = 1; i < 20; i++) {
      expect(frame(watch, 300, 1.0 + i * 0.05), isNull,
          reason: '同一阵卡顿里的后续帧不该各占一行');
    }
    final next = frame(watch, 300, 5.0);
    expect(next, contains('19'), reason: '压下去了多少帧，要说出来');
  });

  test('a later stutter is reported on its own', () {
    final watch = SlowFrames();
    frame(watch, 300, 1.0);
    final later = frame(watch, 300, 30.0);
    expect(later, isNotNull);
    expect(later, isNot(contains('and ')), reason: '中间没有被压下去的帧就别提');
  });

  test('a count that has been reported is not reported again', () {
    // Only the third line tells these apart, which is why a mutation that
    // never cleared the count passed everything else here: after a burst has
    // been stood for once, the next lone stutter must not claim those frames
    // a second time. Left uncleared, every line from then on carries a number
    // that grew and never shrank.
    final watch = SlowFrames();
    frame(watch, 300, 1.0);
    for (var i = 1; i < 6; i++) {
      frame(watch, 300, 1.0 + i * 0.05);
    }
    expect(frame(watch, 300, 5.0), contains('5 more'));

    final lone = frame(watch, 300, 30.0);
    expect(lone, isNotNull);
    expect(lone, isNot(contains('more')),
        reason: '那 5 帧已经报过一次了，不该再算一次');
  });

  test('a frame timer that goes backwards does not silence it for ever', () {
    // Frame timestamps come from the engine and are not wall-clock; a restart
    // of the timebase must not leave this waiting for a moment that never
    // arrives.
    final watch = SlowFrames();
    expect(frame(watch, 300, 100.0), isNotNull);
    expect(frame(watch, 300, 1.0), isNotNull,
        reason: '时间倒退时也该照报，而不是从此沉默');
  });
}

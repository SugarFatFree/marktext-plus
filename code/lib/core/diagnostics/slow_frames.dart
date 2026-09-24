/// Notices the frames a reader would call a stutter, and says so.
///
/// Everything else in this editor times its own work: the parser says how long
/// it parsed, the preview says how long it drew, the startup trace says how
/// long each phase took. A stutter is by definition the part nobody measured,
/// and a report of one ran straight into that. With a 117 KB document open
/// beside a small one, the preview drew in a steady 240-320 ms every time,
/// while switching between the two occasionally took 1153 ms — and in source
/// mode, where no preview is drawn, every switch took 44-62 ms. The missing
/// second was in neither of the two things that were being timed, and nothing
/// anywhere could say where it went.
///
/// Free of Flutter so it can be tested without a frame: the caller hands it
/// what the engine reported.
class SlowFrames {
  SlowFrames({
    this.visible = const Duration(milliseconds: 100),
    this.quiet = const Duration(seconds: 2),
  });

  /// How long a frame has to take before it is worth a line.
  ///
  /// A frame is meant to take 16 ms. Sixteen is not a stutter and neither is
  /// forty; a tenth of a second is where a reader stops believing the window
  /// is listening to them.
  final Duration visible;

  /// How long to say nothing after reporting one.
  ///
  /// A stutter is not one slow frame, it is a run of them — filling a large
  /// document produces hundreds. A line each would push everything else out of
  /// a log that keeps five hundred lines, so the run is reported once and the
  /// rest are counted.
  final Duration quiet;

  Duration? _lastReport;
  int _suppressed = 0;

  /// The line to log for this frame, or null if there is nothing to say.
  ///
  /// [at] is the engine's own timestamp rather than a clock read: this is
  /// called for every frame and reading a clock per frame to decide whether to
  /// stay quiet would be its own small cost.
  String? consider({
    required Duration build,
    required Duration raster,
    required Duration at,
  }) {
    final total = build + raster;
    if (total < visible) return null;

    final last = _lastReport;
    // `at < last` means the engine's timebase restarted. Treating that as "not
    // long enough ago" would leave this waiting for a moment that never comes.
    if (last != null && at >= last && at - last < quiet) {
      _suppressed++;
      return null;
    }
    _lastReport = at;

    final stood = _suppressed;
    _suppressed = 0;
    final where = 'build ${build.inMilliseconds} ms, '
        'raster ${raster.inMilliseconds} ms';
    return stood == 0
        ? 'slow frame: ${total.inMilliseconds} ms ($where)'
        : 'slow frame: ${total.inMilliseconds} ms ($where), '
            'and $stood more not listed';
  }
}

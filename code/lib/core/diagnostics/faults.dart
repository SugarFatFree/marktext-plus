/// Says that something threw, once per thing rather than once per frame.
///
/// Nothing in this editor reported a fault it had not gone looking for. An
/// exception thrown while a widget builds paints a grey rectangle in a release
/// build and writes nothing; one thrown from an unawaited future is printed to
/// a console a windowed program does not have. So the log a reader can open —
/// and the log somebody diagnosing their machine reads — was silent about the
/// one class of failure nobody wrote code for.
///
/// The cost that has to be paid for saying it is repetition. A build that
/// throws throws again on the next frame and every frame after, and the log
/// keeps five hundred lines: said once per frame, one fault erases the history
/// that would explain it. So it is said once and then counted, and what
/// counts as "the same" is deliberately coarse.
///
/// Free of Flutter so it can be tested without a binding: the caller hands it
/// what the framework reported.
class Faults {
  Faults({this.quiet = const Duration(seconds: 10), this.remember = 32});

  /// How long to say nothing more about a fault already reported.
  final Duration quiet;

  /// How many distinct faults to keep track of.
  ///
  /// Bounded because the thing that grows is not the number of faults but the
  /// number of *kinds*, and a message with a changing number in it is a new
  /// kind every time. Past this, the oldest is forgotten — which at worst
  /// means saying an old fault twice, and never means growing without end.
  final int remember;

  final Map<String, Duration> _saidAt = {};
  final Map<String, int> _since = {};

  /// The line to log for this fault, or null if it has just been said.
  ///
  /// [at] is passed in rather than read from a clock so this stays testable
  /// and so a storm of faults does not become a storm of clock reads.
  String? consider({
    required Object error,
    StackTrace? stack,
    required Duration at,
    String? while_,
  }) {
    final kind = _kindOf(error, stack);
    final said = _saidAt[kind];
    // `at < said` means the timebase restarted; waiting for a moment that will
    // never come would silence this for the rest of the run.
    if (said != null && at >= said && at - said < quiet) {
      _since[kind] = (_since[kind] ?? 0) + 1;
      return null;
    }

    if (!_saidAt.containsKey(kind) && _saidAt.length >= remember) {
      final oldest = _saidAt.entries
          .reduce((a, b) => a.value <= b.value ? a : b)
          .key;
      _saidAt.remove(oldest);
      _since.remove(oldest);
    }
    _saidAt[kind] = at;
    final stood = _since.remove(kind) ?? 0;

    final where = while_ == null ? '' : ' while $while_';
    final again = stood == 0 ? '' : ', and $stood more like it';
    return 'fault$where: $error$again${_firstFrameOf(stack)}';
  }

  /// What counts as the same fault.
  ///
  /// The type and the first line of the stack, not the message: a message
  /// carrying a value — an index, a path, a length — is different on every
  /// frame while the fault is the same one, and telling a reader about it four
  /// hundred times is how the rest of the log gets lost.
  static String _kindOf(Object error, StackTrace? stack) {
    final frame = _firstFrameOf(stack);
    return frame.isEmpty ? error.runtimeType.toString()
        : '${error.runtimeType}$frame';
  }

  /// The innermost frame, which is where it threw.
  ///
  /// One line rather than the whole trace: a full stack in a log a person
  /// scrolls is what makes them stop reading the log.
  static String _firstFrameOf(StackTrace? stack) {
    if (stack == null) return '';
    for (final line in stack.toString().split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      return ' at $trimmed';
    }
    return '';
  }
}

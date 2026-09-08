import 'dart:io';

/// How much memory this process is holding, for the lines that report cost.
///
/// "Small footprint" is one of the three things this editor claims, alongside
/// starting in under a second and handling large files. The other two are
/// measured now — the startup milestones carry their times, the preview says
/// how long a document took — and this one was not measured anywhere at all.
///
/// Read at points that already write a line, never on a timer: the question
/// worth answering is "what did opening that document cost", and a number with
/// nothing beside it answers nothing.
///
/// It is not free. `currentRss` measures at 10 µs a call on the machine this
/// was written on — nothing against the two calls on the startup path (21 µs
/// of a 400 ms start), and enough to matter in a `build` or a keystroke
/// handler, which is why `resident_memory_test` counts the call sites.
abstract final class ResidentMemory {
  /// Megabytes resident, or null where the platform will not say.
  ///
  /// `currentRss` answers 0 on a platform with no implementation rather than
  /// throwing, and "0 MB" in a log reads as a measurement rather than as an
  /// absence — so nothing is said instead.
  static int? megabytes() {
    try {
      final bytes = ProcessInfo.currentRss;
      if (bytes <= 0) return null;
      return bytes ~/ (1024 * 1024);
    } catch (_) {
      // Not worth a failed startup or a lost cost line.
      return null;
    }
  }

  /// " (123 MB resident)", or nothing at all, for appending to a log line.
  static String suffix() {
    final mb = megabytes();
    return mb == null ? '' : ' ($mb MB resident)';
  }
}

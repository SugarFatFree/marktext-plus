import 'dart:io';

import 'package:path/path.dart' as p;

/// What the previous run's exit looked like, measured where Dart could not.
///
/// Dart starts timing a close when it is told about one, and every close timed
/// that way runs 17-35 ms from there to the window going — while the reader
/// reports waiting seconds. So the wait is outside Dart's view: either before
/// the message reaches it, or after the window has gone and the process has
/// not. The Windows runner records the arrival of WM_CLOSE and the last
/// instruction it runs, and leaves them beside the executable; this reads them
/// on the next launch.
///
/// Four numbers rather than two, because asking a reader to close their window
/// costs them an interaction and the answer should not need a second one. They
/// divide the close into the three stretches that can hold the wait: the
/// message sitting in the queue before anything noticed it, the editor's own
/// work, and the process leaving once the window has gone.
///
/// One caveat, for whoever reads a startling number here: when a close prompts
/// about unsaved work, the reader's own deliberation happens inside the
/// editor's stretch, and nothing on this side can tell it from work. The trace
/// from the same run can — it marks the geometry save differently after a
/// prompt — so check that before chasing minutes that belong to a dialog.
abstract final class LastExit {
  /// Reads what the runner left beside the executable, and takes it away.
  ///
  /// Taken away because it is about one exit: left in place, every launch from
  /// then on would report the same close as though it had just happened.
  static String? readAndForget() {
    try {
      final file = File(
        '${p.dirname(Platform.resolvedExecutable)}${Platform.pathSeparator}'
        'last-exit.log',
      );
      if (!file.existsSync()) return null;
      final said = describe(file.readAsStringSync());
      file.deleteSync();
      return said;
    } catch (_) {
      // A file that cannot be read or removed is not worth failing a launch
      // over; it is a diagnostic, and the launch is the thing.
      return null;
    }
  }

  /// What that file says, in a sentence, or null if it says nothing usable.
  static String? describe(String contents) {
    final asked = _numberAfter(contents, 'close-asked-ms=');
    final exiting = _numberAfter(contents, 'exiting-ms=');
    if (asked == null || exiting == null) return null;

    if (asked < 0) {
      // The window was never asked to close: an update replaced the editor, or
      // something else ended it. Reporting a duration here would measure from
      // the start of the run.
      return 'the previous run ended without the window being closed';
    }
    // Not a duration that runs backwards. The clock is the process's own and
    // should only go forwards, but a number that says otherwise is a fault in
    // the measurement, and reporting it would look like a fault in the editor.
    if (exiting < asked) return null;

    final parts = <String>[];
    // Left out when the runner could not vouch for it rather than reported as
    // zero: nothing waiting at all and not knowing are different findings, and
    // this is the stretch the whole line exists to expose.
    final queued = _numberAfter(contents, 'queued-ms=');
    if (queued != null && queued >= 0) {
      parts.add('$queued ms for the button to be heard');
    }
    // When the window was destroyed splits the rest in two: before it is
    // everything the editor does, after it is only the process leaving. Absent
    // — a run that left without the window being destroyed — the two are
    // reported together rather than guessed apart.
    final destroyed = _numberAfter(contents, 'destroyed-ms=');
    if (destroyed != null && destroyed >= asked && destroyed <= exiting) {
      parts.add('${destroyed - asked} ms inside the editor');
      parts.add('${exiting - destroyed} ms to leave');
    } else {
      parts.add('${exiting - asked} ms from being heard to the last '
          'instruction this process ran');
    }
    return 'the previous close: ${parts.join(', ')}';
  }

  static int? _numberAfter(String contents, String label) {
    final at = contents.indexOf(label);
    if (at < 0) return null;
    var end = at + label.length;
    if (end < contents.length && contents[end] == '-') end++;
    while (end < contents.length && _isDigit(contents.codeUnitAt(end))) {
      end++;
    }
    return int.tryParse(contents.substring(at + label.length, end));
  }

  static bool _isDigit(int code) => code >= 0x30 && code <= 0x39;
}

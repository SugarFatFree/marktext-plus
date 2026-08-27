import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Records how long each step of startup and shutdown takes.
///
/// Exists because the app went from opening a file in under a second to taking
/// more than two, and there was no way to tell which step had grown. Every
/// measurement is milliseconds since the process started, so the gaps between
/// consecutive marks are what matter.
///
/// The marks are printed *and* appended to `startup-trace.log` in the config
/// directory: a Windows release build is a GUI subsystem binary, so its stdout
/// never reaches the console it was launched from, and the file is the only
/// way to get the numbers back.
class StartupTrace {
  StartupTrace._();

  static final Stopwatch _since = Stopwatch()..start();
  static final List<String> _lines = <String>[];
  static String? _logPath;
  static int _last = 0;

  /// Records that [phase] has just finished.
  static void mark(String phase) {
    final now = _since.elapsedMilliseconds;
    final line = '${now.toString().padLeft(6)} ms  '
        '(+${(now - _last).toString().padLeft(5)} ms)  $phase';
    _last = now;
    _lines.add(line);
    debugPrint('[startup] $line');
    _appendToFile(line);
  }

  /// Where later marks should be written, once the config directory is known.
  ///
  /// Everything recorded before this point is flushed now, so the marks from
  /// before the directory was resolved are not lost.
  static void useDirectory(String directory) {
    _logPath = '$directory${Platform.pathSeparator}startup-trace.log';
    try {
      File(_logPath!).writeAsStringSync(
        'MarkText Plus startup trace\n'
        '${DateTime.now().toIso8601String()}\n'
        '${_lines.join('\n')}\n',
        flush: true,
      );
    } catch (_) {
      // Diagnostics must never be the reason the app fails to start.
    }
  }

  static void _appendToFile(String line) {
    final path = _logPath;
    if (path == null) return;
    try {
      File(path).writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {
      // As above.
    }
  }

  /// Times [body] and records it as [phase].
  static Future<T> time<T>(String phase, Future<T> Function() body) async {
    final result = await body();
    mark(phase);
    return result;
  }

  /// Times a synchronous [body].
  static T timeSync<T>(String phase, T Function() body) {
    final result = body();
    mark(phase);
    return result;
  }
}

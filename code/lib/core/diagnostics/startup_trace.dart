import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
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

  /// Milliseconds between the process being created and this class first being
  /// touched, or null where that cannot be found out.
  ///
  /// The stopwatch above only starts once Dart is running, which leaves out
  /// everything the person actually waits through first: the shell starting
  /// the process, Windows mapping the executable and its libraries, the engine
  /// coming up. That gap is the whole question when a launch feels slow, so it
  /// is measured rather than left to be inferred from someone's impression.
  static final int? _beforeDart = _millisecondsSinceProcessStart();

  /// Windows records when each process was created; ask for this one.
  static int? _millisecondsSinceProcessStart() {
    if (!Platform.isWindows) return null;
    try {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final getCurrentProcess = kernel32
          .lookupFunction<IntPtr Function(), int Function()>(
        'GetCurrentProcess',
      );
      final getProcessTimes = kernel32.lookupFunction<
          Int32 Function(IntPtr, Pointer<Uint64>, Pointer<Uint64>,
              Pointer<Uint64>, Pointer<Uint64>),
          int Function(int, Pointer<Uint64>, Pointer<Uint64>,
              Pointer<Uint64>, Pointer<Uint64>)>('GetProcessTimes');

      final times = calloc<Uint64>(4);
      try {
        final ok = getProcessTimes(
          getCurrentProcess(),
          times,
          times + 1,
          times + 2,
          times + 3,
        );
        if (ok == 0) return null;
        // FILETIME counts 100ns intervals from 1601-01-01 UTC.
        const ticksTo1970 = 116444736000000000;
        final startedMs = (times.value - ticksTo1970) ~/ 10000;
        final elapsed =
            DateTime.now().toUtc().millisecondsSinceEpoch - startedMs;
        return elapsed < 0 ? null : elapsed;
      } finally {
        calloc.free(times);
      }
    } catch (_) {
      // Diagnostics must never be the reason the app fails to start.
      return null;
    }
  }
  static final List<String> _lines = <String>[];
  static String? _logPath;
  static int _last = 0;

  static Timer? _flushTimer;

  /// Records that [phase] has just finished.
  ///
  /// The line is kept in memory and the file is rewritten on a short timer.
  /// Writing on every mark would put a synchronous open/write/flush inside the
  /// very path being measured — eighteen of them, on the startup that is under
  /// suspicion.
  static void mark(String phase) {
    if (_lines.isEmpty) {
      final before = _beforeDart;
      _lines.add(
        before == null
            ? '        (before Dart: not measured on this platform)'
            : '${before.toString().padLeft(6)} ms  '
                '(+${before.toString().padLeft(5)} ms)  '
                'process start → Dart (shell, exe and DLL loading, engine)',
      );
      _last = 0;
    }
    final now = _since.elapsedMilliseconds;
    final line = '${now.toString().padLeft(6)} ms  '
        '(+${(now - _last).toString().padLeft(5)} ms)  $phase';
    _last = now;
    _lines.add(line);
    debugPrint('[startup] $line');
    _scheduleFlush();
  }

  static void _scheduleFlush() {
    if (_logPath == null || _flushTimer != null) return;
    _flushTimer = Timer(const Duration(milliseconds: 200), () {
      _flushTimer = null;
      flush();
    });
  }

  /// Writes everything recorded so far. Returns whether it landed.
  ///
  /// Called on a timer, and directly at the end of a run: the window is about
  /// to be destroyed there, and a pending timer would never fire.
  static bool flush() {
    final path = _logPath;
    if (path == null) return false;
    try {
      File(path).writeAsStringSync(
        'MarkText Plus startup trace\n'
        '${DateTime.now().toIso8601String()}\n'
        'log: $path\n'
        '${_lines.join('\n')}\n',
        flush: true,
      );
      return true;
    } catch (_) {
      // Diagnostics must never be the reason the app fails to start.
      return false;
    }
  }

  /// Where later marks should be written, once the config directory is known.
  ///
  /// Everything recorded before this point is flushed now, so the marks from
  /// before the directory was resolved are not lost.
  ///
  /// Beside the executable when that folder can be written to, and only then
  /// the config directory. Someone running a build from an unzipped folder
  /// finds the log next to the program; hunting through `%APPDATA%` for it is
  /// its own small ordeal, and one the person reporting a slow start should
  /// not have to go through.
  static void useDirectory(String directory) {
    for (final candidate in [_beside(Platform.resolvedExecutable), directory]) {
      if (candidate == null) continue;
      _logPath = '$candidate${Platform.pathSeparator}startup-trace.log';
      if (flush()) return;
    }
    _logPath = null;
  }

  /// The directory holding [executable], or null if it cannot be determined.
  static String? _beside(String executable) {
    final cut = executable.lastIndexOf(Platform.pathSeparator);
    return cut <= 0 ? null : executable.substring(0, cut);
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

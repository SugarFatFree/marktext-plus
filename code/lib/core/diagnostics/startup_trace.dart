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
  /// Reads a milestone the Windows runner left in the environment.
  ///
  /// `windows/runner/main.cpp` stamps three of these before the engine starts.
  /// Missing values mean an older build, or a platform whose runner is not
  /// instrumented; either way the line simply says so rather than guessing.
  static int? _runnerMark(String name) {
    final raw = Platform.environment[name];
    if (raw == null) return null;
    final value = int.tryParse(raw.trim());
    return (value == null || value < 0) ? null : value;
  }

  /// The part of startup that happens before Dart can time anything.
  ///
  /// Split rather than reported as one number: "1.8 seconds before Dart" says
  /// nothing about what to do next, whereas knowing whether it went into
  /// loading the executable, starting the engine or running up to the first
  /// Dart line points at three completely different problems.
  static List<String> _preDartLines() {
    String row(int at, int delta, String phase) =>
        '${at.toString().padLeft(6)} ms  '
        '(+${delta.toString().padLeft(5)} ms)  $phase';

    final runnerEntry = _runnerMark('MARKTEXT_TRACE_RUNNER_ENTRY');
    final engineStart = _runnerMark('MARKTEXT_TRACE_ENGINE_START');
    final windowCreated = _runnerMark('MARKTEXT_TRACE_WINDOW_CREATED');
    final beforeDart = _beforeDart;

    if (runnerEntry == null) {
      // No runner marks: either an older build or a platform where the runner
      // does not stamp them. The single total is still worth having.
      return [
        beforeDart == null
            ? '        (before Dart: not measured on this build)'
            : row(beforeDart, beforeDart,
                'process start → Dart (runner not instrumented; total only)'),
      ];
    }

    final lines = <String>[
      row(runnerEntry, runnerEntry,
          'process created → runner entry (Windows loading the exe and DLLs)'),
    ];
    if (engineStart != null) {
      lines.add(row(engineStart, engineStart - runnerEntry,
          'runner entry → engine start (console, COM, command line)'));
      if (windowCreated != null) {
        lines.add(row(windowCreated, windowCreated - engineStart,
            'engine start → window created (engine boot, AOT snapshot load)'));
      }
    }
    if (beforeDart != null) {
      final previous = windowCreated ?? engineStart ?? runnerEntry;
      lines.add(row(beforeDart, beforeDart - previous,
          'window created → first Dart mark'));
    }
    return lines;
  }

  static final List<String> _lines = <String>[];
  static String? _logPath;
  static int _last = 0;

  static Timer? _flushTimer;

  /// Which build this is, as the CI stamped it in.
  ///
  /// Written into the trace because a log with no build in it cannot be read:
  /// a report of a slow launch was diagnosed against the source as it stood,
  /// while the binary that produced it turned out to be several commits older
  /// — the line that gave it away was a phase name that no longer exists. One
  /// line in the header settles that for good.
  static String get buildStamp {
    const sha = String.fromEnvironment('BUILD_SHA');
    const run = String.fromEnvironment('BUILD_RUN');
    if (sha.isEmpty && run.isEmpty) {
      return 'build: local (no BUILD_SHA; this is not a CI build)';
    }
    final short = sha.length >= 8 ? sha.substring(0, 8) : sha;
    return 'build: ${short.isEmpty ? '?' : short}'
        '${run.isEmpty ? '' : '  (CI run #$run)'}';
  }

  static final Set<String> _once = <String>{};

  /// Records [phase] the first time it happens and never again.
  ///
  /// For marks that sit inside a `build` — those run on every rebuild, and a
  /// trace that repeats the same line hundreds of times is harder to read than
  /// one that omits it.
  static void markOnce(String phase) {
    if (_once.add(phase)) mark(phase);
  }

  static Timer? _shutdownWatchdog;

  /// Starts reporting that the process is still here, and eventually leaves.
  ///
  /// Closing the window has been taking visibly longer than the 10 ms that
  /// `destroy()` reports, so something outlives the Dart-level tidy-up. This
  /// serves two purposes at once, and the second only works because of the
  /// first:
  ///
  /// * **It says which kind of hang it is.** If these lines appear in the log,
  ///   the Dart isolate is still running while the window will not go away —
  ///   something is blocking the Win32 message loop. If the log stops dead at
  ///   `window destroyed` with no lines from here, the isolate is already gone
  ///   and whatever is holding the process open is native. Those are two
  ///   different problems and nothing else in the trace tells them apart.
  /// * **It stops the wait.** Everything that has to reach disk — the window
  ///   geometry, the document, the settings — was written before this is
  ///   armed, so leaving is safe once the wait becomes the worse outcome.
  ///
  /// Armed before `destroy()` rather than after, so that a `destroy()` which
  /// never returns is covered too.
  static void armShutdownWatchdog({
    Duration interval = const Duration(milliseconds: 100),
    Duration giveUpAfter = const Duration(milliseconds: 600),
  }) {
    _shutdownWatchdog?.cancel();
    final armedAt = _since.elapsedMilliseconds;
    _shutdownWatchdog = Timer.periodic(interval, (timer) {
      final waiting = _since.elapsedMilliseconds - armedAt;
      mark('still running ${waiting}ms after close began');
      if (waiting >= giveUpAfter.inMilliseconds) {
        timer.cancel();
        mark('leaving rather than making the reader wait any longer');
        flush();
        exit(0);
      }
    });
  }

  /// Called when shutdown completed on its own; stops the watchdog.
  static void shutdownFinished() {
    _shutdownWatchdog?.cancel();
    _shutdownWatchdog = null;
  }

  /// Records that [phase] has just finished.
  ///
  /// The line is kept in memory and the file is rewritten on a short timer.
  /// Writing on every mark would put a synchronous open/write/flush inside the
  /// very path being measured — eighteen of them, on the startup that is under
  /// suspicion.
  static void mark(String phase) {
    if (_lines.isEmpty) {
      _lines.addAll(_preDartLines());
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
        '$buildStamp\n'
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

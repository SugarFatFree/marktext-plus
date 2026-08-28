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
  static final Map<String, int> _runnerMarks = <String, int>{};
  static List<String> _entrypointArguments = const [];

  /// Picks the runner's own timings out of the entrypoint arguments.
  ///
  /// `windows/runner/main.cpp` appends `--mt-trace-…=<ms>` arguments before the
  /// engine starts. The first attempt used environment variables and Dart's
  /// `Platform.environment` never saw them — the trace read "runner not
  /// instrumented" on a build that certainly was — so they travel as arguments
  /// now, which arrive in `main` with nothing in between to lose them.
  ///
  /// Call before the first [mark].
  static void readRunnerArguments(List<String> args) {
    // Kept whatever happens: two attempts at getting the runner's own timings
    // across have now arrived as nothing, and "the marks are missing" does not
    // say whether the runner failed to add them or the engine failed to pass
    // them on. The raw list settles that in one line.
    _entrypointArguments = args;
    const prefix = '--mt-trace-';
    for (final arg in args) {
      if (!arg.startsWith(prefix)) continue;
      final equals = arg.indexOf('=');
      if (equals < 0) continue;
      final value = int.tryParse(arg.substring(equals + 1).trim());
      if (value == null || value < 0) continue;
      _runnerMarks[arg.substring(prefix.length, equals)] = value;
    }
  }

  /// The two timings the runner could only take after the arguments were set.
  ///
  /// Read from an exported symbol in the executable itself, because the
  /// entrypoint arguments are handed over before the engine starts and cannot
  /// carry anything measured afterwards. Slot 0 is just before the Flutter
  /// view controller is built and slot 1 just after — and building it is what
  /// boots the engine, loads the AOT snapshot and brings up the GPU surface.
  ///
  /// It exists to answer one question before any effort goes into making the
  /// snapshot smaller: of the 2.7 seconds between the runner starting and the
  /// first line of Dart, how much of it is that step?
  ///
  /// Null on anything but Windows, and on a build whose runner predates it.
  static (int, int)? _engineWindow() {
    if (!Platform.isWindows) return null;
    try {
      final symbol = DynamicLibrary.executable().lookup<Int64>('mt_trace_engine');
      final before = symbol[0];
      final after = symbol[1];
      if (before < 0 || after < before) return null;
      return (before, after);
    } catch (_) {
      // An older runner, or a platform that does not export it.
      return null;
    }
  }

  static int? _runnerMark(String name) => _runnerMarks[name];

  @visibleForTesting
  static int? runnerMarkForTesting(String name) => _runnerMark(name);

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

    final runnerEntry = _runnerMark('runner-entry');
    final engineStart = _runnerMark('engine-start');
    final beforeDart = _beforeDart;

    if (runnerEntry == null) {
      // No runner marks: either an older build or a platform where the runner
      // does not stamp them. The single total is still worth having.
      final seen = _entrypointArguments.isEmpty
          ? 'none'
          : _entrypointArguments.join(' ');
      return [
        beforeDart == null
            ? '        (before Dart: not measured on this build)'
            : row(beforeDart, beforeDart,
                'process start → Dart (runner marks absent; total only)'),
        '        entrypoint args as Dart saw them: $seen',
      ];
    }

    final lines = <String>[
      row(runnerEntry, runnerEntry,
          'process created → runner entry (Windows loading the exe and DLLs)'),
    ];
    if (engineStart != null) {
      lines.add(row(engineStart, engineStart - runnerEntry,
          'runner entry → engine start (console, COM, command line)'));
    }
    // Which renderer the runner asked the engine for, when it said.
    final impeller = _runnerMarks.containsKey('impeller')
        ? (_runnerMark('impeller') == 0 ? 'Impeller off' : 'Impeller on')
        : null;
    if (impeller != null) {
      lines.add('        renderer: $impeller');
    }

    final engine = _engineWindow();
    if (engine != null) {
      final (before, after) = engine;
      final previous = engineStart ?? runnerEntry;
      lines.add(row(before, before - previous,
          'engine start → creating the view (plugin registration)'));
      lines.add(row(after, after - before,
          'creating the view (engine boot, AOT snapshot, GPU surface)'));
      if (beforeDart != null) {
        lines.add(row(beforeDart, beforeDart - after,
            'view created → first Dart mark'));
      }
      return lines;
    }

    if (beforeDart != null) {
      final previous = engineStart ?? runnerEntry;
      lines.add(row(beforeDart, beforeDart - previous,
          'engine start → first Dart mark (engine boot, AOT snapshot load)'));
    }
    return lines;
  }

  static final List<String> _lines = <String>[];
  static final List<String> _logPaths = <String>[];

  /// Traces from earlier runs, kept above this one.
  ///
  /// The file used to be overwritten on every launch, so answering "is this
  /// only the first launch, or every launch?" meant starting the program,
  /// copying the file, starting it again and copying it again. That question
  /// decides whether a slow start is Windows reading a cold binary off disk or
  /// something the program itself is doing, so it should not cost the person
  /// reporting it four steps.
  static String _earlierRuns = '';

  /// How many launches the file keeps. Enough to compare a cold start with the
  /// warm ones after it.
  static const _runsKept = 4;

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
    const sdk = String.fromEnvironment('BUILD_SDK');
    final short = sha.length >= 8 ? sha.substring(0, 8) : sha;
    return 'build: ${short.isEmpty ? '?' : short}'
        '${run.isEmpty ? '' : '  (CI run #$run)'}'
        // Which SDK produced this. The channel moves week to week, so two
        // traces taken a month apart differ by more than the source does.
        '${sdk.isEmpty ? '' : '  Flutter $sdk'}';
  }

  /// Where the trace is being written, once that has been settled.
  ///
  /// The config directory when anything is being written at all, since that
  /// one is always there and always writable.
  static String? get logPath => _logPaths.isEmpty ? null : _logPaths.first;

  /// Every place the trace is being written.
  static List<String> get logPaths => List.unmodifiable(_logPaths);

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
    if (_logPaths.isEmpty || _flushTimer != null) return;
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
    if (_logPaths.isEmpty) return false;
    final body = '$_earlierRuns'
        '$_runSeparator\n'
        '${DateTime.now().toIso8601String()}\n'
        '$buildStamp\n'
        'log: ${_logPaths.join('  |  ')}\n'
        '${_lines.join('\n')}\n';
    var landed = false;
    for (final path in _logPaths) {
      try {
        File(path).writeAsStringSync(body, flush: true);
        landed = true;
      } catch (_) {
        // Diagnostics must never be the reason the app fails to start.
      }
    }
    return landed;
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
  /// The line that starts each run's block in the file.
  @visibleForTesting
  static const runSeparator = '=== MarkText Plus startup trace ===';
  static const _runSeparator = runSeparator;

  /// Keeps the last few runs from [existing], oldest first.
  @visibleForTesting
  static String recentRuns(String existing) => _recentRuns(existing);

  static String _recentRuns(String existing) {
    final runs = existing
        .split(_runSeparator)
        .map((run) => run.trim())
        .where((run) => run.isNotEmpty)
        .toList();
    final kept = runs.length <= _runsKept - 1
        ? runs
        : runs.sublist(runs.length - (_runsKept - 1));
    if (kept.isEmpty) return '';
    return '${kept.map((run) => '$_runSeparator\n$run').join('\n\n')}\n\n';
  }

  static void useDirectory(String directory) {
    _logPaths.clear();
    // The config directory first and unconditionally. Trying beside the
    // executable first and stopping at the first success meant that an
    // installed copy — which lives under Program Files — wrote its trace
    // there, while the person who had been asked for it went looking in the
    // config directory where the settings are, found nothing, and reasonably
    // concluded the log was not being written at all.
    for (final candidate in [directory, _beside(Platform.resolvedExecutable)]) {
      if (candidate == null) continue;
      final path = '$candidate${Platform.pathSeparator}startup-trace.log';
      if (_logPaths.contains(path)) continue;
      // Read before the first write, and only from the first location that
      // has anything: the copies are identical, so the earliest readable one
      // carries the history.
      if (_earlierRuns.isEmpty) {
        try {
          final previous = File(path);
          if (previous.existsSync()) {
            _earlierRuns = _recentRuns(previous.readAsStringSync());
          }
        } catch (_) {
          // An unreadable previous log is not worth failing over.
        }
      }
      _logPaths.add(path);
      if (!flush()) _logPaths.remove(path);
    }
  }

  /// The directory holding [executable], or null if it cannot be determined.
  static String? _beside(String executable) {
    final cut = executable.lastIndexOf(Platform.pathSeparator);
    return cut <= 0 ? null : executable.substring(0, cut);
  }

  /// Records how much there was to load, and what the biggest pieces were.
  ///
  /// Windows has to read all of this before the first line of Dart runs, so
  /// when a launch takes seconds this is the first thing worth knowing. It was
  /// asked of the person reporting the slow start twice, when the program was
  /// sitting in the folder and could have measured it itself.
  ///
  /// Called after the window is on screen: it walks a few dozen files, which
  /// is nothing next to what has already happened, but there is no reason for
  /// it to happen first.
  static void recordInstallSize() {
    try {
      final directory = _beside(Platform.resolvedExecutable);
      if (directory == null) return;
      final files = Directory(directory)
          .listSync(recursive: true)
          .whereType<File>()
          .toList();
      if (files.isEmpty) return;

      var total = 0;
      final sizes = <String, int>{};
      for (final file in files) {
        int length;
        try {
          length = file.lengthSync();
        } on FileSystemException {
          continue;
        }
        total += length;
        sizes[file.uri.pathSegments.last] = length;
      }

      String mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);
      final biggest = sizes.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = biggest
          .take(6)
          .map((e) => '${e.key} ${mb(e.value)}MB')
          .join(', ');
      mark('installed size ${mb(total)}MB in ${files.length} files — $top');
    } catch (_) {
      // A diagnostic is never worth failing a launch over.
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

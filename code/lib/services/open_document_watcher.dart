import 'dart:async';
import '../core/constants.dart';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/diagnostics/startup_trace.dart';

/// Reports when a file that is open in a tab changes on disk.
///
/// Watches the containing *directories* rather than the files themselves: a
/// great many tools — editors, `git checkout`, formatters — save by writing a
/// temporary file and renaming it over the original, which severs a watch held
/// on the file itself and leaves it silent from then on.
class OpenDocumentWatcher {
  /// Creates a watcher.
  OpenDocumentWatcher({this.debounce = const Duration(milliseconds: AppConstants.debounceDelay)});

  /// How long to wait after a notification before reporting it.
  ///
  /// A save arrives as a burst of events — truncate, write, close — and
  /// reading the file between them would see it half written.
  final Duration debounce;

  final _controller = StreamController<String>.broadcast();
  final _subscriptions = <String, StreamSubscription<FileSystemEvent>>{};
  final _timers = <String, Timer>{};
  var _watched = <String>{};

  /// Paths of files that changed on disk.
  Stream<String> get changes => _controller.stream;

  /// Watches exactly [filePaths], dropping any watch no longer wanted.
  void watch(Iterable<String> filePaths) {
    _watched = filePaths.map(p.normalize).toSet();
    final wanted = _watched.map(p.dirname).toSet();

    for (final dir in _subscriptions.keys.toList()) {
      if (wanted.contains(dir)) continue;
      _subscriptions.remove(dir)?.cancel();
    }
    for (final dir in wanted) {
      if (_subscriptions.containsKey(dir)) continue;
      _addWatch(dir);
    }
  }

  void _addWatch(String directory) {
    if (!Directory(directory).existsSync()) return;

    final watch = Stopwatch()..start();
    try {
      _subscriptions[directory] = Directory(directory).watch().listen(
        _onEvent,
        // A watch that fails — the folder went away, or the system ran out of
        // watches — must not take the app down with an unhandled stream error.
        onError: (Object _) => _subscriptions.remove(directory)?.cancel(),
        cancelOnError: true,
      );
    } on FileSystemException {
      // Nothing to watch here; the other documents still work.
    }
    StartupTrace.mark(
      'directory watch created in ${watch.elapsedMilliseconds} ms',
    );
  }

  void _onEvent(FileSystemEvent event) {
    final touched = <String>[
      event.path,
      if (event is FileSystemMoveEvent && event.destination != null)
        event.destination!,
    ];

    for (final raw in touched) {
      final path = p.normalize(raw);
      if (!_watched.contains(path)) continue;

      _timers.remove(path)?.cancel();
      _timers[path] = Timer(debounce, () {
        _timers.remove(path);
        if (!_controller.isClosed) _controller.add(path);
      });
    }
  }

  /// Stops watching everything, leaving the stream open.
  void stop() {
    final watch = Stopwatch()..start();
    final count = _subscriptions.length;
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _watched = {};
    if (count > 0) {
      StartupTrace.mark(
        'cancelled $count directory watch(es) in '
        '${watch.elapsedMilliseconds} ms',
      );
    }
  }

  void dispose() {
    stop();
    _controller.close();
  }
}

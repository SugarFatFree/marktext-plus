import 'dart:async';
import 'dart:io';

/// Reports changes in the directories the sidebar is actually showing.
///
/// Deliberately not a recursive watch of the project root. On Linux each
/// watched directory costs one inotify watch, and the limit
/// (`fs.inotify.max_user_watches`) is easy to exhaust on a large tree — which
/// throws, and the tree only ever displays the levels the user has expanded.
class FileWatcherService {
  final _controller = StreamController<FileSystemEvent>.broadcast();
  final _subscriptions = <String, StreamSubscription<FileSystemEvent>>{};
  Timer? _debounceTimer;

  Stream<FileSystemEvent> get events => _controller.stream;

  /// Watches exactly [paths], dropping any watch no longer wanted.
  ///
  /// Called again whenever the visible set changes, so it reconciles rather
  /// than resubscribing: re-establishing every watch on each refresh would
  /// churn through file descriptors for no reason.
  void watch(Iterable<String> paths) {
    final wanted = paths.toSet();

    for (final path in _subscriptions.keys.toList()) {
      if (wanted.contains(path)) continue;
      _subscriptions.remove(path)?.cancel();
    }

    for (final path in wanted) {
      if (_subscriptions.containsKey(path)) continue;
      _addWatch(path);
    }
  }

  void _addWatch(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return;

    try {
      _subscriptions[path] = dir.watch().listen(
        _onEvent,
        // A watch that fails — the directory went away, or the system ran out
        // of watches — must not take the app down with an unhandled stream
        // error. The tree simply stops updating itself for that folder.
        onError: (Object _) => _subscriptions.remove(path)?.cancel(),
        cancelOnError: true,
      );
    } on FileSystemException {
      // Nothing to watch here; the rest of the tree still works.
    }
  }

  void _onEvent(FileSystemEvent event) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!_controller.isClosed) {
        _controller.add(event);
      }
    });
  }

  void stop() {
    _debounceTimer?.cancel();
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  void dispose() {
    stop();
    _controller.close();
  }
}

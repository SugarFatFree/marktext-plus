import 'dart:async';
import 'dart:io';

class FileWatcherService {
  StreamSubscription<FileSystemEvent>? _watchSubscription;
  final _controller = StreamController<FileSystemEvent>.broadcast();
  Timer? _debounceTimer;

  Stream<FileSystemEvent> get events => _controller.stream;

  void watch(String directoryPath) {
    stop();
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) return;
    _watchSubscription = dir.watch(recursive: true).listen((event) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (!_controller.isClosed) {
          _controller.add(event);
        }
      });
    });
  }

  void stop() {
    _debounceTimer?.cancel();
    _watchSubscription?.cancel();
    _watchSubscription = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}

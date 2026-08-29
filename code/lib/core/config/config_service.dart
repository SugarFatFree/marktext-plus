import 'dart:async';
import 'package:path/path.dart' as p;
import 'app_config.dart';
import 'json_store.dart';

class ConfigService {
  final String configDir;
  late final String _configPath;

  /// The write in flight, if any. Saves are serialised so two overlapping
  /// calls cannot interleave their bytes in the file.
  Future<void>? _writing;

  /// The most recent config waiting to be written. Only the last one matters:
  /// dragging the split divider or opening files fires several saves in a row
  /// and each carries the whole config.
  AppConfig? _queued;

  ConfigService({required this.configDir}) {
    _configPath = p.join(configDir, 'config.json');
  }

  Future<AppConfig> load() async {
    final json = await JsonStore(_configPath).read();
    if (json == null) return AppConfig();
    try {
      return AppConfig.fromJson(json);
    } catch (_) {
      // Parsed as JSON but not as a config — a field of the wrong shape. The
      // store only sets aside what it could not parse at all, so this one is
      // still on disk and would be overwritten by the next save.
      return AppConfig();
    }
  }

  Future<void> save(AppConfig config) {
    _queued = config;

    final inFlight = _writing;
    if (inFlight != null) return inFlight;

    final future = _drain();
    _writing = future;
    return future;
  }

  /// Completes when no write is outstanding.
  ///
  /// Nearly every caller updates a setting and moves on without awaiting, so
  /// this is the only way to know the file on disk has caught up — which a
  /// test tearing down its temp directory needs to know.
  Future<void> get pending => _writing ?? Future<void>.value();

  /// The last write failure, or null if the most recent write succeeded.
  ///
  /// A save that cannot reach the disk must not take the caller down with it:
  /// `updateConfig` is called and dropped in a dozen places (a settings toggle,
  /// the split ratio, the sidebar's file list), so a throw here surfaced as an
  /// unhandled asynchronous error far from anything the user did. It is kept
  /// rather than discarded so the failure is inspectable.
  Object? lastSaveError;

  Future<void> _drain() async {
    try {
      while (_queued != null) {
        final next = _queued!;
        _queued = null;
        try {
          await _write(next);
          lastSaveError = null;
        } catch (error) {
          // The directory can vanish under us, the disk can fill, and on
          // Windows a scanner can hold the temporary file open. The next save
          // queues a fresh attempt, so one failure is not permanent.
          lastSaveError = error;
        }
      }
    } finally {
      _writing = null;
    }
  }

  /// Writes to a temporary file and renames it over the real one.
  ///
  /// Writing in place leaves a truncated file if the process dies mid-write,
  /// and a truncated config fails to parse — which used to mean every setting
  /// silently reverted to its default. A rename is atomic, so the file on disk
  /// is always either the old config or the new one.
  Future<void> _write(AppConfig config) =>
      JsonStore(_configPath).write(config.toJson());
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'app_config.dart';

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
    final file = File(_configPath);
    try {
      if (!await file.exists()) return AppConfig();
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return AppConfig.fromJson(json);
    } catch (_) {
      // Falling back to defaults silently discards every setting the user
      // ever chose. Keep the unreadable file so it can be inspected or
      // recovered, rather than overwriting it on the next save.
      await _setAside(file);
      return AppConfig();
    }
  }

  Future<void> _setAside(File file) async {
    try {
      if (await file.exists()) {
        await file.rename('$_configPath.corrupt');
      }
    } catch (_) {
      // Nothing more to try; the caller still gets defaults.
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

  Future<void> _drain() async {
    try {
      while (_queued != null) {
        final next = _queued!;
        _queued = null;
        await _write(next);
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
  Future<void> _write(AppConfig config) async {
    final file = File(_configPath);
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final content = const JsonEncoder.withIndent('  ').convert(config.toJson());
    final temporary = File('$_configPath.tmp');
    await temporary.writeAsString(content, flush: true);
    await temporary.rename(_configPath);
  }
}

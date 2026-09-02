import 'dart:io';

/// Per-plugin log writer with a small size bound and one rotated file.
class PluginLogger {
  PluginLogger(this.pluginId, String directory, {this.maxBytes = 512 * 1024})
      : _directory = Directory(directory),
        path = '${Directory(directory).path}${Platform.pathSeparator}$pluginId.log';

  final String pluginId;
  final Directory _directory;
  final String path;
  final int maxBytes;

  Future<void> info(String message) => _write('INFO', message);

  Future<void> warning(String message) => _write('WARN', message);

  Future<void> error(String message) => _write('ERROR', message);

  Future<void> _write(String level, String message) async {
    await _directory.create(recursive: true);
    final line = '[${DateTime.now().toIso8601String()}] [$level] $message\n';
    final file = File(path);
    if (await file.exists() &&
        await file.length() + line.length > maxBytes) {
      final rotated = File('$path.1');
      if (await rotated.exists()) await rotated.delete();
      await file.rename(rotated.path);
    }
    await file.writeAsString(line, mode: FileMode.append, flush: true);
  }
}

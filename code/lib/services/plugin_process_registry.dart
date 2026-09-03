import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// One plugin process the editor started.
class PluginProcessEntry {
  const PluginProcessEntry(this.pid, this.executable);

  final int pid;
  final String executable;

  Map<String, Object> toJson() => {'pid': pid, 'executable': executable};
}

/// Remembers the plugin processes this editor started, so a crash does not
/// leave them behind.
///
/// Killing a process does not kill its children: if the editor is killed
/// outright — a crash, a force-quit, the machine losing power — every plugin
/// it had started keeps running, and nothing that remains knows they exist.
/// A well-behaved plugin notices its stdin has closed and exits on its own,
/// but nothing forces a plugin to read stdin at all. So the editor writes down
/// what it spawned, and clears the leftovers the next time it starts.
class PluginProcessRegistry {
  PluginProcessRegistry(this.file);

  final File file;

  /// The processes this editor believes it still has running.
  Future<List<PluginProcessEntry>> entries() async {
    if (!await file.exists()) return const [];
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! List) return const [];
      return [
        for (final item in json)
          if (item is Map && item['pid'] is int && item['executable'] is String)
            PluginProcessEntry(
              item['pid'] as int,
              item['executable'] as String,
            ),
      ];
    } catch (_) {
      // A crash mid-write leaves a truncated file. Losing the list costs one
      // round of leftovers; refusing to start costs the reader the editor.
      return const [];
    }
  }

  Future<void> record(int pid, String executable) async {
    await _write([...await entries(), PluginProcessEntry(pid, executable)]);
  }

  Future<void> forget(int pid) async {
    await _write(
      (await entries()).where((entry) => entry.pid != pid).toList(),
    );
  }

  /// Kills whatever a previous run left behind, and returns how many died.
  ///
  /// A recorded pid is only killed when the process wearing it now is still
  /// the same program: the system reissues pids, so a stale number could by
  /// then belong to the reader's browser.
  Future<int> reapOrphans({
    Future<String?> Function(int pid)? imageOf,
    bool Function(int pid)? kill,
  }) async {
    final probe = imageOf ?? _imageOf;
    final terminate =
        kill ?? (int pid) => Process.killPid(pid, ProcessSignal.sigkill);

    final recorded = await entries();
    // The usual case is a clean shutdown with nothing to reap, and the editor
    // starts in under a second: this must cost one existence check, not a
    // write.
    if (recorded.isEmpty) return 0;

    var killed = 0;
    for (final entry in recorded) {
      final image = await probe(entry.pid);
      if (image == null) continue;
      if (!_sameProgram(image, entry.executable)) continue;
      if (terminate(entry.pid)) killed++;
    }
    await _write(const []);
    return killed;
  }

  Future<void> _write(List<PluginProcessEntry> entries) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode([for (final entry in entries) entry.toJson()]),
      flush: true,
    );
  }

  /// Whether a running process is the plugin the editor wrote down.
  ///
  /// Compared by file name: what the system reports for a running process is
  /// the image name on Windows and the command name on macOS, neither of
  /// which is the full path the editor recorded.
  static bool _sameProgram(String image, String executable) {
    final running = p.basename(image.trim());
    final recorded = p.basename(executable.trim());
    return Platform.isWindows
        ? running.toLowerCase() == recorded.toLowerCase()
        : running == recorded;
  }

  static final _argumentSeparator = String.fromCharCode(0);

  /// What program is wearing [pid] right now, or null if nothing is.
  static Future<String?> _imageOf(int pid) async {
    try {
      if (Platform.isLinux) {
        final cmdline = File('/proc/$pid/cmdline');
        if (!await cmdline.exists()) return null;
        // /proc separates the arguments with NUL bytes, so the program is
        // everything up to the first one.
        final line = await cmdline.readAsString();
        final end = line.indexOf(_argumentSeparator);
        final first = end == -1 ? line : line.substring(0, end);
        return first.isEmpty ? null : first;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('ps', ['-p', '$pid', '-o', 'comm=']);
        final out = (result.stdout as String).trim();
        return out.isEmpty ? null : out;
      }
      final result = await Process.run(
        'tasklist',
        ['/FI', 'PID eq $pid', '/NH', '/FO', 'CSV'],
      );
      final out = (result.stdout as String).trim();
      // tasklist answers "INFO: No tasks are running..." rather than failing.
      if (!out.startsWith('"')) return null;
      return out.split('","').first.replaceAll('"', '');
    } catch (_) {
      return null;
    }
  }
}

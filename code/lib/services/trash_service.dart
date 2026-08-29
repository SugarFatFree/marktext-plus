import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// Moving a file or folder to the desktop's trash instead of destroying it.
///
/// Upstream MarkText deletes through Electron's `shell.trashItem`, so a note
/// removed by mistake can be put back. This editor deleted outright — and for
/// a folder, `delete(recursive: true)` takes everything under it with no way
/// back at all.
///
/// Linux is implemented here, to the freedesktop.org trash specification.
/// macOS goes through the platform channel to `FileManager.trashItem`.
/// Where trashing is not available the caller is told so rather than being
/// given a silent permanent delete, because the two are not the same thing
/// and the reader is the one who should know which they are getting.
class TrashService {
  const TrashService._();

  /// The channel macOS answers on — the same one the clipboard uses.
  static const _channel = MethodChannel('com.marktextplus/clipboard');

  /// Whether this platform can move something to the trash.
  static bool get isAvailable => Platform.isLinux || Platform.isMacOS;

  /// Moves [path] to the trash.
  ///
  /// Returns false if it could not be trashed — an unsupported platform, a
  /// trash directory that cannot be created, or a file on a different
  /// filesystem from the home directory. The caller decides what to do about
  /// that; it must not quietly become a permanent delete.
  /// [dataHome] is where the trash lives, defaulting to the desktop's own —
  /// `$XDG_DATA_HOME`, or `~/.local/share`. Passed in rather than only read
  /// from the environment so this can be exercised against a directory that
  /// is not the reader's real trash.
  static Future<bool> moveToTrash(String path, {String? dataHome}) async {
    if (Platform.isMacOS) {
      try {
        return await _channel.invokeMethod<bool>('moveToTrash', path) ?? false;
      } catch (_) {
        // An older build with no handler for this, or the Trash refusing the
        // file. Either way the caller falls back to removing it outright,
        // which is what happened before any of this existed.
        return false;
      }
    }
    if (!Platform.isLinux) return false;
    try {
      return await _moveToXdgTrash(path, dataHome);
    } catch (_) {
      return false;
    }
  }

  /// The freedesktop.org trash: the file goes in `files/`, and a small record
  /// of where it came from goes in `info/` so the desktop can put it back.
  static Future<bool> _moveToXdgTrash(String path, String? dataHomeIn) async {
    final entity = await FileSystemEntity.type(path);
    if (entity == FileSystemEntityType.notFound) return false;

    final dataHome = dataHomeIn ?? _defaultDataHome();
    if (dataHome == null) return false;

    final trash = p.join(dataHome, 'Trash');
    final filesDir = Directory(p.join(trash, 'files'));
    final infoDir = Directory(p.join(trash, 'info'));
    await filesDir.create(recursive: true);
    await infoDir.create(recursive: true);

    final absolute = p.normalize(p.absolute(path));
    final name = _freeName(filesDir.path, infoDir.path, p.basename(absolute));

    // The record is written first. A file in `files/` with no record beside
    // it is an orphan the desktop cannot restore or even name properly; a
    // record with no file is harmless and is cleaned up below if the move
    // fails.
    final info = File(p.join(infoDir.path, '$name.trashinfo'));
    await info.writeAsString(
      '[Trash Info]\n'
      'Path=${_encodePath(absolute)}\n'
      'DeletionDate=${_stamp(DateTime.now())}\n',
    );

    final destination = p.join(filesDir.path, name);
    try {
      if (entity == FileSystemEntityType.directory) {
        await Directory(absolute).rename(destination);
      } else {
        await File(absolute).rename(destination);
      }
    } on FileSystemException {
      // Across a filesystem boundary a rename cannot work, and copying a
      // whole tree only to delete the original is a permanent delete wearing
      // a disguise. Say it could not be trashed instead.
      await info.delete().catchError((_) => info);
      return false;
    }
    return true;
  }

  /// Where the desktop keeps its data, and so its trash.
  static String? _defaultDataHome() {
    final fromEnv = Platform.environment['XDG_DATA_HOME'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) return null;
    return p.join(home, '.local', 'share');
  }

  /// A name not already taken in the trash, since two files called `notes.md`
  /// can be deleted on different days.
  static String _freeName(String filesDir, String infoDir, String base) {
    var candidate = base;
    var counter = 1;
    while (File(p.join(filesDir, candidate)).existsSync() ||
        Directory(p.join(filesDir, candidate)).existsSync() ||
        File(p.join(infoDir, '$candidate.trashinfo')).existsSync()) {
      final ext = p.extension(base);
      final stem = base.substring(0, base.length - ext.length);
      candidate = '$stem.$counter$ext';
      counter++;
    }
    return candidate;
  }

  /// The original path, percent-encoded as the specification asks, with the
  /// separators left alone so the record stays readable.
  static String _encodePath(String path) => path
      .split('/')
      .map((segment) => Uri.encodeComponent(segment))
      .join('/');

  /// `YYYY-MM-DDThh:mm:ss` in local time, which is the format the
  /// specification names.
  static String _stamp(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}'
        'T${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
  }
}

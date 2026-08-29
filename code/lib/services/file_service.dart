import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/file_node.dart';
import '../utils/file_utils.dart';
import '../models/file_encoding.dart';
import '../models/line_ending.dart';

/// Something already sits where a file was about to be written.
///
/// Its own type so the sidebar can say "that name is taken" rather than
/// showing the reader a raw system error.
class PathExistsException implements Exception {
  const PathExistsException(this.path);

  final String path;

  @override
  String toString() => 'PathExistsException: $path';
}

class FileService {
  /// Reads [path] as text, normalised to LF.
  ///
  /// Goes through the same decode as [readFileWithLineEnding]: two ways of
  /// reading a document is how one of them ends up unable to open a file the
  /// other can.
  Future<String> readFile(String path) async {
    final (content, _) = FileEncoding.decode(await File(path).readAsBytes());
    return normalizeLineEndings(content);
  }

  /// Reads [path] and reports which line ending it used.
  ///
  /// The editor works in LF throughout, but saving has to put back what the
  /// file had: rewriting a CRLF file as LF turns a one-word edit into a
  /// whole-file diff for anyone on Windows.
  Future<({String content, LineEnding lineEnding, FileEncoding encoding})>
      readFileWithLineEnding(String path) async {
    // Bytes, not readAsString: that throws on anything but UTF-8, and the tab
    // then disappeared without a word. It also swallows a UTF-8 byte order
    // mark, so a file written by Notepad lost it the first time it was saved.
    final bytes = await File(path).readAsBytes();
    final (raw, encoding) = FileEncoding.decode(bytes);
    return (
      content: normalizeLineEndings(raw),
      lineEnding: LineEnding.detect(raw),
      encoding: encoding,
    );
  }

  /// Converts CRLF and lone CR to LF.
  ///
  /// The scan comes first because the replacement builds two more copies of
  /// the whole document, and most files have no carriage returns at all —
  /// 30ms against 5ms on a five-megabyte file.
  static String normalizeLineEndings(String text) {
    if (!text.contains('\r')) return text;
    return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  /// Writes [content], which is held in LF, using [lineEnding].
  ///
  /// Every path that saves a document goes through here, so the choice cannot
  /// be honoured in one place and forgotten in another.
  /// What a file looked like at a moment, cheaply enough to record on every
  /// read and compare on every save.
  ///
  /// Modification time and size, which is what an editor can afford to check
  /// before each write. Hashing the contents would be exact and would also
  /// mean reading the whole file back every few seconds.
  static Future<({DateTime modified, int size})?> stampOf(String path) async {
    try {
      final stat = await File(path).stat();
      if (stat.type == FileSystemEntityType.notFound) return null;
      return (modified: stat.modified, size: stat.size);
    } on FileSystemException {
      return null;
    }
  }

  /// Whether [path] no longer looks the way it did when [stamp] was taken.
  ///
  /// A file that did not exist then and does not exist now has not changed.
  static Future<bool> hasChangedSince(
    String path,
    ({DateTime modified, int size})? stamp,
  ) async {
    final now = await stampOf(path);
    if (stamp == null) return now != null;
    if (now == null) return true;
    return now.size != stamp.size || now.modified != stamp.modified;
  }

  /// Writes [content] to [path] unconditionally.
  ///
  /// This is what "overwrite" means once the reader has been asked, and what
  /// Save As does. When the file may have changed underneath the editor —
  /// which is every ordinary save — use [saveDocumentIfUnchanged] instead.
  static Future<void> saveDocument(
    String path,
    String content, {
    LineEnding lineEnding = LineEnding.lf,
    FileEncoding encoding = FileEncoding.utf8Encoding,
  }) async {
    final bytes = encoding.encode(lineEnding.apply(content));

    // Write through a symlink to whatever it points at. Renaming over the link
    // itself would replace it with a regular file, quietly detaching the
    // document from wherever the reader actually keeps it.
    var target = path;
    if (await FileSystemEntity.isLink(path)) {
      try {
        target = await File(path).resolveSymbolicLinks();
      } on FileSystemException {
        // Dangling link. Fall through and write the link's own path.
      }
    }

    // The folder may have been moved or deleted while the document was open;
    // recreate it rather than failing the save.
    final parent = Directory(p.dirname(target));
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    // A plain writeAsBytes truncates the file and then writes into it. Killed
    // process, full disk, lost power — the document is left empty or half
    // written, with nothing to recover from. Write a scratch file beside it
    // and swap it in instead, so the document on disk is only ever the old
    // one or the new one.
    final temp = File('$target.${pid}_${_saveCounter++}.mtsave');
    try {
      final handle = await temp.open(mode: FileMode.writeOnly);
      try {
        await handle.writeFrom(bytes);
        // The rename alone is only namespace-atomic: the directory entry
        // flips over while the bytes are still in the page cache, so a crash
        // straight afterwards leaves the good name pointing at a hole.
        await handle.flush();
      } finally {
        await handle.close();
      }
      await _renameWithRetry(temp, target);
    } catch (_) {
      // Never leave the scratch file behind next to the reader's documents.
      try {
        if (await temp.exists()) await temp.delete();
      } on FileSystemException {
        // Nothing further to try.
      }
      rethrow;
    }
  }

  /// Scratch files are numbered as well as pid-tagged: two saves in the same
  /// millisecond, from the split view and an autosave, would otherwise collide.
  static int _saveCounter = 0;

  /// Suffix of the scratch file [saveDocument] swaps in. Hidden from the tree
  /// so it cannot flicker into the sidebar mid-save.
  static const saveTempSuffix = '.mtsave';

  /// Replaces [target] with [temp], retrying briefly.
  ///
  /// On Windows a virus scanner routinely holds a newly written file open for
  /// a few dozen milliseconds, and the rename fails with a sharing violation
  /// that is gone by the next attempt. Without this the atomic save would be
  /// *less* reliable than the truncating write it replaces.
  static Future<void> _renameWithRetry(File temp, String target) async {
    const delays = [Duration(milliseconds: 20), Duration(milliseconds: 60)];
    for (var attempt = 0;; attempt++) {
      try {
        await temp.rename(target);
        return;
      } on FileSystemException {
        if (attempt >= delays.length) rethrow;
        await Future<void>.delayed(delays[attempt]);
      }
    }
  }

  Future<void> writeFile(String path, String content) async {
    await File(path).writeAsString(content);
  }

  /// Reads one level of [dirPath]. Directories first, then files, each group
  /// by name.
  ///
  /// Deliberately not recursive: the sidebar used to walk the entire tree
  /// before it could show anything, which on a project with a node_modules or
  /// a .git took seconds — on every launch, and again after every save, since
  /// the file watcher rebuilt the whole tree. Children are read when a
  /// directory is expanded.
  Future<List<FileNode>> listDirectory(String dirPath) async {
    final dir = Directory(dirPath);

    List<FileSystemEntity> entities;
    try {
      entities = await dir.list(followLinks: false).toList();
    } on FileSystemException {
      // Unreadable directory (permissions, or removed since it was listed).
      return const [];
    }

    entities.sort((a, b) {
      final aIsDir = a is Directory;
      final bIsDir = b is Directory;
      if (aIsDir != bIsDir) return aIsDir ? -1 : 1;
      return p.basename(a.path).toLowerCase().compareTo(
            p.basename(b.path).toLowerCase(),
          );
    });

    return [
      for (final e in entities)
        // A save in flight owns one of these for a millisecond or two; it is
        // not something the reader has any use for seeing.
        if (!e.path.endsWith(saveTempSuffix) && _belongsInTree(e))
          FileNode(
            name: p.basename(e.path),
            path: e.path,
            isDirectory: e is Directory,
          ),
    ];
  }

  /// Whether the sidebar's tree should show [entity].
  ///
  /// Directories and markdown documents, which is what upstream MarkText
  /// shows. Listing everything meant a project folder arrived with `.git`,
  /// `node_modules`, images and binaries in it — and tapping one of those
  /// opened it as a text tab full of mojibake, one stray keystroke away from
  /// an auto-save writing that mojibake back over the original.
  static bool _belongsInTree(FileSystemEntity entity) {
    final name = p.basename(entity.path);
    if (entity is Directory) return !FileUtils.isSkippedDirectory(name);
    return FileUtils.isMarkdownFile(entity.path);
  }

  /// Renames [oldPath] to [newPath], whichever kind of entity it is.
  ///
  /// `File.rename` refuses a directory outright — EISDIR, "Is a directory" —
  /// so renaming a folder in the sidebar could never work, and until the
  /// sidebar started reporting these failures it did nothing at all: the
  /// dialog closed and the folder kept its old name. [deleteEntity] already
  /// dispatched on the type; this did not.
  /// Renames [oldPath] to [newPath], refusing to write over anything.
  ///
  /// `File.rename` replaces the destination without a word, so renaming a
  /// note to a name already in use destroyed the note that had it — no
  /// prompt, no undo, nothing on screen to say it had happened.
  Future<void> renameFile(
    String oldPath,
    String newPath, {
    bool overwrite = false,
  }) async {
    if (!overwrite && oldPath != newPath) {
      await _refuseIfTaken(newPath);
    }
    final type = await FileSystemEntity.type(oldPath);
    if (type == FileSystemEntityType.directory) {
      await Directory(oldPath).rename(newPath);
    } else {
      await File(oldPath).rename(newPath);
    }
  }

  /// Throws when something already sits at [path].
  static Future<void> _refuseIfTaken(String path) async {
    if (await FileSystemEntity.type(path) != FileSystemEntityType.notFound) {
      throw PathExistsException(path);
    }
  }

  /// Writes a new file, refusing to empty one that is already there.
  ///
  /// `writeAsString` truncates, so asking for a new note under a name already
  /// in use replaced that note with an empty document.
  Future<void> createFile(
    String path,
    String content, {
    bool overwrite = false,
  }) async {
    if (!overwrite) await _refuseIfTaken(path);
    await File(path).writeAsString(content);
  }

  Future<void> createDirectory(String path) async {
    await Directory(path).create(recursive: true);
  }

  Future<void> deleteEntity(String path) async {
    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: true);
    } else if (type == FileSystemEntityType.file) {
      await File(path).delete();
    }
  }

  /// Writes [content] to [path], but only if the file still looks the way it
  /// did when [expect] was taken.
  ///
  /// Throws [FileChangedOnDiskException] otherwise, without writing.
  ///
  /// Two entry points rather than one with a flag: a caller that passed the
  /// stamp and forgot to switch the check on would get a silent overwrite,
  /// which is the failure this exists to prevent.
  ///
  /// Auto-save is on by default with a five second delay, so the case is not
  /// hypothetical and needs no deliberate act: open a file, type, have a git
  /// checkout or a sync client rewrite it, and a few seconds later the editor
  /// wrote over that change without a word.
  static Future<void> saveDocumentIfUnchanged(
    String path,
    String content, {
    required ({DateTime modified, int size})? expect,
    LineEnding lineEnding = LineEnding.lf,
    FileEncoding encoding = FileEncoding.utf8Encoding,
  }) async {
    if (await hasChangedSince(path, expect)) {
      throw FileChangedOnDiskException(path);
    }
    await saveDocument(path, content,
        lineEnding: lineEnding, encoding: encoding);
  }
}

/// Raised when a save would write over a file that changed since it was read.
///
/// Carries the path so whoever catches it can name the file to the reader.
class FileChangedOnDiskException implements Exception {
  const FileChangedOnDiskException(this.path);

  final String path;

  @override
  String toString() => 'FileChangedOnDiskException($path)';
}

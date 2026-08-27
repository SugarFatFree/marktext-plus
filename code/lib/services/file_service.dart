import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/file_node.dart';

class FileService {
  Future<String> readFile(String path) async {
    final content = await File(path).readAsString();
    return normalizeLineEndings(content);
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
        FileNode(
          name: p.basename(e.path),
          path: e.path,
          isDirectory: e is Directory,
        ),
    ];
  }

  Future<void> renameFile(String oldPath, String newPath) async {
    await File(oldPath).rename(newPath);
  }

  Future<void> moveFile(String oldPath, String newPath) async {
    await File(oldPath).rename(newPath);
  }

  Future<void> createFile(String path, String content) async {
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
}

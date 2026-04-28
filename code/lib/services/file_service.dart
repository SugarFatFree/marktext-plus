import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/file_node.dart';

class FileService {
  Future<String> readFile(String path) async {
    final content = await File(path).readAsString();
    return content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  Future<void> writeFile(String path, String content) async {
    await File(path).writeAsString(content);
  }

  Future<List<FileNode>> listDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    final entities = await dir.list().toList();
    entities.sort((a, b) {
      final aIsDir = a is Directory;
      final bIsDir = b is Directory;
      if (aIsDir != bIsDir) return aIsDir ? -1 : 1;
      return p.basename(a.path).compareTo(p.basename(b.path));
    });
    return entities.map((e) {
      final name = p.basename(e.path);
      return FileNode(
        name: name,
        path: e.path,
        isDirectory: e is Directory,
      );
    }).toList();
  }

  Future<List<FileNode>> buildFileTree(String dirPath) async {
    final nodes = await listDirectory(dirPath);
    for (final node in nodes) {
      if (node.isDirectory) {
        final children = await buildFileTree(node.path);
        nodes[nodes.indexOf(node)] = FileNode(
          name: node.name,
          path: node.path,
          isDirectory: true,
          children: children,
        );
      }
    }
    return nodes;
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

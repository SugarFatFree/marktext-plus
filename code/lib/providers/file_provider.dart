import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_node.dart';
import '../services/file_service.dart';
import '../services/file_watcher_service.dart';

class FileNotifier extends StateNotifier<List<FileNode>> {
  final FileService _fileService;
  final FileWatcherService _watcherService = FileWatcherService();
  StreamSubscription? _watcherSubscription;
  String? _currentDirectory;

  FileNotifier(this._fileService) : super([]);

  String? get currentDirectory => _currentDirectory;

  Future<void> loadDirectory(String path) async {
    _currentDirectory = path;
    state = await _fileService.buildFileTree(path);
    _watcherSubscription?.cancel();
    _watcherService.watch(path);
    _watcherSubscription = _watcherService.events.listen((_) async {
      if (_currentDirectory != null) {
        state = await _fileService.buildFileTree(_currentDirectory!);
      }
    });
  }

  Future<void> renameNode(String oldPath, String newPath) async {
    await _fileService.renameFile(oldPath, newPath);
    await _refreshTree();
  }

  Future<void> deleteNode(String path) async {
    await _fileService.deleteEntity(path);
    await _refreshTree();
  }

  Future<void> createNode(String path, {bool isDirectory = false, String content = ''}) async {
    if (isDirectory) {
      await _fileService.createDirectory(path);
    } else {
      await _fileService.createFile(path, content);
    }
    await _refreshTree();
  }

  Future<void> _refreshTree() async {
    if (_currentDirectory != null) {
      state = await _fileService.buildFileTree(_currentDirectory!);
    }
  }

  void toggleExpand(String path) {
    state = _toggleNodeExpand(state, path);
  }

  List<FileNode> _toggleNodeExpand(List<FileNode> nodes, String path) {
    return nodes.map((node) {
      if (node.path == path) {
        return FileNode(
          name: node.name,
          path: node.path,
          isDirectory: node.isDirectory,
          children: node.children,
          isExpanded: !node.isExpanded,
        );
      } else if (node.isDirectory && node.children.isNotEmpty) {
        return FileNode(
          name: node.name,
          path: node.path,
          isDirectory: node.isDirectory,
          children: _toggleNodeExpand(node.children, path),
          isExpanded: node.isExpanded,
        );
      }
      return node;
    }).toList();
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, List<FileNode>>((ref) {
  final notifier = FileNotifier(FileService());
  ref.onDispose(() {
    notifier._watcherSubscription?.cancel();
    notifier._watcherService.dispose();
  });
  return notifier;
});

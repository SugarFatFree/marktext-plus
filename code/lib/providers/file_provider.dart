import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_node.dart';
import '../services/file_service.dart';
import '../services/trash_service.dart';
import '../services/file_watcher_service.dart';

class FileNotifier extends StateNotifier<List<FileNode>> {
  final FileService _fileService;
  final FileWatcherService _watcherService = FileWatcherService();
  StreamSubscription? _watcherSubscription;
  String? _currentDirectory;

  /// Directories the user has opened, by absolute path. Kept outside the tree
  /// so a refresh — after a rename, or a change the watcher reported — can put
  /// the tree back the way the user had it instead of collapsing it.
  final Set<String> _expanded = {};

  FileNotifier(this._fileService) : super([]);

  String? get currentDirectory => _currentDirectory;

  static String _displayName(String path) {
    final parts = path.split(RegExp(r'[\\/]')).where((part) => part.isNotEmpty);
    return parts.isEmpty ? path : parts.last;
  }

  Future<void> loadDirectory(String path) async {
    _currentDirectory = path;
    _expanded
      ..clear()
      ..add(path);

    state = [await _readNode(path, _displayName(path))];

    _watcherSubscription?.cancel();
    _watcherSubscription = _watcherService.events.listen((_) => _refreshTree());
    _watcherService.watch(_expanded);
  }

  void closeDirectory() {
    _currentDirectory = null;
    _expanded.clear();
    state = [];
    _watcherSubscription?.cancel();
    _watcherService.stop();
  }

  Future<void> renameNode(String oldPath, String newPath) async {
    await _fileService.renameFile(oldPath, newPath);
    await _refreshTree();
  }

  /// Removes [path], through the desktop's trash where that is possible.
  ///
  /// Upstream MarkText deletes through `shell.trashItem` so a note removed by
  /// mistake can be put back. Where trashing is not available the file is
  /// removed outright — and the confirmation the reader saw said so, which is
  /// the part that matters.
  Future<void> deleteNode(String path) async {
    if (!await TrashService.moveToTrash(path)) {
      await _fileService.deleteEntity(path);
    }
    _expanded.removeWhere((e) => e == path || e.startsWith('$path/'));
    await _refreshTree();
  }

  Future<void> createNode(String path,
      {bool isDirectory = false, String content = ''}) async {
    if (isDirectory) {
      await _fileService.createDirectory(path);
    } else {
      await _fileService.createFile(path, content);
    }
    await _refreshTree();
  }

  Future<void> toggleExpand(String path) async {
    if (_expanded.contains(path)) {
      _expanded.remove(path);
    } else {
      _expanded.add(path);
    }
    await _refreshTree();
  }

  Future<void> _refreshTree() async {
    final path = _currentDirectory;
    if (path == null) return;

    final tree = await _readNode(path, _displayName(path));
    // Another directory was opened, or the sidebar closed, while we were
    // reading; that newer state wins.
    if (_currentDirectory != path) return;
    state = [tree];

    // Expanding or collapsing changes which folders are on screen, and those
    // are exactly the ones worth watching.
    _watcherService.watch(_expanded);
  }

  /// Reads [path] and, recursively, only those descendants the user has
  /// expanded. Everything else stays unread until it is opened.
  Future<FileNode> _readNode(String path, String name) async {
    if (!_expanded.contains(path)) {
      return FileNode(name: name, path: path, isDirectory: true);
    }

    final entries = await _fileService.listDirectory(path);
    final children = <FileNode>[];
    for (final entry in entries) {
      children.add(entry.isDirectory
          ? await _readNode(entry.path, entry.name)
          : entry);
    }

    return FileNode(
      name: name,
      path: path,
      isDirectory: true,
      children: children,
      isExpanded: true,
    );
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

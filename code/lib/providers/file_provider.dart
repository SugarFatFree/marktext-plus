import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_node.dart';
import '../services/file_service.dart';

class FileNotifier extends StateNotifier<List<FileNode>> {
  final FileService _fileService;
  String? _currentDirectory;

  FileNotifier(this._fileService) : super([]);

  String? get currentDirectory => _currentDirectory;

  Future<void> loadDirectory(String path) async {
    _currentDirectory = path;
    state = await _fileService.buildFileTree(path);
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
  return FileNotifier(FileService());
});

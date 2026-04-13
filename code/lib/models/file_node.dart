class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  final List<FileNode> children;
  bool isExpanded;

  FileNode({
    required this.name,
    required this.path,
    this.isDirectory = false,
    this.children = const [],
    this.isExpanded = false,
  });

  String get extension => name.contains('.') ? name.split('.').last : '';
  bool get isMarkdown => const ['md', 'markdown', 'txt'].contains(extension.toLowerCase());
}

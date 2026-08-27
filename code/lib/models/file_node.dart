class FileNode {
  final String name;
  final String path;
  final bool isDirectory;

  /// Populated only for directories the user has expanded. Reading the whole
  /// tree up front cost seconds on a project with a node_modules or a .git —
  /// on every launch, and again on every file-watcher event.
  final List<FileNode> children;

  final bool isExpanded;

  const FileNode({
    required this.name,
    required this.path,
    this.isDirectory = false,
    this.children = const [],
    this.isExpanded = false,
  });

  String get extension => name.contains('.') ? name.split('.').last : '';
  bool get isMarkdown => const ['md', 'markdown', 'txt'].contains(extension.toLowerCase());
}

import '../core/config/app_config.dart';

class TabInfo {
  final String id;
  final String? filePath;
  String fileName;
  String content;
  bool isModified;
  bool isLoading;
  int cursorPosition;
  // Deprecated: use per-mode scroll offsets instead
  @Deprecated('Use sourceScrollOffset, previewScrollOffset, or splitScrollOffset')
  double scrollOffset;
  // Per-mode scroll offsets
  double sourceScrollOffset;
  double previewScrollOffset;
  double splitScrollOffset;
  double splitSourceScrollOffset;
  EditMode editMode;

  TabInfo({
    required this.id,
    this.filePath,
    this.fileName = 'Untitled',
    this.content = '',
    this.isModified = false,
    this.isLoading = false,
    this.cursorPosition = 0,
    this.scrollOffset = 0,
    this.sourceScrollOffset = 0,
    this.previewScrollOffset = 0,
    this.splitScrollOffset = 0,
    this.splitSourceScrollOffset = 0,
    this.editMode = EditMode.preview,
  });

  TabInfo copyWith({
    String? filePath,
    String? fileName,
    String? content,
    bool? isModified,
    bool? isLoading,
    int? cursorPosition,
    double? scrollOffset,
    double? sourceScrollOffset,
    double? previewScrollOffset,
    double? splitScrollOffset,
    double? splitSourceScrollOffset,
    EditMode? editMode,
  }) {
    return TabInfo(
      id: id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      content: content ?? this.content,
      isModified: isModified ?? this.isModified,
      isLoading: isLoading ?? this.isLoading,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      sourceScrollOffset: sourceScrollOffset ?? this.sourceScrollOffset,
      previewScrollOffset: previewScrollOffset ?? this.previewScrollOffset,
      splitScrollOffset: splitScrollOffset ?? this.splitScrollOffset,
      splitSourceScrollOffset: splitSourceScrollOffset ?? this.splitSourceScrollOffset,
      editMode: editMode ?? this.editMode,
    );
  }
}

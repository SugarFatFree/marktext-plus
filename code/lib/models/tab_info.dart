import '../core/config/app_config.dart';

class TabInfo {
  final String id;
  final String? filePath;
  String fileName;
  String content;
  bool isModified;
  int cursorPosition;
  double scrollOffset;
  EditMode editMode;

  TabInfo({
    required this.id,
    this.filePath,
    this.fileName = 'Untitled',
    this.content = '',
    this.isModified = false,
    this.cursorPosition = 0,
    this.scrollOffset = 0,
    this.editMode = EditMode.preview,
  });

  TabInfo copyWith({
    String? fileName,
    String? content,
    bool? isModified,
    int? cursorPosition,
    double? scrollOffset,
    EditMode? editMode,
  }) {
    return TabInfo(
      id: id,
      filePath: filePath,
      fileName: fileName ?? this.fileName,
      content: content ?? this.content,
      isModified: isModified ?? this.isModified,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      editMode: editMode ?? this.editMode,
    );
  }
}

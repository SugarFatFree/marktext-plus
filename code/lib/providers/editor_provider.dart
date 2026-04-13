import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditorState {
  final int cursorLine;
  final int cursorCol;
  final double scrollOffset;
  final String selectedText;

  const EditorState({
    this.cursorLine = 0,
    this.cursorCol = 0,
    this.scrollOffset = 0.0,
    this.selectedText = '',
  });

  EditorState copyWith({
    int? cursorLine,
    int? cursorCol,
    double? scrollOffset,
    String? selectedText,
  }) {
    return EditorState(
      cursorLine: cursorLine ?? this.cursorLine,
      cursorCol: cursorCol ?? this.cursorCol,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      selectedText: selectedText ?? this.selectedText,
    );
  }
}

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(const EditorState());

  void updateCursor(int line, int col) {
    state = state.copyWith(cursorLine: line, cursorCol: col);
  }

  void updateScroll(double offset) {
    state = state.copyWith(scrollOffset: offset);
  }

  void updateSelection(String text) {
    state = state.copyWith(selectedText: text);
  }
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});

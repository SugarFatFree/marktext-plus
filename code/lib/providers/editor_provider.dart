import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FormatAction {
  bold,
  italic,
  strikethrough,
  heading1,
  heading2,
  heading3,
  heading4,
  heading5,
  heading6,
  orderedList,
  unorderedList,
  taskList,
  codeBlock,
  quoteBlock,
  mathBlock,
  table,
  link,
  image,
  horizontalRule,
}

class EditorState {
  final int cursorLine;
  final int cursorCol;
  final double scrollOffset;
  final String selectedText;
  final FormatAction? pendingFormat;
  final bool canUndo;
  final bool canRedo;
  final bool showFindReplace;

  const EditorState({
    this.cursorLine = 0,
    this.cursorCol = 0,
    this.scrollOffset = 0.0,
    this.selectedText = '',
    this.pendingFormat,
    this.canUndo = false,
    this.canRedo = false,
    this.showFindReplace = false,
  });

  EditorState copyWith({
    int? cursorLine,
    int? cursorCol,
    double? scrollOffset,
    String? selectedText,
    FormatAction? pendingFormat,
    bool clearFormat = false,
    bool? canUndo,
    bool? canRedo,
    bool? showFindReplace,
  }) {
    return EditorState(
      cursorLine: cursorLine ?? this.cursorLine,
      cursorCol: cursorCol ?? this.cursorCol,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      selectedText: selectedText ?? this.selectedText,
      pendingFormat: clearFormat ? null : (pendingFormat ?? this.pendingFormat),
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      showFindReplace: showFindReplace ?? this.showFindReplace,
    );
  }
}

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(const EditorState());

  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  TextEditingController? _controller;

  TextEditingController? get controller => _controller;

  void setController(TextEditingController controller) {
    _controller = controller;
  }

  void updateCursor(int line, int col) {
    state = state.copyWith(cursorLine: line, cursorCol: col);
  }

  void updateScroll(double offset) {
    state = state.copyWith(scrollOffset: offset);
  }

  void updateSelection(String text) {
    state = state.copyWith(selectedText: text);
  }

  void applyFormat(FormatAction action) {
    state = state.copyWith(pendingFormat: action);
  }

  void clearFormat() {
    state = state.copyWith(clearFormat: true);
  }

  void pushHistory(String content) {
    if (_undoStack.isEmpty || _undoStack.last != content) {
      _undoStack.add(content);
      _redoStack.clear();
      _updateUndoRedoState();
    }
  }

  void undo() {
    if (_undoStack.isEmpty || _controller == null) return;

    final current = _controller!.text;
    _redoStack.add(current);

    _undoStack.removeLast();
    if (_undoStack.isNotEmpty) {
      final previous = _undoStack.last;
      _controller!.value = TextEditingValue(
        text: previous,
        selection: TextSelection.collapsed(offset: previous.length),
      );
    }

    _updateUndoRedoState();
  }

  void redo() {
    if (_redoStack.isEmpty || _controller == null) return;

    final next = _redoStack.removeLast();
    _undoStack.add(next);

    _controller!.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );

    _updateUndoRedoState();
  }

  void _updateUndoRedoState() {
    state = state.copyWith(
      canUndo: _undoStack.length > 1,
      canRedo: _redoStack.isNotEmpty,
    );
  }

  void toggleFindReplace() {
    state = state.copyWith(showFindReplace: !state.showFindReplace);
  }

  void hideFindReplace() {
    state = state.copyWith(showFindReplace: false);
  }
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});

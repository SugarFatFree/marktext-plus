import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SearchTarget { source, preview }

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
  underline,
  superscript,
  subscript,
  highlight,
  inlineCode,
  inlineMath,
  clearFormatting,
  copyAsMarkdown,
  copyAsHtml,
  selectAll,
  duplicateLine,
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
  final int? targetScrollLine;
  final SearchTarget searchTarget;
  final String previewSearchQuery;
  final bool previewSearchCaseSensitive;
  final bool previewSearchWholeWord;
  final bool previewSearchUseRegex;
  final int previewCurrentMatchIndex;

  const EditorState({
    this.cursorLine = 0,
    this.cursorCol = 0,
    this.scrollOffset = 0.0,
    this.selectedText = '',
    this.pendingFormat,
    this.canUndo = false,
    this.canRedo = false,
    this.showFindReplace = false,
    this.targetScrollLine,
    this.searchTarget = SearchTarget.source,
    this.previewSearchQuery = '',
    this.previewSearchCaseSensitive = false,
    this.previewSearchWholeWord = false,
    this.previewSearchUseRegex = false,
    this.previewCurrentMatchIndex = -1,
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
    int? targetScrollLine,
    bool clearTargetScrollLine = false,
    SearchTarget? searchTarget,
    String? previewSearchQuery,
    bool? previewSearchCaseSensitive,
    bool? previewSearchWholeWord,
    bool? previewSearchUseRegex,
    int? previewCurrentMatchIndex,
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
      targetScrollLine: clearTargetScrollLine ? null : (targetScrollLine ?? this.targetScrollLine),
      searchTarget: searchTarget ?? this.searchTarget,
      previewSearchQuery: previewSearchQuery ?? this.previewSearchQuery,
      previewSearchCaseSensitive: previewSearchCaseSensitive ?? this.previewSearchCaseSensitive,
      previewSearchWholeWord: previewSearchWholeWord ?? this.previewSearchWholeWord,
      previewSearchUseRegex: previewSearchUseRegex ?? this.previewSearchUseRegex,
      previewCurrentMatchIndex: previewCurrentMatchIndex ?? this.previewCurrentMatchIndex,
    );
  }
}

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(const EditorState());

  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  TextEditingController? _controller;
  ScrollController? _editorScrollController;
  double _editorTextFieldWidth = 0;

  TextEditingController? get controller => _controller;

  void setController(TextEditingController controller) {
    _controller = controller;
  }

  void setEditorScrollController(ScrollController controller) {
    _editorScrollController = controller;
  }

  /// Store the actual width available for text rendering inside the TextField.
  /// SourceEditor should call this after layout so that scrollToSearchMatch
  /// can account for soft-wrapped lines when computing the scroll target.
  void setEditorTextFieldWidth(double width) {
    _editorTextFieldWidth = width;
  }

  void scrollToSearchMatch(int lineNumber, double fontSize, double lineHeight, {int? charOffset}) {
    if (_editorScrollController == null || !_editorScrollController!.hasClients) return;

    final actualLineHeight = fontSize * lineHeight;
    final viewportHeight = _editorScrollController!.position.viewportDimension;

    double targetY;

    // When charOffset and a valid editor width are available, use TextPainter
    // to compute the real pixel-Y that accounts for soft-wrapped lines.
    // This fixes the split-mode bug where the narrower pane causes extra
    // visual lines that the simple `lineNumber * lineHeight` formula misses.
    if (charOffset != null && _editorTextFieldWidth > 0 && _controller != null) {
      final text = _controller!.text;
      final safeOffset = charOffset.clamp(0, text.length);
      final textBefore = text.substring(0, safeOffset);

      final painter = TextPainter(
        text: TextSpan(
          text: textBefore,
          style: TextStyle(fontSize: fontSize, height: lineHeight),
        ),
        textDirection: TextDirection.ltr,
      );
      // 16 = contentPadding horizontal (8 * 2) in SourceEditor's TextField
      final layoutWidth = _editorTextFieldWidth - 16;
      painter.layout(maxWidth: layoutWidth > 0 ? layoutWidth : double.infinity);
      targetY = painter.height;
      painter.dispose();
    } else {
      // Fallback: simple line-based calculation (works when no wrapping)
      targetY = lineNumber * actualLineHeight;
    }

    // Position the target line at the upper 1/3 of the viewport for better
    // readability. lineNumber is 0-based from find_replace_bar.dart.
    final targetOffset = (targetY - viewportHeight / 3).clamp(
      0.0,
      _editorScrollController!.position.maxScrollExtent,
    );

    // Adaptive duration based on scroll distance
    final currentOffset = _editorScrollController!.offset;
    final distance = (targetOffset - currentOffset).abs();
    final duration = distance > viewportHeight * 2
        ? const Duration(milliseconds: 400)
        : const Duration(milliseconds: 200);

    _editorScrollController!.animateTo(
      targetOffset,
      duration: duration,
      curve: Curves.easeOut,
    );
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

  void scrollToLine(int line) {
    state = state.copyWith(targetScrollLine: line);
  }

  void clearScrollTarget() {
    state = state.copyWith(clearTargetScrollLine: true);
  }

  void setSearchTarget(SearchTarget target) {
    state = state.copyWith(searchTarget: target);
  }

  void updatePreviewSearch({
    required String query,
    required bool caseSensitive,
    required bool wholeWord,
    required bool useRegex,
    required int currentMatchIndex,
  }) {
    state = state.copyWith(
      previewSearchQuery: query,
      previewSearchCaseSensitive: caseSensitive,
      previewSearchWholeWord: wholeWord,
      previewSearchUseRegex: useRegex,
      previewCurrentMatchIndex: currentMatchIndex,
    );
  }

  void clearPreviewSearch() {
    state = state.copyWith(
      previewSearchQuery: '',
      previewCurrentMatchIndex: -1,
    );
  }
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});

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
  promoteHeading,
  demoteHeading,
  toParagraph,
  frontMatter,
  htmlBlock,
  looseList,
  createParagraph,
  deleteParagraph,
}

class EditorState {
  final int cursorLine;
  final int cursorCol;
  final double scrollOffset;
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

  /// Bumped each time the user asks to step to another search match.
  ///
  /// A counter rather than a flag: two consecutive "next" requests have to be
  /// distinguishable, and the find bar owns the match list so it is the one
  /// that has to act on this.
  final int findStepRequest;

  /// Bumped when the user asks for images to be read from disk again.
  ///
  /// Flutter caches a decoded image against its file path, so a picture edited
  /// outside the app keeps showing the old bitmap. The renderer folds this
  /// into each image's key, which is what makes the widget resolve afresh
  /// after the cache is emptied.
  final int imageRevision;

  /// Which way the last [findStepRequest] wants to go.
  final bool findStepForward;

  const EditorState({
    this.cursorLine = 0,
    this.cursorCol = 0,
    this.scrollOffset = 0.0,
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
    this.findStepRequest = 0,
    this.imageRevision = 0,
    this.findStepForward = true,
  });

  EditorState copyWith({
    int? cursorLine,
    int? cursorCol,
    double? scrollOffset,
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
    int? findStepRequest,
    int? imageRevision,
    bool? findStepForward,
  }) {
    return EditorState(
      cursorLine: cursorLine ?? this.cursorLine,
      cursorCol: cursorCol ?? this.cursorCol,
      scrollOffset: scrollOffset ?? this.scrollOffset,
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
      findStepRequest: findStepRequest ?? this.findStepRequest,
      imageRevision: imageRevision ?? this.imageRevision,
      findStepForward: findStepForward ?? this.findStepForward,
    );
  }
}

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(const EditorState());

  /// Undo history, kept per tab.
  ///
  /// A single shared stack meant switching tabs carried the previous file's
  /// history along: pressing undo in one document could replace it with a
  /// snapshot of another.
  final Map<String, List<String>> _undoStacks = {};
  final Map<String, List<String>> _redoStacks = {};
  String _historyKey = '';

  /// Snapshots kept per tab.
  ///
  /// Each entry is a whole copy of the document, pushed on a 300ms debounce,
  /// so an unbounded stack would grow without limit over a long session.
  static const _maxHistory = 200;

  List<String> get _undoStack => _undoStacks.putIfAbsent(_historyKey, () => []);
  List<String> get _redoStack => _redoStacks.putIfAbsent(_historyKey, () => []);

  /// Points history at [tabId]; call before the editor for that tab is used.
  void setHistoryTab(String tabId) {
    if (_historyKey == tabId) return;
    _historyKey = tabId;
    _updateUndoRedoState();
  }

  /// Drops a closed tab's history so it does not accumulate.
  void forgetHistory(String tabId) {
    _undoStacks.remove(tabId);
    _redoStacks.remove(tabId);
  }
  TextEditingController? _controller;
  ScrollController? _editorScrollController;
  double _editorTextFieldWidth = 0;

  TextEditingController? get controller => _controller;

  void setController(TextEditingController controller) {
    _controller = controller;
  }

  /// Drops [controller] if it is still the registered one.
  ///
  /// The editor that owns it disposes it, and a stale pointer here is worse
  /// than none: the find bar treats a non-null controller as "there is a
  /// source editor on screen", so in preview mode it would attach to a
  /// disposed controller and search a snapshot frozen at the moment the
  /// source editor went away.
  ///
  /// The identity check matters because the replacement editor registers
  /// itself before the outgoing one is disposed.
  void clearController(TextEditingController controller) {
    if (identical(_controller, controller)) _controller = null;
  }

  void setEditorScrollController(ScrollController controller) {
    _editorScrollController = controller;
  }

  /// Drops [controller] if it is still the registered one.
  void clearEditorScrollController(ScrollController controller) {
    if (identical(_editorScrollController, controller)) {
      _editorScrollController = null;
    }
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

  void applyFormat(FormatAction action) {
    state = state.copyWith(pendingFormat: action);
  }

  void clearFormat() {
    state = state.copyWith(clearFormat: true);
  }

  void pushHistory(String content) {
    final stack = _undoStack;
    if (stack.isNotEmpty && stack.last == content) return;

    stack.add(content);
    if (stack.length > _maxHistory) {
      // Oldest first: the recent past is what undo is for.
      stack.removeRange(0, stack.length - _maxHistory);
    }
    _redoStack.clear();
    _updateUndoRedoState();
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

  /// Asks the find bar to move to the next or previous match.
  ///
  /// Opens the bar first when it is closed, so the shortcut works without
  /// having to press Ctrl+F beforehand.
  void stepToFindMatch({required bool forward}) {
    state = state.copyWith(
      showFindReplace: true,
      findStepRequest: state.findStepRequest + 1,
      findStepForward: forward,
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

  /// Drops every decoded image and asks the preview to read them again.
  ///
  /// Emptying the cache alone is not enough: a picture already on screen is
  /// held live, and the widget showing it would not resolve again. Bumping the
  /// revision changes each image's key, which is what forces that.
  void reloadImages() {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    state = state.copyWith(imageRevision: state.imageRevision + 1);
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

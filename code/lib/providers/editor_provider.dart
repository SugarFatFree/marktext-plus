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

  /// A fenced `mermaid` block with a diagram already in it.
  ///
  /// The one block whose syntax nobody remembers — the fence, the word, and a
  /// first line that decides the diagram's kind — and the feature this editor
  /// is built around. Everything else the `/` menu offers was reachable by
  /// typing two or three characters; this was not reachable at all.
  mermaidBlock,
  looseList,
  createParagraph,
  deleteParagraph,
  // Editing an existing table, which upstream MarkText does through a WYSIWYG
  // grid. Here they rewrite the table under the caret in the source.
  tableInsertRowAbove,
  tableInsertRowBelow,
  tableDeleteRow,
  tableInsertColumnLeft,
  tableInsertColumnRight,
  tableDeleteColumn,
  tableAlignLeft,
  tableAlignCenter,
  tableAlignRight,
  tableAlignNone,
  tableTidy,
  // Reordering, which upstream MarkText does by dragging one paragraph over
  // another. Here the block under the caret trades places with its neighbour.
  moveBlockUp,
  moveBlockDown,
}

class EditorState {
  final int cursorLine;
  final int cursorCol;
  final FormatAction? pendingFormat;

  /// Whether the preview currently has a block open for editing.
  ///
  /// In split view both panes are on screen, so both would otherwise take a
  /// pending format command and apply it — the same bold twice, in two
  /// different places. The pane the reader is actually typing in wins.
  final bool previewBlockEditing;
  final bool canUndo;
  final bool canRedo;
  final bool showFindReplace;
  final int? targetScrollLine;

  /// The source line at the top of the editing pane, for the preview beside
  /// it to follow.
  ///
  /// Separate from [targetScrollLine], which is a request made once — by the
  /// outline, or by a search hit — and cleared when it has been honoured.
  /// This one is a running position: it changes as the reader scrolls and is
  /// never cleared.
  final int? syncSourceLine;

  /// The source line at the top of the preview, for the editing pane beside
  /// it to follow. The other direction of [syncSourceLine].
  final int? syncPreviewLine;
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
    this.previewBlockEditing = false,
    this.cursorLine = 0,
    this.cursorCol = 0,
    this.pendingFormat,
    this.canUndo = false,
    this.canRedo = false,
    this.showFindReplace = false,
    this.targetScrollLine,
    this.syncSourceLine,
    this.syncPreviewLine,
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
    bool? previewBlockEditing,
    int? cursorLine,
    int? cursorCol,
    FormatAction? pendingFormat,
    bool clearFormat = false,
    bool? canUndo,
    bool? canRedo,
    bool? showFindReplace,
    int? targetScrollLine,
    int? syncSourceLine,
    int? syncPreviewLine,
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
      previewBlockEditing: previewBlockEditing ?? this.previewBlockEditing,
      cursorLine: cursorLine ?? this.cursorLine,
      cursorCol: cursorCol ?? this.cursorCol,
      pendingFormat: clearFormat ? null : (pendingFormat ?? this.pendingFormat),
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      showFindReplace: showFindReplace ?? this.showFindReplace,
      targetScrollLine: clearTargetScrollLine ? null : (targetScrollLine ?? this.targetScrollLine),
      syncSourceLine: syncSourceLine ?? this.syncSourceLine,
      syncPreviewLine: syncPreviewLine ?? this.syncPreviewLine,
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

  /// One recorded state of the document, and where the caret was in it.
  ///
  /// Undo used to restore the text alone and drop the caret at the very end.
  /// In a long document that means every undo throws the reader to the bottom
  /// of the file, away from the edit they were undoing — which makes a working
  /// undo tiring to use.
  /// Undo history, kept per tab.
  ///
  /// A single shared stack meant switching tabs carried the previous file's
  /// history along: pressing undo in one document could replace it with a
  /// snapshot of another.
  final Map<String, List<_Snapshot>> _undoStacks = {};
  final Map<String, List<_Snapshot>> _redoStacks = {};
  String _historyKey = '';

  /// Where each pane of each tab was scrolled to, so coming back to a tab
  /// comes back to where you were reading.
  ///
  /// A plain map rather than part of [EditorState], for the same reason the
  /// undo stacks are: writing it to the state would rebuild everything
  /// watching this provider on a tab switch, and the panes record it while
  /// they are being taken down, which is not a moment to be notifying anyone.
  /// Nothing reads it except the pane rebuilding itself.
  final Map<String, double> _sourceScroll = {};
  final Map<String, double> _previewScroll = {};

  /// Snapshots kept per tab.
  ///
  /// Each entry is a whole copy of the document, pushed on a 300ms debounce,
  /// so an unbounded stack would grow without limit over a long session.
  static const maxHistory = 200;

  /// How much snapshot text one tab's history will hold.
  ///
  /// The step count alone was the wrong unit. An entry is a whole copy of the
  /// document, so two hundred of them is twenty megabytes of history for a
  /// 100 KB note, two hundred megabytes for a one-megabyte document and two
  /// gigabytes for a ten-megabyte one — per tab, and again for redo. A low
  /// footprint and large files are the first two things this editor promises,
  /// and this was the largest thing in the process that nothing measured. The
  /// highlighter's cache a few files away budgets by characters for exactly
  /// this reason; the history counted steps.
  ///
  /// Sixteen megabytes leaves every document under about eighty kilobytes with
  /// all two hundred steps — which is almost every Markdown file — and turns the
  /// pathological case from gigabytes into this.
  static const historyCharBudget = 16 * 1024 * 1024;

  /// Drops the oldest snapshots until [stack] is inside both bounds.
  ///
  /// Never below two: the top of the stack is the current state, so one entry
  /// means there is nowhere to go back to and the key does nothing. A single
  /// snapshot larger than the whole budget is therefore kept — one undo on a
  /// huge document is worth more than the budget is.
  ///
  /// The total is summed rather than carried along. `String.length` is constant
  /// time and the stack is two hundred entries at most, so this is two hundred
  /// additions on a push that is already behind a 300 ms debounce; a running
  /// total would be a second piece of state to keep in step with redo, which
  /// moves entries between the two stacks.
  static void _trim(List<_Snapshot> stack) {
    if (stack.length > maxHistory) {
      stack.removeRange(0, stack.length - maxHistory);
    }
    var chars = 0;
    for (final entry in stack) {
      chars += entry.text.length;
    }
    while (chars > historyCharBudget && stack.length > 2) {
      chars -= stack.removeAt(0).text.length;
    }
  }

  /// How much text one tab's history is holding, for the test that bounds it.
  @visibleForTesting
  int historyCharsForTest(String tabId) => (_undoStacks[tabId] ?? const [])
      .fold(0, (total, entry) => total + entry.text.length);

  /// How many snapshots one tab's history is holding.
  @visibleForTesting
  int historyLengthForTest(String tabId) => (_undoStacks[tabId] ?? const []).length;

  /// The newest snapshot's text, to check that eviction took the oldest.
  @visibleForTesting
  String? historyTopForTest(String tabId) =>
      (_undoStacks[tabId] ?? const <_Snapshot>[]).lastOrNull?.text;

  List<_Snapshot> get _undoStack =>
      _undoStacks.putIfAbsent(_historyKey, () => []);
  List<_Snapshot> get _redoStack =>
      _redoStacks.putIfAbsent(_historyKey, () => []);

  /// Where the caret is now, for the snapshot about to be taken.
  int get _caret {
    final selection = _controller?.selection;
    if (selection == null || !selection.isValid) return 0;
    return selection.baseOffset;
  }

  /// Where the caret is, as an offset into the document — or null when there is
  /// no source pane holding one.
  ///
  /// The field knows this; it does not have to be worked out. The Format menu
  /// rebuilt it from the line and column it shows in the status bar, which meant
  /// splitting the document into lines to add their lengths up — 36.7 ms over
  /// eight megabytes, on every caret move, and again inside
  /// `TableEditService.locate` for the same keypress.
  ///
  /// Null rather than zero when there is no source pane: in preview mode the
  /// line and column are whatever the source pane last reported, so an offset
  /// built from them points into a document nobody is editing. The table
  /// commands are source-pane commands and being told "nowhere" is what greys
  /// them out.
  int? get caretOffset {
    final selection = _controller?.selection;
    if (selection == null || !selection.isValid) return null;
    return selection.baseOffset;
  }

  /// Puts [snapshot] back on screen, caret and all.
  void _restore(_Snapshot snapshot) {
    final controller = _controller;
    if (controller == null) return;
    controller.value = TextEditingValue(
      text: snapshot.text,
      selection: TextSelection.collapsed(
        // The document this snapshot came from may be shorter than the one on
        // screen, and an offset past its end is not a position at all.
        offset: snapshot.caret.clamp(0, snapshot.text.length),
      ),
    );
  }

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
    _sourceScroll.remove(tabId);
    _previewScroll.remove(tabId);
  }

  /// Records where a pane of [tabId] was scrolled to.
  ///
  /// Called as the pane goes away, which is what a tab switch does to it.
  void rememberScroll(String tabId, double offset, {required bool preview}) {
    (preview ? _previewScroll : _sourceScroll)[tabId] = offset;
  }

  /// Where that pane was, or null if this tab has not been read yet.
  ///
  /// Null and zero are deliberately different: a tab opened for the first time
  /// has nothing to restore, and asking for a jump to zero on every first
  /// build is a scroll animation nobody asked for.
  double? recallScroll(String tabId, {required bool preview}) =>
      (preview ? _previewScroll : _sourceScroll)[tabId];
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

  void applyFormat(FormatAction action) {
    state = state.copyWith(pendingFormat: action);
  }

  /// Records whether a block in the preview is open for editing.
  void setPreviewBlockEditing(bool editing) {
    if (state.previewBlockEditing == editing) return;
    state = state.copyWith(previewBlockEditing: editing);
  }

  void clearFormat() {
    state = state.copyWith(clearFormat: true);
  }

  /// Records [content] as a state undo can come back to.
  ///
  /// [tabId] says whose history this belongs to. It matters because only the
  /// source editor ever names the current tab, and in preview mode there is no
  /// source editor: a plugin writing into the document from there pushed its
  /// entry onto whichever tab was named last — a different document, or none —
  /// so the change it made could not be taken back, and undo in *that* tab
  /// would have written this document's text into it.
  void pushHistory(String content, {String? tabId}) {
    final stack = tabId == null
        ? _undoStack
        : _undoStacks.putIfAbsent(tabId, () => []);
    if (stack.isNotEmpty && stack.last.text == content) return;

    stack.add((text: content, caret: _caret));
    // Oldest first: the recent past is what undo is for.
    _trim(stack);
    if (tabId == null || tabId == _historyKey) {
      _redoStack.clear();
      _updateUndoRedoState();
    } else {
      _redoStacks.putIfAbsent(tabId, () => []).clear();
    }
  }

  /// Steps back one snapshot and answers with the text the document should
  /// hold, or null when there was nowhere to go.
  ///
  /// With a source editor on screen this also puts the text in the field and
  /// the caller may ignore the answer. Without one it cannot: the right-hand
  /// rail offers a plugin's rewrite in preview mode, where nothing is holding
  /// the text, and this used to look for a controller, find none and return —
  /// so a rewrite the reader accepted could not be taken back, and the key did
  /// nothing at all. The caller writes the answer to the tab, which is where
  /// the document lives when nothing is being typed into.
  /// Whether a source editor is on screen holding the document's text.
  ///
  /// Undo restores into that field when there is one. In preview mode there is
  /// not, and the caller has to write the result to the tab instead.
  bool get hasSourceEditor => _controller != null;

  String? undo({String? current}) {
    if (_undoStack.isEmpty) return null;

    // The newest text has to come from somewhere. A source editor holds it; in
    // preview mode the tab does, and only the caller can read that — so it
    // says. Without either, the stack's own top is the best guess, which makes
    // undo a no-op rather than a step to the wrong place.
    final now = current ?? _controller?.text ?? _undoStack.last.text;
    // Snapshots are taken on a 300 ms debounce, so the edit the reader just
    // made is usually not on the stack yet. Undo assumed it was, and the two
    // ways that went wrong were both silent:
    //
    // * with one entry on the stack, undo popped it, found nothing to put
    //   back, and left the text alone — the key did nothing at all;
    // * with more, it popped the *previous* state and applied the one before
    //   that, so a single press stepped back twice and took away an edit the
    //   reader had not asked to lose.
    //
    // Added straight to the stack rather than through pushHistory, which
    // clears the redo stack — the one thing undo must not do.
    if (_undoStack.last.text != now) {
      _undoStack.add((text: now, caret: _caret));
      _trim(_undoStack);
    }

    // Only the current state is left; there is nowhere to go back to.
    if (_undoStack.length < 2) {
      _updateUndoRedoState();
      return null;
    }

    _redoStack.add(_undoStack.removeLast());
    _restore(_undoStack.last);

    _updateUndoRedoState();
    return _undoStack.last.text;
  }

  /// Steps forward again, answering the same way [undo] does.
  String? redo() {
    if (_redoStack.isEmpty) return null;

    final next = _redoStack.removeLast();
    _undoStack.add(next);
    _restore(next);

    _updateUndoRedoState();
    return next.text;
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

  /// Reports where the editing pane is looking, so the preview can look there
  /// too. Nothing is done when the line has not changed: this is called on
  /// every scroll event.
  void reportSourceLine(int line) {
    if (state.syncSourceLine == line) return;
    state = state.copyWith(syncSourceLine: line);
  }

  /// The other direction: where the preview is looking, for the editing pane
  /// to follow.
  void reportPreviewLine(int line) {
    if (state.syncPreviewLine == line) return;
    state = state.copyWith(syncPreviewLine: line);
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

  /// The source pane's selection, as a range into the document it holds.
  ///
  /// A range and not the text. The text used to be pushed here on every
  /// selection change — a substring of the selection, a comparison of that
  /// whole string against the one before it, and a state notification — while
  /// all three places that want it ask for it at the moment a command runs.
  /// Holding Shift+Down through a large document copied a progressively larger
  /// string on every keypress, so the gesture as a whole was quadratic, and a
  /// four-megabyte selection then sat in the state until the next one, beside
  /// the document, the field's own copy and the undo history.
  ///
  /// Measured before this: a partial substring of half a megabyte takes 1.1 ms
  /// and of four megabytes 3.6 ms. Select-All was free, because Dart hands back
  /// the same string for the whole range — which is why trying it by selecting
  /// everything showed nothing.
  void setSourceSelection(TextSelection selection) {
    _previewSelection = '';
    _sourceSelection =
        selection.isValid && !selection.isCollapsed ? selection : null;
  }

  /// What the reader dragged across in the preview.
  ///
  /// Kept as text because the preview has no offsets to keep instead: its
  /// selection is rendered text, and the source it came from is spread over the
  /// blocks it covers. Flutter has already built the string by the time this is
  /// called, so nothing is copied here that was not copied anyway.
  void setPreviewSelection(String text) {
    _sourceSelection = null;
    _previewSelection = text;
  }

  /// The selected text, taken now.
  ///
  /// Whichever pane changed last is the one that answers, which is what the one
  /// shared field used to give: a plugin run from the preview must not be handed
  /// what the source pane had selected a minute ago.
  String selectedText() {
    final selection = _sourceSelection;
    if (selection == null) return _previewSelection;
    final text = _controller?.text;
    if (text == null) return '';
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(start, text.length);
    return text.substring(start, end);
  }

  TextSelection? _sourceSelection;
  String _previewSelection = '';
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});

typedef _Snapshot = ({String text, int caret});

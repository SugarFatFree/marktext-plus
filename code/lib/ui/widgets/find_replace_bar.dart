import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../providers/editor_provider.dart';
import '../../providers/settings_provider.dart';
import '../editor/highlighting_controller.dart';

class FindReplaceBar extends ConsumerStatefulWidget {
  final TextEditingController? textController;
  final String? rawContent;
  final bool isSplitMode;

  const FindReplaceBar({
    super.key,
    this.textController,
    this.rawContent,
    this.isSplitMode = false,
  }) : assert(textController != null || rawContent != null, 'Either textController or rawContent must be provided');

  /// Scans [text] for [pattern], returning non-overlapping ranges in document
  /// order. Exposed for testing because the ranges are spliced back into the
  /// document by replace-all, where an off-by-one costs the user text.
  @visibleForTesting
  static List<TextRange> findMatches(
    String text,
    String pattern, {
    bool caseSensitive = false,
    bool wholeWord = false,
    bool useRegex = false,
  }) {
    final matches = <TextRange>[];
    if (pattern.isEmpty) return matches;

    if (useRegex) {
      try {
        final regex = RegExp(pattern, caseSensitive: caseSensitive);
        for (final match in regex.allMatches(text)) {
          matches.add(TextRange(start: match.start, end: match.end));
        }
      } catch (_) {
        // Invalid regex: report nothing rather than a partial scan.
      }
      return matches;
    }

    final searchText = caseSensitive ? text : text.toLowerCase();
    final searchPattern = caseSensitive ? pattern : pattern.toLowerCase();

    int index = 0;
    while (index < searchText.length) {
      final pos = searchText.indexOf(searchPattern, index);
      if (pos == -1) break;

      if (!wholeWord) {
        matches.add(TextRange(start: pos, end: pos + pattern.length));
      } else {
        final isWordStart = pos == 0 || !_isWordChar(text[pos - 1]);
        final isWordEnd = pos + pattern.length >= text.length ||
            !_isWordChar(text[pos + pattern.length]);
        if (isWordStart && isWordEnd) {
          matches.add(TextRange(start: pos, end: pos + pattern.length));
        }
      }

      // Advance past the match, not by one character. Overlapping hits ("aa"
      // in "aaaa") inflate the counter and make replace-all splice ranges that
      // overlap, which destroys text instead of replacing it.
      index = pos + pattern.length;
    }
    return matches;
  }

  static bool _isWordChar(String char) => RegExp(r'[a-zA-Z0-9_]').hasMatch(char);

  @override
  ConsumerState<FindReplaceBar> createState() => _FindReplaceBarState();
}

class _FindReplaceBarState extends ConsumerState<FindReplaceBar> {
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final FocusNode _findFocusNode = FocusNode();

  bool _caseSensitive = false;
  bool _wholeWord = false;
  bool _useRegex = false;
  bool _showReplace = false;

  List<TextRange> _matches = [];
  int _currentMatchIndex = -1;

  /// The document text the current [_matches] offsets were computed against.
  /// The bar stays open while the user keeps editing, so offsets go stale and
  /// must not be used to splice text.
  String _scannedText = '';

  @override
  void initState() {
    super.initState();
    _findController.addListener(_onFindTextChanged);
    widget.textController?.addListener(_onDocumentChanged);

    // Find Next and Find Previous live in the Edit menu and on a shortcut, but
    // the match list is here, so they arrive as a request to step.
    ref.listenManual(editorProvider.select((s) => s.findStepRequest),
        (previous, next) {
      if (previous == null || next <= previous) return;
      if (ref.read(editorProvider).findStepForward) {
        _findNext();
      } else {
        _findPrevious();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findFocusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(FindReplaceBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textController != widget.textController) {
      oldWidget.textController?.removeListener(_onDocumentChanged);
      widget.textController?.addListener(_onDocumentChanged);
      _findMatches();
    } else if (widget.rawContent != oldWidget.rawContent) {
      _findMatches(jumpToMatch: false);
    }
  }

  @override
  void dispose() {
    _clearHighlighting();
    widget.textController?.removeListener(_onDocumentChanged);
    _findController.dispose();
    _replaceController.dispose();
    _findFocusNode.dispose();
    super.dispose();
  }

  void _clearHighlighting() {
    if (widget.textController is HighlightingController) {
      (widget.textController as HighlightingController)
          .updateSearchMatches([], -1);
    }
    ref.read(editorProvider.notifier).clearPreviewSearch();
  }

  void _onFindTextChanged() {
    _findMatches();
  }

  /// The editor's controller also notifies on selection changes, so compare the
  /// text before rescanning. Never moves the caret: the user is typing.
  void _onDocumentChanged() {
    if (_getSearchText() == _scannedText) return;
    _findMatches(jumpToMatch: false);
  }

  /// Get the text to search based on current search target.
  String _getSearchText() {
    if (widget.isSplitMode) {
      final target = ref.read(editorProvider).searchTarget;
      if (target == SearchTarget.preview) {
        return widget.rawContent ?? '';
      }
      return widget.textController?.text ?? '';
    }
    return widget.textController?.text ?? widget.rawContent ?? '';
  }

  /// Whether current search target is source (has textController).
  bool _isSourceTarget() {
    if (widget.isSplitMode) {
      return ref.read(editorProvider).searchTarget == SearchTarget.source;
    }
    return widget.textController != null;
  }

  void _findMatches({bool jumpToMatch = true}) {
    final text = _getSearchText();
    _scannedText = text;

    final matches = FindReplaceBar.findMatches(
      text,
      _findController.text,
      caseSensitive: _caseSensitive,
      wholeWord: _wholeWord,
      useRegex: _useRegex,
    );

    // Keep the user's place across a rescan triggered by typing.
    final selected = matches.isEmpty
        ? -1
        : (jumpToMatch ? 0 : _currentMatchIndex.clamp(0, matches.length - 1));

    setState(() {
      _matches = matches;
      _currentMatchIndex = selected;
    });

    _updateHighlighting();

    if (jumpToMatch && matches.isNotEmpty) {
      _highlightMatch(0);
    }
  }

  void _updateHighlighting() {
    if (widget.textController is HighlightingController) {
      (widget.textController as HighlightingController)
          .updateSearchMatches(_matches, _currentMatchIndex);
    }
    // Update preview search state in provider
    if (!_isSourceTarget()) {
      ref.read(editorProvider.notifier).updatePreviewSearch(
        query: _findController.text,
        caseSensitive: _caseSensitive,
        wholeWord: _wholeWord,
        useRegex: _useRegex,
        currentMatchIndex: _currentMatchIndex,
      );
    }
  }

  void _highlightMatch(int index) {
    if (index < 0 || index >= _matches.length) return;

    final match = _matches[index];
    final text = _getSearchText();

    // Update highlighting
    _updateHighlighting();

    if (_isSourceTarget()) {
      // Source mode: set selection
      widget.textController!.selection = TextSelection(
        baseOffset: match.start,
        extentOffset: match.end,
      );

      // Scroll to match
      final lineNumber = text.substring(0, match.start).split('\n').length - 1;
      final config = ref.read(settingsProvider);
      ref.read(editorProvider.notifier).scrollToSearchMatch(
        lineNumber,
        config.fontSize,
        config.lineHeight,
        charOffset: match.start,
      );
    } else {
      // Preview mode: scroll to line
      final lineNumber = text.substring(0, match.start).split('\n').length;
      ref.read(editorProvider.notifier).scrollToLine(lineNumber);
    }
  }

  void _findNext() {
    if (_matches.isEmpty) return;

    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matches.length;
    });
    _highlightMatch(_currentMatchIndex);
  }

  void _findPrevious() {
    if (_matches.isEmpty) return;

    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _matches.length) % _matches.length;
    });
    _highlightMatch(_currentMatchIndex);
  }

  void _replace() {
    if (!_isSourceTarget() || widget.textController == null) return;
    if (_currentMatchIndex < 0 || _currentMatchIndex >= _matches.length) return;

    final match = _matches[_currentMatchIndex];
    final text = widget.textController!.text;
    // The offsets were computed against an earlier revision if the document
    // changed underneath us; splicing them would overwrite unrelated text.
    if (match.end > text.length || text != _scannedText) {
      _findMatches();
      return;
    }

    final replacement = _replaceController.text;
    final newText = text.substring(0, match.start) +
        replacement +
        text.substring(match.end);

    widget.textController!.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: match.start + replacement.length,
      ),
    );

    // Settle on the first match after what we just wrote, so pressing Replace
    // repeatedly walks through the document instead of snapping back to the
    // top — and cannot loop forever when the replacement contains the pattern.
    final resumeFrom = match.start + replacement.length;
    _findMatches(jumpToMatch: false);
    if (_matches.isNotEmpty) {
      var next = _matches.indexWhere((m) => m.start >= resumeFrom);
      if (next == -1) next = 0;
      setState(() => _currentMatchIndex = next);
      _highlightMatch(next);
    }
  }

  void _replaceAll() {
    if (!_isSourceTarget() || widget.textController == null) return;
    if (_matches.isEmpty) return;

    final text = widget.textController!.text;
    if (text != _scannedText) {
      _findMatches();
      return;
    }

    final replacement = _replaceController.text;
    final pattern = _findController.text;

    String newText = text;

    if (_useRegex) {
      try {
        final regex = RegExp(
          pattern,
          caseSensitive: _caseSensitive,
        );
        newText = text.replaceAll(regex, replacement);
      } catch (e) {
        return;
      }
    } else {
      for (int i = _matches.length - 1; i >= 0; i--) {
        final match = _matches[i];
        newText = newText.substring(0, match.start) +
            replacement +
            newText.substring(match.end);
      }
    }

    widget.textController!.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: 0),
    );

    _findMatches();
  }

  void _close() {
    _clearHighlighting();
    ref.read(editorProvider.notifier).hideFindReplace();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (widget.isSplitMode) ...[
                SegmentedButton<SearchTarget>(
                  segments: [
                    ButtonSegment(
                      value: SearchTarget.source,
                      label: Text(l10n.viewSourceCode,
                          style: const TextStyle(fontSize: 12)),
                      icon: const Icon(Icons.code, size: 14),
                    ),
                    ButtonSegment(
                      value: SearchTarget.preview,
                      label: Text(l10n.viewPreview,
                          style: const TextStyle(fontSize: 12)),
                      icon: const Icon(Icons.visibility, size: 14),
                    ),
                  ],
                  selected: {ref.watch(editorProvider).searchTarget},
                  onSelectionChanged: (Set<SearchTarget> newSelection) {
                    ref.read(editorProvider.notifier).setSearchTarget(newSelection.first);
                    _findMatches();
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextField(
                  controller: _findController,
                  focusNode: _findFocusNode,
                  decoration: InputDecoration(
                    hintText: l10n.editFind,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    suffixText: _matches.isNotEmpty
                        ? '${_currentMatchIndex + 1}/${_matches.length}'
                        : null,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (_) => _findNext(),
                ),
              ),
              const SizedBox(width: 4),
              _buildOptionButton(
                label: 'Aa',
                tooltip: l10n.editCaseSensitive,
                isActive: _caseSensitive,
                onPressed: () {
                  setState(() {
                    _caseSensitive = !_caseSensitive;
                  });
                  _findMatches();
                },
              ),
              const SizedBox(width: 2),
              _buildOptionButton(
                label: '\\b',
                tooltip: l10n.editWholeWord,
                isActive: _wholeWord && !_useRegex,
                // The regex scan never applies the word test, so leaving the
                // button live would show it lit while doing nothing. Regex
                // users can write \b themselves.
                onPressed: _useRegex
                    ? null
                    : () {
                        setState(() {
                          _wholeWord = !_wholeWord;
                        });
                        _findMatches();
                      },
              ),
              const SizedBox(width: 2),
              _buildOptionButton(
                label: '.*',
                tooltip: l10n.editRegex,
                isActive: _useRegex,
                onPressed: () {
                  setState(() {
                    _useRegex = !_useRegex;
                  });
                  _findMatches();
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 16),
                onPressed: _matches.isNotEmpty ? _findPrevious : null,
                tooltip: l10n.editFindPrevious,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 16),
                onPressed: _matches.isNotEmpty ? _findNext : null,
                tooltip: l10n.editFindNext,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
              ),
              if (_isSourceTarget())
                IconButton(
                  icon: Icon(
                    _showReplace ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                  ),
                  onPressed: () {
                    setState(() {
                      _showReplace = !_showReplace;
                    });
                  },
                  tooltip: l10n.editReplace,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: _close,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
              ),
            ],
          ),
          if (_showReplace) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replaceController,
                    decoration: InputDecoration(
                      hintText: l10n.editReplace,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onSubmitted: (_) => _replace(),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _matches.isNotEmpty ? _replace : null,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: const Size(0, 28),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: Text(l10n.editReplace),
                ),
                TextButton(
                  onPressed: _matches.isNotEmpty ? _replaceAll : null,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: const Size(0, 28),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: Text(l10n.editReplaceAll),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required String label,
    required String tooltip,
    required bool isActive,
    required VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;

    // The tooltip was accepted but never rendered, so these three buttons —
    // labelled only "Aa", "\\b" and ".*" — had nothing explaining them.
    return Tooltip(
      message: tooltip,
      child: Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isActive ? theme.colorScheme.primary : theme.dividerColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

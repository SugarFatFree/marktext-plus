import 'package:flutter/material.dart';
import '../../services/file_service.dart';
import 'syntax_highlighter.dart';

class HighlightingController extends TextEditingController {
  Color headingColor;
  Color boldColor;
  Color codeColor;
  Color linkColor;
  Color defaultColor;
  Color quoteColor;
  Color commentColor;

  List<TextRange> _searchMatches = [];
  int _currentMatchIndex = -1;

  HighlightingController({
    String? text,
    required this.headingColor,
    required this.boldColor,
    required this.codeColor,
    required this.linkColor,
    required this.defaultColor,
    Color? quoteColor,
    Color? commentColor,
  })  : quoteColor = quoteColor ?? defaultColor,
        commentColor = commentColor ?? defaultColor,
        super(text: text != null ? _normalizeLineEndings(text) : null);

  static String _normalizeLineEndings(String text) =>
      FileService.normalizeLineEndings(text);

  @override
  set text(String newText) {
    super.text = _normalizeLineEndings(newText);
  }

  @override
  set value(TextEditingValue newValue) {
    if (newValue.text.contains('\r')) {
      final normalized = _normalizeLineEndings(newValue.text);
      final offsetDiff = newValue.text.length - normalized.length;
      super.value = newValue.copyWith(
        text: normalized,
        selection: TextSelection.collapsed(
          offset: (newValue.selection.baseOffset - offsetDiff)
              .clamp(0, normalized.length),
        ),
      );
    } else {
      super.value = newValue;
    }
  }

  /// How many matches are painted at once.
  ///
  /// Searching a five megabyte document for a common word finds around a
  /// hundred thousand of them. Painting all of them costs 133 ms and builds a
  /// span tree with 195 000 children — on every rebuild, which includes every
  /// caret move — and Flutter then has to lay all of it out. None of it is
  /// visible: a viewport holds a few dozen lines.
  ///
  /// So a window around the match the reader is on, which is the part they
  /// can see. Stepping through the document moves the window with them. A
  /// search with fewer matches than this is unaffected.
  static const _paintedMatchLimit = 1000;

  /// Sets which ranges to paint, and which of them is the current one.
  ///
  /// [matches] is the whole list — the count in the find bar is the reader's,
  /// not something to quietly shrink. Only the painting is bounded.
  void updateSearchMatches(List<TextRange> matches, int currentIndex) {
    if (matches.length <= _paintedMatchLimit) {
      _searchMatches = matches;
      _currentMatchIndex = currentIndex;
    } else {
      const half = _paintedMatchLimit ~/ 2;
      final centre = currentIndex < 0 ? 0 : currentIndex;
      var start = centre - half;
      if (start < 0) start = 0;
      var end = start + _paintedMatchLimit;
      if (end > matches.length) {
        end = matches.length;
        start = end - _paintedMatchLimit;
      }
      _searchMatches = matches.sublist(start, end);
      _currentMatchIndex = currentIndex < 0 ? -1 : currentIndex - start;
    }
    notifyListeners();
  }

  final IncrementalMarkdownHighlighter _highlighter =
      IncrementalMarkdownHighlighter();

  /// Whether the document is large enough that highlighting has been turned
  /// off. Editing still works; only the colouring is gone.
  bool get isHighlightingSuspended => _highlighter.isSuspended;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Called on every rebuild — caret moves, focus changes, a search-match
    // update — so this reuses the spans of every line the last edit did not
    // touch instead of re-scanning the document.
    final children = _highlighter.build(
      text,
      HighlightColors(
        heading: headingColor,
        bold: boldColor,
        code: codeColor,
        link: linkColor,
        defaultColor: defaultColor,
        quote: quoteColor,
        comment: commentColor,
      ),
    );

    // EditableText positions the caret and selection by walking these spans,
    // so their combined length has to equal the controller's text. If a
    // highlighting bug ever breaks that, an unstyled document is far better
    // than misplaced selection rectangles.
    // Each entry is one line, holding its own runs as children, so the count
    // has to descend one level. Summing `child.text` alone would come to zero
    // and quietly drop the reader back to an unstyled document.
    int spanTextLen = 0;
    for (final child in children) {
      spanTextLen += child.text?.length ?? 0;
      final runs = child.children;
      if (runs == null) continue;
      for (final run in runs) {
        if (run is TextSpan) spanTextLen += run.text?.length ?? 0;
      }
    }
    if (spanTextLen != text.length) {
      if (_searchMatches.isEmpty) {
        return TextSpan(style: style, text: text);
      }
      return TextSpan(
        style: style,
        children: _applySearchHighlight(
          [TextSpan(text: text, style: TextStyle(color: defaultColor))],
        ),
      );
    }

    if (_searchMatches.isEmpty) {
      return TextSpan(style: style, children: children);
    }

    // Flattened only here: painting a match across the document needs the runs
    // end to end. Typing does not, which is the whole point of returning lines.
    return TextSpan(
      style: style,
      children: _applySearchHighlight(
        IncrementalMarkdownHighlighter.flatten(children),
      ),
    );
  }

  /// Paints the search highlight over the syntax spans.
  ///
  /// Both lists are in ascending document order, so this walks them together.
  /// Testing every match against every span was quadratic, and a search in a
  /// large document produces plenty of both.
  List<InlineSpan> _applySearchHighlight(List<TextSpan> spans) {
    final result = <InlineSpan>[];
    int offset = 0;
    int matchIndex = 0;

    for (final span in spans) {
      final spanText = span.text;
      if (spanText == null) {
        result.add(span);
        continue;
      }

      final spanStart = offset;
      final spanEnd = offset + spanText.length;
      offset = spanEnd;

      // Matches that ended before this span will not be needed again.
      while (matchIndex < _searchMatches.length &&
          _searchMatches[matchIndex].end <= spanStart) {
        matchIndex++;
      }

      if (matchIndex >= _searchMatches.length ||
          _searchMatches[matchIndex].start >= spanEnd) {
        result.add(span);
        continue;
      }

      int segmentStart = 0;
      // A match can straddle several spans, so look ahead without consuming:
      // the next span may still need this one.
      for (int i = matchIndex;
          i < _searchMatches.length && _searchMatches[i].start < spanEnd;
          i++) {
        final match = _searchMatches[i];
        final matchStart = (match.start - spanStart).clamp(0, spanText.length);
        final matchEnd = (match.end - spanStart).clamp(0, spanText.length);
        if (matchEnd <= segmentStart) continue;

        if (segmentStart < matchStart) {
          result.add(TextSpan(
            text: spanText.substring(segmentStart, matchStart),
            style: span.style,
          ));
        }

        result.add(TextSpan(
          text: spanText.substring(matchStart, matchEnd),
          style: span.style?.copyWith(
            backgroundColor: i == _currentMatchIndex
                ? const Color(0x80FF9800) // Orange for the current match
                : const Color(0x4DFFEB3B), // Yellow for the others
          ),
        ));

        segmentStart = matchEnd;
      }

      if (segmentStart < spanText.length) {
        result.add(TextSpan(
          text: spanText.substring(segmentStart),
          style: span.style,
        ));
      }
    }

    return result;
  }
}

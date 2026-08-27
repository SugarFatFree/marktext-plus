import 'package:flutter/material.dart';
import 'syntax_highlighter.dart';

class HighlightingController extends TextEditingController {
  Color headingColor;
  Color boldColor;
  Color codeColor;
  Color linkColor;
  Color defaultColor;

  List<TextRange> _searchMatches = [];
  int _currentMatchIndex = -1;

  HighlightingController({
    String? text,
    required this.headingColor,
    required this.boldColor,
    required this.codeColor,
    required this.linkColor,
    required this.defaultColor,
  }) : super(text: text != null ? _normalizeLineEndings(text) : null);

  static String _normalizeLineEndings(String text) {
    return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

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

  void updateSearchMatches(List<TextRange> matches, int currentIndex) {
    _searchMatches = matches;
    _currentMatchIndex = currentIndex;
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
      ),
    );

    // EditableText positions the caret and selection by walking these spans,
    // so their combined length has to equal the controller's text. If a
    // highlighting bug ever breaks that, an unstyled document is far better
    // than misplaced selection rectangles.
    int spanTextLen = 0;
    for (final child in children) {
      spanTextLen += child.text?.length ?? 0;
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

    return TextSpan(style: style, children: _applySearchHighlight(children));
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

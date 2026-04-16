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
    super.text,
    required this.headingColor,
    required this.boldColor,
    required this.codeColor,
    required this.linkColor,
    required this.defaultColor,
  });

  void updateSearchMatches(List<TextRange> matches, int currentIndex) {
    _searchMatches = matches;
    _currentMatchIndex = currentIndex;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final highlighted = MarkdownSyntaxHighlighter.highlight(
      text,
      headingColor: headingColor,
      boldColor: boldColor,
      codeColor: codeColor,
      linkColor: linkColor,
      defaultColor: defaultColor,
    );

    final children = highlighted.children;

    // Validate that the total text length of all children spans matches the
    // controller text length.  A mismatch causes Flutter's EditableText to
    // miscalculate selection rects, leading to highlight overflow.  When a
    // mismatch is detected, fall back to a single unstyled TextSpan.
    if (children != null && children.isNotEmpty) {
      int spanTextLen = 0;
      for (final child in children) {
        if (child is TextSpan) {
          spanTextLen += (child.text?.length ?? 0);
        }
      }
      if (spanTextLen != text.length) {
        // Fallback: single span, no syntax highlighting
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
    }

    if (_searchMatches.isEmpty) {
      return TextSpan(style: style, children: children);
    }

    // Apply search highlight on top of syntax highlighting
    return TextSpan(
      style: style,
      children: _applySearchHighlight(children ?? []),
    );
  }

  List<InlineSpan> _applySearchHighlight(List<InlineSpan> spans) {
    final result = <InlineSpan>[];
    int offset = 0;

    for (final span in spans) {
      if (span is TextSpan && span.text != null) {
        final spanText = span.text!;
        final spanStart = offset;
        final spanEnd = offset + spanText.length;

        // Find matches that overlap with this span
        final overlappingMatches = _searchMatches.where((match) {
          return match.start < spanEnd && match.end > spanStart;
        }).toList();

        if (overlappingMatches.isEmpty) {
          result.add(span);
        } else {
          // Split span and apply highlights
          final segments = <InlineSpan>[];
          int segmentStart = 0;

          for (int i = 0; i < overlappingMatches.length; i++) {
            final match = overlappingMatches[i];
            final matchStart = (match.start - spanStart).clamp(0, spanText.length);
            final matchEnd = (match.end - spanStart).clamp(0, spanText.length);

            // Add text before match
            if (segmentStart < matchStart) {
              segments.add(TextSpan(
                text: spanText.substring(segmentStart, matchStart),
                style: span.style,
              ));
            }

            // Add highlighted match
            final isCurrentMatch = _searchMatches.indexOf(match) == _currentMatchIndex;
            segments.add(TextSpan(
              text: spanText.substring(matchStart, matchEnd),
              style: span.style?.copyWith(
                backgroundColor: isCurrentMatch
                    ? const Color(0x80FF9800) // Orange for current match
                    : const Color(0x4DFFEB3B), // Yellow for other matches
              ),
            ));

            segmentStart = matchEnd;
          }

          // Add remaining text
          if (segmentStart < spanText.length) {
            segments.add(TextSpan(
              text: spanText.substring(segmentStart),
              style: span.style,
            ));
          }

          result.addAll(segments);
        }

        offset = spanEnd;
      } else {
        result.add(span);
      }
    }

    return result;
  }
}

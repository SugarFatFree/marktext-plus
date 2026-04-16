import 'package:flutter/material.dart';

class MarkdownSyntaxHighlighter {
  static final List<_Pattern> _inlinePatterns = [
    _Pattern(RegExp(r'\*\*(.+?)\*\*'), _PatternType.bold),
    _Pattern(RegExp(r'`(.+?)`'), _PatternType.code),
    _Pattern(RegExp(r'!\[([^\]]*)\]\(([^)]+)\)'), _PatternType.link),
    _Pattern(RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), _PatternType.link),
    _Pattern(RegExp(r'~~(.+?)~~'), _PatternType.strikethrough),
    _Pattern(RegExp(r'\*(.+?)\*'), _PatternType.italic),
  ];

  static TextSpan highlight(
    String text, {
    required Color headingColor,
    required Color boldColor,
    required Color codeColor,
    required Color linkColor,
    required Color defaultColor,
  }) {
    if (text.isEmpty) {
      return const TextSpan(children: <TextSpan>[]);
    }

    // Split text into lines (preserving line structure) and produce one
    // TextSpan per line with the newline character appended to the line
    // content.  This avoids orphan '\n' spans that cause Flutter's
    // EditableText to extend the selection highlight across the full
    // remaining width of the line (the "selection overflow" bug).
    final lines = text.split('\n');
    final List<TextSpan> spans = [];

    for (int i = 0; i < lines.length; i++) {
      final lineText = lines[i];
      final isLastLine = i == lines.length - 1;
      // Suffix: attach '\n' to the last span of each line (except the
      // very last line of the document) so that every newline character
      // shares the same TextStyle as the preceding visible text.
      final suffix = isLastLine ? '' : '\n';

      if (lineText.isEmpty) {
        // Blank line – emit a single span containing only the newline.
        if (suffix.isNotEmpty) {
          spans.add(TextSpan(
            text: suffix,
            style: TextStyle(color: defaultColor),
          ));
        }
        continue;
      }

      if (lineText.startsWith('#')) {
        spans.add(TextSpan(
          text: '$lineText$suffix',
          style: TextStyle(color: headingColor, fontWeight: FontWeight.bold),
        ));
      } else if (lineText.startsWith('```')) {
        spans.add(TextSpan(
          text: '$lineText$suffix',
          style: TextStyle(color: codeColor, fontFamily: 'monospace'),
        ));
      } else {
        final inlineSpans = _highlightInline(
          lineText,
          boldColor: boldColor,
          codeColor: codeColor,
          linkColor: linkColor,
          defaultColor: defaultColor,
        );
        if (suffix.isNotEmpty && inlineSpans.isNotEmpty) {
          // Append '\n' to the last inline span so it shares the same style.
          final last = inlineSpans.last;
          inlineSpans[inlineSpans.length - 1] = TextSpan(
            text: '${last.text ?? ''}$suffix',
            style: last.style,
          );
        }
        spans.addAll(inlineSpans);
      }
    }

    return TextSpan(children: spans);
  }

  static List<TextSpan> _highlightInline(
    String text, {
    required Color boldColor,
    required Color codeColor,
    required Color linkColor,
    required Color defaultColor,
  }) {
    if (text.isEmpty) {
      return const <TextSpan>[];
    }

    final List<TextSpan> spans = [];
    int pos = 0;

    while (pos < text.length) {
      Match? earliestMatch;
      _Pattern? matchedPattern;

      for (final pattern in _inlinePatterns) {
        final match = pattern.regex.matchAsPrefix(text, pos) ??
            pattern.regex.firstMatch(text.substring(pos));
        if (match != null) {
          final normalizedMatch = match.pattern == pattern.regex
              ? match
              : pattern.regex.firstMatch(text.substring(pos));
          if (normalizedMatch != null) {
            if (earliestMatch == null ||
                normalizedMatch.start < earliestMatch.start) {
              earliestMatch = normalizedMatch;
              matchedPattern = pattern;
            }
          }
        }
      }

      if (earliestMatch == null) {
        spans.add(TextSpan(
          text: text.substring(pos),
          style: TextStyle(color: defaultColor),
        ));
        break;
      }

      if (earliestMatch.start > 0) {
        spans.add(TextSpan(
          text: text.substring(pos, pos + earliestMatch.start),
          style: TextStyle(color: defaultColor),
        ));
      }

      final matchText = earliestMatch.group(0)!;
      spans.add(TextSpan(
        text: matchText,
        style: _styleForPattern(
          matchedPattern!.type,
          boldColor: boldColor,
          codeColor: codeColor,
          linkColor: linkColor,
          defaultColor: defaultColor,
        ),
      ));

      pos += earliestMatch.start + matchText.length;
    }

    return spans;
  }

  static TextStyle _styleForPattern(
    _PatternType type, {
    required Color boldColor,
    required Color codeColor,
    required Color linkColor,
    required Color defaultColor,
  }) {
    switch (type) {
      case _PatternType.bold:
        return TextStyle(color: boldColor, fontWeight: FontWeight.bold);
      case _PatternType.code:
        return TextStyle(color: codeColor, fontFamily: 'monospace');
      case _PatternType.link:
        return TextStyle(color: linkColor);
      case _PatternType.strikethrough:
        return TextStyle(
          color: defaultColor,
          decoration: TextDecoration.lineThrough,
        );
      case _PatternType.italic:
        return TextStyle(color: defaultColor, fontStyle: FontStyle.italic);
    }
  }
}

enum _PatternType {
  bold,
  code,
  link,
  strikethrough,
  italic,
}

class _Pattern {
  final RegExp regex;
  final _PatternType type;

  const _Pattern(this.regex, this.type);
}

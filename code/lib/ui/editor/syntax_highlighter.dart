import 'package:flutter/material.dart';

class MarkdownSyntaxHighlighter {
  static TextSpan highlight(
    String text, {
    required Color headingColor,
    required Color boldColor,
    required Color codeColor,
    required Color linkColor,
    required Color defaultColor,
  }) {
    final List<TextSpan> spans = [];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('#')) {
        spans.add(TextSpan(
          text: line,
          style: TextStyle(color: headingColor, fontWeight: FontWeight.bold),
        ));
      } else if (line.startsWith('```')) {
        spans.add(TextSpan(
          text: line,
          style: TextStyle(color: codeColor, fontFamily: 'monospace'),
        ));
      } else {
        spans.addAll(_highlightInline(
          line,
          boldColor: boldColor,
          codeColor: codeColor,
          linkColor: linkColor,
          defaultColor: defaultColor,
        ));
      }

      if (i < lines.length - 1) {
        spans.add(TextSpan(text: '\n', style: TextStyle(color: defaultColor)));
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
    final List<TextSpan> spans = [];
    int pos = 0;

    final patterns = [
      _Pattern(RegExp(r'\*\*(.+?)\*\*'), boldColor, FontWeight.bold),
      _Pattern(RegExp(r'`(.+?)`'), codeColor, FontWeight.normal, 'monospace'),
      _Pattern(RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), linkColor, FontWeight.normal),
      _Pattern(RegExp(r'!\[([^\]]*)\]\(([^)]+)\)'), linkColor, FontWeight.normal),
      _Pattern(RegExp(r'~~(.+?)~~'), defaultColor, FontWeight.normal, null, TextDecoration.lineThrough),
      _Pattern(RegExp(r'\*(.+?)\*'), defaultColor, FontWeight.normal, null, null, FontStyle.italic),
    ];

    while (pos < text.length) {
      Match? earliestMatch;
      _Pattern? matchedPattern;

      for (final pattern in patterns) {
        final match = pattern.regex.firstMatch(text.substring(pos));
        if (match != null) {
          if (earliestMatch == null || match.start < earliestMatch.start) {
            earliestMatch = match;
            matchedPattern = pattern;
          }
        }
      }

      if (earliestMatch == null) {
        spans.add(TextSpan(text: text.substring(pos), style: TextStyle(color: defaultColor)));
        break;
      }

      if (earliestMatch.start > 0) {
        spans.add(TextSpan(
          text: text.substring(pos, pos + earliestMatch.start),
          style: TextStyle(color: defaultColor),
        ));
      }

      final matchText = earliestMatch.group(1) ?? earliestMatch.group(0)!;
      spans.add(TextSpan(
        text: matchText,
        style: TextStyle(
          color: matchedPattern!.color,
          fontWeight: matchedPattern.fontWeight,
          fontFamily: matchedPattern.fontFamily,
          decoration: matchedPattern.decoration,
          fontStyle: matchedPattern.fontStyle,
        ),
      ));

      pos += earliestMatch.start + earliestMatch.group(0)!.length;
    }

    return spans;
  }
}

class _Pattern {
  final RegExp regex;
  final Color color;
  final FontWeight fontWeight;
  final String? fontFamily;
  final TextDecoration? decoration;
  final FontStyle? fontStyle;

  _Pattern(
    this.regex,
    this.color,
    this.fontWeight, [
    this.fontFamily,
    this.decoration,
    this.fontStyle,
  ]);
}

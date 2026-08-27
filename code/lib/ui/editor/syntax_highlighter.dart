import 'package:flutter/material.dart';

/// Colours one line of Markdown at a time.
///
/// Everything here works per line so that [IncrementalMarkdownHighlighter] can
/// reuse the lines an edit did not touch. A keystroke in a large document used
/// to re-scan the whole file on every rebuild.
class MarkdownSyntaxHighlighter {
  static final List<_Pattern> _inlinePatterns = [
    _Pattern(RegExp(r'\*\*(.+?)\*\*'), _PatternType.bold),
    _Pattern(RegExp(r'`(.+?)`'), _PatternType.code),
    _Pattern(RegExp(r'!\[([^\]]*)\]\(([^)]+)\)'), _PatternType.link),
    _Pattern(RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), _PatternType.link),
    // Before the emphasis patterns: a comment may contain anything, and
    // letting `*` inside one match first would colour half of it as italic.
    _Pattern(RegExp(r'<!--.*?-->'), _PatternType.comment),
    _Pattern(RegExp(r'~~(.+?)~~'), _PatternType.strikethrough),
    _Pattern(RegExp(r'\*(.+?)\*'), _PatternType.italic),
  ];

  /// Highlights [text] in one pass, without caching.
  static TextSpan highlight(
    String text, {
    required Color headingColor,
    required Color boldColor,
    required Color codeColor,
    required Color linkColor,
    required Color defaultColor,
    Color? quoteColor,
    Color? commentColor,
  }) {
    if (text.isEmpty) {
      return const TextSpan(children: <TextSpan>[]);
    }

    final colors = HighlightColors(
      heading: headingColor,
      quote: quoteColor ?? defaultColor,
      comment: commentColor ?? defaultColor,
      bold: boldColor,
      code: codeColor,
      link: linkColor,
      defaultColor: defaultColor,
    );

    final lines = text.split('\n');
    return TextSpan(
      children: flatten(
        [for (final line in lines) highlightLine(line, colors)],
        colors,
      ),
    );
  }

  /// Joins per-line spans back into one document-order list.
  ///
  /// Each line's terminating newline is appended to that line's last span so
  /// it carries the same style: an unstyled orphan '\n' span makes
  /// EditableText stretch the selection highlight across the rest of the line.
  /// A blank line has no span to attach to, so it gets a standalone newline
  /// span carrying the default style.
  static List<TextSpan> flatten(
    List<List<TextSpan>> lineSpans,
    HighlightColors colors,
  ) {
    final out = <TextSpan>[];
    for (int i = 0; i < lineSpans.length; i++) {
      final spans = lineSpans[i];
      final isLastLine = i == lineSpans.length - 1;

      if (isLastLine) {
        out.addAll(spans);
        continue;
      }

      if (spans.isEmpty) {
        out.add(TextSpan(text: '\n', style: TextStyle(color: colors.defaultColor)));
        continue;
      }

      for (int j = 0; j < spans.length - 1; j++) {
        out.add(spans[j]);
      }
      final last = spans.last;
      out.add(TextSpan(text: '${last.text ?? ''}\n', style: last.style));
    }
    return out;
  }

  /// Spans for a single line, excluding its terminating newline.
  static List<TextSpan> highlightLine(String line, HighlightColors colors) {
    if (line.isEmpty) return const <TextSpan>[];

    if (line.startsWith('#')) {
      return [
        TextSpan(
          text: line,
          style: TextStyle(color: colors.heading, fontWeight: FontWeight.bold),
        ),
      ];
    }

    // A quoted line is coloured whole, which is how the themes' quote colour
    // was meant to be used — it was defined and then never painted with.
    final withoutIndent = line.trimLeft();
    if (withoutIndent.startsWith('>')) {
      return [TextSpan(text: line, style: TextStyle(color: colors.quote))];
    }

    if (line.startsWith('```')) {
      return [
        TextSpan(
          text: line,
          style: TextStyle(color: colors.code, fontFamily: 'monospace'),
        ),
      ];
    }

    return _highlightInline(line, colors);
  }

  static List<TextSpan> _highlightInline(String text, HighlightColors colors) {
    final spans = <TextSpan>[];
    int pos = 0;

    while (pos < text.length) {
      Match? earliest;
      _Pattern? matchedPattern;

      for (final pattern in _inlinePatterns) {
        // allMatches takes a start offset and is lazy, so this finds the first
        // match at or after `pos` without copying the rest of the line. The
        // previous code called substring(pos) up to three times per pattern
        // per position, which made a long paragraph quadratic.
        final iterator = pattern.regex.allMatches(text, pos).iterator;
        if (!iterator.moveNext()) continue;
        final match = iterator.current;
        if (earliest == null || match.start < earliest.start) {
          earliest = match;
          matchedPattern = pattern;
        }
      }

      if (earliest == null) {
        spans.add(TextSpan(
          text: text.substring(pos),
          style: TextStyle(color: colors.defaultColor),
        ));
        break;
      }

      if (earliest.start > pos) {
        spans.add(TextSpan(
          text: text.substring(pos, earliest.start),
          style: TextStyle(color: colors.defaultColor),
        ));
      }

      spans.add(TextSpan(
        text: earliest.group(0)!,
        style: _styleForPattern(matchedPattern!.type, colors),
      ));

      pos = earliest.end;
    }

    return spans;
  }

  static TextStyle _styleForPattern(_PatternType type, HighlightColors colors) {
    switch (type) {
      case _PatternType.bold:
        return TextStyle(color: colors.bold, fontWeight: FontWeight.bold);
      case _PatternType.code:
        return TextStyle(color: colors.code, fontFamily: 'monospace');
      case _PatternType.link:
        return TextStyle(color: colors.link);
      case _PatternType.strikethrough:
        return TextStyle(
          color: colors.defaultColor,
          decoration: TextDecoration.lineThrough,
        );
      case _PatternType.italic:
        return TextStyle(color: colors.defaultColor, fontStyle: FontStyle.italic);
      case _PatternType.comment:
        return TextStyle(color: colors.comment, fontStyle: FontStyle.italic);
    }
  }
}

/// The five colours the highlighter paints with, so they travel as one value
/// and can be compared to decide whether a cached result is still good.
@immutable
class HighlightColors {
  final Color heading;
  final Color bold;
  final Color code;
  final Color link;
  final Color defaultColor;

  /// A blockquote line.
  final Color quote;

  /// An HTML comment on one line.
  final Color comment;

  const HighlightColors({
    required this.heading,
    required this.bold,
    required this.code,
    required this.link,
    required this.defaultColor,
    Color? quote,
    Color? comment,
  })  : quote = quote ?? defaultColor,
        comment = comment ?? defaultColor;

  @override
  bool operator ==(Object other) =>
      other is HighlightColors &&
      other.heading == heading &&
      other.bold == bold &&
      other.code == code &&
      other.link == link &&
      other.defaultColor == defaultColor &&
      // Part of the comparison because the cached spans were painted with
      // these: leaving them out would keep stale colours after a theme change.
      other.quote == quote &&
      other.comment == comment;

  @override
  int get hashCode =>
      Object.hash(heading, bold, code, link, defaultColor, quote, comment);
}

/// Keeps per-line spans between rebuilds and re-scans only the lines an edit
/// touched.
///
/// `TextEditingController.buildTextSpan` runs on every rebuild — caret moves,
/// focus changes, a search-match update — and re-highlighting a megabyte of
/// Markdown each time cost hundreds of milliseconds per keystroke.
class IncrementalMarkdownHighlighter {
  /// Above this many characters the document is shown unstyled.
  ///
  /// Not about the scan itself: a document this size produces hundreds of
  /// thousands of spans, and it is laying those out that stalls the frame. An
  /// unstyled document stays fully editable.
  static const int maxHighlightedLength = 2 * 1024 * 1024;

  List<String> _lines = const [];
  List<List<TextSpan>> _lineSpans = const [];
  HighlightColors? _colors;
  bool _suspended = false;

  /// Whether the last [build] gave up on highlighting because the document is
  /// too large.
  bool get isSuspended => _suspended;

  List<TextSpan> build(String text, HighlightColors colors) {
    if (text.length > maxHighlightedLength) {
      _suspended = true;
      _lines = const [];
      _lineSpans = const [];
      _colors = colors;
      return [TextSpan(text: text, style: TextStyle(color: colors.defaultColor))];
    }
    _suspended = false;

    // A theme change invalidates every cached span.
    if (_colors != colors) {
      _colors = colors;
      _lines = const [];
      _lineSpans = const [];
    }

    final next = text.split('\n');

    // Reuse the untouched head and tail. Typing changes one line, so this
    // leaves everything but that line alone; an insert or delete shifts the
    // tail, which the suffix scan follows.
    final shorter = next.length < _lines.length ? next.length : _lines.length;
    int head = 0;
    while (head < shorter && next[head] == _lines[head]) {
      head++;
    }
    int tail = 0;
    while (tail < shorter - head &&
        next[next.length - 1 - tail] == _lines[_lines.length - 1 - tail]) {
      tail++;
    }

    final rebuilt = List<List<TextSpan>>.filled(next.length, const []);
    for (int i = 0; i < head; i++) {
      rebuilt[i] = _lineSpans[i];
    }
    for (int i = 0; i < tail; i++) {
      rebuilt[next.length - 1 - i] = _lineSpans[_lines.length - 1 - i];
    }
    for (int i = head; i < next.length - tail; i++) {
      rebuilt[i] = MarkdownSyntaxHighlighter.highlightLine(next[i], colors);
    }

    _lines = next;
    _lineSpans = rebuilt;

    return MarkdownSyntaxHighlighter.flatten(rebuilt, colors);
  }
}

enum _PatternType {
  bold,
  code,
  link,
  strikethrough,
  italic,
  comment,
}

class _Pattern {
  final RegExp regex;
  final _PatternType type;

  const _Pattern(this.regex, this.type);
}

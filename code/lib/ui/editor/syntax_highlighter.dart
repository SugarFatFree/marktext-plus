import 'package:flutter/material.dart';

import '../../services/inline_emphasis.dart';
import '../../services/markdown_parser.dart';

/// Colours one line of Markdown at a time.
///
/// Everything here works per line so that [IncrementalMarkdownHighlighter] can
/// reuse the lines an edit did not touch. A keystroke in a large document used
/// to re-scan the whole file on every rebuild.
class MarkdownSyntaxHighlighter {
  static final List<_Pattern> _inlinePatterns = [
    _Pattern(RegExp(r'\*\*(.+?)\*\*'), _PatternType.bold,
        emphasisChar: '**', marker: _asterisk),
    // CommonMark gives `_` the same standing as `*`, and the parser has
    // always read both. Only this list knew about asterisks, so a document
    // written with underscores was left grey while the pane beside it drew
    // every run of them emphasised.
    //
    // Before the single-underscore pattern, which the loop needs: at the same
    // starting point it takes whichever it reaches first.
    _Pattern(RegExp(r'__(.+?)__'), _PatternType.bold,
        emphasisChar: '__', marker: _underscore),
    _Pattern(RegExp(r'`(.+?)`'), _PatternType.code, marker: _backtick),
    // Both halves allow the same nesting the parser allows — two levels of
    // brackets in the text, one level of parentheses in the destination — so
    // the two agree on `[见 [附录 [A]]](/url)` and on `…/wiki/A_(b)`. A tint
    // that stops one level short says a link is not a link.
    //
    // It is also what keeps this linear. `[^\]]+` and `[^)\n]*` each gave the
    // engine a run it had to hand back one character at a time from every
    // starting position: a line of 60,000 `[` took 46 seconds, and one of
    // `[a](` repeated took 11 — with the editor frozen throughout.
    _Pattern(
      RegExp(r'!\[((?:[^\[\]]|\[(?:[^\[\]]|\[[^\[\]]*\])*\])*)\]'
          r'\(((?:[^()\s]|\([^()]*\))*)\)'),
      _PatternType.link,
      marker: _bang,
    ),
    _Pattern(
      RegExp(r'\[((?:[^\[\]]|\[(?:[^\[\]]|\[[^\[\]]*\])*\])*)\]'
          r'\(((?:[^()\s]|\([^()]*\))*)\)'),
      _PatternType.link,
      marker: _openBracket,
    ),
    // Before the emphasis patterns: a comment may contain anything, and
    // letting `*` inside one match first would colour half of it as italic.
    _Pattern(RegExp(r'<!--.*?-->'), _PatternType.comment, marker: _lessThan),
    // No flanking test on this one: this project's parser is deliberately
    // more forgiving than GitHub about `~~文字。~~后面` and draws it, so the
    // tint has to agree with the pane beside it rather than with GitHub.
    _Pattern(RegExp(r'~~(.+?)~~'), _PatternType.strikethrough,
        marker: _tilde),
    // Not part of a longer run: without the guards this matched `**加粗。*`
    // out of the middle of a bold run and tinted half of it.
    _Pattern(RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)'),
        _PatternType.italic, emphasisChar: '*', marker: _asterisk),
    // What keeps `snake_case_name` grey is not this pattern — it matches
    // `_case_` happily — but the flanking rule `accepts` asks the parser for,
    // which refuses a run with word characters on both sides. That rule is
    // the reason `_` can be added here at all.
    _Pattern(RegExp(r'(?<!_)_(?!_)(.+?)(?<!_)_(?!_)'),
        _PatternType.italic, emphasisChar: '_', marker: _underscore),
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
    final inFence = fenceStates(lines);
    return TextSpan(
      children: flatten(
        [
          for (var i = 0; i < lines.length; i++)
            highlightLine(lines[i], colors, inCodeFence: inFence[i]),
        ],
        colors,
      ),
    );
  }

  static const int _backtick = 0x60;
  static const int _asterisk = 0x2A;
  static const int _underscore = 0x5F;
  static const int _openBracket = 0x5B;
  static const int _bang = 0x21;
  static const int _lessThan = 0x3C;
  static const int _tilde = 0x7E;
  static const int _space = 0x20;

  /// The fence run opening or closing at the start of [line], or null.
  ///
  /// Hand-rolled rather than a regular expression because it runs over every
  /// line of the document on every keystroke: the first character decides it
  /// for almost every line, and a `RegExp` cost 33 ms on a 1.4 MiB file where
  /// this costs under two.
  static ({int char, int length, bool bare})? _fenceRun(String line) {
    var i = 0;
    while (i < 3 && i < line.length && line.codeUnitAt(i) == _space) {
      i++;
    }
    if (i >= line.length) return null;
    final char = line.codeUnitAt(i);
    if (char != _backtick && char != _tilde) return null;

    var length = 0;
    while (i + length < line.length && line.codeUnitAt(i + length) == char) {
      length++;
    }
    if (length < 3) return null;

    // A closing fence carries no info string.
    final bare = line.substring(i + length).trim().isEmpty;
    return (char: char, length: length, bare: bare);
  }

  /// Whether each line *begins* inside a fenced code block.
  ///
  /// Styling is decided a line at a time so the incremental highlighter can
  /// reuse untouched lines, and a line on its own cannot tell that it sits
  /// inside a fence. Without this, `**bold**`, `[a](b)`, `# comment` and
  /// `> arrow` inside a snippet were all coloured as markdown.
  static List<bool> fenceStates(List<String> lines) {
    final states = List<bool>.filled(lines.length, false);
    int? openChar;
    var openLength = 0;
    for (var i = 0; i < lines.length; i++) {
      states[i] = openChar != null;
      final run = _fenceRun(lines[i]);
      if (run == null) continue;
      if (openChar == null) {
        openChar = run.char;
        openLength = run.length;
      } else if (run.char == openChar &&
          run.length >= openLength &&
          run.bare) {
        // A closing fence uses the same character, is at least as long, and
        // carries no info string.
        openChar = null;
      }
    }
    return states;
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
      if (i == lineSpans.length - 1) {
        out.addAll(lineSpans[i]);
      } else {
        out.addAll(withNewline(lineSpans[i], colors));
      }
    }
    return out;
  }

  /// One line's spans with its terminating newline attached.
  ///
  /// Deliberately independent of where the line sits, so the incremental
  /// highlighter can cache this per line: rebuilding it for all 85,000 lines
  /// of a large document cost 32 ms of every keystroke, most of it in
  /// allocating a new string per line.
  static List<TextSpan> withNewline(
    List<TextSpan> spans,
    HighlightColors colors,
  ) {
    if (spans.isEmpty) {
      return [
        TextSpan(text: '\n', style: TextStyle(color: colors.defaultColor)),
      ];
    }
    final out = <TextSpan>[];
    for (int j = 0; j < spans.length - 1; j++) {
      out.add(spans[j]);
    }
    final last = spans.last;
    out.add(TextSpan(text: '${last.text ?? ''}\n', style: last.style));
    return out;
  }

  /// Spans for a single line, excluding its terminating newline.
  ///
  /// [inCodeFence] says whether the line begins inside a fenced block, which
  /// only [fenceStates] can know.
  static List<TextSpan> highlightLine(
    String line,
    HighlightColors colors, {
    bool inCodeFence = false,
  }) {
    if (line.isEmpty) return const <TextSpan>[];

    // Everything between the fences is code, delimiters included.
    if (inCodeFence || _fenceRun(line) != null) {
      return [
        TextSpan(
          text: line,
          style: TextStyle(color: colors.code, fontFamily: 'monospace'),
        ),
      ];
    }

    // The parser's own answer, not `startsWith('#')`: see headingLevelOf.
    if (MarkdownParser.headingLevelOf(line) != null) {
      return [
        TextSpan(
          text: line,
          style: TextStyle(color: colors.heading, fontWeight: FontWeight.bold),
        ),
      ];
    }

    // A quoted line is coloured whole, which is how the themes' quote colour
    // was meant to be used — it was defined and then never painted with.
    //
    // The parser's answer, not `trimLeft().startsWith('>')`: a marker may sit
    // behind up to three columns of indentation and no more, because four is
    // where an indented block starts. The looser test painted those lines as
    // quotes the preview does not draw.
    if (MarkdownParser.blockquoteDepthOf(line) != null) {
      return [TextSpan(text: line, style: TextStyle(color: colors.quote))];
    }

    return _highlightInline(line, colors);
  }

  /// The bit [marker] sets in the presence mask built for each line.
  static int _bitFor(int marker) => switch (marker) {
        _asterisk => 1,
        _underscore => 2,
        _backtick => 4,
        _openBracket => 8,
        _bang => 16,
        _lessThan => 32,
        _tilde => 64,
        _ => 0,
      };

  static List<TextSpan> _highlightInline(String text, HighlightColors colors) {
    final spans = <TextSpan>[];
    int pos = 0;

    // The first match of each pattern at or after `pos`, remembered between
    // rounds.
    //
    // `pos` only moves forward, so a remembered match that still starts at or
    // after it is still that pattern's first: anything nearer would have been
    // found in the earlier round too. Re-running every pattern from every
    // position made a line with many markers quadratic — 60,000 asterisks took
    // fourteen seconds, and the editor was frozen for all of it.
    final upcoming = List<Match?>.filled(_inlinePatterns.length, null);
    final spent = List<bool>.filled(_inlinePatterns.length, false);

    // A pattern whose opening character is nowhere on the line cannot match,
    // and running it costs a scan of the whole line. Most lines carry none of
    // these characters at all, so one pass over the text buys the rest.
    //
    // This is what pays for reading `_` and `__` as well as `*` and `**`:
    // adding those two patterns cost 50% on a 2.5 MB document, and skipping
    // the absent ones gave back more than that.
    var seen = 0;
    for (var i = 0; i < text.length; i++) {
      switch (text.codeUnitAt(i)) {
        case _asterisk:
          seen |= 1;
        case _underscore:
          seen |= 2;
        case _backtick:
          seen |= 4;
        case _openBracket:
          seen |= 8;
        case _bang:
          seen |= 16;
        case _lessThan:
          seen |= 32;
        case _tilde:
          seen |= 64;
      }
    }
    for (var k = 0; k < _inlinePatterns.length; k++) {
      final bit = _bitFor(_inlinePatterns[k].marker);
      // No bit means no cheap test for this one — run it. A pattern added
      // without a marker, or with one this switch does not know, must still
      // work; silently skipping it would be a hole nothing points at.
      if (bit != 0 && seen & bit == 0) spent[k] = true;
    }

    while (pos < text.length) {
      Match? earliest;
      _Pattern? matchedPattern;

      for (int k = 0; k < _inlinePatterns.length; k++) {
        if (spent[k]) continue;
        var match = upcoming[k];
        if (match == null || match.start < pos) {
          // allMatches takes a start offset and is lazy, so this finds the
          // first match at or after `pos` without copying the rest of the line.
          final iterator =
              _inlinePatterns[k].regex.allMatches(text, pos).iterator;
          // Past any match the flanking rule refuses: those characters are not
          // emphasis, and something further along the line may still be.
          Match? found;
          while (iterator.moveNext()) {
            if (_inlinePatterns[k].accepts(text, iterator.current)) {
              found = iterator.current;
              break;
            }
          }
          if (found == null) {
            // No match anywhere ahead; never scan for this one again.
            spent[k] = true;
            upcoming[k] = null;
            continue;
          }
          match = found;
          upcoming[k] = match;
        }
        if (earliest == null || match.start < earliest.start) {
          earliest = match;
          matchedPattern = _inlinePatterns[k];
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
  ///
  /// Measured, opening a file of Markdown with the usual amount of `code` and
  /// **emphasis** in it, timed to the first painted frame:
  ///
  /// | size   | with highlighting |
  /// |--------|-------------------|
  /// | 64 KB  | 1.2 s             |
  /// | 128 KB | 1.3 s             |
  /// | 256 KB | 8.0 s             |
  /// | 384 KB | 24 s              |
  /// | 512 KB | 45 s              |
  ///
  /// The cost is superlinear in the number of spans, so the number is a cliff
  /// rather than a slope: 128 KB is the last size that opens in about a
  /// second. It was two megabytes, which no document ever reached — a 739 KB
  /// file took seven seconds to open, and the limit that was supposed to
  /// prevent exactly that never came into play.
  static const int maxHighlightedLength = 128 * 1024;

  List<String> _lines = const [];
  List<List<TextSpan>> _lineSpans = const [];

  /// Whether each cached line began inside a fenced code block.
  ///
  /// A line's styling depends on this as well as on its text, so reuse has to
  /// match on both: typing the opening ``` of a fence leaves every line below
  /// textually unchanged while changing how all of them are drawn.
  List<bool> _lineFences = const [];

  /// Each line's spans with its newline already attached.
  ///
  /// Cached alongside [_lineSpans] because attaching the newline allocates a
  /// string per line, and doing that for every line of a large document was
  /// the single most expensive part of a keystroke.
  List<List<TextSpan>> _lineFlat = const [];

  /// Each line as a single span holding its own children.
  ///
  /// What [build] returns is a list with one entry per line rather than one
  /// entry per styled run. On a one megabyte document that is thirty thousand
  /// entries instead of half a million, and the list was being built from
  /// scratch on every keystroke — the copying, not the highlighting, was what
  /// made typing in a large file cost about 47 ms a key.
  List<TextSpan> _lineNodes = const [];
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
      _lineFences = const [];
      _lineFlat = const [];
      _lineNodes = const [];
      _colors = colors;
      return [TextSpan(text: text, style: TextStyle(color: colors.defaultColor))];
    }
    _suspended = false;

    // A theme change invalidates every cached span.
    if (_colors != colors) {
      _colors = colors;
      _lines = const [];
      _lineSpans = const [];
      _lineFences = const [];
      _lineFlat = const [];
      _lineNodes = const [];
    }

    final next = text.split('\n');
    final fences = MarkdownSyntaxHighlighter.fenceStates(next);

    // Reuse the untouched head and tail. Typing changes one line, so this
    // leaves everything but that line alone; an insert or delete shifts the
    // tail, which the suffix scan follows.
    final shorter = next.length < _lines.length ? next.length : _lines.length;
    int head = 0;
    while (head < shorter &&
        next[head] == _lines[head] &&
        fences[head] == _lineFences[head]) {
      head++;
    }
    int tail = 0;
    while (tail < shorter - head &&
        next[next.length - 1 - tail] == _lines[_lines.length - 1 - tail] &&
        fences[next.length - 1 - tail] ==
            _lineFences[_lines.length - 1 - tail]) {
      tail++;
    }

    final rebuilt = List<List<TextSpan>>.filled(next.length, const []);
    final flat = List<List<TextSpan>>.filled(next.length, const []);
    final nodes = List<TextSpan>.filled(next.length, const TextSpan());
    for (int i = 0; i < head; i++) {
      rebuilt[i] = _lineSpans[i];
      flat[i] = _lineFlat[i];
      nodes[i] = _lineNodes[i];
    }
    for (int i = 0; i < tail; i++) {
      rebuilt[next.length - 1 - i] = _lineSpans[_lines.length - 1 - i];
      flat[next.length - 1 - i] = _lineFlat[_lines.length - 1 - i];
      nodes[next.length - 1 - i] = _lineNodes[_lines.length - 1 - i];
    }
    for (int i = head; i < next.length - tail; i++) {
      final spans = MarkdownSyntaxHighlighter.highlightLine(
        next[i],
        colors,
        inCodeFence: fences[i],
      );
      rebuilt[i] = spans;
      flat[i] = MarkdownSyntaxHighlighter.withNewline(spans, colors);
      nodes[i] = TextSpan(children: flat[i]);
    }

    // Two lines need their node rebuilt whatever the diff said, because a
    // node's contents depend on whether its line is the last one — the last
    // line is the only one with no newline after it.
    //
    // The line that is last now: its spans must come from the form without a
    // newline.
    //
    // And the line that *was* last: adding a line after it leaves it textually
    // unchanged, so the head scan reuses it — handing back the node built when
    // it had no newline, and dropping a line break out of the document. The
    // existing tests caught this, which is the whole reason they compare the
    // incremental result against a full re-highlight rather than against
    // themselves.
    final wasLast = _lines.length - 1;
    if (wasLast >= 0 && wasLast < next.length - 1) {
      nodes[wasLast] = TextSpan(children: flat[wasLast]);
    }
    if (next.isNotEmpty) {
      nodes[next.length - 1] = TextSpan(children: rebuilt[next.length - 1]);
    }

    _lines = next;
    _lineSpans = rebuilt;
    _lineFences = fences;
    _lineFlat = flat;
    _lineNodes = nodes;

    return nodes;
  }

  /// The line spans laid out end to end.
  ///
  /// Only what needs a flat view asks for one — painting a search highlight
  /// across the document. Typing does not, and paying for the flattening on
  /// every keystroke is what this class exists to avoid.
  static List<TextSpan> flatten(List<TextSpan> lineNodes) => [
        for (final line in lineNodes)
          if (line.children == null)
            line
          else
            ...line.children!.cast<TextSpan>(),
      ];

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

  /// The marker this pattern's run is made of, for the ones the flanking rule
  /// applies to. Null for those it does not — a code span, a link.
  final String? emphasisChar;

  /// The first literal character this pattern's match must contain.
  ///
  /// Used to skip the pattern entirely on a line that has none, which is most
  /// lines. Required rather than defaulted: a pattern added without one would
  /// be skipped on every line, and a default cannot be told apart from a
  /// forgotten argument.
  final int marker;

  const _Pattern(this.regex, this.type,
      {this.emphasisChar, required this.marker});

  /// Whether [match] is emphasis where it stands.
  ///
  /// A pattern alone cannot tell: `**加粗。**后面` matches the bold pattern and
  /// is not bold, because the closing run sits between a full stop and a
  /// letter. The source pane used to colour it anyway, so it said "bold" while
  /// the pane beside it drew asterisks. The judgement comes from the parser's
  /// own rule, not a second copy of it.
  bool accepts(String text, Match match) {
    final char = emphasisChar;
    if (char == null) return true;
    final run = char.length == 1 ? 1 : char.length;

    final openBefore = match.start > 0 ? text[match.start - 1] : ' ';
    final openAfter = match.start + run < text.length
        ? text[match.start + run]
        : ' ';
    final closeBefore =
        match.end - run - 1 >= 0 ? text[match.end - run - 1] : ' ';
    final closeAfter = match.end < text.length ? text[match.end] : ' ';

    return emphasisFlanking(
              before: openBefore,
              after: openAfter,
              char: char[0],
            ).canOpen &&
        emphasisFlanking(
          before: closeBefore,
          after: closeAfter,
          char: char[0],
        ).canClose;
  }
}

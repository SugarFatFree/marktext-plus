// Lightweight self-built Markdown parser supporting CommonMark + GFM subset.
// Uses regex-based line scanning for block-level and inline parsing.

import 'dart:convert' show LineSplitter;

// -- Enums --

enum NodeType {
  heading,
  paragraph,
  codeBlock,
  orderedList,
  unorderedList,
  blockquote,
  horizontalRule,
  table,
  mathBlock,
  frontMatter,
  footnoteDefinition,
  htmlBlock,
}

enum InlineType {
  text,
  bold,
  italic,
  code,
  link,
  image,
  strikethrough,
  mathInline,
  highlight,
  superscript,
  subscript,
  underline,
  footnoteRef,
  boldItalic,
}

// -- Inline Span --

class InlineSpan {
  final InlineType type;
  final String text;
  final String? href;
  final String? title;

  const InlineSpan({
    required this.type,
    required this.text,
    this.href,
    this.title,
  });
}

// -- AST Nodes --

abstract class MarkdownNode {
  NodeType get type;
  String get rawContent;

  /// 0-based index of this block's first source line.
  ///
  /// Tracked as lines rather than character offsets because the parser is
  /// line-oriented, and because BOM stripping and \r\n handling would make
  /// character offsets disagree with the original text while line numbers
  /// stay correct.
  int sourceStart = 0;

  /// 0-based index one past this block's last source line.
  int sourceEnd = 0;
}

/// Records [node]'s source line range and returns it, so parse sites can stay
/// single expressions.
T _withSpan<T extends MarkdownNode>(T node, int start, int end) {
  node.sourceStart = start;
  node.sourceEnd = end;
  return node;
}

class HeadingNode extends MarkdownNode {
  final int level;
  final String content;
  final List<InlineSpan> inlineSpans;

  HeadingNode({
    required this.level,
    required this.content,
    required this.inlineSpans,
  });

  @override
  NodeType get type => NodeType.heading;
  @override
  String get rawContent => content;
}
class ParagraphNode extends MarkdownNode {
  final String content;
  final List<InlineSpan> inlineSpans;

  ParagraphNode({required this.content, required this.inlineSpans});

  @override
  NodeType get type => NodeType.paragraph;
  @override
  String get rawContent => content;
}

class CodeBlockNode extends MarkdownNode {
  final String language;
  final String code;

  CodeBlockNode({required this.language, required this.code});

  @override
  NodeType get type => NodeType.codeBlock;
  @override
  String get rawContent => code;
}

class ListItem {
  final String content;
  final List<InlineSpan> inlineSpans;
  final bool isTask;
  final bool isChecked;

  /// Nesting level, 0 for a top-level item.
  ///
  /// Derived from the ordering of indentation widths within one list rather
  /// than from a fixed number of spaces, since authors indent by two or four
  /// and only the relative depth matters.
  final int depth;

  /// Whether this item carries a number or a bullet.
  ///
  /// Per item rather than per list: a numbered step may hold bulleted
  /// sub-points, and taking the marker from the list meant those sub-points
  /// came out numbered.
  final bool ordered;

  ListItem({
    required this.content,
    required this.inlineSpans,
    this.isTask = false,
    this.isChecked = false,
    this.depth = 0,
    this.ordered = false,
  });
}

class ListNode extends MarkdownNode {
  final bool ordered;
  final List<ListItem> items;

  ListNode({required this.ordered, required this.items});

  @override
  NodeType get type => ordered ? NodeType.orderedList : NodeType.unorderedList;
  @override
  String get rawContent => items.map((i) => i.content).join('\n');
}
class BlockquoteNode extends MarkdownNode {
  /// Nesting level, 0 for a top-level quote.
  ///
  /// A quote containing a deeper quote is emitted as consecutive nodes rather
  /// than nested ones: `> a` then `>> b` gives depth 0 and depth 1.
  final int depth;

  final String content;
  final List<InlineSpan> inlineSpans;

  /// The blocks inside the quote.
  ///
  /// A quote can hold a list, a heading, a code block — anything a document
  /// can. Rendering only [inlineSpans] showed those as their source text:
  /// `> - a` came out as the characters "- a" rather than a bulleted item.
  final List<MarkdownNode> children;

  BlockquoteNode({
    required this.content,
    required this.inlineSpans,
    this.children = const [],
    this.depth = 0,
  });

  @override
  NodeType get type => NodeType.blockquote;
  @override
  String get rawContent => content;
}

class HorizontalRuleNode extends MarkdownNode {
  @override
  NodeType get type => NodeType.horizontalRule;
  @override
  String get rawContent => '---';
}

class TableNode extends MarkdownNode {
  final List<String> headers;
  final List<List<String>> rows;
  final List<String> alignments; // 'left', 'center', 'right', 'default'

  TableNode({
    required this.headers,
    required this.rows,
    this.alignments = const [],
  });

  @override
  NodeType get type => NodeType.table;
  @override
  String get rawContent =>
      [headers.join(' | '), ...rows.map((r) => r.join(' | '))].join('\n');
}

class MathBlockNode extends MarkdownNode {
  final String expression;

  MathBlockNode({required this.expression});

  @override
  NodeType get type => NodeType.mathBlock;
  @override
  String get rawContent => expression;
}

class FrontMatterNode extends MarkdownNode {
  final String content;

  FrontMatterNode({required this.content});

  @override
  NodeType get type => NodeType.frontMatter;
  @override
  String get rawContent => content;
}

class FootnoteDefinitionNode extends MarkdownNode {
  final String id;
  final String content;

  FootnoteDefinitionNode({required this.id, required this.content});

  @override
  NodeType get type => NodeType.footnoteDefinition;
  @override
  String get rawContent => '[$id]: $content';
}

class HtmlBlockNode extends MarkdownNode {
  final String html;

  HtmlBlockNode({required this.html});

  @override
  NodeType get type => NodeType.htmlBlock;
  @override
  String get rawContent => html;
}
// -- Parser --

class MarkdownParser {
  /// One heading, as the outline sees it.
  ///
  /// [line] is 1-based, matching what the editor and the scroll targets use.

  static final _headingRe = RegExp(r'^(#{1,6})\s+(.+)$');
  static final _hrRe = RegExp(r'^(\*{3,}|-{3,}|_{3,})\s*$');
  /// A fence opening a code block.
  ///
  /// Three or more backticks or tildes. The length and the character both
  /// matter: a longer fence is how a document shows ``` inside a code block,
  /// and CommonMark allows ~~~ as well. Matching only ``` turned a ````
  /// fence into two empty blocks with the contents lost, and left a ~~~ block
  /// as an ordinary paragraph.
  static final _codeFenceRe = RegExp(r'^\s*(`{3,}|~{3,})\s*([^`\s]*)');
  static final _codeFenceEndRe = RegExp(r'^\s*(`{3,}|~{3,})\s*$');

  /// The headings of [source], in document order.
  ///
  /// The outline panel and the preview's scroll targets both need this and
  /// have to agree exactly: the preview maps its Nth heading widget to the
  /// Nth entry here, so one list seeing a heading the other does not puts
  /// every later entry on the wrong line.
  ///
  /// Lines inside a fenced code block are not headings. `# install deps` in a
  /// shell snippet is a comment, and counting it filled the outline with
  /// entries that scrolled somewhere unrelated.
  static List<({int line, int level, String text})> headingOutline(
      String source) {
    // A byte order mark would sit in front of the first '#' and stop it
    // matching, so the two callers disagreed about the first heading.
    final text = source.isNotEmpty && source.codeUnitAt(0) == 0xFEFF
        ? source.substring(1)
        : source;

    final headings = <({int line, int level, String text})>[];
    final lines = text.split('\n');
    var inFence = false;

    for (var i = 0; i < lines.length; i++) {
      if (_codeFenceRe.hasMatch(lines[i])) {
        inFence = !inFence;
        continue;
      }
      if (inFence) continue;

      final match = _headingRe.firstMatch(lines[i]);
      if (match == null) continue;
      headings.add((
        line: i + 1,
        level: match.group(1)!.length,
        text: match.group(2)!.trim(),
      ));
    }
    return headings;
  }
  /// Removes the markers that force a line break inside a paragraph.
  ///
  /// Two trailing spaces, or a trailing backslash, ask for a break — which
  /// this parser gives every newline anyway. Left in place the backslash
  /// showed up as a stray character at the end of the line, and the spaces
  /// travelled into every export.
  static List<String> _stripHardBreakMarkers(List<String> lines) {
    return [
      for (var i = 0; i < lines.length; i++)
        // The last line ends the paragraph, so nothing there is a break.
        i == lines.length - 1
            ? lines[i]
            : lines[i].replaceFirst(RegExp(r'(\s{2,}|\\)$'), ''),
    ];
  }

  /// Whether [line] closes a block opened by [fence].
  ///
  /// The closing fence must use the same character and be at least as long,
  /// so ``` inside a ```` block is content rather than the end of it.
  static bool _closesFence(String line, String fence) {
    final match = _codeFenceEndRe.firstMatch(line);
    if (match == null) return false;
    final closing = match.group(1)!;
    return closing[0] == fence[0] && closing.length >= fence.length;
  }

  static final _mathBlockRe = RegExp(r'^\$\$\s*$');
  /// A task marker. GFM treats `[x]` and `[X]` alike, and the editor's own
  /// prefix handling already accepted both — only the parser did not, so a
  /// list written with `[X]` rendered as a bullet with the brackets showing.
  static final _taskRe = RegExp(r'^\[([ xX])\]\s+(.+)$');
  static final _blockquoteRe = RegExp(r'^(>+)\s?(.*)$');
  static final _ulRe = RegExp(r'^[\s]*[-*+]\s+(.+)$');
  /// An ordered list item. CommonMark allows `)` as well as `.` after the
  /// number, and the editor's own prefix handling already accepted both — only
  /// the parser did not, so `1) one` rendered as an ordinary paragraph.
  static final _olRe = RegExp(r'^[\s]*\d+[.)]\s+(.+)$');
  /// A table row. GFM makes the outer pipes optional, so `a | b` is a row;
  /// requiring them turned such a table into an ordinary paragraph.
  static final _tableRowRe = RegExp(r'^\s*\|?.*\|.*\|?\s*$');

  /// The row of dashes under the header.
  static final _tableSepRe = RegExp(r'^\s*\|?[\s:|-]+\|?\s*$');
  static final _frontMatterRe = RegExp(r'^---\s*$');
  static final _footnoteDefRe = RegExp(r'^\[\^([^\]]+)\]:\s*(.+)$');
  /// An HTML element opening a block.
  ///
  /// The tag name must be followed by something that can start an attribute
  /// list or close the tag, which keeps `<https://example.com>` — an autolink,
  /// not an element — out of this branch.
  static final _htmlBlockStartRe =
      RegExp(r'^<([a-zA-Z][a-zA-Z0-9-]*)(?=[\s/>])');

  /// A link reference definition: `[label]: url "title"`.
  static final _linkDefRe = RegExp(
    r'^\s{0,3}\[([^\]]+)\]:\s*(\S+)(?:\s+"([^"]*)")?\s*$',
  );

  /// A setext underline: `===` for level 1, `---` for level 2.
  static final _setextRe = RegExp(r'^\s{0,3}(=+|-+)\s*$');

  /// HTML elements that never have a closing tag.
  static const _voidHtmlTags = {
    'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input',
    'link', 'meta', 'param', 'source', 'track', 'wbr',
  };

  /// Splits [source] the same way [parse] does, so line indices recorded on a
  /// node line up with the returned list.
  static List<String> _sourceLines(String source) {
    return const LineSplitter().convert(_stripBom(source));
  }

  static String _stripBom(String source) {
    return source.isNotEmpty && source.codeUnitAt(0) == 0xFEFF
        ? source.substring(1)
        : source;
  }

  /// The raw markdown that produced [node].
  ///
  /// This is not the same as `node.rawContent`, which holds parsed content —
  /// a heading's `rawContent` has already lost its `#` prefix. Editing needs
  /// the original text back.
  static String sourceOfBlock(String source, MarkdownNode node) {
    final lines = _sourceLines(source);
    final start = node.sourceStart.clamp(0, lines.length);
    final end = node.sourceEnd.clamp(start, lines.length);
    return lines.sublist(start, end).join('\n');
  }

  /// Returns [source] with [node]'s lines replaced by [replacement].
  ///
  /// Preserves the document's line ending style, its BOM, and whether it ended
  /// with a newline, so a round trip through the editor cannot silently
  /// rewrite those.
  static String replaceBlock(
    String source,
    MarkdownNode node,
    String replacement,
  ) {
    final hasBom = source.isNotEmpty && source.codeUnitAt(0) == 0xFEFF;
    final body = _stripBom(source);
    final newline = body.contains('\r\n') ? '\r\n' : '\n';
    final endsWithNewline = body.endsWith('\n') || body.endsWith('\r');

    final lines = const LineSplitter().convert(body);
    final start = node.sourceStart.clamp(0, lines.length);
    final end = node.sourceEnd.clamp(start, lines.length);

    final replacementLines = replacement.isEmpty
        ? const <String>[]
        : const LineSplitter().convert(replacement);

    final result = <String>[
      ...lines.sublist(0, start),
      ...replacementLines,
      ...lines.sublist(end),
    ];

    final joined = result.join(newline);
    return (hasBom ? '\uFEFF' : '') +
        joined +
        (endsWithNewline ? newline : '');
  }

  /// Removes up to [columns] of leading whitespace, tabs counted as four.
  static String _stripIndent(String line, int columns) {
    var removed = 0;
    var index = 0;
    while (index < line.length && removed < columns) {
      final rune = line.codeUnitAt(index);
      if (rune == 0x20) {
        removed++;
      } else if (rune == 0x09) {
        removed += 4 - (removed % 4);
      } else {
        break;
      }
      index++;
    }
    return line.substring(index);
  }

  /// Leading whitespace in columns, counting a tab as up to four.
  static int _indentColumns(String line) {
    var columns = 0;
    for (final rune in line.runes) {
      if (rune == 0x20) {
        columns++;
      } else if (rune == 0x09) {
        columns += 4 - (columns % 4);
      } else {
        break;
      }
    }
    return columns;
  }

  /// Builds list items from one block of lines per item.
  ///
  /// The distinct indentation widths in the list are sorted and an item's
  /// depth is its position among them, so two-space and four-space authors
  /// both get 0, 1, 2 rather than 1, 2 and 2, 4.
  ///
  /// Lines after the first in a block are continuation lines, joined with a
  /// space — markdown treats a wrapped item as one paragraph.
  /// The marker to draw in front of each of [items].
  ///
  /// Numbering runs per nesting level, so a numbered list inside a numbered
  /// list starts again at one, and a bulleted sub-point does not consume a
  /// number. Counting over the flat list gave `1. 2. 3.` down a tree that
  /// should read `1. 1. 2. 2.`.
  ///
  /// Shared so the preview and the three export paths cannot disagree.
  static List<String> listMarkers(List<ListItem> items) {
    final counters = <int, int>{};
    return [
      for (final item in items) _markerFor(item, counters),
    ];
  }

  static String _markerFor(ListItem item, Map<int, int> counters) {
    // Coming back out to a shallower level ends the deeper lists, so the next
    // parent's sub-list starts from one again.
    counters.removeWhere((depth, _) => depth > item.depth);

    if (!item.ordered) {
      // A bullet at this level ends whatever numbering was running here.
      counters.remove(item.depth);
      return '• ';
    }

    final next = (counters[item.depth] ?? 0) + 1;
    counters[item.depth] = next;
    return '$next. ';
  }

  List<ListItem> _buildListItems(List<List<String>> itemBlocks) {
    final widths =
        itemBlocks.map((block) => _indentColumns(block.first)).toSet().toList()
          ..sort();

    return itemBlocks.map((block) {
      // Each item is read with its own marker, not the list's: a bulleted
      // sub-point under a numbered step is still a bullet.
      final ordered = _olRe.hasMatch(block.first);
      final marker = ordered ? _olRe : _ulRe;
      final first = marker.firstMatch(block.first)!.group(1)!;
      final content = block.length == 1
          ? first
          : [first, ...block.skip(1).map((line) => line.trim())].join(' ');
      final depth = widths.indexOf(_indentColumns(block.first));

      final taskMatch = _taskRe.firstMatch(content);
      if (taskMatch != null) {
        final taskContent = taskMatch.group(2)!;
        return ListItem(
          content: taskContent,
          inlineSpans: parseInline(taskContent),
          isTask: true,
          isChecked: taskMatch.group(1)!.toLowerCase() == 'x',
          depth: depth,
          ordered: ordered,
        );
      }

      return ListItem(
        content: content,
        inlineSpans: parseInline(content),
        depth: depth,
        ordered: ordered,
      );
    }).toList();
  }

  /// Collects the lines of one list, starting at [start].
  ///
  /// Returns one block of lines per item and the index just past the list.
  ///
  /// Two things end up inside the list that a naive "while the line matches"
  /// loop would push out of it: a blank line between items, which used to
  /// split one list into two, and an indented continuation line, which used
  /// to become a paragraph wedged between them.
  /// Whether [line] starts a list item of either kind.
  ///
  /// A numbered step may hold bulleted sub-points and vice versa, so a list
  /// cannot be collected by looking only for its own marker: the sub-points
  /// were swallowed into the parent item's text.
  static bool _startsListItem(String line) =>
      _ulRe.hasMatch(line) || _olRe.hasMatch(line);

  (List<List<String>>, int) _collectListItems(List<String> lines, int start) {
    final blocks = <List<String>>[];
    var i = start;

    while (i < lines.length) {
      if (_startsListItem(lines[i])) {
        blocks.add([lines[i]]);
        i++;
        continue;
      }

      if (lines[i].trim().isEmpty) {
        var next = i + 1;
        while (next < lines.length && lines[next].trim().isEmpty) {
          next++;
        }
        // The list continues only if what follows the gap is another item.
        if (next < lines.length && _startsListItem(lines[next])) {
          i = next;
          continue;
        }
        break;
      }

      if (blocks.isNotEmpty && _indentColumns(lines[i]) > 0) {
        blocks.last.add(lines[i]);
        i++;
        continue;
      }

      break;
    }

    return (blocks, i);
  }

  /// Link reference definitions found in the document being parsed.
  ///
  /// Collected up front because a reference may appear before its definition.
  /// Empty when [parseInline] is called on its own, in which case a reference
  /// link stays plain text.
  final Map<String, ({String url, String? title})> _linkDefinitions = {};

  /// Parse markdown text into a list of block-level nodes.
  List<MarkdownNode> parse(String markdown) {
    // Strip UTF-8 BOM if present (otherwise heading regex on the first line fails)
    final source = markdown.isNotEmpty && markdown.codeUnitAt(0) == 0xFEFF
        ? markdown.substring(1)
        : markdown;
    // LineSplitter handles \n, \r\n, and \r in a single pass without
    // creating intermediate string copies (faster than replaceAll for large files)
    final lines = const LineSplitter().convert(source);

    _linkDefinitions.clear();
    for (final line in lines) {
      final match = _linkDefRe.firstMatch(line);
      if (match == null) continue;
      _linkDefinitions[match.group(1)!.toLowerCase()] =
          (url: match.group(2)!, title: match.group(3));
    }

    final nodes = <MarkdownNode>[];
    var i = 0;

    // Front matter detection (must be at start of file, with closing ---)
    if (i < lines.length && _frontMatterRe.hasMatch(lines[i])) {
      // Look ahead for closing ---
      var j = i + 1;
      while (j < lines.length && !_frontMatterRe.hasMatch(lines[j])) {
        j++;
      }
      if (j < lines.length) {
        // Found closing --- → parse as front matter
        final fmLines = <String>[];
        i++; // skip opening ---
        while (i < j) {
          fmLines.add(lines[i]);
          i++;
        }
        i++; // skip closing ---
        nodes.add(_withSpan(
          FrontMatterNode(content: fmLines.join('\n')),
          0,
          i,
        ));
      }
      // else: no closing --- found, fall through to normal parsing
    }

    while (i < lines.length) {
      final line = lines[i];
      final blockStart = i;

      // Blank line — skip
      if (line.trim().isEmpty) {
        i++;
        continue;
      }

      // A link reference definition is metadata, not content; leaving it to
      // the paragraph branch printed `[ref]: https://…` in the document.
      if (_linkDefRe.hasMatch(line)) {
        i++;
        continue;
      }

      // Footnote definition
      final footnoteMatch = _footnoteDefRe.firstMatch(line);
      if (footnoteMatch != null) {
        nodes.add(_withSpan(
          FootnoteDefinitionNode(
            id: footnoteMatch.group(1)!,
            content: footnoteMatch.group(2)!,
          ),
          blockStart,
          i + 1,
        ));
        i++;
        continue;
      }

      // HTML block
      final htmlMatch = _htmlBlockStartRe.firstMatch(line);
      if (htmlMatch != null) {
        final tag = htmlMatch.group(1)!;
        final htmlLines = <String>[line];
        final closeTag = '</$tag>';
        i++;

        // A tag that closes on its own line, a self-closing tag, or a void
        // element is the whole block. Scanning ahead for a closing tag that
        // was already on the opening line used to run to the end of the file
        // and swallow every block after it.
        final selfContained = line.contains(closeTag) ||
            line.trimRight().endsWith('/>') ||
            _voidHtmlTags.contains(tag.toLowerCase());

        if (!selfContained) {
          // Look for the close before consuming anything: an unclosed tag
          // should cost one line, not the rest of the document.
          var closeIndex = -1;
          for (var j = i; j < lines.length; j++) {
            if (lines[j].contains(closeTag)) {
              closeIndex = j;
              break;
            }
          }
          if (closeIndex != -1) {
            while (i <= closeIndex) {
              htmlLines.add(lines[i]);
              i++;
            }
          }
        }

        nodes.add(_withSpan(
          HtmlBlockNode(html: htmlLines.join('\n')),
          blockStart,
          i,
        ));
        continue;
      }

      // Math block ($$...$$)
      if (_mathBlockRe.hasMatch(line)) {
        final mathLines = <String>[];
        i++;
        while (i < lines.length && !_mathBlockRe.hasMatch(lines[i])) {
          mathLines.add(lines[i]);
          i++;
        }
        if (i < lines.length) i++; // skip closing $$
        nodes.add(_withSpan(
          MathBlockNode(expression: mathLines.join('\n')),
          blockStart,
          i,
        ));
        continue;
      }

      // Fenced code block
      final codeFenceMatch = _codeFenceRe.firstMatch(line);
      if (codeFenceMatch != null && !_ulRe.hasMatch(line)) {
        final fence = codeFenceMatch.group(1)!;
        final lang = codeFenceMatch.group(2) ?? '';
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !_closesFence(lines[i], fence)) {
          codeLines.add(lines[i]);
          i++;
        }
        if (i < lines.length) i++; // skip closing fence
        nodes.add(_withSpan(
          CodeBlockNode(language: lang, code: codeLines.join('\n')),
          blockStart,
          i,
        ));
        continue;
      }

      // Horizontal rule
      if (_hrRe.hasMatch(line)) {
        nodes.add(_withSpan(HorizontalRuleNode(), blockStart, i + 1));
        i++;
        continue;
      }
      // Heading
      final headingMatch = _headingRe.firstMatch(line);
      if (headingMatch != null) {
        final level = headingMatch.group(1)!.length;
        final content = headingMatch.group(2)!.trim();
        nodes.add(_withSpan(
          HeadingNode(
            level: level,
            content: content,
            inlineSpans: parseInline(content),
          ),
          blockStart,
          i + 1,
        ));
        i++;
        continue;
      }

      // Blockquote
      final bqMatch = _blockquoteRe.firstMatch(line);
      if (bqMatch != null) {
        // Consecutive lines at the same depth form one quote; a change in
        // depth starts another. Stripping a single `>` and keeping the rest as
        // text left the inner marker showing as literal `>`.
        final depth = bqMatch.group(1)!.length;
        final quoteStart = i;
        final bqLines = <String>[];

        while (i < lines.length) {
          final m = _blockquoteRe.firstMatch(lines[i]);
          if (m == null || m.group(1)!.length != depth) break;
          bqLines.add(m.group(2) ?? '');
          i++;
        }

        final content = bqLines.join('\n').trim();
        nodes.add(_withSpan(
          BlockquoteNode(
            content: content,
            inlineSpans: parseInline(content),
            // Parsed again so a list or a heading inside the quote is one.
            // The spans stay for anything still reading them.
            children: parse(content),
            // Depth counts from zero for a single `>`.
            depth: depth - 1,
          ),
          quoteStart,
          i,
        ));
        continue;
      }

      // Table (GFM)
      if (_tableRowRe.hasMatch(line) &&
          i + 1 < lines.length &&
          _tableSepRe.hasMatch(lines[i + 1]) &&
          // GFM requires the dashes row to have as many cells as the header.
          // Without this, now that the outer pipes are optional, a line of
          // prose containing a pipe followed by a horizontal rule became a
          // one-column table.
          _parseCells(lines[i + 1]).length == _parseCells(line).length) {
        final headers = _parseCells(line);
        final sepLine = lines[i + 1];
        final alignments = _parseAlignments(sepLine);
        final rows = <List<String>>[];
        i += 2;
        while (i < lines.length && _tableRowRe.hasMatch(lines[i])) {
          // GFM pads a short row and drops the extra cells of a long one, so
          // every row has as many cells as the header has columns.
          final cells = _parseCells(lines[i]);
          if (cells.length < headers.length) {
            cells.addAll(
                List.filled(headers.length - cells.length, ''));
          } else if (cells.length > headers.length) {
            cells.removeRange(headers.length, cells.length);
          }
          rows.add(cells);
          i++;
        }
        nodes.add(_withSpan(
          TableNode(
            headers: headers,
            rows: rows,
            alignments: alignments,
          ),
          blockStart,
          i,
        ));
        continue;
      }
      // Unordered list
      if (_ulRe.hasMatch(line)) {
        final (itemBlocks, next) = _collectListItems(lines, i);
        i = next;
        nodes.add(_withSpan(
          ListNode(ordered: false, items: _buildListItems(itemBlocks)),
          blockStart,
          i,
        ));
        continue;
      }

      // Ordered list
      if (_olRe.hasMatch(line)) {
        final (itemBlocks, next) = _collectListItems(lines, i);
        i = next;
        nodes.add(_withSpan(
          ListNode(ordered: true, items: _buildListItems(itemBlocks)),
          blockStart,
          i,
        ));
        continue;
      }

      // Setext heading: text underlined with === or ---.
      //
      // Checked here rather than beside the ATX pattern because it depends on
      // the *next* line. A bare `---` was handled by the horizontal-rule
      // branch above; reaching this point means real text precedes it, which
      // is exactly when CommonMark reads it as a heading.
      if (i + 1 < lines.length && _setextRe.hasMatch(lines[i + 1])) {
        final content = line.trim();
        final level = lines[i + 1].trim().startsWith('=') ? 1 : 2;
        i += 2;
        nodes.add(_withSpan(
          HeadingNode(
            level: level,
            content: content,
            inlineSpans: parseInline(content),
          ),
          blockStart,
          i,
        ));
        continue;
      }

      // Indented code block: four columns of indentation, starting a block
      // rather than continuing a paragraph.
      //
      // List items are matched before this, so an indented `- item` is still a
      // nested list rather than code.
      if (_indentColumns(line) >= 4 &&
          (i == 0 || lines[i - 1].trim().isEmpty)) {
        final codeLines = <String>[];
        while (i < lines.length &&
            (lines[i].trim().isEmpty || _indentColumns(lines[i]) >= 4)) {
          codeLines.add(_stripIndent(lines[i], 4));
          i++;
        }
        // Blank lines at the end belong to the document, not the code.
        while (codeLines.isNotEmpty && codeLines.last.trim().isEmpty) {
          codeLines.removeLast();
          i--;
        }
        nodes.add(_withSpan(
          CodeBlockNode(language: '', code: codeLines.join('\n')),
          blockStart,
          i,
        ));
        continue;
      }

      // Paragraph (default)
      final paraLines = <String>[];
      while (i < lines.length &&
          lines[i].trim().isNotEmpty &&
          !_headingRe.hasMatch(lines[i]) &&
          !_hrRe.hasMatch(lines[i]) &&
          !_codeFenceRe.hasMatch(lines[i]) &&
          !_blockquoteRe.hasMatch(lines[i]) &&
          !_ulRe.hasMatch(lines[i]) &&
          !_olRe.hasMatch(lines[i])) {
        paraLines.add(lines[i]);
        i++;
      }
      if (paraLines.isNotEmpty) {
        final content = _stripHardBreakMarkers(paraLines).join('\n');
        nodes.add(_withSpan(
          ParagraphNode(
            content: content,
            inlineSpans: parseInline(content),
          ),
          blockStart,
          i,
        ));
      }
    }

    return nodes;
  }
  /// Any ASCII punctuation may be escaped with a backslash.
  static final _escapedPunctRe = RegExp(r'\\([!-/:-@\[-`{-~])');

  /// Private-use code points standing in for escaped characters while the
  /// inline pattern runs.
  ///
  /// Substituting them is what stops `\*literal\*` being read as emphasis;
  /// the pattern has no way to look behind for a backslash across fourteen
  /// alternatives. The block runs to U+F8FF, so documents with more than
  /// [_maxEscapes] escapes leave the remainder as written.
  static const _escapeSentinelBase = 0xE000;
  static const _maxEscapes = 0xF8FF - 0xE000;

  /// Parse inline markdown text into a list of InlineSpan.
  List<InlineSpan> parseInline(String source) {
    final escapes = <String>[];
    final text = source.replaceAllMapped(_escapedPunctRe, (match) {
      if (escapes.length >= _maxEscapes) return match.group(0)!;
      escapes.add(match.group(1)!);
      return String.fromCharCode(_escapeSentinelBase + escapes.length - 1);
    });

    final spans = <InlineSpan>[];
    // Combined pattern for inline elements, ordered by priority
    final re = RegExp(
      // A URL may contain one level of balanced parentheses — Wikipedia links
      // routinely do — and an optional quoted title follows it. `[^)]+` used
      // to stop at the first `)`, truncating such URLs, and swallowed the
      // title into the path so images with one never loaded.
      // The destination may be wrapped in angle brackets, which is how a path
      // containing a space is written — `[doc](<my file.md>)` — and the title
      // may be quoted with either kind of quote. Neither was accepted, and
      // both fell apart into literal text.
      r'!\[([^\]]*)\]\(\s*(?:<([^>]*)>|((?:[^()\s"]|\([^()]*\))+))'
      r'''(?:\s+(?:"([^"]*)"|'([^']*)'))?\s*\)'''  // 1 alt, 2/3 src, 4/5 title
      r'''|\[([^\]]*)\]\(\s*(?:<([^>]*)>|((?:[^()\s"]|\([^()]*\))+))'''
      r'''(?:\s+(?:"([^"]*)"|'([^']*)'))?\s*\)'''  // 6 text, 7/8 href, 9/10 title
      r'|\[\^([^\]]+)\]'           // footnote ref
      // A code span is delimited by a run of backticks and closed by a run of
      // the same length, which is how a document writes code that itself
      // contains a backtick. Matching a single pair mangled ``a`` into three
      // spans and truncated `` `x` `` at the first inner tick.
      // The backreference is by absolute group number, so it moves whenever a
      // group is added ahead of it — as the angle-bracket destinations did.
      r'|(`+)([^`]|[^`].*?[^`]|`+?)\12(?!`)'  // inline code
      // Requires non-space at both ends, so `$5 and $10` is money, not maths.
      r'|\$(?!\s)([^$\n]+?)(?<!\s)\$'  // inline math
      r'|==(.+?)=='                // highlight
      r'|\+\+(.+?)\+\+'            // underline
      // Must precede the ** branch: alternation prefers the first that
      // matches at the same position, and `***x***` read as bold left a
      // stray asterisk behind.
      r'|\*\*\*(.+?)\*\*\*'          // bold italic ***
      r'|\*\*(.+?)\*\*'            // bold **
      // `_` must not sit inside a word, or snake_case_names read as emphasis.
      // The boundary excludes `_` itself as well: in `read__me__now` the
      // second underscore of the pair is not alphanumeric, so without it the
      // inner `_me_` still matched.
      r'|(?<![a-zA-Z0-9_])___(.+?)___(?![a-zA-Z0-9_])'  // bold italic ___
      r'|(?<![a-zA-Z0-9_])__(.+?)__(?![a-zA-Z0-9_])'  // bold __
      r'|~~(.+?)~~'                // strikethrough
      // No spaces inside, or `x^2 and y^3` becomes one long superscript.
      r'|\^([^\s^]+)\^'            // superscript
      r'|(?<!~)~([^\s~]+?)~(?!~)'  // subscript (single ~, not ~~)
      // CommonMark: a delimiter with whitespace just inside it does not open
      // or close emphasis. Without this, "2 * 3 * 4" italicised the 3 and
      // ordinary prose with a stray asterisk came out slanted.
      r'|\*([^\s].*?[^\s]|[^\s])\*'  // italic *
      r'|(?<![a-zA-Z0-9_])_([^\s].*?[^\s]|[^\s])_(?![a-zA-Z0-9_])'  // italic _
      // Appended rather than inserted: these add groups 19..21, leaving every
      // existing branch's numbering alone.
      r'|<((?:https?|ftp|mailto):[^>\s]+)>'         // 19 autolink
      r'|\[([^\]]+)\]\[([^\]]*)\]'                // 20 text, 21 label
      // A bare address, which GitHub Flavored Markdown links automatically.
      // Last of all, so an address already inside [](…) or <…> is claimed by
      // those branches first.
      r'|((?:https?://|www\.)[^\s<>\[\]()]+)'      // 22 bare url
    );

    var lastEnd = 0;
    for (final match in re.allMatches(text)) {
      // Add preceding plain text
      if (match.start > lastEnd) {
        spans.add(InlineSpan(
          type: InlineType.text,
          text: text.substring(lastEnd, match.start),
        ));
      }

      // Groups: 1 alt, 2/3 src, 4/5 title | 6 text, 7/8 href, 9/10 title |
      // 11 footnote... Destination and title each have two forms, so each
      // contributes two groups of which one is null.
      final imageSrc = match.group(2) ?? match.group(3);
      final linkHref = match.group(7) ?? match.group(8);

      if (imageSrc != null) {
        // Image: ![alt](src "title")
        spans.add(InlineSpan(
          type: InlineType.image,
          text: match.group(1) ?? '',
          href: imageSrc,
          title: match.group(4) ?? match.group(5),
        ));
      } else if (linkHref != null) {
        // Link: [text](href "title")
        spans.add(InlineSpan(
          type: InlineType.link,
          text: match.group(6) ?? '',
          href: linkHref,
          title: match.group(9) ?? match.group(10),
        ));
      } else if (match.group(11) != null) {
        // Footnote ref
        spans.add(InlineSpan(
          type: InlineType.footnoteRef,
          text: match.group(11)!,
        ));
      } else if (match.group(12) != null) {
        // Inline code. CommonMark drops one leading and one trailing space
        // when both are present, so `` ` `` is a single backtick rather than
        // a padded one.
        var code = match.group(13)!;
        if (code.length >= 2 &&
            code.startsWith(' ') &&
            code.endsWith(' ') &&
            code.trim().isNotEmpty) {
          code = code.substring(1, code.length - 1);
        }
        spans.add(InlineSpan(type: InlineType.code, text: code));
      } else if (match.group(14) != null) {
        // Inline math
        spans.add(InlineSpan(type: InlineType.mathInline, text: match.group(14)!));
      } else if (match.group(15) != null) {
        // Highlight
        spans.add(InlineSpan(type: InlineType.highlight, text: match.group(15)!));
      } else if (match.group(16) != null) {
        // Underline
        spans.add(InlineSpan(type: InlineType.underline, text: match.group(16)!));
      } else if (match.group(17) != null) {
        // Bold italic ***
        spans.add(
            InlineSpan(type: InlineType.boldItalic, text: match.group(17)!));
      } else if (match.group(18) != null) {
        // Bold **
        spans.add(InlineSpan(type: InlineType.bold, text: match.group(18)!));
      } else if (match.group(19) != null) {
        // Bold italic ___
        spans.add(
            InlineSpan(type: InlineType.boldItalic, text: match.group(19)!));
      } else if (match.group(20) != null) {
        // Bold __
        spans.add(InlineSpan(type: InlineType.bold, text: match.group(20)!));
      } else if (match.group(21) != null) {
        // Strikethrough
        spans.add(InlineSpan(
          type: InlineType.strikethrough,
          text: match.group(21)!,
        ));
      } else if (match.group(22) != null) {
        // Superscript
        spans.add(InlineSpan(type: InlineType.superscript, text: match.group(22)!));
      } else if (match.group(23) != null) {
        // Subscript
        spans.add(InlineSpan(type: InlineType.subscript, text: match.group(23)!));
      } else if (match.group(24) != null) {
        // Italic *
        spans.add(InlineSpan(type: InlineType.italic, text: match.group(24)!));
      } else if (match.group(25) != null) {
        // Italic _
        spans.add(InlineSpan(type: InlineType.italic, text: match.group(25)!));
      } else if (match.group(26) != null) {
        // Autolink: <https://example.com>
        final url = match.group(26)!;
        spans.add(InlineSpan(type: InlineType.link, text: url, href: url));
      } else if (match.group(29) != null) {
        // Trailing punctuation ends the sentence, not the address: in
        // "see https://example.com." the full stop is not part of the link.
        final raw = match.group(29)!;
        final url = raw.replaceFirst(RegExp(r'[.,;:!?]+$'), '');
        spans.add(InlineSpan(type: InlineType.link, text: url, href: url));
        if (url.length < raw.length) {
          spans.add(InlineSpan(
            type: InlineType.text,
            text: raw.substring(url.length),
          ));
        }
      } else if (match.group(27) != null) {
        // Reference link: [text][label], or [text][] where the text is the
        // label. Unresolved references stay as written rather than becoming a
        // link to nowhere.
        final label = match.group(28)!.isEmpty
            ? match.group(27)!
            : match.group(28)!;
        final definition = _linkDefinitions[label.toLowerCase()];
        if (definition == null) {
          spans.add(InlineSpan(type: InlineType.text, text: match.group(0)!));
        } else {
          spans.add(InlineSpan(
            type: InlineType.link,
            text: match.group(27)!,
            href: definition.url,
            title: definition.title,
          ));
        }
      }

      lastEnd = match.end;
    }

    // Trailing plain text
    if (lastEnd < text.length) {
      spans.add(InlineSpan(
        type: InlineType.text,
        text: text.substring(lastEnd),
      ));
    }

    // If no inline markup found, return the whole text as a single span
    if (spans.isEmpty) {
      spans.add(InlineSpan(type: InlineType.text, text: text));
    }

    return spans.map((span) {
      final restored =
          escapes.isEmpty ? span : _restoreEscapes(span, escapes);
      // Entities inside inline code are literal, per CommonMark.
      if (restored.type == InlineType.code) return restored;
      return InlineSpan(
        type: restored.type,
        text: _decodeEntities(restored.text),
        href: restored.href,
        title: restored.title,
      );
    }).toList();
  }

  /// Character entities markdown documents commonly carry over from HTML.
  static const _namedEntities = <String, String>{
    'amp': '&',
    'lt': '<',
    'gt': '>',
    'quot': '"',
    'apos': "'",
    'nbsp': '\u00A0',
    'copy': '©',
    'reg': '®',
    'trade': '™',
    'hellip': '…',
    'mdash': '—',
    'ndash': '–',
    'laquo': '«',
    'raquo': '»',
    'deg': '°',
    'plusmn': '±',
    'times': '×',
    'divide': '÷',
  };

  static final _entityRe =
      RegExp(r'&(#[0-9]+|#[xX][0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);');

  /// Resolves character entities to the characters they name.
  ///
  /// Without this `&amp;` showed as `&amp;` in the preview, and export escaped
  /// the ampersand again into `&amp;amp;`. Decoding here means the span holds
  /// a real `&`, which each output then escapes once, as it should.
  static String _decodeEntities(String text) {
    if (!text.contains('&')) return text;

    return text.replaceAllMapped(_entityRe, (match) {
      final body = match.group(1)!;

      if (body.startsWith('#')) {
        final isHex = body.length > 1 && (body[1] == 'x' || body[1] == 'X');
        final digits = body.substring(isHex ? 2 : 1);
        final code = int.tryParse(digits, radix: isHex ? 16 : 10);
        // Anything outside Unicode, or a surrogate, is left as written rather
        // than producing an invalid string.
        if (code == null ||
            code < 0 ||
            code > 0x10FFFF ||
            (code >= 0xD800 && code <= 0xDFFF)) {
          return match.group(0)!;
        }
        return String.fromCharCode(code);
      }

      return _namedEntities[body] ?? match.group(0)!;
    });
  }

  /// Puts escaped characters back, minus their backslashes.
  InlineSpan _restoreEscapes(InlineSpan span, List<String> escapes) {
    String restore(String text) {
      return text.replaceAllMapped(RegExp(r'[\uE000-\uF8FF]'), (match) {
        final index = match.group(0)!.codeUnitAt(0) - _escapeSentinelBase;
        return index >= 0 && index < escapes.length
            ? escapes[index]
            : match.group(0)!;
      });
    }

    return InlineSpan(
      type: span.type,
      text: restore(span.text),
      href: span.href == null ? null : restore(span.href!),
      title: span.title == null ? null : restore(span.title!),
    );
  }

  // -- Helpers --

  /// Splits a table row into cells.
  ///
  /// A pipe may be escaped with a backslash, which is the only way to put one
  /// in a cell. Splitting on every pipe broke the cell in two and left the
  /// backslash behind.
  List<String> _parseCells(String line) {
    var text = line.trim();
    if (text.startsWith('|')) text = text.substring(1);
    if (text.endsWith('|') && !text.endsWith(r'\|')) {
      text = text.substring(0, text.length - 1);
    }

    final cells = <String>[];
    final cell = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == r'\' && i + 1 < text.length && text[i + 1] == '|') {
        cell.write('|');
        i++;
        continue;
      }
      if (char == '|') {
        cells.add(cell.toString().trim());
        cell.clear();
        continue;
      }
      cell.write(char);
    }
    cells.add(cell.toString().trim());
    return cells;
  }

  List<String> _parseAlignments(String line) {
    return _parseCells(line).map((cell) {
      final c = cell.trim();
      if (c.startsWith(':') && c.endsWith(':')) return 'center';
      if (c.endsWith(':')) return 'right';
      if (c.startsWith(':')) return 'left';
      return 'default';
    }).toList();
  }
}
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

  ListItem({
    required this.content,
    required this.inlineSpans,
    this.isTask = false,
    this.isChecked = false,
    this.depth = 0,
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
  final String content;
  final List<InlineSpan> inlineSpans;

  BlockquoteNode({required this.content, required this.inlineSpans});

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
  static final _headingRe = RegExp(r'^(#{1,6})\s+(.+)$');
  static final _hrRe = RegExp(r'^(\*{3,}|-{3,}|_{3,})\s*$');
  static final _codeFenceRe = RegExp(r'^\s*```(\w*)');
  static final _codeFenceEndRe = RegExp(r'^\s*```\s*$');
  static final _mathBlockRe = RegExp(r'^\$\$\s*$');
  static final _taskRe = RegExp(r'^\[( |x)\]\s+(.+)$');
  static final _blockquoteRe = RegExp(r'^>\s?(.*)$');
  static final _ulRe = RegExp(r'^[\s]*[-*+]\s+(.+)$');
  static final _olRe = RegExp(r'^[\s]*\d+\.\s+(.+)$');
  static final _tableRowRe = RegExp(r'^\|(.+)\|$');
  static final _tableSepRe = RegExp(r'^\|[\s:|-]+\|$');
  static final _frontMatterRe = RegExp(r'^---\s*$');
  static final _footnoteDefRe = RegExp(r'^\[\^([^\]]+)\]:\s*(.+)$');
  static final _htmlBlockStartRe = RegExp(r'^<(\w+)');

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
  List<ListItem> _buildListItems(List<List<String>> itemBlocks, RegExp itemRe) {
    final widths =
        itemBlocks.map((block) => _indentColumns(block.first)).toSet().toList()
          ..sort();

    return itemBlocks.map((block) {
      final first = itemRe.firstMatch(block.first)!.group(1)!;
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
          isChecked: taskMatch.group(1) == 'x',
          depth: depth,
        );
      }

      return ListItem(
        content: content,
        inlineSpans: parseInline(content),
        depth: depth,
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
  (List<List<String>>, int) _collectListItems(
    List<String> lines,
    int start,
    RegExp itemRe,
  ) {
    final blocks = <List<String>>[];
    var i = start;

    while (i < lines.length) {
      if (itemRe.hasMatch(lines[i])) {
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
        if (next < lines.length && itemRe.hasMatch(lines[next])) {
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

  /// Parse markdown text into a list of block-level nodes.
  List<MarkdownNode> parse(String markdown) {
    // Strip UTF-8 BOM if present (otherwise heading regex on the first line fails)
    final source = markdown.isNotEmpty && markdown.codeUnitAt(0) == 0xFEFF
        ? markdown.substring(1)
        : markdown;
    // LineSplitter handles \n, \r\n, and \r in a single pass without
    // creating intermediate string copies (faster than replaceAll for large files)
    final lines = const LineSplitter().convert(source);
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
        final lang = codeFenceMatch.group(1) ?? '';
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !_codeFenceEndRe.hasMatch(lines[i])) {
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
        final bqLines = <String>[];
        while (i < lines.length) {
          final m = _blockquoteRe.firstMatch(lines[i]);
          if (m != null) {
            bqLines.add(m.group(1) ?? '');
            i++;
          } else {
            break;
          }
        }
        final content = bqLines.join('\n').trim();
        nodes.add(_withSpan(
          BlockquoteNode(
            content: content,
            inlineSpans: parseInline(content),
          ),
          blockStart,
          i,
        ));
        continue;
      }

      // Table (GFM)
      if (_tableRowRe.hasMatch(line) &&
          i + 1 < lines.length &&
          _tableSepRe.hasMatch(lines[i + 1])) {
        final headers = _parseCells(line);
        final sepLine = lines[i + 1];
        final alignments = _parseAlignments(sepLine);
        final rows = <List<String>>[];
        i += 2;
        while (i < lines.length && _tableRowRe.hasMatch(lines[i])) {
          rows.add(_parseCells(lines[i]));
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
        final (itemBlocks, next) = _collectListItems(lines, i, _ulRe);
        i = next;
        nodes.add(_withSpan(
          ListNode(ordered: false, items: _buildListItems(itemBlocks, _ulRe)),
          blockStart,
          i,
        ));
        continue;
      }

      // Ordered list
      if (_olRe.hasMatch(line)) {
        final (itemBlocks, next) = _collectListItems(lines, i, _olRe);
        i = next;
        nodes.add(_withSpan(
          ListNode(ordered: true, items: _buildListItems(itemBlocks, _olRe)),
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
        final content = paraLines.join('\n');
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
      r'!\[([^\]]*)\]\(([^)]+)\)'  // image
      r'|\[([^\]]*)\]\(([^)]+)\)'  // link
      r'|\[\^([^\]]+)\]'           // footnote ref
      r'|`([^`]+)`'                // inline code
      // Requires non-space at both ends, so `$5 and $10` is money, not maths.
      r'|\$(?!\s)([^$\n]+?)(?<!\s)\$'  // inline math
      r'|==(.+?)=='                // highlight
      r'|\+\+(.+?)\+\+'            // underline
      r'|\*\*(.+?)\*\*'            // bold **
      // `_` must not sit inside a word, or snake_case_names read as emphasis.
      // The boundary excludes `_` itself as well: in `read__me__now` the
      // second underscore of the pair is not alphanumeric, so without it the
      // inner `_me_` still matched.
      r'|(?<![a-zA-Z0-9_])__(.+?)__(?![a-zA-Z0-9_])'  // bold __
      r'|~~(.+?)~~'                // strikethrough
      // No spaces inside, or `x^2 and y^3` becomes one long superscript.
      r'|\^([^\s^]+)\^'            // superscript
      r'|(?<!~)~([^\s~]+?)~(?!~)'  // subscript (single ~, not ~~)
      r'|\*(.+?)\*'                // italic *
      r'|(?<![a-zA-Z0-9_])_(.+?)_(?![a-zA-Z0-9_])'  // italic _
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

      if (match.group(1) != null || match.group(2) != null) {
        // Image: ![alt](url)
        if (match.group(0)!.startsWith('!')) {
          spans.add(InlineSpan(
            type: InlineType.image,
            text: match.group(1) ?? '',
            href: match.group(2),
          ));
        } else {
          // Link: [text](url)
          spans.add(InlineSpan(
            type: InlineType.link,
            text: match.group(1) ?? '',
            href: match.group(2),
          ));
        }
      } else if (match.group(3) != null) {
        // Link
        spans.add(InlineSpan(
          type: InlineType.link,
          text: match.group(3)!,
          href: match.group(4),
        ));
      } else if (match.group(5) != null) {
        // Footnote ref
        spans.add(InlineSpan(
          type: InlineType.footnoteRef,
          text: match.group(5)!,
        ));
      } else if (match.group(6) != null) {
        // Inline code
        spans.add(InlineSpan(type: InlineType.code, text: match.group(6)!));
      } else if (match.group(7) != null) {
        // Inline math
        spans.add(InlineSpan(type: InlineType.mathInline, text: match.group(7)!));
      } else if (match.group(8) != null) {
        // Highlight
        spans.add(InlineSpan(type: InlineType.highlight, text: match.group(8)!));
      } else if (match.group(9) != null) {
        // Underline
        spans.add(InlineSpan(type: InlineType.underline, text: match.group(9)!));
      } else if (match.group(10) != null) {
        // Bold **
        spans.add(InlineSpan(type: InlineType.bold, text: match.group(10)!));
      } else if (match.group(11) != null) {
        // Bold __
        spans.add(InlineSpan(type: InlineType.bold, text: match.group(11)!));
      } else if (match.group(12) != null) {
        // Strikethrough
        spans.add(InlineSpan(
          type: InlineType.strikethrough,
          text: match.group(12)!,
        ));
      } else if (match.group(13) != null) {
        // Superscript
        spans.add(InlineSpan(type: InlineType.superscript, text: match.group(13)!));
      } else if (match.group(14) != null) {
        // Subscript
        spans.add(InlineSpan(type: InlineType.subscript, text: match.group(14)!));
      } else if (match.group(15) != null) {
        // Italic *
        spans.add(InlineSpan(type: InlineType.italic, text: match.group(15)!));
      } else if (match.group(16) != null) {
        // Italic _
        spans.add(InlineSpan(type: InlineType.italic, text: match.group(16)!));
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

    if (escapes.isEmpty) return spans;
    return spans.map((span) => _restoreEscapes(span, escapes)).toList();
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

  List<String> _parseCells(String line) {
    return line
        .replaceAll(RegExp(r'^\||\|$'), '')
        .split('|')
        .map((c) => c.trim())
        .toList();
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
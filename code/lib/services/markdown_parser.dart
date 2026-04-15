// Lightweight self-built Markdown parser supporting CommonMark + GFM subset.
// Uses regex-based line scanning for block-level and inline parsing.

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

  ListItem({
    required this.content,
    required this.inlineSpans,
    this.isTask = false,
    this.isChecked = false,
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
  static final _codeFenceRe = RegExp(r'^```(\w*)');
  static final _codeFenceEndRe = RegExp(r'^```\s*$');
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

  /// Parse markdown text into a list of block-level nodes.
  List<MarkdownNode> parse(String markdown) {
    final lines = markdown.split('\n');
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
        nodes.add(FrontMatterNode(content: fmLines.join('\n')));
      }
      // else: no closing --- found, fall through to normal parsing
    }

    while (i < lines.length) {
      final line = lines[i];

      // Blank line — skip
      if (line.trim().isEmpty) {
        i++;
        continue;
      }

      // Footnote definition
      final footnoteMatch = _footnoteDefRe.firstMatch(line);
      if (footnoteMatch != null) {
        nodes.add(FootnoteDefinitionNode(
          id: footnoteMatch.group(1)!,
          content: footnoteMatch.group(2)!,
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
        while (i < lines.length && !lines[i].contains(closeTag)) {
          htmlLines.add(lines[i]);
          i++;
        }
        if (i < lines.length) {
          htmlLines.add(lines[i]);
          i++;
        }
        nodes.add(HtmlBlockNode(html: htmlLines.join('\n')));
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
        nodes.add(MathBlockNode(expression: mathLines.join('\n')));
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
        nodes.add(CodeBlockNode(language: lang, code: codeLines.join('\n')));
        continue;
      }

      // Horizontal rule
      if (_hrRe.hasMatch(line)) {
        nodes.add(HorizontalRuleNode());
        i++;
        continue;
      }
      // Heading
      final headingMatch = _headingRe.firstMatch(line);
      if (headingMatch != null) {
        final level = headingMatch.group(1)!.length;
        final content = headingMatch.group(2)!.trim();
        nodes.add(HeadingNode(
          level: level,
          content: content,
          inlineSpans: parseInline(content),
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
        nodes.add(BlockquoteNode(
          content: content,
          inlineSpans: parseInline(content),
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
        nodes.add(TableNode(
          headers: headers,
          rows: rows,
          alignments: alignments,
        ));
        continue;
      }
      // Unordered list
      if (_ulRe.hasMatch(line)) {
        final items = <ListItem>[];
        while (i < lines.length && _ulRe.hasMatch(lines[i])) {
          final m = _ulRe.firstMatch(lines[i])!;
          final content = m.group(1)!;

          // Check for task list syntax: [ ] or [x]
          final taskMatch = _taskRe.firstMatch(content);
          if (taskMatch != null) {
            final isChecked = taskMatch.group(1) == 'x';
            final taskContent = taskMatch.group(2)!;
            items.add(ListItem(
              content: taskContent,
              inlineSpans: parseInline(taskContent),
              isTask: true,
              isChecked: isChecked,
            ));
          } else {
            items.add(ListItem(
              content: content,
              inlineSpans: parseInline(content),
            ));
          }
          i++;
        }
        nodes.add(ListNode(ordered: false, items: items));
        continue;
      }

      // Ordered list
      if (_olRe.hasMatch(line)) {
        final items = <ListItem>[];
        while (i < lines.length && _olRe.hasMatch(lines[i])) {
          final m = _olRe.firstMatch(lines[i])!;
          final content = m.group(1)!;
          items.add(ListItem(
            content: content,
            inlineSpans: parseInline(content),
          ));
          i++;
        }
        nodes.add(ListNode(ordered: true, items: items));
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
        nodes.add(ParagraphNode(
          content: content,
          inlineSpans: parseInline(content),
        ));
      }
    }

    return nodes;
  }
  /// Parse inline markdown text into a list of InlineSpan.
  List<InlineSpan> parseInline(String text) {
    final spans = <InlineSpan>[];
    // Combined pattern for inline elements, ordered by priority
    final re = RegExp(
      r'!\[([^\]]*)\]\(([^)]+)\)'  // image
      r'|\[([^\]]*)\]\(([^)]+)\)'  // link
      r'|\[\^([^\]]+)\]'           // footnote ref
      r'|`([^`]+)`'                // inline code
      r'|\$([^$]+)\$'              // inline math
      r'|==(.+?)=='                // highlight
      r'|\+\+(.+?)\+\+'            // underline
      r'|\*\*(.+?)\*\*'            // bold **
      r'|__(.+?)__'                // bold __
      r'|~~(.+?)~~'                // strikethrough
      r'|\^(.+?)\^'                // superscript
      r'|(?<!~)~([^~]+?)~(?!~)'    // subscript (single ~, not ~~)
      r'|\*(.+?)\*'                // italic *
      r'|_(.+?)_'                  // italic _
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

    return spans;
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
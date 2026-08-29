// Lightweight self-built Markdown parser supporting CommonMark + GFM subset.
// Uses regex-based line scanning for block-level and inline parsing.

import 'dart:convert' show LineSplitter;
import 'dart:math' as math;

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

  /// Where an image links to, when it is wrapped in a link.
  ///
  /// The shape of a README badge. Kept alongside the image rather than as a
  /// separate span because the model is flat: a link span cannot contain an
  /// image span.
  final String? linkHref;

  const InlineSpan({
    required this.type,
    required this.text,
    this.href,
    this.title,
    this.linkHref,
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

/// Moves a nested parse's line numbers back into the document's own.
///
/// The blocks inside a quote or under a list item are parsed from text that
/// has been lifted out of the document — the `>` markers stripped, the indent
/// removed — so they come back numbered from zero. Left that way, a diagram
/// inside a quote reported the document's *first* lines as its source: its
/// "copy source" button copied the wrong text, and editing it in the preview
/// wrote the edit over the top of the document.
void _shiftSpans(List<MarkdownNode> nodes, int offset) {
  if (offset == 0) return;
  for (final node in MarkdownParser.walk(nodes)) {
    node.sourceStart += offset;
    node.sourceEnd += offset;
  }
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

  /// The number this item was written with, for an ordered item.
  ///
  /// A list that starts at 3 is numbered from 3, which is what CommonMark
  /// says and what a document continuing a numbered sequence across a figure
  /// or a note relies on. Only the *first* item's number is honoured; the
  /// rest run on from it however they are written.
  final int? number;

  /// Blocks written under this item — a code fence beneath a numbered step, a
  /// second paragraph, a quote.
  ///
  /// Empty for the ordinary one-line item. Rendering only [inlineSpans] left
  /// these at the document's left margin, outside the step they belong to,
  /// and split one list into two around them.
  final List<MarkdownNode> children;

  ListItem({
    required this.content,
    required this.inlineSpans,
    this.isTask = false,
    this.isChecked = false,
    this.depth = 0,
    this.number,
    this.ordered = false,
    this.children = const [],
  });
}

class ListNode extends MarkdownNode {
  final bool ordered;
  final List<ListItem> items;

  /// Whether any two items were separated by a blank line.
  ///
  /// CommonMark calls such a list loose and renders each item as a paragraph,
  /// which is what puts space between them. A list written with gaps was
  /// coming out as tight as one written without, so the spacing the author
  /// asked for was silently dropped.
  final bool isLoose;

  ListNode({
    required this.ordered,
    required this.items,
    this.isLoose = false,
  });

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

  /// `yaml`, `toml` or `json`, from which delimiter opened the block.
  ///
  /// Upstream accepts four spellings and remembers which one a document used;
  /// a Hugo file with `+++` metadata used to render as a paragraph of literal
  /// plus signs here.
  final String lang;

  FrontMatterNode({required this.content, this.lang = 'yaml'});

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
  /// Creates a parser.
  ///
  /// [enableHtml] turns on the inline HTML the settings switch offers. It is
  /// off by default, which is what every existing caller wants and what keeps
  /// a document with a stray `<` in it reading the same as before.
  MarkdownParser({this.enableHtml = false});

  /// Whether a handful of inline HTML tags are rendered rather than shown.
  ///
  /// Deliberately a small, closed set — `<b>`, `<kbd>`, `<br>` and their
  /// like, with no attributes and no markup inside. Block-level HTML is not
  /// touched. That covers what markdown documents actually contain without
  /// pulling in an HTML engine.
  final bool enableHtml;

  /// One heading, as the outline sees it.
  ///
  /// [line] is 1-based, matching what the editor and the scroll targets use.

  /// One ATX heading.
  ///
  /// The optional run of #s at the end is a closing sequence, not content:
  /// CommonMark drops it, and `## Section ##` was showing the trailing hashes
  /// in the outline and in the rendered heading alike. Whitespace has to
  /// precede it, so `# C#` keeps its hash.
  static final _headingRe = RegExp(r'^(#{1,6})\s+(.+?)(?:\s+#+)?\s*$');
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

    // The outline has to see the document the way parse() does, because the
    // preview maps its Nth heading widget to the Nth entry here. Two of them
    // disagreed: a `# comment` inside front matter was listed although no
    // heading is drawn for it, and a setext heading was drawn although
    // nothing was listed — so from the first disagreement on, every entry
    // scrolled to the wrong heading.
    var i = 0;
    if (lines.isNotEmpty && isFrontMatterOpener(lines.first.trim())) {
      final closer = lines.first.trim() == '{' ? '}' : lines.first.trim();
      for (var j = 1; j < lines.length; j++) {
        if (lines[j].trim() == closer) {
          i = j + 1;
          break;
        }
      }
    }

    for (; i < lines.length; i++) {
      if (_codeFenceRe.hasMatch(lines[i])) {
        inFence = !inFence;
        continue;
      }
      if (inFence) continue;

      final match = _headingRe.firstMatch(lines[i]);
      if (match != null) {
        headings.add((
          line: i + 1,
          level: match.group(1)!.length,
          text: match.group(2)!.trim(),
        ));
        continue;
      }

      // Text underlined with `===` or `---`, which parse() reads as a heading
      // for the same reason: real text precedes the rule.
      // Unindented, as the ATX pattern above also insists: what the preview
      // counts is a heading at the top level of the document, and an indented
      // one belongs to the list item or quote that carries it. Listing those
      // put an entry in the outline that the preview had no heading for, and
      // every entry after it then scrolled to the wrong place.
      if (lines[i].trim().isNotEmpty &&
          !lines[i].startsWith(RegExp(r'\s')) &&
          !_hrRe.hasMatch(lines[i]) &&
          i + 1 < lines.length &&
          _setextRe.hasMatch(lines[i + 1])) {
        headings.add((
          line: i + 1,
          level: lines[i + 1].trim().startsWith('=') ? 1 : 2,
          text: lines[i].trim(),
        ));
        i++;
      }
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
  // CommonMark writes a nested quote as `> > inner`, with a space between the
  // markers; `>>inner` is the same thing. Matching only adjacent `>` read the
  // spaced form as one level deep and left the inner marker as literal text.
  // Up to three leading spaces are allowed before a marker; four make it code.
  static final _blockquoteRe = RegExp(r'^((?:[ \t]{0,3}>)+)[ \t]?(.*)$');

  /// Removes exactly one `>` marker, so a deeper line keeps the rest of its
  /// markers and becomes a quote again when the content is parsed.
  static final _blockquoteStripRe = RegExp(r'^[ \t]{0,3}>[ \t]?');
  static final _ulRe = RegExp(r'^[\s]*[-*+]\s+(.+)$');
  /// An ordered list item. CommonMark allows `)` as well as `.` after the
  /// number, and the editor's own prefix handling already accepted both — only
  /// the parser did not, so `1) one` rendered as an ordinary paragraph.
  static final _olRe = RegExp(r'^[\s]*\d+[.)]\s+(.+)$');

  /// The number an ordered item was written with.
  ///
  /// Separate from [_olRe] rather than a group added to it: that pattern's
  /// group 1 is the item's content and is read in several places.
  static final _olNumberRe = RegExp(r'^\s*(\d+)[.)]\s');
  /// A table row. GFM makes the outer pipes optional, so `a | b` is a row;
  /// requiring them turned such a table into an ordinary paragraph.
  static final _tableRowRe = RegExp(r'^\s*\|?.*\|.*\|?\s*$');

  /// The row of dashes under the header.
  static final _tableSepRe = RegExp(r'^\s*\|?[\s:|-]+\|?\s*$');

  /// Front matter openers, mapped to their closer and the language inside.
  ///
  /// These are the four spellings upstream accepts. `{` closes with `}`, so
  /// opener and closer are kept apart rather than assumed equal.
  static const _frontMatterDelimiters =
      <String, ({String close, String lang})>{
    '---': (close: '---', lang: 'yaml'),
    '+++': (close: '+++', lang: 'toml'),
    ';;;': (close: ';;;', lang: 'json'),
    '{': (close: '}', lang: 'json'),
  };

  /// Whether `line` opens a front matter block, in any of the four spellings.
  ///
  /// The editor's "Front Matter" command asks this before prepending one, so a
  /// document that already opens with `+++` does not gain a second block.
  static bool isFrontMatterOpener(String line) =>
      _frontMatterDelimiters.containsKey(line.trimRight());
  static final _footnoteDefRe = RegExp(r'^\[\^([^\]]+)\]:\s*(.+)$');
  /// An HTML element opening a block.
  ///
  /// The tag name must be followed by something that can start an attribute
  /// list or close the tag, which keeps `<https://example.com>` — an autolink,
  /// not an element — out of this branch.
  static final _htmlBlockStartRe =
      RegExp(r'^<([a-zA-Z][a-zA-Z0-9-]*)(?=[\s/>])');

  /// Tag names that begin an HTML *block*.
  ///
  /// CommonMark's list, and the distinction matters more here than it looks:
  /// an html block is drawn as a grey monospace box, so treating every leading
  /// tag as one turned a line of `<kbd>Ctrl</kbd>+<kbd>C</kbd>` — ordinary
  /// README prose — into a code box. An inline tag leaves the line a
  /// paragraph, which is where its raw text belongs.
  static const _blockHtmlTags = <String>{
    'address', 'article', 'aside', 'base', 'basefont', 'blockquote', 'body',
    'caption', 'center', 'col', 'colgroup', 'dd', 'details', 'dialog', 'dir',
    'div', 'dl', 'dt', 'fieldset', 'figcaption', 'figure', 'footer', 'form',
    'frame', 'frameset', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'head', 'header',
    'hr', 'html', 'iframe', 'legend', 'li', 'link', 'main', 'menu', 'menuitem',
    'nav', 'noframes', 'ol', 'optgroup', 'option', 'p', 'param', 'search',
    'section', 'summary', 'table', 'tbody', 'td', 'tfoot', 'th', 'thead',
    'title', 'tr', 'track', 'ul',
    // Condition 1 of the spec: these hold raw text and end at their own
    // closing tag rather than at a blank line.
    'pre', 'script', 'style', 'textarea',
  };

  /// A single complete tag with nothing else on its line.
  ///
  /// Condition 7 of the spec: a tag of *any* name alone on its line opens a
  /// block too. That is how a README writes `<a href="…">` or `<img src="…">`
  /// on lines of their own, and it is what separates them from a line of
  /// `<kbd>Ctrl</kbd>+<kbd>C</kbd>`, where the tag is followed by content.
  static final _htmlTagAloneRe =
      RegExp(r'^<[a-zA-Z][a-zA-Z0-9-]*(?:\s[^<>]*?)?/?>\s*$');

  /// A link reference definition: `[label]: url "title"`.
  ///
  /// The label may not begin with `^`: `[^1]: note` is a footnote definition,
  /// and this pattern matched it first. Since a link definition is dropped as
  /// metadata rather than rendered, every footnote definition in the document
  /// disappeared without a trace.
  static final _linkDefRe = RegExp(
    r'^\s{0,3}\[([^\^\]][^\]]*)\]:\s*(\S+)(?:\s+"([^"]*)")?\s*$',
  );

  /// Every node in [nodes], and every node they carry, in the order a reader
  /// meets them.
  ///
  /// A list item and a quote hold blocks of their own, so walking only the
  /// top level misses a diagram written under a numbered step — which is how
  /// the export came to render one without its picture while the two places
  /// that count diagrams still agreed with each other, both being wrong.
  static Iterable<MarkdownNode> walk(List<MarkdownNode> nodes) sync* {
    for (final node in nodes) {
      yield node;
      if (node is BlockquoteNode) {
        yield* walk(node.children);
      } else if (node is ListNode) {
        for (final item in node.items) {
          yield* walk(item.children);
        }
      }
    }
  }

  /// A setext underline: `===` for level 1, `---` for level 2.
  static final _setextRe = RegExp(r'^\s{0,3}(=+|-+)\s*$');

  /// HTML elements that never have a closing tag.
  static const _voidHtmlTags = {
    'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input',
    'link', 'meta', 'param', 'source', 'track', 'wbr',
  };

  /// Splits [source] the same way [parse] does, so line indices recorded on a
  /// node line up with the returned list.
  /// How much of [source] can be shown while the rest is still being parsed.
  ///
  /// Parsing costs about 0.02–0.04 ms per block and there is no hot spot to
  /// remove — it is the inline pass and the spans it builds. A five megabyte
  /// document therefore takes about three seconds, and until it finishes there
  /// is nothing on screen. Parsing a prefix first puts the top of the document
  /// up straight away; the full parse then replaces it.
  ///
  /// A *prefix* rather than a chunk on purpose: line numbers in a prefix are
  /// the same numbers as in the whole document, so the blocks it yields carry
  /// the right source ranges with no arithmetic — and those ranges are what
  /// editing a block in the preview depends on.
  ///
  /// The cut is moved forward to a blank line that is not inside a fenced code
  /// block or front matter, so the prefix never ends mid-block and never shows
  /// half a code fence. Returns the whole of [source] when it is short enough
  /// to be worth parsing in one go, or when no safe cut exists.
  static String? safePrefix(String source, {int minimumLines = 1500}) {
    final lines = _sourceLines(source);
    if (lines.length <= minimumLines) return null;

    var inFence = false;
    var fenceMarker = '';
    String? frontMatterCloser;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimRight();

      if (frontMatterCloser != null) {
        if (trimmed == frontMatterCloser) frontMatterCloser = null;
        continue;
      }
      if (i == 0) {
        final opener = _frontMatterDelimiters[trimmed];
        if (opener != null) {
          frontMatterCloser = opener.close;
          continue;
        }
      }

      final fence = RegExp(r'^\s{0,3}(`{3,}|~{3,})').firstMatch(line);
      if (fence != null) {
        final marker = fence.group(1)![0];
        if (!inFence) {
          inFence = true;
          fenceMarker = marker;
        } else if (marker == fenceMarker) {
          inFence = false;
        }
        continue;
      }

      // A blank line outside everything is where one block ends and the next
      // has not started: the only place a prefix can stop without cutting
      // something in half.
      if (!inFence && i >= minimumLines && trimmed.isEmpty) {
        return lines.sublist(0, i).join('\n');
      }
    }
    return null;
  }

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

    // A level that is not already counting starts at whatever the item was
    // written with; after that the numbers run on regardless of the source.
    final running = counters[item.depth];
    final next = running == null ? (item.number ?? 1) : running + 1;
    counters[item.depth] = next;
    return '$next. ';
  }

  List<ListItem> _buildListItems(
    List<List<String>> itemBlocks,
    List<int> itemStarts,
  ) {
    final widths =
        itemBlocks.map((block) => _indentColumns(block.first)).toSet().toList()
          ..sort();

    return itemBlocks.indexed.map((entry) {
      final (index, block) = entry;
      // Each item is read with its own marker, not the list's: a bulleted
      // sub-point under a numbered step is still a bullet.
      final ordered = _olRe.hasMatch(block.first);
      final number = ordered
          ? int.tryParse(_olNumberRe.firstMatch(block.first)?.group(1) ?? '')
          : null;
      final marker = ordered ? _olRe : _ulRe;
      final first = marker.firstMatch(block.first)!.group(1)!;

      // The item's own text runs to the first blank line; anything after it
      // is a block the item carries, parsed on its own terms.
      final blank = block.indexWhere((line) => line.trim().isEmpty);
      final lead = blank < 0 ? block.skip(1) : block.take(blank).skip(1);
      final carried = blank < 0
          ? const <MarkdownNode>[]
          : parse(_dedent(block.skip(blank + 1)));
      // A block's lines are consecutive in the document, so the blocks the
      // item carries start `blank + 1` lines after the item's own first line.
      _shiftSpans(carried, itemStarts[index] + blank + 1);

      final content = lead.isEmpty
          ? first
          : [first, ...lead.map((line) => line.trim())].join(' ');
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
          number: number,
          children: carried,
        );
      }

      return ListItem(
        content: content,
        inlineSpans: parseInline(content),
        depth: depth,
        ordered: ordered,
        number: number,
        children: carried,
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
  /// Removes the common indentation from an item's carried block, so it is
  /// parsed as the code fence or quote it is rather than as indented code.
  static String _dedent(Iterable<String> lines) {
    final kept = lines.toList();
    final indents = kept
        .where((line) => line.trim().isNotEmpty)
        .map(_indentColumns);
    final common = indents.isEmpty ? 0 : indents.reduce(math.min);
    return kept
        .map((line) => line.length <= common ? '' : line.substring(common))
        .join('\n');
  }

  /// The column an item's own text starts at, which is where any block it
  /// carries has to be indented to.
  static int _contentColumn(String line) {
    final match = _olRe.firstMatch(line) ?? _ulRe.firstMatch(line);
    if (match == null) return 0;
    // The indentation plus the marker's own width. Measuring the prefix with
    // _indentColumns alone returned zero for `4. fourth`, which has no leading
    // space at all — and a column of zero let the next line, whatever it was,
    // be swallowed as content belonging to the item.
    final prefix = line.substring(0, line.length - match.group(1)!.length);
    final indent = _indentColumns(prefix);
    return indent + prefix.trimLeft().length;
  }

  /// Whether [line] starts a list item of either kind.
  ///
  /// A numbered step may hold bulleted sub-points and vice versa, so a list
  /// cannot be collected by looking only for its own marker: the sub-points
  /// were swallowed into the parent item's text.
  static bool _startsListItem(String line) =>
      _ulRe.hasMatch(line) || _olRe.hasMatch(line);

  /// A list item line, including one with nothing written in it yet.
  ///
  /// [_ulRe] and [_olRe] both require content, because an empty marker is not
  /// an item of a parsed document. Pressing Enter on one is exactly when that
  /// matters, so continuation needs its own reading of the line.
  static final _continuationRe =
      RegExp(r'^(\s*)([-*+]|\d+[.)])(\s+)(.*)$');

  /// What pressing Enter at the end of [line] should carry to the next line.
  ///
  /// Returns null when the line is not a list item. `marker` is the text to
  /// put in front of the new line — the same bullet, or the next number, with
  /// the indentation and spacing the author used, and an unticked box when
  /// the item had one. `isEmpty` says the item has no text yet, which is how
  /// a writer ends a list: the marker comes off instead of another appearing.
  static ({String marker, bool isEmpty})? listContinuation(String line) {
    // `- - -` and `* * *` are thematic breaks, however much the first
    // characters look like a bullet. This parser reads them as list items —
    // the list branch is tried before the rule — but there is no reason for
    // the editor to put a marker under one.
    if (RegExp(r'^\s*([-*_])(\s*\1){2,}\s*$').hasMatch(line)) return null;

    final match = _continuationRe.firstMatch(line);
    if (match == null) return null;

    final indent = match.group(1)!;
    final bullet = match.group(2)!;
    final gap = match.group(3)!;
    final content = match.group(4)!;

    final task = RegExp(r'^\[([ xX])\]\s*(.*)$').firstMatch(content);
    final body = task == null ? content : task.group(2)!;

    final number = int.tryParse(bullet.substring(0, bullet.length - 1));
    final nextBullet = number == null
        ? bullet
        : '${number + 1}${bullet.substring(bullet.length - 1)}';

    return (
      marker: '$indent$nextBullet$gap${task == null ? '' : '[ ] '}',
      isEmpty: body.trim().isEmpty,
    );
  }

  /// Whether [line] opens a list item, of either kind.
  ///
  /// Public because the preview has to find the line an item was written on:
  /// counting one line per item put the checkbox toggle on a continuation
  /// line, a blank line, or a line inside a carried code block.
  static bool startsListItem(String line) => _startsListItem(line);

  (List<List<String>>, List<int>, int, bool) _collectListItems(
    List<String> lines,
    int start,
  ) {
    final blocks = <List<String>>[];
    // Where each block began in the document. Not derivable by adding block
    // lengths: a blank line between two items belongs to neither block.
    final blockStarts = <int>[];
    var i = start;
    var loose = false;

    // Changing from numbers to bullets — or back — starts a new list, as
    // CommonMark has it. Collecting them into one node put bullets inside an
    // `<ol>` on export, where a browser draws them as numbers.
    //
    // Only at the list's own indentation: a bulleted sub-point under a
    // numbered step is a deeper item of the same list, not a new one.
    final firstIndent = _indentColumns(lines[start]);
    final firstOrdered = _olRe.hasMatch(lines[start]);

    while (i < lines.length) {
      if (_startsListItem(lines[i])) {
        if (_startsAnotherList(lines[i], firstIndent, firstOrdered)) break;
        blocks.add([lines[i]]);
        blockStarts.add(i);
        i++;
        continue;
      }

      if (lines[i].trim().isEmpty) {
        var next = i + 1;
        while (next < lines.length && lines[next].trim().isEmpty) {
          next++;
        }
        // The list continues only if what follows the gap is another item of
        // the same kind. Deciding that here rather than after the jump is what
        // keeps the blank line out of this list's line range: `i` still points
        // at it, so the span ends before it and the block can be edited and
        // put back unchanged.
        if (next < lines.length &&
            _startsListItem(lines[next]) &&
            !_startsAnotherList(lines[next], firstIndent, firstOrdered)) {
          // A gap between two items is what makes the list loose.
          loose = true;
          i = next;
          continue;
        }

        // Or the item carries a block of its own: a code fence under a
        // numbered step, a second paragraph, a quote. CommonMark says content
        // indented to where the item's text begins belongs to that item, and
        // this used to break the list in three — the fence came out at the
        // left margin and the steps became two separate lists.
        if (blocks.isNotEmpty &&
            next < lines.length &&
            _indentColumns(lines[next]) >= _contentColumn(blocks.last.first)) {
          loose = true;
          blocks.last.addAll(lines.getRange(i, next));
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

    return (blocks, blockStarts, i, loose);
  }

  /// Whether [line] begins a list separate from the one being collected.
  ///
  /// Changing from numbers to bullets — or back — starts a new list, as
  /// CommonMark has it. Only at the list's own indentation: a bulleted
  /// sub-point under a numbered step is a deeper item of the same list.
  bool _startsAnotherList(String line, int firstIndent, bool firstOrdered) =>
      _indentColumns(line) <= firstIndent &&
      _olRe.hasMatch(line) != firstOrdered;

  /// Link reference definitions found in the document being parsed.
  ///
  /// Collected up front because a reference may appear before its definition.
  /// Empty when [parseInline] is called on its own, in which case a reference
  /// link stays plain text.
  final Map<String, ({String url, String? title})> _linkDefinitions = {};

  /// Parse markdown text into a list of block-level nodes.
  /// [quoteDepth] is how many blockquotes enclose this text; it is set by
  /// the parser itself when it descends into a quote, not by callers.
  List<MarkdownNode> parse(String markdown, {int quoteDepth = 0}) {
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
    //
    // The line right after the opening delimiter has to carry something: YAML,
    // TOML and JSON all reject a leading blank line, so a `---` followed by one
    // is a thematic break that happens to open the document. Without this, a
    // document starting with a rule was read as front matter reaching all the
    // way to the next `---`, and everything in between vanished from the
    // preview and from all three export paths.
    // `---` immediately followed by `---` is likewise two thematic breaks
    // rather than an empty metadata block, which is what upstream reads it as.
    final opener = i < lines.length
        ? _frontMatterDelimiters[lines[i].trimRight()]
        : null;
    if (opener != null &&
        i + 1 < lines.length &&
        lines[i + 1].trim().isNotEmpty &&
        lines[i + 1].trimRight() != opener.close) {
      // Look ahead for the matching closing delimiter
      var j = i + 1;
      while (j < lines.length && lines[j].trimRight() != opener.close) {
        j++;
      }
      if (j < lines.length) {
        // Found the closer → parse as front matter
        final fmLines = <String>[];
        i++; // skip the opening delimiter
        while (i < j) {
          fmLines.add(lines[i]);
          i++;
        }
        i++; // skip the closing delimiter
        nodes.add(_withSpan(
          FrontMatterNode(content: fmLines.join('\n'), lang: opener.lang),
          0,
          i,
        ));
      }
      // else: no closer found, fall through to normal parsing
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
      if (htmlMatch != null &&
          (_blockHtmlTags.contains(htmlMatch.group(1)!.toLowerCase()) ||
              _htmlTagAloneRe.hasMatch(line))) {
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
          // The block ends at the closing tag or, as CommonMark has it, at the
          // first blank line — whichever comes first. Scanning past a blank
          // line for a closing tag much further down swallowed everything in
          // between, and stopping there is also what lets the markdown inside
          // a `<details>` be read as markdown.
          //
          // Look before consuming anything: a tag with neither a close nor a
          // blank line after it should cost one line, not the document.
          var lastLine = -1;
          for (var j = i; j < lines.length; j++) {
            if (lines[j].trim().isEmpty) {
              lastLine = j - 1;
              break;
            }
            if (lines[j].contains(closeTag)) {
              lastLine = j;
              break;
            }
          }
          while (i <= lastLine) {
            htmlLines.add(lines[i]);
            i++;
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
        // A fence indented under a list item indents its content by the same
        // amount, and that indentation belongs to the list, not to the code.
        // Left in, every line of a snippet inside a numbered step came out
        // shifted right by three spaces. `_stripIndent` takes *up to* that
        // much, so a line indented less keeps what it has.
        final fenceIndent = _indentColumns(line);
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !_closesFence(lines[i], fence)) {
          codeLines.add(_stripIndent(lines[i], fenceIndent));
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
        // One `>` comes off every line of the run, and what is left is parsed
        // again. A deeper line still starts with a marker, so it comes back as
        // a quote inside this one. Splitting the run by marker count instead
        // made `>> inner` a sibling box while `> > inner` — the same thing in
        // CommonMark — nested, so one document rendered two ways.
        final quoteStart = i;
        final bqLines = <String>[];

        while (i < lines.length && _blockquoteRe.hasMatch(lines[i])) {
          bqLines.add(lines[i].replaceFirst(_blockquoteStripRe, ''));
          i++;
        }

        final content = bqLines.join('\n').trim();
        // `trim` drops the blank lines at the top of the quote, so the parse
        // below starts that many lines further down the document.
        var quoteBlank = 0;
        while (quoteBlank < bqLines.length &&
            bqLines[quoteBlank].trim().isEmpty) {
          quoteBlank++;
        }
        final quoted = parse(content, quoteDepth: quoteDepth + 1);
        _shiftSpans(quoted, quoteStart + quoteBlank);
        nodes.add(_withSpan(
          BlockquoteNode(
            content: content,
            inlineSpans: parseInline(content),
            // Parsed again so a list or a heading inside the quote is one.
            // The spans stay for anything still reading them.
            children: quoted,
            // Counting from zero for the outermost quote.
            depth: quoteDepth,
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
        final (itemBlocks, itemStarts, next, loose) =
            _collectListItems(lines, i);
        i = next;
        nodes.add(_withSpan(
          ListNode(
            ordered: false,
            items: _buildListItems(itemBlocks, itemStarts),
            isLoose: loose,
          ),
          blockStart,
          i,
        ));
        continue;
      }

      // Ordered list
      if (_olRe.hasMatch(line)) {
        final (itemBlocks, itemStarts, next, loose) =
            _collectListItems(lines, i);
        i = next;
        nodes.add(_withSpan(
          ListNode(
            ordered: true,
            items: _buildListItems(itemBlocks, itemStarts),
            isLoose: loose,
          ),
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
      // An image used as a link — the shape of a README badge. It has to come
      // before the image branch, which would otherwise claim the inner
      // ![...](...) and leave the rest as literal text.
      //
      // The alt text uses the same balanced shape as the branches below. With
      // `[^\]]*` a line of `![` repeated made the engine hand the run back one
      // character at a time from every starting position: 30,000 of them took
      // twenty-two seconds. Group count is unchanged — the inner groups are
      // non-capturing.
      r'\[!\[((?:[^\[\]]|\[[^\[\]]*\])*)\]\(\s*(?:<([^>]*)>|([^()\s"]+))\s*\)\]'
      r'\(\s*(?:<([^>]*)>|([^()\s"]+))\s*\)'  // 1 alt, 2/3 src, 4/5 href
      // Same balanced-bracket alt text as the link branch below. Without it
      // `![alt [x]](img.png)` fell through to that branch, which matched from
      // the `[` and turned an image into a link with a stray `!` in front.
      r'|!\[((?:[^\[\]]|\[[^\[\]]*\])*)\]\(\s*(?:<([^>]*)>|((?:[^()\s"]|\([^()]*\))+))'
      r'''(?:\s+(?:"([^"]*)"|'([^']*)'))?\s*\)'''  // 1 alt, 2/3 src, 4/5 title
      // The link text may itself hold a bracketed run — `[see [1] here](x)`
      // is a link, and `[^\]]*` stopped at the inner bracket and left the
      // whole thing as literal text.
      r'''|\[((?:[^\[\]]|\[[^\[\]]*\])*)\]\(\s*(?:<([^>]*)>|((?:[^()\s"]|\([^()]*\))+))'''
      r'''(?:\s+(?:"([^"]*)"|'([^']*)'))?\s*\)'''  // 6 text, 7/8 href, 9/10 title
      r'|\[\^([^\]]+)\]'           // footnote ref
      // A code span is delimited by a run of backticks and closed by a run of
      // the same length, which is how a document writes code that itself
      // contains a backtick. Matching a single pair mangled ``a`` into three
      // spans and truncated `` `x` `` at the first inner tick.
      // The backreference is by absolute group number, so it moves whenever a
      // group is added ahead of it — as the angle-bracket destinations did.
      // `[\s\S]` rather than `.`: this regex is not dotAll, so a code span
      // broken across two lines — which is how a long command gets written —
      // did not match at all and the backticks were left in the text.
      r'|(`+)([^`]|[^`][\s\S]*?[^`]|`+?)\17(?!`)'  // inline code
      // Requires non-space at both ends, so `$5 and $10` is money, not maths.
      r'|\$(?!\s)([^$\n]+?)(?<!\s)\$'  // inline math
      r'|==(.+?)=='                // highlight
      r'|\+\+(.+?)\+\+'            // underline
      // Must precede the ** branch: alternation prefers the first that
      // matches at the same position, and `***x***` read as bold left a
      // stray asterisk behind.
      // The same whitespace rule the single-asterisk branch below carries:
      // a delimiter with a space just inside it neither opens nor closes.
      // Without it `2 ** 3 ** 4` came out with a bold 3, and `** note **`
      // — a line someone typed with spaces for emphasis of their own — was
      // silently turned into bold.
      r'|\*\*\*([^\s].*?[^\s]|[^\s])\*\*\*'  // bold italic ***
      r'|\*\*([^\s].*?[^\s]|[^\s])\*\*'  // bold **
      // `_` must not sit inside a word, or snake_case_names read as emphasis.
      // The boundary excludes `_` itself as well: in `read__me__now` the
      // second underscore of the pair is not alphanumeric, so without it the
      // inner `_me_` still matched.
      //
      // `\p{L}\p{N}` rather than `a-zA-Z0-9`: the rule is about being inside
      // a word, and a word is not only a Latin one. With the ASCII class,
      // `пристаням_стремятся_` and any Chinese text with underscores in it
      // came out emphasised — the boundary saw a non-ASCII letter as "not a
      // word character" and let the delimiter through.
      r'|(?<![\p{L}\p{N}_])___([^\s].*?[^\s]|[^\s])___(?![\p{L}\p{N}_])'
      r'|(?<![\p{L}\p{N}_])__([^\s].*?[^\s]|[^\s])__(?![\p{L}\p{N}_])'
      r'|~~(.+?)~~'                // strikethrough
      // No spaces inside, or `x^2 and y^3` becomes one long superscript.
      r'|\^([^\s^]+)\^'            // superscript
      r'|(?<!~)~([^\s~]+?)~(?!~)'  // subscript (single ~, not ~~)
      // CommonMark: a delimiter with whitespace just inside it does not open
      // or close emphasis. Without this, "2 * 3 * 4" italicised the 3 and
      // ordinary prose with a stray asterisk came out slanted.
      r'|\*([^\s].*?[^\s]|[^\s])\*'  // italic *
      r'|(?<![\p{L}\p{N}_])_([^\s].*?[^\s]|[^\s])_(?![\p{L}\p{N}_])'  // italic _
      // Appended rather than inserted: these add groups 19..21, leaving every
      // existing branch's numbering alone.
      r'|<((?:https?|ftp|mailto):[^>\s]+)>'         // 19 autolink
      // Both brackets use the balanced shape the inline-link branch uses. With
      // `[^\]]+` the engine handed a long run of `[` back one character at a
      // time from every starting position, and a line of 60,000 of them took
      // fifty-one seconds to parse — with the preview frozen throughout.
      // Group count is unchanged: the inner groups are non-capturing.
      r'|\[((?:[^\[\]]|\[[^\[\]]*\])*)\]'
      r'\[((?:[^\[\]]|\[[^\[\]]*\])*)\]'          // 20 text, 21 label
      // A bare address, which GitHub Flavored Markdown links automatically.
      // Last of all, so an address already inside [](…) or <…> is claimed by
      // those branches first.
      r'|((?:https?://|www\.)[^\s<>\[\]()]+)'      // 22 bare url
      // Appended after the bare-url branch so its numbering stays put. An
      // address in angle brackets is CommonMark; a bare one is GitHub's
      // extension, and both are what a reader expects to be able to click.
      r'|<([^\s<>@]+@[^\s<>@]+\.[^\s<>@]+)>'       // 23 email autolink
      // The lookbehind keeps this off the tail of something already matched
      // as an address, and requiring a dot in the domain keeps it off `a@b`.
      r'|(?<![\w.@+-])([\w.+-]+@[\w-]+(?:\.[\w-]+)+)'  // 24 bare email
      // A reference image: `![alt][label]`, or `![label][]`. The inline form
      // `![alt](src)` has had its own branch since a stray `!` in front of a
      // link gave it away; the reference form never did, so `![alt][img]`
      // matched the reference *link* branch from its `[` and came out as a
      // link with the `!` left beside it as text — the same fault, in the
      // sibling nobody looked at.
      //
      // Appended last so no group number ahead of it moves; the leftmost
      // match still wins, and this one starts a character earlier than the
      // reference-link branch it has to beat.
      r'|!\[((?:[^\[\]]|\[[^\[\]]*\])*)\]\[((?:[^\[\]]|\[[^\[\]]*\])*)\]',
      // `unicode: true` so `\p{L}` and `\p{N}` mean what they say: the
      // word-boundary rule around `_` has to hold for Chinese and Cyrillic
      // text as much as for Latin.
      unicode: true,
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
      final badgeSrc = match.group(2) ?? match.group(3);
      final imageSrc = match.group(7) ?? match.group(8);
      final linkHref = match.group(12) ?? match.group(13);

      if (badgeSrc != null) {
        // An image that is itself a link.
        spans.add(InlineSpan(
          type: InlineType.image,
          text: match.group(1) ?? '',
          href: badgeSrc,
          linkHref: match.group(4) ?? match.group(5),
        ));
      } else if (imageSrc != null) {
        // Image: ![alt](src "title")
        spans.add(InlineSpan(
          type: InlineType.image,
          text: match.group(6) ?? '',
          href: imageSrc,
          title: match.group(9) ?? match.group(10),
        ));
      } else if (linkHref != null) {
        // Link: [text](href "title")
        spans.add(InlineSpan(
          type: InlineType.link,
          text: match.group(11) ?? '',
          href: linkHref,
          title: match.group(14) ?? match.group(15),
        ));
      } else if (match.group(16) != null) {
        // Footnote ref
        spans.add(InlineSpan(
          type: InlineType.footnoteRef,
          text: match.group(16)!,
        ));
      } else if (match.group(17) != null) {
        // Inline code. CommonMark drops one leading and one trailing space
        // when both are present, so `` ` `` is a single backtick rather than
        // a padded one.
        // CommonMark folds the line endings inside a code span into spaces:
        // the span is one run of code however it was wrapped in the source.
        var code = match.group(18)!.replaceAll(RegExp(r'\r?\n'), ' ');
        if (code.length >= 2 &&
            code.startsWith(' ') &&
            code.endsWith(' ') &&
            code.trim().isNotEmpty) {
          code = code.substring(1, code.length - 1);
        }
        spans.add(InlineSpan(type: InlineType.code, text: code));
      } else if (match.group(19) != null) {
        // Inline math
        spans.add(InlineSpan(type: InlineType.mathInline, text: match.group(19)!));
      } else if (match.group(20) != null) {
        // Highlight
        spans.add(InlineSpan(type: InlineType.highlight, text: match.group(20)!));
      } else if (match.group(21) != null) {
        // Underline
        spans.add(InlineSpan(type: InlineType.underline, text: match.group(21)!));
      } else if (match.group(22) != null) {
        // Bold italic ***
        spans.add(
            InlineSpan(type: InlineType.boldItalic, text: match.group(22)!));
      } else if (match.group(23) != null) {
        // Bold **
        spans.add(InlineSpan(type: InlineType.bold, text: match.group(23)!));
      } else if (match.group(24) != null) {
        // Bold italic ___
        spans.add(
            InlineSpan(type: InlineType.boldItalic, text: match.group(24)!));
      } else if (match.group(25) != null) {
        // Bold __
        spans.add(InlineSpan(type: InlineType.bold, text: match.group(25)!));
      } else if (match.group(26) != null) {
        // Strikethrough
        spans.add(InlineSpan(
          type: InlineType.strikethrough,
          text: match.group(26)!,
        ));
      } else if (match.group(27) != null) {
        // Superscript
        spans.add(InlineSpan(type: InlineType.superscript, text: match.group(27)!));
      } else if (match.group(28) != null) {
        // Subscript
        spans.add(InlineSpan(type: InlineType.subscript, text: match.group(28)!));
      } else if (match.group(29) != null) {
        // Italic *
        spans.add(InlineSpan(type: InlineType.italic, text: match.group(29)!));
      } else if (match.group(30) != null) {
        // Italic _
        spans.add(InlineSpan(type: InlineType.italic, text: match.group(30)!));
      } else if (match.group(31) != null) {
        // Autolink: <https://example.com>
        final url = match.group(31)!;
        spans.add(InlineSpan(type: InlineType.link, text: url, href: url));
      } else if (match.group(34) != null) {
        // Trailing punctuation ends the sentence, not the address: in
        // "see https://example.com." the full stop is not part of the link.
        final raw = match.group(34)!;
        final url = raw.replaceFirst(RegExp(r'[.,;:!?]+$'), '');
        spans.add(InlineSpan(type: InlineType.link, text: url, href: url));
        if (url.length < raw.length) {
          spans.add(InlineSpan(
            type: InlineType.text,
            text: raw.substring(url.length),
          ));
        }
      } else if (match.group(35) != null) {
        // Autolink: <foo@example.com>
        final address = match.group(35)!;
        spans.add(InlineSpan(
          type: InlineType.link,
          text: address,
          href: 'mailto:$address',
        ));
      } else if (match.group(36) != null) {
        // A bare address. Trailing punctuation ends the sentence, not the
        // address, exactly as for a bare URL.
        final raw = match.group(36)!;
        final address = raw.replaceFirst(RegExp(r'[.,;:!?]+$'), '');
        spans.add(InlineSpan(
          type: InlineType.link,
          text: address,
          href: 'mailto:$address',
        ));
        if (address.length < raw.length) {
          spans.add(InlineSpan(
            type: InlineType.text,
            text: raw.substring(address.length),
          ));
        }
      } else if (match.group(37) != null) {
        // Reference image: ![alt][label], or ![alt][] where the alt text is
        // the label. Same rules as the reference link below — including
        // leaving an unresolved one as written — but it has to be tested
        // first, because when this branch matches the link branch's groups
        // are null anyway and reading them would be meaningless.
        final label =
            match.group(38)!.isEmpty ? match.group(37)! : match.group(38)!;
        final definition = _linkDefinitions[label.toLowerCase()];
        if (definition == null) {
          spans.add(InlineSpan(type: InlineType.text, text: match.group(0)!));
        } else {
          spans.add(InlineSpan(
            type: InlineType.image,
            text: match.group(37)!,
            href: definition.url,
            title: definition.title,
          ));
        }
      } else if (match.group(32) != null) {
        // Reference link: [text][label], or [text][] where the text is the
        // label. Unresolved references stay as written rather than becoming a
        // link to nowhere.
        final label = match.group(33)!.isEmpty
            ? match.group(32)!
            : match.group(33)!;
        final definition = _linkDefinitions[label.toLowerCase()];
        if (definition == null) {
          spans.add(InlineSpan(type: InlineType.text, text: match.group(0)!));
        } else {
          spans.add(InlineSpan(
            type: InlineType.link,
            text: match.group(32)!,
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

    // Before escapes are restored and entities decoded, so `\<b>` and
    // `&lt;b&gt;` both stay literal text — they are how a document writes a
    // tag it does not want interpreted.
    final expanded = enableHtml ? _expandInlineHtml(spans) : spans;

    return expanded.map((span) {
      final restored =
          escapes.isEmpty ? span : _restoreEscapes(span, escapes);
      // Entities inside inline code are literal, per CommonMark.
      if (restored.type == InlineType.code) return restored;
      return InlineSpan(
        type: restored.type,
        text: _decodeEntities(restored.text),
        href: restored.href,
        title: restored.title,
        linkHref: restored.linkHref,
      );
    }).toList();
  }

  /// The inline tags [enableHtml] understands, and what each becomes.
  static const _inlineHtmlTypes = <String, InlineType>{
    'b': InlineType.bold,
    'strong': InlineType.bold,
    'i': InlineType.italic,
    'em': InlineType.italic,
    'u': InlineType.underline,
    'mark': InlineType.highlight,
    'code': InlineType.code,
    'kbd': InlineType.code,
    'del': InlineType.strikethrough,
    's': InlineType.strikethrough,
    'strike': InlineType.strikethrough,
    'sub': InlineType.subscript,
    'sup': InlineType.superscript,
  };

  /// A supported tag pair with plain content, or a line break.
  ///
  /// The content may not itself contain `<` or `>`: a tag wrapping other
  /// markup needs a real HTML parser, and guessing at it would be worse than
  /// leaving it as written.
  static final _inlineHtmlRe = RegExp(
    r'<(b|strong|i|em|u|mark|code|kbd|del|s|strike|sub|sup)>([^<>]*)</\1>'
    r'|<br\s*/?>',
    caseSensitive: false,
  );

  /// Rewrites supported inline tags inside text spans as real formatting.
  static List<InlineSpan> _expandInlineHtml(List<InlineSpan> spans) {
    final result = <InlineSpan>[];

    for (final span in spans) {
      if (span.type != InlineType.text || !span.text.contains('<')) {
        result.add(span);
        continue;
      }

      final text = span.text;
      var last = 0;
      for (final match in _inlineHtmlRe.allMatches(text)) {
        if (match.start > last) {
          result.add(InlineSpan(
            type: InlineType.text,
            text: text.substring(last, match.start),
          ));
        }

        final tag = match.group(1)?.toLowerCase();
        if (tag == null) {
          // `<br>`: a line break inside the paragraph, which is what the
          // renderer already makes of a newline.
          result.add(const InlineSpan(type: InlineType.text, text: '\n'));
        } else {
          result.add(InlineSpan(
            type: _inlineHtmlTypes[tag]!,
            text: match.group(2) ?? '',
          ));
        }
        last = match.end;
      }

      if (last == 0) {
        result.add(span);
      } else if (last < text.length) {
        result.add(InlineSpan(
          type: InlineType.text,
          text: text.substring(last),
        ));
      }
    }

    return result;
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
      // Rebuilding the span here means every field has to be carried across;
      // one left out is silently lost for any text containing an escape.
      linkHref: span.linkHref == null ? null : restore(span.linkHref!),
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
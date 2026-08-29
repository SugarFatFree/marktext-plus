import 'markdown_parser.dart';
import 'export_service.dart';

/// Turns what was selected in the preview into HTML for the clipboard.
///
/// The preview renders markdown, so what a selection yields is the *rendered*
/// text: selecting a heading gives `My Heading`, without the `#`. The first
/// attempt at rich copy fed that text back through the markdown parser, which
/// could only ever produce `<p>My Heading</p>` — the heading, the bold and the
/// links were gone by the time the conversion started, which is exactly what
/// the reader saw when they pasted into Word.
///
/// So the HTML is built from the blocks the document was parsed into. The
/// selected text is located in the document's own rendered text, and the
/// blocks it covers are converted with [ExportService.nodeToHtml], which
/// already knows how to write a heading as a heading and bold as bold.
class RichCopyService {
  const RichCopyService._();

  /// The text [node] shows on screen, which is what a selection returns.
  ///
  /// Deliberately not the source: `# Title` is drawn as `Title`, and matching
  /// a selection against the source would never find it.
  static String plainTextOf(MarkdownNode node) {
    switch (node) {
      case HeadingNode():
        return _spans(node.inlineSpans);
      case ParagraphNode():
        return _spans(node.inlineSpans);
      case CodeBlockNode():
        return node.code;
      case MathBlockNode():
        return node.expression;
      case HtmlBlockNode():
        return node.html;
      case FrontMatterNode():
        return node.content;
      case HorizontalRuleNode():
        return '';
      case BlockquoteNode():
        return node.children.map(plainTextOf).join('\n');
      case FootnoteDefinitionNode():
        return node.content;
      case TableNode():
        return [
          for (final row in [node.headers, ...node.rows]) row.join('\t'),
        ].join('\n');
      case ListNode():
        return node.items
            .map((item) => [
                  _spans(item.inlineSpans),
                  ...item.children.map(plainTextOf),
                ].join('\n'))
            .join('\n');
      default:
        return node.rawContent;
    }
  }

  static String _spans(List<InlineSpan> spans) =>
      spans.map((span) => span.text).join();

  /// HTML for [selection], as it appears inside [ast].
  ///
  /// Returns null when the selection cannot be placed — a caller with nothing
  /// better to offer should fall back to the plain text rather than write
  /// something that does not describe what was copied.
  static String? htmlForSelection(List<MarkdownNode> ast, String selection) {
    final trimmed = selection.trim();
    if (trimmed.isEmpty || ast.isEmpty) return null;

    // The document as the reader sees it, with each block's span recorded.
    final buffer = StringBuffer();
    final ranges = <({int start, int end, MarkdownNode node})>[];
    for (final node in ast) {
      final text = plainTextOf(node);
      final start = buffer.length;
      buffer.write(text);
      ranges.add((start: start, end: buffer.length, node: node));
      buffer.write('\n');
    }

    final rendered = buffer.toString();
    final at = rendered.indexOf(trimmed);
    if (at < 0) return null;
    final to = at + trimmed.length;

    final covered = [
      for (final range in ranges)
        if (range.end > at && range.start < to) range,
    ];
    if (covered.isEmpty) return null;

    final html = StringBuffer();
    for (final range in covered) {
      final whole = at <= range.start && to >= range.end;
      if (whole) {
        // The block in full, inline formatting and all.
        html.writeln(ExportService.nodeToHtml(range.node));
        continue;
      }

      // Part of a block. The inline runs cannot be clipped without rebuilding
      // them, so the covered text goes in as text — but inside the block's own
      // element, because a heading half-selected is still a heading and that
      // is the whole point of copying it.
      final from = at > range.start ? at : range.start;
      final until = to < range.end ? to : range.end;
      final piece = rendered.substring(from, until);
      html.writeln(_wrap(range.node, _escape(piece)));
    }

    final result = html.toString().trim();
    return result.isEmpty ? null : result;
  }

  static String _wrap(MarkdownNode node, String text) => switch (node) {
        HeadingNode() => '<h${node.level}>$text</h${node.level}>',
        CodeBlockNode() => '<pre><code>$text</code></pre>',
        BlockquoteNode() => '<blockquote><p>$text</p></blockquote>',
        _ => '<p>$text</p>',
      };

  static String _escape(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

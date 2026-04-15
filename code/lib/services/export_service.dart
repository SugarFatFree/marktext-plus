import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'markdown_parser.dart';

class ExportService {
  ExportService._();

  /// Export Markdown to HTML with GitHub-style CSS
  static Future<void> exportToHtml(String markdown, String savePath) async {
    final parser = MarkdownParser();
    final ast = parser.parse(markdown);

    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>Exported Markdown</title>');
    buffer.writeln('  <style>');
    buffer.writeln(_getGitHubStyleCss());
    buffer.writeln('  </style>');
    buffer.writeln('  <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>');
    buffer.writeln('  <script>mermaid.initialize({startOnLoad: true, securityLevel: "strict"});</script>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <div class="markdown-body">');

    for (final node in ast) {
      buffer.writeln(_nodeToHtml(node));
    }

    buffer.writeln('  </div>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    await File(savePath).writeAsString(buffer.toString());
  }

  /// Export Markdown to PDF
  static Future<void> exportToPdf(String markdown, String savePath) async {
    final parser = MarkdownParser();
    final ast = parser.parse(markdown);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          final widgets = <pw.Widget>[];
          for (final node in ast) {
            widgets.addAll(_nodeToPdfWidgets(node));
          }
          return widgets;
        },
      ),
    );

    final bytes = await pdf.save();
    await File(savePath).writeAsBytes(bytes);
  }

  static String _nodeToHtml(MarkdownNode node) {
    switch (node.type) {
      case NodeType.heading:
        final heading = node as HeadingNode;
        final content = _inlineSpansToHtml(heading.inlineSpans);
        return '<h${heading.level}>$content</h${heading.level}>';

      case NodeType.paragraph:
        final para = node as ParagraphNode;
        final content = _inlineSpansToHtml(para.inlineSpans);
        return '<p>$content</p>';

      case NodeType.codeBlock:
        final code = node as CodeBlockNode;
        final lang = code.language.toLowerCase();
        // Mermaid diagram languages: use <pre class="mermaid"> for CDN rendering
        const diagramLangs = {'mermaid', 'flowchart', 'sequence', 'gantt', 'classdiagram', 'statediagram', 'erdiagram', 'journey', 'gitgraph', 'pie', 'mindmap'};
        if (diagramLangs.contains(lang)) {
          return '<pre class="mermaid">${_escapeHtml(code.code)}</pre>';
        }
        final langClass = code.language.isNotEmpty ? ' class="language-${code.language}"' : '';
        final escaped = _escapeHtml(code.code);
        return '<pre><code$langClass>$escaped</code></pre>';

      case NodeType.orderedList:
      case NodeType.unorderedList:
        final list = node as ListNode;
        final tag = list.ordered ? 'ol' : 'ul';
        final items = list.items.map((item) {
          final content = _inlineSpansToHtml(item.inlineSpans);
          return '  <li>$content</li>';
        }).join('\n');
        return '<$tag>\n$items\n</$tag>';

      case NodeType.blockquote:
        final quote = node as BlockquoteNode;
        final content = _inlineSpansToHtml(quote.inlineSpans);
        return '<blockquote>\n<p>$content</p>\n</blockquote>';

      case NodeType.horizontalRule:
        return '<hr>';

      case NodeType.table:
        final table = node as TableNode;
        final buffer = StringBuffer('<table>\n<thead>\n<tr>\n');
        for (final header in table.headers) {
          buffer.write('  <th>${_escapeHtml(header)}</th>\n');
        }
        buffer.write('</tr>\n</thead>\n<tbody>\n');
        final colCount = table.headers.length;
        for (final row in table.rows) {
          buffer.write('<tr>\n');
          for (var i = 0; i < colCount; i++) {
            final cell = i < row.length ? row[i] : '';
            buffer.write('  <td>${_escapeHtml(cell)}</td>\n');
          }
          buffer.write('</tr>\n');
        }
        buffer.write('</tbody>\n</table>');
        return buffer.toString();

      case NodeType.mathBlock:
        final math = node as MathBlockNode;
        return '<pre class="math-block">\\[${_escapeHtml(math.expression)}\\]</pre>';

      case NodeType.frontMatter:
        final fm = node as FrontMatterNode;
        return '<pre class="front-matter">${_escapeHtml(fm.content)}</pre>';

      case NodeType.footnoteDefinition:
        final fn = node as FootnoteDefinitionNode;
        return '<div class="footnote" id="fn-${_escapeHtml(fn.id)}"><sup>${_escapeHtml(fn.id)}</sup> ${_escapeHtml(fn.content)}</div>';

      case NodeType.htmlBlock:
        final html = node as HtmlBlockNode;
        return html.html;
    }
  }

  static String _inlineSpansToHtml(List<InlineSpan> spans) {
    return spans.map((span) {
      final text = _escapeHtml(span.text);
      switch (span.type) {
        case InlineType.text:
          return text;
        case InlineType.bold:
          return '<strong>$text</strong>';
        case InlineType.italic:
          return '<em>$text</em>';
        case InlineType.code:
          return '<code>$text</code>';
        case InlineType.link:
          final href = _escapeHtml(span.href ?? '');
          final title = span.title != null ? ' title="${_escapeHtml(span.title!)}"' : '';
          return '<a href="$href"$title>$text</a>';
        case InlineType.image:
          final src = _escapeHtml(span.href ?? '');
          final alt = _escapeHtml(span.text);
          final title = span.title != null ? ' title="${_escapeHtml(span.title!)}"' : '';
          return '<img src="$src" alt="$alt"$title>';
        case InlineType.strikethrough:
          return '<del>$text</del>';
        case InlineType.mathInline:
          return '<span class="math-inline">\\($text\\)</span>';
        case InlineType.highlight:
          return '<mark>$text</mark>';
        case InlineType.superscript:
          return '<sup>$text</sup>';
        case InlineType.subscript:
          return '<sub>$text</sub>';
        case InlineType.underline:
          return '<u>$text</u>';
        case InlineType.footnoteRef:
          return '<sup><a href="#fn-$text">[$text]</a></sup>';
      }
    }).join();
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static List<pw.Widget> _nodeToPdfWidgets(MarkdownNode node) {
    switch (node.type) {
      case NodeType.heading:
        final heading = node as HeadingNode;
        final fontSize = 24.0 - (heading.level - 1) * 2.0;
        return [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
            child: pw.Text(
              heading.content,
              style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ];

      case NodeType.paragraph:
        final para = node as ParagraphNode;
        return [
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Text(para.content, style: const pw.TextStyle(fontSize: 12)),
          ),
        ];

      case NodeType.codeBlock:
        final code = node as CodeBlockNode;
        return [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.only(bottom: 10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              code.code,
              style: pw.TextStyle(fontSize: 10, font: pw.Font.courier()),
            ),
          ),
        ];

      case NodeType.orderedList:
      case NodeType.unorderedList:
        final list = node as ListNode;
        final isOrdered = list.ordered;
        return [
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 20, bottom: 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: list.items.asMap().entries.map((entry) {
                final prefix = isOrdered ? '${entry.key + 1}.' : '\u2022';
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text('$prefix ${_inlineSpansToText(entry.value.inlineSpans)}'),
                );
              }).toList(),
            ),
          ),
        ];

      case NodeType.blockquote:
        final quote = node as BlockquoteNode;
        return [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.only(bottom: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(left: pw.BorderSide(width: 4, color: PdfColors.grey)),
            ),
            child: pw.Text(quote.content, style: const pw.TextStyle(fontSize: 12)),
          ),
        ];

      case NodeType.horizontalRule:
        return [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 10),
            child: pw.Divider(thickness: 1),
          ),
        ];

      case NodeType.table:
        final table = node as TableNode;
        return [
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.TableHelper.fromTextArray(
              headers: table.headers,
              data: table.rows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ),
        ];

      case NodeType.mathBlock:
        final math = node as MathBlockNode;
        return [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.only(bottom: 10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Text(math.expression, style: const pw.TextStyle(fontSize: 12)),
          ),
        ];

      case NodeType.frontMatter:
        final fm = node as FrontMatterNode;
        return [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.only(bottom: 10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(fm.content, style: pw.TextStyle(fontSize: 10, font: pw.Font.courier())),
          ),
        ];

      case NodeType.footnoteDefinition:
        final fn = node as FootnoteDefinitionNode;
        return [
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              '[${fn.id}]: ${fn.content}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ];

      case NodeType.htmlBlock:
        final html = node as HtmlBlockNode;
        return [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.only(bottom: 10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(html.html, style: pw.TextStyle(fontSize: 10, font: pw.Font.courier())),
          ),
        ];
    }
  }

  static String _inlineSpansToText(List<InlineSpan> spans) {
    return spans.map((span) => span.text).join();
  }

  static String _getGitHubStyleCss() {
    return '''
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
      font-size: 16px;
      line-height: 1.6;
      color: #24292e;
      background-color: #ffffff;
      margin: 0;
      padding: 0;
    }
    .markdown-body {
      box-sizing: border-box;
      min-width: 200px;
      max-width: 980px;
      margin: 0 auto;
      padding: 45px;
    }
    h1, h2, h3, h4, h5, h6 {
      margin-top: 24px;
      margin-bottom: 16px;
      font-weight: 600;
      line-height: 1.25;
    }
    h1 { font-size: 2em; border-bottom: 1px solid #eaecef; padding-bottom: 0.3em; }
    h2 { font-size: 1.5em; border-bottom: 1px solid #eaecef; padding-bottom: 0.3em; }
    h3 { font-size: 1.25em; }
    h4 { font-size: 1em; }
    h5 { font-size: 0.875em; }
    h6 { font-size: 0.85em; color: #6a737d; }
    p { margin-top: 0; margin-bottom: 16px; }
    code {
      padding: 0.2em 0.4em;
      margin: 0;
      font-size: 85%;
      background-color: rgba(27,31,35,0.05);
      border-radius: 3px;
      font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;
    }
    pre {
      padding: 16px;
      overflow: auto;
      font-size: 85%;
      line-height: 1.45;
      background-color: #f6f8fa;
      border-radius: 3px;
    }
    pre code {
      display: inline;
      padding: 0;
      margin: 0;
      overflow: visible;
      line-height: inherit;
      background-color: transparent;
      border: 0;
    }
    ul, ol {
      padding-left: 2em;
      margin-top: 0;
      margin-bottom: 16px;
    }
    li + li { margin-top: 0.25em; }
    blockquote {
      padding: 0 1em;
      color: #6a737d;
      border-left: 0.25em solid #dfe2e5;
      margin: 0 0 16px 0;
    }
    blockquote > :first-child { margin-top: 0; }
    blockquote > :last-child { margin-bottom: 0; }
    hr {
      height: 0.25em;
      padding: 0;
      margin: 24px 0;
      background-color: #e1e4e8;
      border: 0;
    }
    table {
      border-spacing: 0;
      border-collapse: collapse;
      margin-top: 0;
      margin-bottom: 16px;
    }
    table th, table td {
      padding: 6px 13px;
      border: 1px solid #dfe2e5;
    }
    table th {
      font-weight: 600;
      background-color: #f6f8fa;
    }
    table tr {
      background-color: #ffffff;
      border-top: 1px solid #c6cbd1;
    }
    table tr:nth-child(2n) {
      background-color: #f6f8fa;
    }
    a {
      color: #0366d6;
      text-decoration: none;
    }
    a:hover {
      text-decoration: underline;
    }
    img {
      max-width: 100%;
      box-sizing: content-box;
    }
    strong { font-weight: 600; }
    em { font-style: italic; }
    del { text-decoration: line-through; }
    ''';
  }
}

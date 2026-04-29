import 'dart:io';
import 'package:docx_creator/docx_creator.dart' hide MarkdownParser;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'markdown_parser.dart';

class ExportService {
  ExportService._();

  static List<pw.Font>? _cachedFontFallbacks;

  /// Load system fonts for multi-language support (CJK, Cyrillic, Arabic, etc.)
  /// Only loads .ttf files (not .ttc) to avoid TTC parsing issues.
  static Future<List<pw.Font>> _loadSystemFonts() async {
    if (_cachedFontFallbacks != null) {
      return _cachedFontFallbacks!;
    }

    final fonts = <pw.Font>[];
    final fontPaths = <String>[];

    if (Platform.isWindows) {
      final windir = Platform.environment['WINDIR'] ?? 'C:\\Windows';
      fontPaths.addAll([
        '$windir\\Fonts\\simhei.ttf',
        '$windir\\Fonts\\malgun.ttf',
        '$windir\\Fonts\\arial.ttf',
        '$windir\\Fonts\\tahoma.ttf',
        '$windir\\Fonts\\times.ttf',
        '$windir\\Fonts\\seguiemj.ttf',    // Segoe UI Emoji (emoji)
      ]);
    } else if (Platform.isMacOS) {
      fontPaths.addAll([
        '/Library/Fonts/Arial Unicode.ttf',
        '/Library/Fonts/Osaka.ttf',
        '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
        '/System/Library/Fonts/Apple Color Emoji.ttc',
      ]);
    } else if (Platform.isLinux) {
      fontPaths.addAll([
        '/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf',
        '/usr/share/fonts/truetype/noto/NotoSansArabic-Regular.ttf',
        '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf',
        '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
        '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
      ]);
    }

    // Load all available fonts
    for (final path in fontPaths) {
      final file = File(path);
      if (await file.exists()) {
        try {
          final bytes = await file.readAsBytes();
          final font = pw.Font.ttf(bytes.buffer.asByteData());
          fonts.add(font);
        } catch (e) {
          // Skip fonts that fail to load
          continue;
        }
      }
    }

    _cachedFontFallbacks = fonts;
    return fonts;
  }

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
    buffer.writeln('  <script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>');
    buffer.writeln('  <script>mermaid.initialize({startOnLoad: true, securityLevel: "strict"});</script>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <div class="markdown-body">');

    for (final node in ast) {
      buffer.writeln(nodeToHtml(node));
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

    final fontFallbacks = await _loadSystemFonts();
    final primaryFont = fontFallbacks.isNotEmpty ? fontFallbacks.first : null;

    try {
      final bytes = await _buildPdf(ast, primaryFont, fontFallbacks);
      await File(savePath).writeAsBytes(bytes);
    } catch (e) {
      // Font error — retry without custom fonts
      final bytes = await _buildPdf(ast, null, []);
      await File(savePath).writeAsBytes(bytes);
    }
  }

  static Future<List<int>> _buildPdf(List<MarkdownNode> ast, pw.Font? primaryFont, List<pw.Font> fontFallbacks) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          final widgets = <pw.Widget>[];
          for (final node in ast) {
            widgets.addAll(_nodeToPdfWidgets(node, primaryFont: primaryFont, fontFallbacks: fontFallbacks));
          }
          return widgets;
        },
      ),
    );

    return await pdf.save();
  }

  /// Export Markdown to Word (.docx)
  static Future<void> exportToDocx(String markdown, String savePath) async {
    final parser = MarkdownParser();
    final ast = parser.parse(markdown);

    var builder = docx();

    for (final node in ast) {
      builder = _addNodeToDocx(builder, node);
    }

    final doc = builder.build();
    await DocxExporter().exportToFile(doc, savePath);
  }

  static DocxDocumentBuilder _addNodeToDocx(DocxDocumentBuilder builder, MarkdownNode node) {
    switch (node.type) {
      case NodeType.heading:
        final heading = node as HeadingNode;
        final level = switch (heading.level) {
          1 => DocxHeadingLevel.h1,
          2 => DocxHeadingLevel.h2,
          3 => DocxHeadingLevel.h3,
          4 => DocxHeadingLevel.h4,
          5 => DocxHeadingLevel.h5,
          _ => DocxHeadingLevel.h6,
        };
        return builder.heading(level, heading.content);

      case NodeType.paragraph:
        final para = node as ParagraphNode;
        if (para.inlineSpans.length == 1 && para.inlineSpans.first.type == InlineType.text) {
          return builder.p(para.content);
        }
        final children = _inlineSpansToDocxTexts(para.inlineSpans);
        return builder.add(DocxParagraph(children: children));

      case NodeType.codeBlock:
        final code = node as CodeBlockNode;
        return builder.code(code.code);

      case NodeType.orderedList:
      case NodeType.unorderedList:
        final list = node as ListNode;
        final items = list.items.map((item) {
          final text = _inlineSpansToText(item.inlineSpans);
          if (item.isTask) {
            return '${item.isChecked ? '☑' : '☐'} $text';
          }
          return text;
        }).toList();
        return list.ordered ? builder.numbered(items) : builder.bullet(items);

      case NodeType.blockquote:
        final quote = node as BlockquoteNode;
        return builder.quote(quote.content);

      case NodeType.horizontalRule:
        return builder.hr();

      case NodeType.table:
        final table = node as TableNode;
        final rows = <List<String>>[
          table.headers,
          ...table.rows,
        ];
        return builder.table(rows);

      case NodeType.mathBlock:
        final math = node as MathBlockNode;
        return builder.code(math.expression);

      case NodeType.frontMatter:
        final fm = node as FrontMatterNode;
        return builder.code(fm.content);

      case NodeType.footnoteDefinition:
        final fn = node as FootnoteDefinitionNode;
        return builder.p('[${fn.id}]: ${fn.content}');

      case NodeType.htmlBlock:
        final html = node as HtmlBlockNode;
        return builder.p(html.html);
    }
  }

  static List<DocxText> _inlineSpansToDocxTexts(List<InlineSpan> spans) {
    return spans.map((span) {
      switch (span.type) {
        case InlineType.bold:
          return DocxText(span.text, fontWeight: DocxFontWeight.bold);
        case InlineType.italic:
          return DocxText(span.text, fontStyle: DocxFontStyle.italic);
        case InlineType.underline:
          return DocxText(span.text, decorations: [DocxTextDecoration.underline]);
        case InlineType.strikethrough:
          return DocxText(span.text, decorations: [DocxTextDecoration.strikethrough]);
        case InlineType.code:
          return DocxText(span.text, fontFamily: 'Courier New', shadingFill: 'f6f8fa');
        case InlineType.link:
          return DocxText(span.text, color: DocxColor('#0366d6'), href: span.href, decorations: [DocxTextDecoration.underline]);
        case InlineType.superscript:
          return DocxText(span.text, isSuperscript: true);
        case InlineType.subscript:
          return DocxText(span.text, isSubscript: true);
        default:
          return DocxText(span.text);
      }
    }).toList();
  }

  static String nodeToHtml(MarkdownNode node) {
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

  static List<pw.Widget> _nodeToPdfWidgets(MarkdownNode node, {pw.Font? primaryFont, List<pw.Font> fontFallbacks = const []}) {
    switch (node.type) {
      case NodeType.heading:
        final heading = node as HeadingNode;
        final fontSize = 24.0 - (heading.level - 1) * 2.0;
        return [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
            child: pw.Text(
              _normalizeForPdf(heading.content),
              style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold, font: primaryFont, fontFallback: fontFallbacks),
            ),
          ),
        ];

      case NodeType.paragraph:
        final para = node as ParagraphNode;
        return [
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Text(_normalizeForPdf(para.content), style: pw.TextStyle(fontSize: 12, font: primaryFont, fontFallback: fontFallbacks)),
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
              _normalizeForPdf(code.code),
              style: pw.TextStyle(fontSize: 10, font: pw.Font.courier(), fontFallback: fontFallbacks),
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
                  child: pw.Text(
                    _normalizeForPdf('$prefix ${_inlineSpansToText(entry.value.inlineSpans)}'),
                    style: pw.TextStyle(font: primaryFont, fontFallback: fontFallbacks),
                  ),
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
            child: pw.Text(_normalizeForPdf(quote.content), style: pw.TextStyle(fontSize: 12, font: primaryFont, fontFallback: fontFallbacks)),
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
              headers: table.headers.map(_normalizeForPdf).toList(),
              data: table.rows.map((row) => row.map(_normalizeForPdf).toList()).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: primaryFont, fontFallback: fontFallbacks),
              cellStyle: pw.TextStyle(font: primaryFont, fontFallback: fontFallbacks),
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
            child: pw.Text(_normalizeForPdf(math.expression), style: pw.TextStyle(fontSize: 12, font: primaryFont, fontFallback: fontFallbacks)),
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
            child: pw.Text(_normalizeForPdf(fm.content), style: pw.TextStyle(fontSize: 10, font: pw.Font.courier(), fontFallback: fontFallbacks)),
          ),
        ];

      case NodeType.footnoteDefinition:
        final fn = node as FootnoteDefinitionNode;
        return [
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              _normalizeForPdf('[${fn.id}]: ${fn.content}'),
              style: pw.TextStyle(fontSize: 10, font: primaryFont, fontFallback: fontFallbacks),
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
            child: pw.Text(html.html, style: pw.TextStyle(fontSize: 10, font: pw.Font.courier(), fontFallback: fontFallbacks)),
          ),
        ];
    }
  }

  /// Normalize text for PDF rendering - only map common emoji that might not be in fonts
  static String _normalizeForPdf(String text) {
    // Keep most emoji as-is, only normalize problematic ones
    return text
        .replaceAll('✅', '☑')  // Checkmark variants
        .replaceAll('❌', '✗')
        .replaceAll('✔️', '✔')
        .replaceAll('❤️', '♥');
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

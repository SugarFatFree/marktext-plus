import 'dart:io';
import 'dart:typed_data';
import 'package:docx_creator/docx_creator.dart' hide MarkdownParser;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'markdown_parser.dart';

class ExportService {
  ExportService._();

  // PDF style constants (GitHub Markdown inspired)
  static const _pdfBodySize = 12.0;
  static const _pdfBodyHeight = 1.5;
  static const _pdfCodeSize = 11.0;
  static const _pdfHeadingSizes = <int, double>{1: 24, 2: 20, 3: 18, 4: 16, 5: 14, 6: 12};
  static const _pdfSpaceBefore = 16.0;
  static const _pdfSpaceAfter = 12.0;
  static const _pdfSpaceHeading = 8.0;
  static const _pdfSpaceListItem = 6.0;
  static final _pdfCodeBg = PdfColor.fromHex('#f6f8fa');
  static final _pdfCodeBorder = PdfColor.fromHex('#e1e4e8');
  static final _pdfQuoteBorder = PdfColor.fromHex('#dfe2e5');
  static final _pdfQuoteBg = PdfColor.fromHex('#f9f9f9');
  static final _pdfTableHeaderBg = PdfColor.fromHex('#f6f8fa');
  static final _pdfTableBorder = PdfColor.fromHex('#dfe2e5');
  static final _pdfTableAltBg = PdfColor.fromHex('#f9f9f9');

  static List<pw.Font>? _cachedFontFallbacks;

  static const _mermaidLanguages = {
    'mermaid',
    'flowchart',
    'sequence',
    'gantt',
    'classdiagram',
    'statediagram',
    'erdiagram',
    'journey',
    'gitgraph',
    'pie',
    'mindmap',
  };

  static bool _isMermaidLanguage(String? lang) {
    if (lang == null || lang.isEmpty) return false;
    return _mermaidLanguages.contains(lang.toLowerCase());
  }

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
  static Future<void> exportToPdf(String markdown, String savePath, {Map<String, Uint8List>? mermaidImages}) async {
    final parser = MarkdownParser();
    final ast = parser.parse(markdown);

    final fontFallbacks = await _loadSystemFonts();
    final primaryFont = fontFallbacks.isNotEmpty ? fontFallbacks.first : null;

    try {
      final bytes = await _buildPdf(ast, primaryFont, fontFallbacks, mermaidImages);
      await File(savePath).writeAsBytes(bytes);
    } catch (e) {
      final bytes = await _buildPdf(ast, null, [], mermaidImages);
      await File(savePath).writeAsBytes(bytes);
    }
  }

  static Future<List<int>> _buildPdf(List<MarkdownNode> ast, pw.Font? primaryFont, List<pw.Font> fontFallbacks, Map<String, Uint8List>? mermaidImages) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          final widgets = <pw.Widget>[];
          int mermaidIndex = 0;
          for (final node in ast) {
            String? mermaidKey;
            if (node is CodeBlockNode && _isMermaidLanguage(node.language)) {
              mermaidKey = 'mermaid_$mermaidIndex';
              mermaidIndex++;
            }
            Uint8List? img;
            if (mermaidKey != null && mermaidImages != null) {
              img = mermaidImages[mermaidKey];
            }
            widgets.addAll(_nodeToPdfWidgets(node, primaryFont: primaryFont, fontFallbacks: fontFallbacks, mermaidImage: img));
          }
          return widgets;
        },
      ),
    );

    return await pdf.save();
  }

  /// Export Markdown to Word (.docx)
  static Future<void> exportToDocx(String markdown, String savePath, {Map<String, Uint8List>? mermaidImages}) async {
    final parser = MarkdownParser();
    final ast = parser.parse(markdown);

    var builder = docx().section(
      pageSize: DocxPageSize.a4,
      marginTop: 1440,
      marginBottom: 1440,
      marginLeft: 1440,
      marginRight: 1440,
    );

    int mermaidIndex = 0;
    for (final node in ast) {
      String? mermaidKey;
      if (node is CodeBlockNode && _isMermaidLanguage(node.language)) {
        mermaidKey = 'mermaid_$mermaidIndex';
        mermaidIndex++;
      }
      Uint8List? img;
      if (mermaidKey != null && mermaidImages != null) {
        img = mermaidImages[mermaidKey];
      }
      builder = _addNodeToDocx(builder, node, mermaidImage: img);
    }

    final doc = builder.build();
    await DocxExporter().exportToFile(doc, savePath);
  }

  static DocxDocumentBuilder _addNodeToDocx(DocxDocumentBuilder builder, MarkdownNode node, {Uint8List? mermaidImage}) {
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
        final children = (para.inlineSpans.length == 1 && para.inlineSpans.first.type == InlineType.text)
            ? [DocxText(para.content)]
            : _inlineSpansToDocxTexts(para.inlineSpans);
        return builder.add(DocxParagraph(
          children: children,
          spacingAfter: 240,
          lineSpacing: 360,
        ));

      case NodeType.codeBlock:
        final code = node as CodeBlockNode;
        final isMermaid = _isMermaidLanguage(code.language);
        if (isMermaid && mermaidImage != null) {
          return builder.image(DocxImage(bytes: mermaidImage, extension: 'png', width: 400, height: 300));
        }
        if (isMermaid) {
          builder = builder.add(DocxParagraph(
            children: [
              DocxText('Mermaid Diagram (${code.language})', fontSize: 18, fontStyle: DocxFontStyle.italic, color: DocxColor('#6a737d')),
            ],
            spacingAfter: 60,
          ));
        }
        return builder.add(DocxParagraph(
          children: [
            DocxText(code.code, fontFamily: 'Courier New', fontSize: 20, shadingFill: 'f6f8fa'),
          ],
          spacingAfter: 240,
          spacingBefore: isMermaid ? 0 : 120,
          indentLeft: 240,
          indentRight: 240,
          shadingFill: 'f6f8fa',
        ));

      case NodeType.orderedList:
      case NodeType.unorderedList:
        final list = node as ListNode;
        // Built as indented paragraphs rather than through builder.bullet:
        // that takes plain strings, which drops both the inline formatting and
        // the nesting depth.
        final counters = <int, int>{};
        var result = builder;
        for (final item in list.items) {
          counters[item.depth] = (counters[item.depth] ?? 0) + 1;
          counters.removeWhere((depth, _) => depth > item.depth);

          final marker = list.ordered
              ? '${counters[item.depth]}. '
              : (item.isTask ? (item.isChecked ? '☑ ' : '☐ ') : '• ');

          result = result.add(DocxParagraph(
            children: [
              DocxText(marker),
              ..._inlineSpansToDocxTexts(item.inlineSpans),
            ],
            indentLeft: 360 + item.depth * 360,
            spacingAfter: 60,
          ));
        }
        return result;

      case NodeType.blockquote:
        final quote = node as BlockquoteNode;
        // Through the parsed spans, not quote.content: the raw content still
        // carries the markdown syntax, so `**bold**` reached Word with its
        // asterisks showing. The quote still reads as a quote from the
        // paragraph's border, indent and shading below.
        return builder.add(DocxParagraph(
          children: _inlineSpansToDocxTexts(quote.inlineSpans),
          indentLeft: 720,
          spacingAfter: 240,
          borderLeft: DocxBorderSide(
            style: DocxBorder.single,
            color: DocxColor('#dfe2e5'),
            size: 12,
            space: 8,
          ),
          shadingFill: 'f9f9f9',
        ));

      case NodeType.horizontalRule:
        return builder.hr();

      case NodeType.table:
        final table = node as TableNode;
        final rows = <List<String>>[table.headers, ...table.rows];
        return builder.table(rows, hasHeader: true);

      case NodeType.mathBlock:
        final math = node as MathBlockNode;
        return builder.add(DocxParagraph(
          children: [DocxText(math.expression, fontFamily: 'Courier New', fontSize: 20)],
          spacingAfter: 240,
          shadingFill: 'f6f8fa',
          indentLeft: 240,
          indentRight: 240,
        ));

      case NodeType.frontMatter:
        final fm = node as FrontMatterNode;
        return builder.add(DocxParagraph(
          children: [DocxText(fm.content, fontFamily: 'Courier New', fontSize: 20)],
          spacingAfter: 240,
          shadingFill: 'f6f8fa',
          indentLeft: 240,
          indentRight: 240,
        ));

      case NodeType.footnoteDefinition:
        final fn = node as FootnoteDefinitionNode;
        return builder.add(DocxParagraph(
          children: [DocxText('[${fn.id}]: ${fn.content}', fontSize: 20, color: DocxColor('#6a737d'))],
          spacingAfter: 120,
        ));

      case NodeType.htmlBlock:
        final html = node as HtmlBlockNode;
        return builder.add(DocxParagraph(
          children: [DocxText(html.html, fontFamily: 'Courier New', fontSize: 20)],
          spacingAfter: 240,
          shadingFill: 'f6f8fa',
          indentLeft: 240,
          indentRight: 240,
        ));
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
          return DocxText(span.text, fontFamily: 'Courier New', fontSize: 20, shadingFill: 'f6f8fa');
        case InlineType.link:
          return DocxText(span.text, color: DocxColor('#0366d6'), href: span.href, decorations: [DocxTextDecoration.underline]);
        case InlineType.superscript:
          return DocxText(span.text, isSuperscript: true);
        case InlineType.subscript:
          return DocxText(span.text, isSubscript: true);
        case InlineType.highlight:
          // Word has no ==highlight== equivalent, but shading is what the code
          // branch above already uses to tint a run's background.
          return DocxText(span.text, shadingFill: 'fff3a3');
        case InlineType.footnoteRef:
          // Not a real Word footnote — a real one needs a footnotes part — but
          // superscript at least keeps the marker readable as a reference.
          return DocxText(span.text, isSuperscript: true);
        case InlineType.mathInline:
          return DocxText(
            span.text,
            fontFamily: 'Cambria Math',
            fontStyle: DocxFontStyle.italic,
          );
        case InlineType.image:
          // Images are not embedded here; the alt text is all that survives,
          // which is better than dropping the span entirely.
          return DocxText(span.text);
        case InlineType.text:
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
        return _listToHtml(node as ListNode);

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

  /// Renders a list, opening and closing a nested list as the depth changes.
  ///
  /// Items carry a depth rather than being a tree, so the nesting is rebuilt
  /// here; a flat run of `<li>` would lose the structure the parser recorded.
  /// Task items get a disabled checkbox, which was otherwise dropped entirely
  /// — the parser strips `[ ]` from the text, so nothing marked them as tasks.
  static String _listToHtml(ListNode list) {
    final tag = list.ordered ? 'ol' : 'ul';
    final buffer = StringBuffer()..writeln('<$tag>');
    var depth = 0;

    for (final item in list.items) {
      while (depth < item.depth) {
        buffer.writeln('<$tag>');
        depth++;
      }
      while (depth > item.depth) {
        buffer.writeln('</$tag>');
        depth--;
      }

      final content = _inlineSpansToHtml(item.inlineSpans);
      final checkbox = item.isTask
          ? '<input type="checkbox" ${item.isChecked ? 'checked ' : ''}disabled> '
          : '';
      buffer.writeln('  <li>$checkbox$content</li>');
    }

    while (depth > 0) {
      buffer.writeln('</$tag>');
      depth--;
    }
    buffer.write('</$tag>');
    return buffer.toString();
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

  /// Builds PDF rich-text spans from parsed inline content.
  ///
  /// PDF export used to print a node's raw `content`, which still holds the
  /// markdown syntax — so `**bold**` reached the page with its asterisks
  /// showing. HTML and DOCX already went through the parsed spans; this brings
  /// PDF in line.
  static List<pw.TextSpan> _inlineSpansToPdf(
    List<InlineSpan> spans, {
    required pw.TextStyle baseStyle,
    pw.Font? primaryFont,
    List<pw.Font> fontFallbacks = const [],
  }) {
    final codeStyle = baseStyle.copyWith(
      font: pw.Font.courier(),
      fontFallback: fontFallbacks,
      fontSize: _pdfCodeSize,
      background: pw.BoxDecoration(color: _pdfCodeBg),
    );

    return spans.map((span) {
      final text = _normalizeForPdf(span.text);
      switch (span.type) {
        case InlineType.bold:
          return pw.TextSpan(
            text: text,
            style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold),
          );
        case InlineType.italic:
          return pw.TextSpan(
            text: text,
            style: baseStyle.copyWith(fontStyle: pw.FontStyle.italic),
          );
        case InlineType.strikethrough:
          return pw.TextSpan(
            text: text,
            style: baseStyle.copyWith(
              decoration: pw.TextDecoration.lineThrough,
            ),
          );
        case InlineType.underline:
          return pw.TextSpan(
            text: text,
            style: baseStyle.copyWith(
              decoration: pw.TextDecoration.underline,
            ),
          );
        case InlineType.code:
          return pw.TextSpan(text: text, style: codeStyle);
        case InlineType.link:
          return pw.TextSpan(
            text: text,
            style: baseStyle.copyWith(
              color: PdfColors.blue700,
              decoration: pw.TextDecoration.underline,
            ),
          );
        case InlineType.highlight:
          return pw.TextSpan(
            text: text,
            style: baseStyle.copyWith(
              background: const pw.BoxDecoration(color: PdfColors.yellow100),
            ),
          );
        case InlineType.superscript:
        case InlineType.subscript:
          // The pdf package has no baseline shift, so these are shown smaller
          // rather than raised or lowered.
          return pw.TextSpan(
            text: text,
            style: baseStyle.copyWith(fontSize: _pdfBodySize * 0.75),
          );
        case InlineType.mathInline:
          return pw.TextSpan(
            text: text,
            style: baseStyle.copyWith(fontStyle: pw.FontStyle.italic),
          );
        case InlineType.footnoteRef:
          return pw.TextSpan(
            text: text,
            style: baseStyle.copyWith(fontSize: _pdfBodySize * 0.75),
          );
        case InlineType.image:
        case InlineType.text:
          return pw.TextSpan(text: text, style: baseStyle);
      }
    }).toList();
  }

  static List<pw.Widget> _nodeToPdfWidgets(MarkdownNode node, {pw.Font? primaryFont, List<pw.Font> fontFallbacks = const [], Uint8List? mermaidImage}) {
    switch (node.type) {
      case NodeType.heading:
        final heading = node as HeadingNode;
        final fontSize = _pdfHeadingSizes[heading.level] ?? 12.0;
        final hasBottomBorder = heading.level <= 2;
        return [
          pw.Padding(
            padding: pw.EdgeInsets.only(top: _pdfSpaceBefore, bottom: _pdfSpaceHeading),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.RichText(
                  text: pw.TextSpan(
                    children: _inlineSpansToPdf(
                      heading.inlineSpans,
                      baseStyle: pw.TextStyle(
                        fontSize: fontSize,
                        fontWeight: pw.FontWeight.bold,
                        font: primaryFont,
                        fontFallback: fontFallbacks,
                        height: 1.2,
                      ),
                      primaryFont: primaryFont,
                      fontFallbacks: fontFallbacks,
                    ),
                  ),
                ),
                if (hasBottomBorder)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 4),
                    height: 1,
                    color: PdfColors.grey300,
                  ),
              ],
            ),
          ),
        ];

      case NodeType.paragraph:
        final para = node as ParagraphNode;
        return [
          pw.Padding(
            padding: pw.EdgeInsets.only(bottom: _pdfSpaceAfter),
            child: pw.RichText(
              text: pw.TextSpan(
                children: _inlineSpansToPdf(
                  para.inlineSpans,
                  baseStyle: pw.TextStyle(
                    fontSize: _pdfBodySize,
                    height: _pdfBodyHeight,
                    font: primaryFont,
                    fontFallback: fontFallbacks,
                  ),
                  primaryFont: primaryFont,
                  fontFallbacks: fontFallbacks,
                ),
              ),
            ),
          ),
        ];

      case NodeType.codeBlock:
        final code = node as CodeBlockNode;
        final isMermaid = _isMermaidLanguage(code.language);
        final widgets = <pw.Widget>[];

        if (isMermaid && mermaidImage != null) {
          // Render Mermaid as image
          widgets.add(
            pw.Container(
              margin: pw.EdgeInsets.only(bottom: _pdfSpaceAfter),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _pdfCodeBorder, width: 1),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Image(pw.MemoryImage(mermaidImage)),
            ),
          );
        } else {
          // Show source code
          if (isMermaid) {
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  'Mermaid Diagram (${code.language})',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                    font: primaryFont,
                    fontFallback: fontFallbacks,
                  ),
                ),
              ),
            );
          }

          widgets.add(
            pw.Container(
              margin: pw.EdgeInsets.only(bottom: _pdfSpaceAfter),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _pdfCodeBg,
                border: pw.Border.all(color: _pdfCodeBorder, width: 1),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                _normalizeForPdf(code.code),
                style: pw.TextStyle(
                  font: primaryFont ?? pw.Font.courier(),
                  fontFallback: [pw.Font.courier(), ...fontFallbacks],
                  fontSize: _pdfCodeSize,
                  height: 1.4,
                ),
              ),
            ),
          );
        }

        return widgets;

      case NodeType.orderedList:
      case NodeType.unorderedList:
        final list = node as ListNode;
        final items = <pw.Widget>[];
        // Numbering counts within a level: a nested ordered list starts at 1
        // again rather than continuing its parent's sequence.
        final counters = <int, int>{};
        for (var i = 0; i < list.items.length; i++) {
          final item = list.items[i];
          counters[item.depth] = (counters[item.depth] ?? 0) + 1;
          counters.removeWhere((depth, _) => depth > item.depth);
          final marker =
              list.ordered ? '${counters[item.depth]}. ' : '• ';
          final checkbox = item.isTask ? (item.isChecked ? '☑ ' : '☐ ') : '';
          items.add(
            pw.Padding(
              padding: pw.EdgeInsets.only(
                left: 20 + item.depth * 18.0,
                bottom: _pdfSpaceListItem,
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    checkbox + marker,
                    style: pw.TextStyle(
                      fontSize: _pdfBodySize,
                      height: _pdfBodyHeight,
                      font: primaryFont,
                      fontFallback: fontFallbacks,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.RichText(
                      text: pw.TextSpan(
                        children: _inlineSpansToPdf(
                          item.inlineSpans,
                          baseStyle: pw.TextStyle(
                            fontSize: _pdfBodySize,
                            height: _pdfBodyHeight,
                            font: primaryFont,
                            fontFallback: fontFallbacks,
                          ),
                          primaryFont: primaryFont,
                          fontFallbacks: fontFallbacks,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return [
          pw.Padding(
            padding: pw.EdgeInsets.only(bottom: _pdfSpaceAfter),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: items,
            ),
          ),
        ];

      case NodeType.blockquote:
        final quote = node as BlockquoteNode;
        return [
          pw.Container(
            margin: pw.EdgeInsets.only(bottom: _pdfSpaceAfter),
            padding: const pw.EdgeInsets.only(left: 12, top: 8, bottom: 8, right: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(left: pw.BorderSide(color: _pdfQuoteBorder, width: 3)),
              color: _pdfQuoteBg,
            ),
            child: pw.RichText(
              text: pw.TextSpan(
                children: _inlineSpansToPdf(
                  quote.inlineSpans,
                  baseStyle: pw.TextStyle(
                    fontSize: _pdfBodySize,
                    height: _pdfBodyHeight,
                    font: primaryFont,
                    fontFallback: fontFallbacks,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                  primaryFont: primaryFont,
                  fontFallbacks: fontFallbacks,
                ),
              ),
            ),
          ),
        ];

      case NodeType.horizontalRule:
        return [
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(vertical: _pdfSpaceAfter),
            child: pw.Divider(thickness: 2, color: PdfColors.grey300),
          ),
        ];

      case NodeType.table:
        final table = node as TableNode;
        return [
          pw.Padding(
            padding: pw.EdgeInsets.only(bottom: _pdfSpaceAfter),
            child: pw.Table(
              border: pw.TableBorder.all(color: _pdfTableBorder, width: 1),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: _pdfTableHeaderBg),
                  children: table.headers.map((header) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        _normalizeForPdf(header),
                        style: pw.TextStyle(
                          fontSize: _pdfBodySize,
                          fontWeight: pw.FontWeight.bold,
                          font: primaryFont,
                          fontFallback: fontFallbacks,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                ...table.rows.asMap().entries.map((entry) {
                  final rowIndex = entry.key;
                  final row = entry.value;
                  final isEvenRow = rowIndex % 2 == 0;
                  return pw.TableRow(
                    decoration: isEvenRow ? pw.BoxDecoration(color: _pdfTableAltBg) : null,
                    children: row.map((cell) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          _normalizeForPdf(cell),
                          style: pw.TextStyle(
                            fontSize: _pdfBodySize,
                            height: 1.3,
                            font: primaryFont,
                            fontFallback: fontFallbacks,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        ];

      case NodeType.mathBlock:
        final math = node as MathBlockNode;
        return [
          pw.Container(
            margin: pw.EdgeInsets.only(bottom: _pdfSpaceAfter),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _pdfCodeBg,
              border: pw.Border.all(color: _pdfCodeBorder, width: 1),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(_normalizeForPdf(math.expression), style: pw.TextStyle(fontSize: _pdfBodySize, font: primaryFont, fontFallback: fontFallbacks)),
          ),
        ];

      case NodeType.frontMatter:
        final fm = node as FrontMatterNode;
        return [
          pw.Container(
            margin: pw.EdgeInsets.only(bottom: _pdfSpaceAfter),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _pdfCodeBg,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(_normalizeForPdf(fm.content), style: pw.TextStyle(fontSize: _pdfCodeSize, font: primaryFont ?? pw.Font.courier(), fontFallback: [pw.Font.courier(), ...fontFallbacks], height: 1.4)),
          ),
        ];

      case NodeType.footnoteDefinition:
        final fn = node as FootnoteDefinitionNode;
        return [
          pw.Padding(
            padding: pw.EdgeInsets.only(bottom: _pdfSpaceListItem),
            child: pw.Text(
              _normalizeForPdf('[${fn.id}]: ${fn.content}'),
              style: pw.TextStyle(fontSize: 10, font: primaryFont, fontFallback: fontFallbacks, color: PdfColors.grey700),
            ),
          ),
        ];

      case NodeType.htmlBlock:
        final html = node as HtmlBlockNode;
        return [
          pw.Container(
            margin: pw.EdgeInsets.only(bottom: _pdfSpaceAfter),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _pdfCodeBg,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(html.html, style: pw.TextStyle(fontSize: _pdfCodeSize, font: primaryFont ?? pw.Font.courier(), fontFallback: [pw.Font.courier(), ...fontFallbacks], height: 1.4)),
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

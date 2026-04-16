import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/tab_info.dart';
import '../../providers/editor_provider.dart';
import '../../providers/file_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tab_provider.dart';
import '../../services/markdown_parser.dart' as md;
import '../widgets/diagram_widget.dart';

class MarkdownRenderer extends ConsumerStatefulWidget {
  final String markdown;
  final void Function(int lineIndex, bool checked)? onTaskToggle;

  const MarkdownRenderer({
    super.key,
    required this.markdown,
    this.onTaskToggle,
  });

  @override
  ConsumerState<MarkdownRenderer> createState() => _MarkdownRendererState();
}

class _MarkdownRendererState extends ConsumerState<MarkdownRenderer> {
  final _headingKeys = <int, GlobalKey>{};

  /// Parse raw markdown to find heading line numbers (1-based),
  /// matching the same logic used by the TOC panel.
  List<int> _findHeadingLines(String markdown) {
    final lines = markdown.split('\n');
    final result = <int>[];
    for (int i = 0; i < lines.length; i++) {
      if (RegExp(r'^#{1,6}\s+.+$').hasMatch(lines[i])) {
        result.add(i + 1);
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(
        editorProvider.select((s) => s.targetScrollLine),
        (prev, next) {
          if (next != null) {
            final key = _headingKeys[next];
            if (key?.currentContext != null) {
              Scrollable.ensureVisible(
                key!.currentContext!,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
            ref.read(editorProvider.notifier).clearScrollTarget();
          }
        },
      );
    });
  }

  void _handleLinkTap(String? href) {
    if (href == null || href.isEmpty) return;

    // External URL
    if (href.startsWith('http://') || href.startsWith('https://')) {
      launchUrl(Uri.parse(href));
      return;
    }

    // Local markdown file
    final ext = p.extension(href).toLowerCase();
    if (ext == '.md' || ext == '.markdown' || ext == '.txt') {
      // Resolve relative path against current file
      final activeTab = ref.read(activeTabProvider);
      String resolvedPath = href;
      if (activeTab?.filePath != null && !p.isAbsolute(href)) {
        resolvedPath = p.normalize(p.join(p.dirname(activeTab!.filePath!), href));
      }
      final file = File(resolvedPath);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final tab = TabInfo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          filePath: resolvedPath,
          fileName: p.basename(resolvedPath),
          content: content,
        );
        ref.read(tabProvider.notifier).addTab(tab);
        ref.read(settingsProvider.notifier).addRecentFile(resolvedPath);

        // If no folder is open, load the file's parent directory
        final currentDir = ref.read(fileProvider.notifier).currentDirectory;
        if (currentDir == null) {
          ref.read(fileProvider.notifier).loadDirectory(p.dirname(resolvedPath));
        }
      }
      return;
    }

    // Other local links - try to launch
    launchUrl(Uri.parse(href));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = ref.watch(settingsProvider);
    final tokens = AppTheme.getTokens(config.themeName);
    final parser = md.MarkdownParser();
    final nodes = parser.parse(widget.markdown);
    final headingLines = _findHeadingLines(widget.markdown);
    final widgets = <Widget>[];

    int headingIndex = 0;
    for (final node in nodes) {
      switch (node) {
        case md.HeadingNode():
          final lineNum = headingIndex < headingLines.length
              ? headingLines[headingIndex]
              : -1;
          headingIndex++;
          _headingKeys.putIfAbsent(lineNum, () => GlobalKey());
          widgets.add(_buildHeading(node, theme, tokens, key: _headingKeys[lineNum]));
        case md.ParagraphNode():
          widgets.add(_buildParagraph(node, theme));
        case md.CodeBlockNode():
          widgets.add(_buildCodeBlock(node, theme, tokens));
        case md.ListNode():
          widgets.add(_buildList(node, theme));
        case md.BlockquoteNode():
          widgets.add(_buildBlockquote(node, theme, tokens));
        case md.HorizontalRuleNode():
          widgets.add(Divider(thickness: 1, color: tokens.colorBorder));
        case md.TableNode():
          widgets.add(_buildTable(node, theme));
        case md.MathBlockNode():
          widgets.add(_buildMathBlock(node, theme));
        case md.FrontMatterNode():
          widgets.add(_buildFrontMatter(node, theme));
        case md.FootnoteDefinitionNode():
          widgets.add(_buildFootnoteDefinition(node, theme));
        case md.HtmlBlockNode():
          widgets.add(_buildHtmlBlock(node, theme));
      }
    }

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widgets,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeading(md.HeadingNode node, ThemeData theme, AppThemeTokens tokens, {Key? key}) {
    final style = switch (node.level) {
      1 => TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: tokens.colorText),
      2 => TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: tokens.colorText),
      3 => TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: tokens.colorText),
      _ => TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: tokens.colorTextMuted),
    };

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            _buildInlineSpans(node.inlineSpans, theme, style),
            style: style,
          ),
          if (node.level == 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Divider(height: 1, thickness: 1, color: tokens.colorBorder),
            ),
        ],
      ),
    );
  }

  Widget _buildParagraph(md.ParagraphNode node, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text.rich(
        _buildInlineSpans(node.inlineSpans, theme, const TextStyle(fontSize: 17, height: 1.7)),
      ),
    );
  }

  /// Languages recognized as Mermaid diagram types.
  static const _diagramLanguages = {
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

  Widget _buildCodeBlock(md.CodeBlockNode node, ThemeData theme, AppThemeTokens tokens) {
    final lang = node.language.toLowerCase();
    if (_diagramLanguages.contains(lang)) {
      return DiagramWidget(
        code: node.code,
        type: node.language,
        isDarkMode: theme.brightness == Brightness.dark,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: node.language.isNotEmpty
          ? HighlightView(
              node.code,
              language: node.language,
              theme: githubTheme,
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            )
          : Text(
              node.code,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
    );
  }

  Widget _buildList(md.ListNode node, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < node.items.length; i++)
            _buildListItem(node.items[i], i, node.ordered, theme),
        ],
      ),
    );
  }

  Widget _buildListItem(md.ListItem item, int index, bool ordered, ThemeData theme) {
    if (item.isTask) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: item.isChecked,
              onChanged: widget.onTaskToggle != null
                  ? (value) => widget.onTaskToggle!(index, value ?? false)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                _buildInlineSpans(item.inlineSpans, theme, theme.textTheme.bodyMedium),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ordered ? '${index + 1}. ' : '• ',
            style: theme.textTheme.bodyMedium,
          ),
          Expanded(
            child: Text.rich(
              _buildInlineSpans(item.inlineSpans, theme, theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockquote(md.BlockquoteNode node, ThemeData theme, AppThemeTokens tokens) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: tokens.colorAccent, width: 3),
        ),
        color: tokens.colorAccentMuted.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text.rich(
        _buildInlineSpans(node.inlineSpans, theme, const TextStyle(fontSize: 17, height: 1.7)),
      ),
    );
  }

  Widget _buildTable(md.TableNode node, ThemeData theme) {
    final colCount = node.headers.length;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Table(
        border: TableBorder.symmetric(
          inside: BorderSide(color: theme.dividerColor),
        ),
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            children: [
              for (var i = 0; i < node.headers.length; i++)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    node.headers[i],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: _getAlignment(node.alignments, i),
                  ),
                ),
            ],
          ),
          for (final row in node.rows)
            TableRow(
              children: [
                for (var i = 0; i < colCount; i++)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      i < row.length ? row[i] : '',
                      textAlign: _getAlignment(node.alignments, i),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  TextAlign _getAlignment(List<String> alignments, int index) {
    if (index >= alignments.length) return TextAlign.left;
    return switch (alignments[index]) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    };
  }

  Widget _buildMathBlock(md.MathBlockNode node, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Math.tex(
          node.expression,
          textStyle: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildFrontMatter(md.FrontMatterNode node, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Text(
        node.content,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }

  Widget _buildFootnoteDefinition(md.FootnoteDefinitionNode node, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[${node.id}]: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(node.content, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _buildHtmlBlock(md.HtmlBlockNode node, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        node.html,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }

  TextSpan _buildInlineSpans(
    List<md.InlineSpan> spans,
    ThemeData theme,
    TextStyle? baseStyle,
  ) {
    final children = <InlineSpan>[];

    for (final span in spans) {
      switch (span.type) {
        case md.InlineType.text:
          children.add(TextSpan(text: span.text, style: baseStyle));
        case md.InlineType.bold:
          children.add(TextSpan(
            text: span.text,
            style: baseStyle?.copyWith(fontWeight: FontWeight.bold),
          ));
        case md.InlineType.italic:
          children.add(TextSpan(
            text: span.text,
            style: baseStyle?.copyWith(fontStyle: FontStyle.italic),
          ));
        case md.InlineType.code:
          children.add(TextSpan(
            text: span.text,
            style: baseStyle?.copyWith(
              fontFamily: 'monospace',
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ));
        case md.InlineType.link:
          children.add(TextSpan(
            text: span.text,
            style: baseStyle?.copyWith(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _handleLinkTap(span.href),
          ));
        case md.InlineType.image:
          children.add(_buildImageSpan(span, theme));
        case md.InlineType.strikethrough:
          children.add(TextSpan(
            text: span.text,
            style: baseStyle?.copyWith(decoration: TextDecoration.lineThrough),
          ));
        case md.InlineType.mathInline:
          children.add(WidgetSpan(
            child: Math.tex(
              span.text,
              textStyle: baseStyle,
            ),
          ));
        case md.InlineType.highlight:
          children.add(TextSpan(
            text: span.text,
            style: baseStyle?.copyWith(
              backgroundColor: Colors.yellow.withValues(alpha: 0.4),
            ),
          ));
        case md.InlineType.superscript:
          children.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Transform.translate(
              offset: const Offset(0, -4),
              child: Text(
                span.text,
                style: baseStyle?.copyWith(fontSize: (baseStyle.fontSize ?? 14) * 0.75),
              ),
            ),
          ));
        case md.InlineType.subscript:
          children.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Transform.translate(
              offset: const Offset(0, 4),
              child: Text(
                span.text,
                style: baseStyle?.copyWith(fontSize: (baseStyle.fontSize ?? 14) * 0.75),
              ),
            ),
          ));
        case md.InlineType.underline:
          children.add(TextSpan(
            text: span.text,
            style: baseStyle?.copyWith(decoration: TextDecoration.underline),
          ));
        case md.InlineType.footnoteRef:
          children.add(WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Text(
              '[${span.text}]',
              style: baseStyle?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: (baseStyle.fontSize ?? 14) * 0.75,
              ),
            ),
          ));
      }
    }

    return TextSpan(children: children);
  }

  InlineSpan _buildImageSpan(md.InlineSpan span, ThemeData theme) {
    final href = span.href;
    if (href == null || href.isEmpty) {
      return TextSpan(
        text: '[${span.text}]',
        style: TextStyle(color: theme.colorScheme.error),
      );
    }

    Widget imageWidget;
    if (href.startsWith('http://') || href.startsWith('https://')) {
      imageWidget = Image.network(
        href,
        errorBuilder: (context, error, stackTrace) => Text(
          '[${span.text}]',
          style: TextStyle(color: theme.colorScheme.error),
        ),
      );
    } else {
      final file = File(href);
      imageWidget = Image.file(
        file,
        errorBuilder: (context, error, stackTrace) => Text(
          '[${span.text}]',
          style: TextStyle(color: theme.colorScheme.error),
        ),
      );
    }

    return WidgetSpan(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: imageWidget,
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:highlight/highlight.dart' show highlight, Node;
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/tab_info.dart';
import '../../providers/editor_provider.dart';
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
  int _matchCounter = 0;
  final _recognizers = <TapGestureRecognizer>[];

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

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  Future<void> _openLink(String href) async {
    if (href.startsWith('http://') || href.startsWith('https://')) {
      await launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
      return;
    }

    final activeTabId = ref.read(tabProvider).activeTabId;
    final activeTab = ref.read(tabProvider).tabs.where((tab) => tab.id == activeTabId).firstOrNull;
    final baseDir = activeTab?.filePath != null ? p.dirname(activeTab!.filePath!) : null;
    final resolvedPath = baseDir != null ? p.normalize(p.join(baseDir, href)) : p.normalize(href);
    final file = File(resolvedPath);
    if (!file.existsSync()) return;

    final content = await file.readAsString();
    ref.read(tabProvider.notifier).addTab(
      TabInfo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        filePath: resolvedPath,
        fileName: p.basename(resolvedPath),
        content: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final theme = Theme.of(context);
    final config = ref.watch(settingsProvider);
    final tokens = AppTheme.getTokens(config.themeName);
    // Watch editorProvider to rebuild when search state changes
    ref.watch(editorProvider);
    final parser = md.MarkdownParser();
    final nodes = parser.parse(widget.markdown);
    final headingLines = _findHeadingLines(widget.markdown);
    final widgets = <Widget>[];
    _matchCounter = 0;

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
      child: SelectionArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: config.editorMaxWidth.toDouble()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widgets,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeading(md.HeadingNode node, ThemeData theme, AppThemeTokens tokens, {Key? key}) {
    final style = switch (node.level) {
      1 => TextStyle(fontFamily: _previewFontFamily, fontFamilyFallback: _previewFontFallback, fontSize: 28, fontWeight: FontWeight.w700, color: tokens.colorText),
      2 => TextStyle(fontFamily: _previewFontFamily, fontFamilyFallback: _previewFontFallback, fontSize: 24, fontWeight: FontWeight.w600, color: tokens.colorText),
      3 => TextStyle(fontFamily: _previewFontFamily, fontFamilyFallback: _previewFontFallback, fontSize: 21, fontWeight: FontWeight.w600, color: tokens.colorText),
      _ => TextStyle(fontFamily: _previewFontFamily, fontFamilyFallback: _previewFontFallback, fontSize: 17, fontWeight: FontWeight.w600, color: tokens.colorTextMuted),
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

  static const _previewFontFamily = 'Open Sans';
  static const _previewFontFallback = ['Helvetica Neue', 'Arial'];

  Widget _buildParagraph(md.ParagraphNode node, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text.rich(
        _buildInlineSpans(node.inlineSpans, theme, const TextStyle(fontFamily: _previewFontFamily, fontSize: 16, height: 1.6)),
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

    final baseCodeStyle = const TextStyle(fontFamily: 'monospace', fontSize: 14);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: node.language.isNotEmpty
          ? Text.rich(
              TextSpan(
                style: _buildCodeTextStyle(baseCodeStyle),
                children: _buildHighlightedCodeSpans(node.code, node.language),
              ),
            )
          : Text(
              node.code,
              style: baseCodeStyle,
            ),
    );
  }

  TextStyle _buildCodeTextStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      color: githubTheme['root']?.color ?? const Color(0xff000000),
    );
  }

  List<TextSpan> _buildHighlightedCodeSpans(String source, String language, {int tabSize = 8}) {
    final nodes = highlight.parse(source.replaceAll('\t', ' ' * tabSize), language: language).nodes;
    if (nodes == null || nodes.isEmpty) {
      return [TextSpan(text: source)];
    }
    return _convertHighlightNodes(nodes, githubTheme);
  }

  List<TextSpan> _convertHighlightNodes(List<Node> nodes, Map<String, TextStyle> theme) {
    final spans = <TextSpan>[];
    var currentSpans = spans;
    final stack = <List<TextSpan>>[];

    void traverse(Node node) {
      if (node.value != null) {
        currentSpans.add(
          node.className == null
              ? TextSpan(text: node.value)
              : TextSpan(text: node.value, style: theme[node.className!]),
        );
        return;
      }

      if (node.children == null) return;

      if (node.className == null) {
        for (final child in node.children!) {
          traverse(child);
        }
        return;
      }

      final nestedSpans = <TextSpan>[];
      currentSpans.add(TextSpan(children: nestedSpans, style: theme[node.className!]));
      stack.add(currentSpans);
      currentSpans = nestedSpans;

      for (final child in node.children!) {
        traverse(child);
      }

      currentSpans = stack.removeLast();
    }

    for (final node in nodes) {
      traverse(node);
    }

    return spans;
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
        _buildInlineSpans(node.inlineSpans, theme, const TextStyle(fontFamily: _previewFontFamily, fontSize: 16, height: 1.6)),
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
      // Remove SingleChildScrollView to avoid breaking SelectionArea continuity
      // Trade-off: wide tables will wrap or overflow instead of horizontal scroll
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
                      fontFamily: _previewFontFamily,
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
                      style: TextStyle(fontFamily: _previewFontFamily),
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

  /// Split a text span into segments with search highlighting applied.
  List<InlineSpan> _applySearchHighlight(String text, TextStyle? style, EditorState editorState) {
    final query = editorState.previewSearchQuery;
    if (query.isEmpty || text.isEmpty) {
      return [TextSpan(text: text, style: style)];
    }

    final matchRanges = <TextRange>[];
    try {
      if (editorState.previewSearchUseRegex) {
        final regex = RegExp(query, caseSensitive: editorState.previewSearchCaseSensitive);
        for (final m in regex.allMatches(text)) {
          matchRanges.add(TextRange(start: m.start, end: m.end));
        }
      } else {
        String searchText = text;
        String searchPattern = query;
        if (!editorState.previewSearchCaseSensitive) {
          searchText = text.toLowerCase();
          searchPattern = query.toLowerCase();
        }
        int index = 0;
        while (index < searchText.length) {
          final pos = searchText.indexOf(searchPattern, index);
          if (pos == -1) break;
          if (editorState.previewSearchWholeWord) {
            final isWordStart = pos == 0 || !RegExp(r'[a-zA-Z0-9_]').hasMatch(text[pos - 1]);
            final isWordEnd = pos + query.length >= text.length ||
                !RegExp(r'[a-zA-Z0-9_]').hasMatch(text[pos + query.length]);
            if (isWordStart && isWordEnd) {
              matchRanges.add(TextRange(start: pos, end: pos + query.length));
            }
          } else {
            matchRanges.add(TextRange(start: pos, end: pos + query.length));
          }
          index = pos + 1;
        }
      }
    } catch (_) {
      return [TextSpan(text: text, style: style)];
    }

    if (matchRanges.isEmpty) {
      return [TextSpan(text: text, style: style)];
    }

    final result = <InlineSpan>[];
    int lastEnd = 0;
    final currentIdx = editorState.previewCurrentMatchIndex;

    for (final range in matchRanges) {
      if (range.start > lastEnd) {
        result.add(TextSpan(text: text.substring(lastEnd, range.start), style: style));
      }
      final isCurrent = _matchCounter == currentIdx;
      result.add(TextSpan(
        text: text.substring(range.start, range.end),
        style: style?.copyWith(
          backgroundColor: isCurrent
              ? Colors.orange.withValues(alpha: 0.6)
              : Colors.yellow.withValues(alpha: 0.4),
        ),
      ));
      _matchCounter++;
      lastEnd = range.end;
    }
    if (lastEnd < text.length) {
      result.add(TextSpan(text: text.substring(lastEnd), style: style));
    }
    return result;
  }

  TextSpan _buildInlineSpans(
    List<md.InlineSpan> spans,
    ThemeData theme,
    TextStyle? baseStyle,
  ) {
    final children = <InlineSpan>[];
    final es = ref.read(editorProvider);
    final hasSearch = es.previewSearchQuery.isNotEmpty;

    for (final span in spans) {
      switch (span.type) {
        case md.InlineType.text:
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, baseStyle, es));
          } else {
            children.add(TextSpan(text: span.text, style: baseStyle));
          }
        case md.InlineType.bold:
          final s = baseStyle?.copyWith(fontWeight: FontWeight.bold);
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(TextSpan(text: span.text, style: s));
          }
        case md.InlineType.italic:
          final s = baseStyle?.copyWith(fontStyle: FontStyle.italic);
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(TextSpan(text: span.text, style: s));
          }
        case md.InlineType.code:
          final s = baseStyle?.copyWith(
            fontFamily: 'monospace',
            backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          );
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(TextSpan(text: ' ${span.text} ', style: s));
          }
        case md.InlineType.link:
          final s = baseStyle?.copyWith(
            color: theme.colorScheme.primary,
            // Remove underline decoration to avoid triggering rebuild on Ctrl press
            decoration: TextDecoration.none,
          );
          // Check modifier state at click time, not during build
          final recognizer = TapGestureRecognizer()
            ..onTap = () {
              if (span.href != null &&
                  (HardwareKeyboard.instance.isControlPressed ||
                   HardwareKeyboard.instance.isMetaPressed)) {
                _openLink(span.href!);
              }
            };
          _recognizers.add(recognizer);
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(TextSpan(text: span.text, style: s, recognizer: recognizer));
          }
        case md.InlineType.image:
          children.add(_buildImageSpan(span, theme));
        case md.InlineType.strikethrough:
          final s = baseStyle?.copyWith(decoration: TextDecoration.lineThrough);
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(TextSpan(text: span.text, style: s));
          }
        case md.InlineType.mathInline:
          children.add(WidgetSpan(
            child: Math.tex(
              span.text,
              textStyle: baseStyle,
            ),
          ));
        case md.InlineType.highlight:
          final s = baseStyle?.copyWith(
            backgroundColor: Colors.yellow.withValues(alpha: 0.4),
          );
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(TextSpan(text: span.text, style: s));
          }
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
          final s = baseStyle?.copyWith(decoration: TextDecoration.underline);
          if (hasSearch) {
            children.addAll(_applySearchHighlight(span.text, s, es));
          } else {
            children.add(TextSpan(text: span.text, style: s));
          }
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

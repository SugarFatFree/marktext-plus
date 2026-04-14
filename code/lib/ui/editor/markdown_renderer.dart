import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/markdown_parser.dart' as md;

class MarkdownRenderer extends ConsumerWidget {
  final String markdown;
  final void Function(int lineIndex, bool checked)? onTaskToggle;

  const MarkdownRenderer({
    super.key,
    required this.markdown,
    this.onTaskToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final parser = md.MarkdownParser();
    final nodes = parser.parse(markdown);
    final widgets = <Widget>[];

    for (final node in nodes) {
      switch (node) {
        case md.HeadingNode():
          widgets.add(_buildHeading(node, theme));
        case md.ParagraphNode():
          widgets.add(_buildParagraph(node, theme));
        case md.CodeBlockNode():
          widgets.add(_buildCodeBlock(node, theme));
        case md.ListNode():
          widgets.add(_buildList(node, theme));
        case md.BlockquoteNode():
          widgets.add(_buildBlockquote(node, theme));
        case md.HorizontalRuleNode():
          widgets.add(const Divider(thickness: 1));
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  Widget _buildHeading(md.HeadingNode node, ThemeData theme) {
    final textStyle = switch (node.level) {
      1 => theme.textTheme.displaySmall,
      2 => theme.textTheme.headlineMedium,
      3 => theme.textTheme.headlineSmall,
      4 => theme.textTheme.titleLarge,
      5 => theme.textTheme.titleMedium,
      _ => theme.textTheme.titleSmall,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text.rich(
        _buildInlineSpans(node.inlineSpans, theme, textStyle),
        style: textStyle,
      ),
    );
  }

  Widget _buildParagraph(md.ParagraphNode node, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text.rich(
        _buildInlineSpans(node.inlineSpans, theme, theme.textTheme.bodyMedium),
      ),
    );
  }

  Widget _buildCodeBlock(md.CodeBlockNode node, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
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
              onChanged: onTaskToggle != null
                  ? (value) => onTaskToggle!(index, value ?? false)
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

  Widget _buildBlockquote(md.BlockquoteNode node, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 4),
        ),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Text.rich(
        _buildInlineSpans(node.inlineSpans, theme, theme.textTheme.bodyMedium),
      ),
    );
  }

  Widget _buildTable(md.TableNode node, ThemeData theme) {
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
                for (var i = 0; i < row.length; i++)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      row[i],
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MarkdownRenderer extends ConsumerWidget {
  final String markdown;

  const MarkdownRenderer({
    super.key,
    required this.markdown,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lines = markdown.split('\n');
    final widgets = <Widget>[];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];

      // Code block
      if (line.startsWith('```')) {
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        if (i < lines.length) i++; // skip closing ```
        widgets.add(_buildCodeBlock(codeLines.join('\n'), theme));
        continue;
      }

      // Heading
      if (line.startsWith('#')) {
        final match = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
        if (match != null) {
          final level = match.group(1)!.length;
          final text = match.group(2)!;
          widgets.add(_buildHeading(text, level, theme));
          i++;
          continue;
        }
      }

      // Horizontal rule
      if (RegExp(r'^(-{3,}|\*{3,}|_{3,})$').hasMatch(line.trim())) {
        widgets.add(const Divider(thickness: 1));
        i++;
        continue;
      }

      // Blockquote
      if (line.startsWith('>')) {
        final quoteLines = <String>[];
        while (i < lines.length && lines[i].startsWith('>')) {
          quoteLines.add(lines[i].replaceFirst(RegExp(r'^>\s?'), ''));
          i++;
        }
        widgets.add(_buildBlockquote(quoteLines.join('\n'), theme));
        continue;
      }

      // Unordered list
      if (RegExp(r'^[-*+]\s').hasMatch(line)) {
        final listItems = <String>[];
        while (i < lines.length && RegExp(r'^[-*+]\s').hasMatch(lines[i])) {
          listItems.add(lines[i].replaceFirst(RegExp(r'^[-*+]\s'), ''));
          i++;
        }
        widgets.add(_buildUnorderedList(listItems, theme));
        continue;
      }

      // Ordered list
      if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final listItems = <String>[];
        while (i < lines.length && RegExp(r'^\d+\.\s').hasMatch(lines[i])) {
          listItems.add(lines[i].replaceFirst(RegExp(r'^\d+\.\s'), ''));
          i++;
        }
        widgets.add(_buildOrderedList(listItems, theme));
        continue;
      }

      // Empty line
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        i++;
        continue;
      }

      // Paragraph
      widgets.add(_buildParagraph(line, theme));
      i++;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  // PLACEHOLDER_HEADING
  // PLACEHOLDER_REST

  Widget _buildHeading(String text, int level, ThemeData theme) {
    final sizes = [28.0, 24.0, 20.0, 18.0, 16.0, 14.0];
    final size = level <= sizes.length ? sizes[level - 1] : 14.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(text: _buildInlineSpans(text, theme)),
    );
  }

  Widget _buildCodeBlock(String code, ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildBlockquote(String text, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
            width: 3,
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildUnorderedList(List<String> items, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('  \u2022  ', style: TextStyle(color: theme.colorScheme.onSurface)),
              Expanded(child: RichText(text: _buildInlineSpans(item, theme))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildOrderedList(List<String> items, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(items.length, (index) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text('${index + 1}. ', style: TextStyle(color: theme.colorScheme.onSurface)),
              ),
              Expanded(child: RichText(text: _buildInlineSpans(items[index], theme))),
            ],
          ),
        )),
      ),
    );
  }

  TextSpan _buildInlineSpans(String text, ThemeData theme) {
    final spans = <InlineSpan>[];
    int pos = 0;
    final defaultStyle = TextStyle(color: theme.colorScheme.onSurface, fontSize: 14);

    final patterns = <_InlinePattern>[
      _InlinePattern(RegExp(r'!\[([^\]]*)\]\(([^)]+)\)'), 'image'),
      _InlinePattern(RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), 'link'),
      _InlinePattern(RegExp(r'\*\*(.+?)\*\*'), 'bold'),
      _InlinePattern(RegExp(r'`(.+?)`'), 'code'),
      _InlinePattern(RegExp(r'~~(.+?)~~'), 'strikethrough'),
      _InlinePattern(RegExp(r'\*(.+?)\*'), 'italic'),
    ];

    while (pos < text.length) {
      Match? earliest;
      _InlinePattern? matched;

      for (final p in patterns) {
        final m = p.regex.firstMatch(text.substring(pos));
        if (m != null && (earliest == null || m.start < earliest.start)) {
          earliest = m;
          matched = p;
        }
      }

      if (earliest == null) {
        spans.add(TextSpan(text: text.substring(pos), style: defaultStyle));
        break;
      }

      if (earliest.start > 0) {
        spans.add(TextSpan(text: text.substring(pos, pos + earliest.start), style: defaultStyle));
      }

      final content = earliest.group(1) ?? earliest.group(0)!;
      switch (matched!.type) {
        case 'bold':
          spans.add(TextSpan(text: content, style: defaultStyle.copyWith(fontWeight: FontWeight.bold)));
        case 'italic':
          spans.add(TextSpan(text: content, style: defaultStyle.copyWith(fontStyle: FontStyle.italic)));
        case 'code':
          spans.add(TextSpan(
            text: content,
            style: defaultStyle.copyWith(fontFamily: 'monospace', backgroundColor: theme.colorScheme.surface),
          ));
        case 'link':
          spans.add(TextSpan(
            text: content,
            style: defaultStyle.copyWith(color: theme.colorScheme.primary, decoration: TextDecoration.underline),
          ));
        case 'image':
          spans.add(TextSpan(text: '[image: $content]', style: defaultStyle.copyWith(color: theme.colorScheme.primary)));
        case 'strikethrough':
          spans.add(TextSpan(text: content, style: defaultStyle.copyWith(decoration: TextDecoration.lineThrough)));
        default:
          spans.add(TextSpan(text: content, style: defaultStyle));
      }

      pos += earliest.start + earliest.group(0)!.length;
    }

    return TextSpan(children: spans);
  }
}

class _InlinePattern {
  final RegExp regex;
  final String type;
  _InlinePattern(this.regex, this.type);
}

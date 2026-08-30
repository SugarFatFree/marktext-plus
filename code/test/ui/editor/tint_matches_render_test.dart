import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
import 'package:marktext_plus/ui/editor/syntax_highlighter.dart';

/// The source pane's tint against what the preview actually draws.
///
/// Two panes, two readings of the same characters: the pane being typed in
/// colours emphasis from patterns, and the pane beside it draws emphasis from
/// the parser. When they disagree the editor contradicts itself — the source
/// says a sentence is bold and the preview shows its asterisks — and the
/// reader has no way to tell which one is right.
///
/// This asserts the property rather than either answer, so it keeps holding
/// when either side changes.
void main() {
  const colors = HighlightColors(
    heading: Colors.blue,
    bold: Colors.red,
    code: Colors.green,
    link: Colors.purple,
    defaultColor: Colors.black,
  );

  bool tinted(String line) =>
      MarkdownSyntaxHighlighter.highlightLine(line, colors).any((span) =>
          span.style?.fontWeight == FontWeight.bold ||
          span.style?.fontStyle == FontStyle.italic ||
          span.style?.decoration == TextDecoration.lineThrough);

  bool drawn(String line) => MarkdownParser()
      .parse(line)
      .map(ExportService.nodeToHtml)
      .join()
      .contains(RegExp(r'<(strong|em|del)>'));

  void agree(String line) {
    test(line, () {
      expect(tinted(line), drawn(line),
          reason: tinted(line)
              ? '源码区染了色，预览却不画'
              : '预览画了，源码区没染色');
    });
  }

  group('emphasis beside punctuation', () {
    // The shapes a Chinese sentence produces, where the flanking rule decides.
    agree('**加粗。**后面接中文');
    agree('**加粗**。后面接中文');
    agree('**bold.**after');
    agree('前面**「加粗」**后面');
    agree('*斜体。*后面');
    agree('*斜体*。后面');
  });

  group('ordinary emphasis', () {
    agree('普通 **加粗** 文字');
    agree('一句 *斜体* 话');
    agree('~~删除线~~ 后面');
    agree('没有任何标记的一行');
  });

  group('markers that are not emphasis', () {
    agree('价格 3*4 元 和 5*6 元');
    agree('snake_case_name 是一个词');
    agree('a * b * c');
  });

  group('strikethrough follows this parser, not GitHub', () {
    // Deliberately more forgiving here than GitHub, so the tint follows the
    // pane beside it rather than the format.
    agree('~~删除。~~后面');
  });
}

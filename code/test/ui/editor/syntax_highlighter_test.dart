import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/syntax_highlighter.dart';

void main() {
  group('MarkdownSyntaxHighlighter', () {
    const headingColor = Colors.blue;
    const boldColor = Colors.red;
    const codeColor = Colors.green;
    const linkColor = Colors.purple;
    const defaultColor = Colors.black;

    test('highlights heading', () {
      final result = MarkdownSyntaxHighlighter.highlight(
        '# Heading',
        headingColor: headingColor,
        boldColor: boldColor,
        codeColor: codeColor,
        linkColor: linkColor,
        defaultColor: defaultColor,
      );

      expect(result.children, isNotNull);
      expect(result.children!.length, greaterThan(0));
      final firstSpan = result.children!.first as TextSpan;
      expect(firstSpan.style?.color, headingColor);
      expect(firstSpan.text, '# Heading');
    });

    test('highlights bold text', () {
      final result = MarkdownSyntaxHighlighter.highlight(
        '**bold**',
        headingColor: headingColor,
        boldColor: boldColor,
        codeColor: codeColor,
        linkColor: linkColor,
        defaultColor: defaultColor,
      );

      expect(result.children, isNotNull);
      final spans = result.children!.cast<TextSpan>();
      final boldSpan = spans.firstWhere((s) => s.style?.color == boldColor);
      expect(boldSpan.text, 'bold');
      expect(boldSpan.style?.fontWeight, FontWeight.bold);
    });

    test('highlights inline code', () {
      final result = MarkdownSyntaxHighlighter.highlight(
        '`code`',
        headingColor: headingColor,
        boldColor: boldColor,
        codeColor: codeColor,
        linkColor: linkColor,
        defaultColor: defaultColor,
      );

      expect(result.children, isNotNull);
      final spans = result.children!.cast<TextSpan>();
      final codeSpan = spans.firstWhere((s) => s.style?.color == codeColor);
      expect(codeSpan.text, 'code');
      expect(codeSpan.style?.fontFamily, 'monospace');
    });

    test('highlights link', () {
      final result = MarkdownSyntaxHighlighter.highlight(
        '[link](url)',
        headingColor: headingColor,
        boldColor: boldColor,
        codeColor: codeColor,
        linkColor: linkColor,
        defaultColor: defaultColor,
      );

      expect(result.children, isNotNull);
      final spans = result.children!.cast<TextSpan>();
      final linkSpan = spans.firstWhere((s) => s.style?.color == linkColor);
      expect(linkSpan.text, '[link](url)');
    });

    test('plain text uses default color', () {
      final result = MarkdownSyntaxHighlighter.highlight(
        'plain text',
        headingColor: headingColor,
        boldColor: boldColor,
        codeColor: codeColor,
        linkColor: linkColor,
        defaultColor: defaultColor,
      );

      expect(result.children, isNotNull);
      final spans = result.children!.cast<TextSpan>();
      final plainSpan = spans.firstWhere((s) => s.text == 'plain text');
      expect(plainSpan.style?.color, defaultColor);
    });
  });
}

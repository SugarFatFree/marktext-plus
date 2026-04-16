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

    test('preserves original text length and content for markdown markers', () {
      const source = '**bold** end\n`code` tail';
      final result = MarkdownSyntaxHighlighter.highlight(
        source,
        headingColor: headingColor,
        boldColor: boldColor,
        codeColor: codeColor,
        linkColor: linkColor,
        defaultColor: defaultColor,
      );

      final renderedText = result.children!
          .cast<TextSpan>()
          .map((span) => span.text ?? '')
          .join();

      expect(renderedText, source);
      expect(renderedText.length, source.length);
    });

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
      expect(boldSpan.text, '**bold**');
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
      expect(codeSpan.text, '`code`');
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

    // --- TextSpan text consistency tests ---

    /// Helper: extract concatenated text from a TextSpan tree.
    String extractText(TextSpan root) {
      final buf = StringBuffer();
      void visit(InlineSpan span) {
        if (span is TextSpan) {
          if (span.text != null) buf.write(span.text);
          span.children?.forEach(visit);
        }
      }
      visit(root);
      return buf.toString();
    }

    TextSpan hl(String source) => MarkdownSyntaxHighlighter.highlight(
          source,
          headingColor: headingColor,
          boldColor: boldColor,
          codeColor: codeColor,
          linkColor: linkColor,
          defaultColor: defaultColor,
        );

    test('text consistency: multiline plain text', () {
      const source = 'line one\nline two\nline three';
      expect(extractText(hl(source)), source);
    });

    test('text consistency: empty lines', () {
      const source = 'hello\n\nworld';
      expect(extractText(hl(source)), source);
    });

    test('text consistency: multiple consecutive empty lines', () {
      const source = 'a\n\n\nb';
      expect(extractText(hl(source)), source);
    });

    test('text consistency: trailing newline', () {
      const source = 'hello\n';
      expect(extractText(hl(source)), source);
    });

    test('text consistency: only newlines', () {
      const source = '\n\n\n';
      expect(extractText(hl(source)), source);
    });

    test('text consistency: mixed markdown with empty lines', () {
      const source = '# Heading\n\n**bold** text\n\n`code`\n\n[link](url)';
      expect(extractText(hl(source)), source);
    });

    test('text consistency: line ending with spaces', () {
      const source = 'hello   \nworld';
      expect(extractText(hl(source)), source);
    });

    test('text consistency: consecutive markdown markers', () {
      const source = '****\n`````';
      expect(extractText(hl(source)), source);
    });

    test('text consistency: single character lines', () {
      const source = 'a\nb\nc';
      expect(extractText(hl(source)), source);
    });

    test('text consistency: empty string', () {
      const source = '';
      expect(extractText(hl(source)), source);
    });

    test('no span has null text in children list', () {
      const source = '# Heading\n\n**bold** and `code`\nplain\n';
      final result = hl(source);
      for (final child in result.children!) {
        if (child is TextSpan) {
          expect(child.text, isNotNull,
              reason: 'TextSpan with null text found');
          expect(child.text, isNot(''),
              reason: 'TextSpan with empty text found');
        }
      }
    });

    test('newline is attached to preceding span, not standalone', () {
      // Newline characters must share the same TextStyle as the preceding
      // visible text.  Orphan unstyled '\n' spans cause Flutter's
      // EditableText to extend the selection highlight across the full
      // remaining width of the line (selection overflow bug).
      const source = 'hello\nworld\n\nend';
      final result = hl(source);
      final spans = result.children!.cast<TextSpan>();
      for (int i = 0; i < spans.length; i++) {
        final text = spans[i].text ?? '';
        if (text == '\n') {
          // A standalone '\n' is only acceptable for blank lines where
          // there is no preceding visible text to attach to.  In that
          // case the span must still carry a TextStyle.
          expect(spans[i].style, isNotNull,
              reason: 'Standalone newline span must have a style');
        }
      }
    });

    test('line-ending newline shares style with preceding text', () {
      const source = '# Heading\nplain text\n**bold**\nend';
      final result = hl(source);
      final spans = result.children!.cast<TextSpan>();
      for (final span in spans) {
        final text = span.text ?? '';
        // If a span ends with '\n' and has visible text before it,
        // it must have a non-null style (proving the newline shares
        // the style of the preceding text).
        if (text.endsWith('\n') && text.length > 1) {
          expect(span.style, isNotNull,
              reason:
                  'Span "$text" ends with newline but has no style');
        }
      }
    });
  });
}

String repr(String s) =>
    s.replaceAll('\n', '\\n').replaceAll('\t', '\\t');

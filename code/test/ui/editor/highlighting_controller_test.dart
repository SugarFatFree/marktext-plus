import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/highlighting_controller.dart';

void main() {
  group('HighlightingController.buildTextSpan', () {
    late HighlightingController controller;

    setUp(() {
      controller = HighlightingController(
        headingColor: Colors.blue,
        boldColor: Colors.red,
        codeColor: Colors.green,
        linkColor: Colors.purple,
        defaultColor: Colors.black,
      );
    });

    tearDown(() {
      controller.dispose();
    });

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

    testWidgets('buildTextSpan text matches controller.text', (tester) async {
      const source = '# Heading\n\n**bold** and `code`\nplain line\n';
      controller.text = source;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(builder: (context) {
          final span = controller.buildTextSpan(
            context: context,
            style: const TextStyle(),
            withComposing: false,
          );
          final rendered = extractText(span);
          expect(rendered, source);
          expect(rendered.length, source.length);
          return const SizedBox();
        })),
      ));
    });

    testWidgets('buildTextSpan text matches with search highlights',
        (tester) async {
      const source = 'hello world\nhello again';
      controller.text = source;
      controller.updateSearchMatches([
        const TextRange(start: 0, end: 5),
        const TextRange(start: 12, end: 17),
      ], 0);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(builder: (context) {
          final span = controller.buildTextSpan(
            context: context,
            style: const TextStyle(),
            withComposing: false,
          );
          final rendered = extractText(span);
          expect(rendered, source);
          expect(rendered.length, source.length);
          return const SizedBox();
        })),
      ));
    });

    testWidgets('search highlight keeps trailing newline attached to previous text',
        (tester) async {
      const source = '**bold**\nnext';
      controller.text = source;
      controller.updateSearchMatches([
        const TextRange(start: 2, end: 6),
      ], 0);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(builder: (context) {
          final span = controller.buildTextSpan(
            context: context,
            style: const TextStyle(),
            withComposing: false,
          );

          final rendered = extractText(span);
          expect(rendered, source);

          final children = span.children!.cast<TextSpan>().toList();
          expect(children.any((child) => child.text == '\n'), isFalse,
              reason: 'Trailing newline must not become a standalone span');
          expect(children.any((child) => (child.text ?? '').endsWith('\n')), isTrue,
              reason: 'Trailing newline should remain attached to previous text span');
          return const SizedBox();
        })),
      ));
    });

    testWidgets(
        'selection boxes for inline code at line end do not overflow',
        (tester) async {
      const source = 'prefix `code`\nnext line';
      controller.text = source;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(builder: (context) {
          final baseStyle = const TextStyle(fontSize: 14, fontFamily: 'Roboto');
          final span = controller.buildTextSpan(
            context: context,
            style: baseStyle,
            withComposing: false,
          );

          final painter = TextPainter(
            text: span,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: 800);

          final codeStart = source.indexOf('`code`');
          final codeEnd = codeStart + '`code`'.length;
          final boxes = painter.getBoxesForSelection(
            TextSelection(baseOffset: codeStart, extentOffset: codeEnd),
          );

          expect(boxes, isNotEmpty, reason: 'Should have selection boxes');
          for (final box in boxes) {
            final boxWidth = box.right - box.left;
            expect(boxWidth, lessThan(200),
                reason:
                    'Selection box width ${boxWidth.toStringAsFixed(1)} is '
                    'unreasonably large for inline code at line end');
          }

          painter.dispose();
          return const SizedBox();
        })),
      ));
    });

    testWidgets(
        'selection boxes for full highlighted block at line end do not overflow',
        (tester) async {
      const source = 'prefix **bold**\nnext line';
      controller.text = source;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(builder: (context) {
          final baseStyle = const TextStyle(fontSize: 14, fontFamily: 'Roboto');
          final span = controller.buildTextSpan(
            context: context,
            style: baseStyle,
            withComposing: false,
          );

          final painter = TextPainter(
            text: span,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: 800);

          final blockStart = source.indexOf('**bold**');
          final blockEnd = blockStart + '**bold**'.length;
          final boxes = painter.getBoxesForSelection(
            TextSelection(baseOffset: blockStart, extentOffset: blockEnd),
          );

          expect(boxes, isNotEmpty, reason: 'Should have selection boxes');
          for (final box in boxes) {
            final boxWidth = box.right - box.left;
            expect(boxWidth, lessThan(200),
                reason:
                    'Selection box width ${boxWidth.toStringAsFixed(1)} is '
                    'unreasonably large for full highlighted block at line end');
          }

          painter.dispose();
          return const SizedBox();
        })),
      ));
    });

    testWidgets(
        'selection boxes for highlighted text at line end do not overflow',
        (tester) async {
      const source = 'prefix **bold**\nnext line';
      controller.text = source;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(builder: (context) {
          final baseStyle = const TextStyle(fontSize: 14, fontFamily: 'Roboto');
          final span = controller.buildTextSpan(
            context: context,
            style: baseStyle,
            withComposing: false,
          );

          final painter = TextPainter(
            text: span,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: 800);

          final boldStart = source.indexOf('bold');
          final boldEnd = boldStart + 'bold'.length;
          final boxes = painter.getBoxesForSelection(
            TextSelection(baseOffset: boldStart, extentOffset: boldEnd),
          );

          expect(boxes, isNotEmpty, reason: 'Should have selection boxes');
          for (final box in boxes) {
            final boxWidth = box.right - box.left;
            expect(boxWidth, lessThan(200),
                reason:
                    'Selection box width ${boxWidth.toStringAsFixed(1)} is '
                    'unreasonably large for highlighted text at line end');
          }

          painter.dispose();
          return const SizedBox();
        })),
      ));
    });

    testWidgets(
        'selection boxes for line-end word do not extend beyond text width',
        (tester) async {
      // Simulates the exact scenario from the bug report: double-clicking
      // "Linux" at the end of a line should NOT produce a selection box
      // that extends far to the right of the word.
      const source = '**Platform**: Windows / macOS / Linux\nNext line';
      controller.text = source;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(builder: (context) {
          final baseStyle = const TextStyle(fontSize: 14, fontFamily: 'Roboto');
          final span = controller.buildTextSpan(
            context: context,
            style: baseStyle,
            withComposing: false,
          );

          // Use TextPainter to lay out the text and measure selection boxes
          final painter = TextPainter(
            text: span,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: 800);

          // Select "Linux" (characters 32..37 in the source)
          final linuxStart = source.indexOf('Linux');
          final linuxEnd = linuxStart + 'Linux'.length;
          final boxes = painter.getBoxesForSelection(
            TextSelection(baseOffset: linuxStart, extentOffset: linuxEnd),
          );

          expect(boxes, isNotEmpty, reason: 'Should have selection boxes');

          // All selection boxes must be within a reasonable width.
          // "Linux" in 14px font is roughly 30-50px wide.  If the bug is
          // present, the box extends to 800px (the layout width).
          for (final box in boxes) {
            final boxWidth = box.right - box.left;
            expect(boxWidth, lessThan(200),
                reason:
                    'Selection box width ${boxWidth.toStringAsFixed(1)} is '
                    'unreasonably large — selection highlight overflow');
          }

          painter.dispose();
          return const SizedBox();
        })),
      ));
    });
  });
}

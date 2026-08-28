import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/widgets/mermaid_diagram.dart';

/// A diagram wider than the space it is given.
///
/// The box was clamped to the available width while the painting inside kept
/// its full size, so a wide flowchart or sequence diagram simply had its
/// right-hand side cut off — with nothing to say so and no way to see the rest.
/// Upstream MarkText fixed the same fault by scaling the drawing down to fit
/// (#3560).
///
/// The check is for the scaling itself rather than for pixel sizes: the widget
/// is handed its width by the pane it sits in either way, so measuring that
/// would pass whether or not anything was cut off.
void main() {
  const wide = '''
sequenceDiagram
  Alice->>Bob: a reasonably long message number one
  Bob->>Carol: a reasonably long message number two
  Carol->>Dave: a reasonably long message number three
  Dave->>Erin: a reasonably long message number four
  Erin->>Frank: a reasonably long message number five
''';

  const narrow = 'flowchart TD\n  A --> B\n';

  Future<void> renderIn(WidgetTester tester, double width, String code) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: MermaidDiagram(code: code)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a diagram wider than its pane is scaled to fit', (tester) async {
    await renderIn(tester, 700, wide);

    expect(find.byType(FittedBox), findsOneWidget,
        reason: '没有缩放 —— 超出容器的部分会被裁掉');

    final box = tester.getSize(find.byType(FittedBox));
    expect(box.width, lessThanOrEqualTo(700.5),
        reason: '缩放之后仍然比容器宽');
  });

  testWidgets('a diagram that already fits is left exactly as it is',
      (tester) async {
    await renderIn(tester, 1200, narrow);

    // Nothing is scaled, so nothing can be blown up either: FittedBox with
    // BoxFit.contain would happily enlarge a small drawing to fill the pane.
    expect(find.byType(FittedBox), findsNothing);
  });

  testWidgets('the same diagram scales in a narrow pane and not in a wide one',
      (tester) async {
    await renderIn(tester, 700, wide);
    expect(find.byType(FittedBox), findsOneWidget);

    await renderIn(tester, 1600, wide);
    expect(find.byType(FittedBox), findsNothing,
        reason: '宽到放得下时不该再缩放');
  });
}

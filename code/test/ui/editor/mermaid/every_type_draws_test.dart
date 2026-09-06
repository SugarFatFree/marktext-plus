import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/mermaid.dart';

import '../../../support/mermaid_samples.dart';

/// Every diagram type the app claims, drawn.
///
/// The test beside this one checks that each type parses and reports itself
/// as the right type. Parsing is not drawing: laying a diagram out and
/// painting it is where the work is, and a type that parses and then throws
/// in its layout shows the reader an error box. Nothing covered that.
///
/// The samples are richer than the one-line headers next door on purpose —
/// nodes, edges and labels, so the painters have something to paint.
void main() {
  const samples = mermaidSamples;

  test('every implemented type has a sample here', () {
    final all = DiagramType.values.toSet()..remove(DiagramType.unknown);
    expect(all.difference(samples.keys.toSet()), isEmpty,
        reason: '新增了图型但这里没有样例，下面那条就漏掉了它');
  });

  for (final entry in samples.entries) {
    testWidgets('${entry.key.name} 能画出来', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? reported;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 700,
              child: MermaidDiagram(
                code: entry.value,
                onError: (message) => reported = message,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull,
          reason: '${entry.key.name} 在布局或绘制时抛了异常');
      expect(reported, isNull, reason: '${entry.key.name} 报错：$reported');

      // What the reader would be looking at: not the spinner, not the error
      // box, and something with area on the screen.
      //
      // Not "the painter is a MermaidPainter": only five of the twenty-two
      // painters extend that base — the rest are CustomPainters of their own —
      // so asking that would fail seventeen types that draw perfectly well.
      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: '${entry.key.name} 停在加载状态，没有画出来');
      final box = tester.renderObject<RenderBox>(
        find.byType(MermaidDiagram),
      );
      expect(box.size.width, greaterThan(0));
      expect(box.size.height, greaterThan(0));
      expect(tester.widgetList<CustomPaint>(find.byType(CustomPaint)),
          isNotEmpty,
          reason: '${entry.key.name} 的子树里没有任何画布');
    });
  }
}

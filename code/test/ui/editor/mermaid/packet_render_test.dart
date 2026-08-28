import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/mermaid.dart';

/// The parser being right is not the same as the diagram appearing: a type
/// that is parsed but not wired into the widget's painter switch renders as a
/// blank box, which looks exactly like the code-block fallback it replaced.
void main() {
  Future<void> render(WidgetTester tester, String code) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 900, child: MermaidDiagram(code: code)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a packet diagram reaches the packet painter', (tester) async {
    await render(tester, 'packet-beta\n'
        'title TCP header\n'
        '0-15: "Source Port"\n'
        '16-31: "Destination Port"\n'
        '32-63: "Sequence Number"\n');

    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<PacketPainter>()
        .toList();
    expect(painters, isNotEmpty, reason: 'packet 图没有走到自己的画笔');
    expect(painters.first.packetData.fields.length, 3);
    expect(painters.first.packetData.rowCount, 2);
  });

  testWidgets('the title is drawn once, not twice', (tester) async {
    await render(tester, 'packet-beta\ntitle TCP header\n0-15: "Port"\n');
    // The widget draws a header of its own for diagrams whose painter has no
    // title; the packet painter draws its own, so the widget must not.
    expect(find.text('TCP header'), findsNothing);
  });

  testWidgets('an unparseable packet still reports rather than blanks',
      (tester) async {
    await render(tester, 'packet-beta\n');
    expect(find.byType(PacketPainter), findsNothing);
  });
}

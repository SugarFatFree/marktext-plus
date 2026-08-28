import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/mermaid.dart';

/// `architecture-beta` was the last diagram type mermaid 11 draws that this
/// app did not: a document using it fell back to a plain code block.
void main() {
  ArchitectureDiagramData parse(String code) =>
      const MermaidParser().parseWithData(code)!.architectureData!;

  // The example from mermaid's own documentation.
  const docs = '''
architecture-beta
    group api(cloud)[API]

    service db(database)[Database] in api
    service disk1(disk)[Storage] in api
    service disk2(disk)[Storage] in api
    service server(server)[Server] in api

    db:L -- R:server
    disk1:T -- B:server
    disk2:T -- B:db
''';

  group('parsing', () {
    test('services, groups and edges are all read', () {
      final data = parse(docs);
      expect(data.groups.single.id, 'api');
      expect(data.groups.single.label, 'API');
      expect(data.groups.single.icon, 'cloud');
      expect(data.nodes.map((n) => n.id).toList(),
          ['db', 'disk1', 'disk2', 'server']);
      expect(data.nodes.first.icon, 'database');
      expect(data.nodes.every((n) => n.parent == 'api'), isTrue);
      expect(data.edges.length, 3);
      expect(data.edges.first.fromSide, ArchSide.left);
      expect(data.edges.first.toSide, ArchSide.right);
    });

    test('arrowheads are read from the arrow that was written', () {
      final data = parse('architecture-beta\n'
          'service a(server)[A]\n'
          'service b(server)[B]\n'
          'service c(server)[C]\n'
          'service d(server)[D]\n'
          'a:R -- L:b\n'
          'a:B --> T:c\n'
          'a:T <-- B:d\n');
      expect(data.edges[0].arrowAtFrom, isFalse);
      expect(data.edges[0].arrowAtTo, isFalse);
      expect(data.edges[1].arrowAtTo, isTrue);
      expect(data.edges[1].arrowAtFrom, isFalse);
      expect(data.edges[2].arrowAtFrom, isTrue);
    });

    test('an element written without a label is drawn with its id', () {
      final data = parse('architecture-beta\nservice lonely\n');
      expect(data.nodes.single.label, 'lonely');
      expect(data.nodes.single.icon, isNull);
    });

    test('a junction is a node but not a labelled one', () {
      final data = parse('architecture-beta\n'
          'group g[G]\n'
          'junction j in g\n');
      expect(data.nodes.single.isJunction, isTrue);
      expect(data.nodes.single.parent, 'g');
    });

    test('an endpoint may name a group', () {
      final data = parse('architecture-beta\n'
          'group left[L]\n'
          'group right[R]\n'
          'service a[A] in left\n'
          'service b[B] in right\n'
          'a:R --> L:right{group}\n');
      expect(data.edges.single.toIsGroup, isTrue);
      expect(data.edges.single.fromIsGroup, isFalse);
    });

    test('a header with nothing in it does not claim to have parsed', () {
      expect(const MermaidParser().parseWithData('architecture-beta\n'), isNull);
    });
  });

  group('layout', () {
    test('an edge decides which side of the other a node lands on', () {
      // `db:L -- R:server` says the server is to the *left* of the db, which
      // is the opposite of the order they were written in. Laying them out in
      // source order would draw a picture contradicting its own arrow.
      final result = const ArchitectureLayout().layout(parse(docs));
      final db = result.placementOf('db')!.rect;
      final server = result.placementOf('server')!.rect;
      expect(server.center.dx, lessThan(db.center.dx));
    });

    test('a T/B edge stacks the nodes vertically', () {
      final result = const ArchitectureLayout().layout(parse(docs));
      final disk1 = result.placementOf('disk1')!.rect;
      final server = result.placementOf('server')!.rect;
      // `disk1:T -- B:server` — the server is above the disk.
      expect(server.center.dy, lessThan(disk1.center.dy));
    });

    test('no two nodes are drawn on top of each other', () {
      final result = const ArchitectureLayout().layout(parse(docs));
      for (var i = 0; i < result.placements.length; i++) {
        for (var j = i + 1; j < result.placements.length; j++) {
          final a = result.placements[i];
          final b = result.placements[j];
          expect(a.rect.overlaps(b.rect), isFalse,
              reason: '${a.node.id} 与 ${b.node.id} 重叠了');
        }
      }
    });

    test('the group frame contains every one of its members', () {
      final result = const ArchitectureLayout().layout(parse(docs));
      final frame = result.groupBoxOf('api')!.rect;
      for (final placement in result.placements) {
        expect(frame.contains(placement.rect.topLeft), isTrue,
            reason: '${placement.node.id} 落在 API 框外');
        expect(frame.contains(placement.rect.bottomRight), isTrue,
            reason: '${placement.node.id} 落在 API 框外');
      }
    });

    test('two groups do not overlap', () {
      final data = parse('architecture-beta\n'
          'group left(cloud)[Left]\n'
          'group right(cloud)[Right]\n'
          'service a(disk)[A] in left\n'
          'service b(disk)[B] in left\n'
          'service c(disk)[C] in right\n'
          'a:B -- T:b\n'
          'a:R --> L:c\n');
      final result = const ArchitectureLayout().layout(data);
      final left = result.groupBoxOf('left')!.rect;
      final right = result.groupBoxOf('right')!.rect;
      expect(left.overlaps(right), isFalse);
    });

    test('nodes with no edges between them still get their own cells', () {
      final data = parse('architecture-beta\n'
          'service a[A]\n'
          'service b[B]\n'
          'service c[C]\n');
      final result = const ArchitectureLayout().layout(data);
      expect(result.placements.length, 3);
      for (var i = 0; i < 3; i++) {
        for (var j = i + 1; j < 3; j++) {
          expect(result.placements[i].rect
              .overlaps(result.placements[j].rect), isFalse);
        }
      }
    });

    test('the reported size covers everything drawn', () {
      final result = const ArchitectureLayout().layout(parse(docs));
      final bounds = Offset.zero & result.size;
      for (final placement in result.placements) {
        expect(bounds.contains(placement.rect.bottomRight), isTrue);
      }
      for (final box in result.groupBoxes) {
        expect(bounds.contains(box.rect.bottomRight), isTrue);
      }
    });
  });

  group('rendering', () {
    testWidgets('an architecture diagram reaches its own painter',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 900, child: MermaidDiagram(code: docs)),
            ),
          ),
        ),
      );
      await tester.pump();

      final painters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<ArchitecturePainter>()
          .toList();
      expect(painters, isNotEmpty, reason: 'architecture 图没有走到自己的画笔');
      expect(painters.first.layout.placements.length, 4);
    });
  });
}

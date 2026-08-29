import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/mermaid.dart';

/// `treemap-beta`, the last diagram type mermaid 11 draws that this app did
/// not implement. The grammar was read out of mermaid 11.16's own definition
/// rather than guessed: `INDENTATION` is `[ \t]+` and its length nests a row,
/// `STRING2` is a quoted name, and `NUMBER2` is `[0-9_.,]+` read with the
/// commas taken out.
void main() {
  TreemapDiagramData parse(String code) =>
      const MermaidParser().parseWithData(code)!.treemapData!;

  group('parsing', () {
    test('indentation is what nests a row', () {
      final data = parse('treemap-beta\n'
          '"Root"\n'
          '    "Section A"\n'
          '        "Leaf A1": 10\n'
          '        "Leaf A2": 20\n'
          '    "Section B"\n'
          '        "Leaf B1": 15\n');

      expect(data.roots.length, 1);
      final root = data.roots.single;
      expect(root.name, 'Root');
      expect(root.children.map((c) => c.name), ['Section A', 'Section B']);
      expect(root.children.first.children.map((c) => c.name),
          ['Leaf A1', 'Leaf A2']);
    });

    test("a section's area is what is underneath it", () {
      final data = parse('treemap-beta\n'
          '"Root"\n'
          '    "A"\n'
          '        "A1": 10\n'
          '        "A2": 20\n'
          '    "B": 30\n');
      expect(data.roots.single.children.first.total, 30);
      expect(data.total, 60);
    });

    test('a value may carry thousands separators', () {
      // NUMBER2 is `[0-9_.,]+`, read with the commas removed. Left in, this
      // would not parse at all and the box would be drawn with no area.
      final data = parse('treemap-beta\n"Root"\n    "Big": 1,024\n');
      expect(data.roots.single.children.single.value, 1024);
    });

    test('a class selector is read off the item', () {
      final data = parse('treemap-beta\n'
          '"Root"\n'
          '    "Tagged": 5:::important\n'
          'classDef important fill:#f9f\n');
      expect(data.roots.single.children.single.classSelector, 'important');
      expect(data.classStyles['important'], 'fill:#f9f');
    });

    test('single quotes work as well as double', () {
      final data = parse("treemap-beta\n'Root'\n    'Leaf': 3\n");
      expect(data.roots.single.name, 'Root');
    });

    test('a title is read and the widget is told not to draw it twice', () {
      final result = const MermaidParser()
          .parseWithData('treemap-beta\ntitle Budget\n"Root"\n    "A": 1\n')!;
      expect(result.treemapData!.title, 'Budget');
      expect(result.hasOwnTitle, isTrue);
    });

    test('a header with nothing under it does not claim to have parsed', () {
      expect(const MermaidParser().parseWithData('treemap-beta\n'), isNull);
    });

    test('the suffix-less spelling is recognised too', () {
      expect(parse('treemap\n"Root"\n    "A": 1\n').roots.length, 1);
    });
  });

  group('layout', () {
    const size = Size(600, 400);

    TreemapLayoutResult layoutOf(String code) =>
        const TreemapLayout().layout(parse(code), size);

    const sample = 'treemap-beta\n'
        '"Root"\n'
        '    "A"\n'
        '        "A1": 40\n'
        '        "A2": 30\n'
        '    "B": 20\n'
        '    "C": 10\n';

    test('every node gets a box, and none of them escapes the canvas', () {
      final result = layoutOf(sample);
      expect(result.tiles.length, 6);
      final bounds = Offset.zero & size;
      for (final tile in result.tiles) {
        expect(bounds.contains(tile.rect.topLeft), isTrue,
            reason: '${tile.node.name} 出界');
        expect(bounds.inflate(0.5).contains(tile.rect.bottomRight), isTrue,
            reason: '${tile.node.name} 出界');
      }
    });

    test('siblings do not overlap', () {
      final result = layoutOf(sample);
      final leaves = result.tiles.where((t) => t.node.isLeaf).toList();
      for (var i = 0; i < leaves.length; i++) {
        for (var j = i + 1; j < leaves.length; j++) {
          final a = leaves[i].rect.deflate(0.5);
          final b = leaves[j].rect.deflate(0.5);
          expect(a.overlaps(b), isFalse,
              reason: '${leaves[i].node.name} 与 ${leaves[j].node.name} 重叠');
        }
      }
    });

    test('a bigger value gets a bigger box', () {
      // This is the whole point of a treemap: area stands for value.
      final result = layoutOf(sample);
      double areaOf(String name) => result.tiles
          .firstWhere((t) => t.node.name == name)
          .rect
          .let((r) => r.width * r.height);

      expect(areaOf('A1'), greaterThan(areaOf('A2')));
      expect(areaOf('B'), greaterThan(areaOf('C')));
    });

    test('boxes are kept close to square, not sliced into slivers', () {
      // Slicing alternately by row and column is the easy way and produces
      // shapes whose areas cannot be compared by eye — which is the one thing
      // the chart is for.
      final result = layoutOf(sample);
      for (final tile in result.tiles.where((t) => t.node.isLeaf)) {
        final ratio = math.max(
          tile.rect.width / tile.rect.height,
          tile.rect.height / tile.rect.width,
        );
        expect(ratio, lessThan(6.0),
            reason: '${tile.node.name} 被压成了 ${ratio.toStringAsFixed(1)}:1 的细条');
      }
    });

    test('a child is drawn inside its parent', () {
      final result = layoutOf(sample);
      final a = result.tiles.firstWhere((t) => t.node.name == 'A').rect;
      for (final name in ['A1', 'A2']) {
        final child =
            result.tiles.firstWhere((t) => t.node.name == name).rect;
        expect(a.inflate(0.5).contains(child.topLeft), isTrue, reason: name);
        expect(a.inflate(0.5).contains(child.bottomRight), isTrue,
            reason: name);
      }
    });

    test('nodes with no values still get boxes rather than vanishing',
        () {
      final result = layoutOf('treemap-beta\n"Root"\n    "A"\n    "B"\n');
      expect(result.tiles.length, 3);
      for (final tile in result.tiles) {
        expect(tile.rect.width, greaterThan(0));
        expect(tile.rect.height, greaterThan(0));
      }
    });
  });

  group('rendering', () {
    testWidgets('a treemap reaches its own painter', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 800,
                child: MermaidDiagram(
                  code: 'treemap-beta\n'
                      'title Budget\n'
                      '"Root"\n'
                      '    "A": 40\n'
                      '    "B": 20\n',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final painters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<TreemapPainter>()
          .toList();
      expect(painters, isNotEmpty, reason: 'treemap 没有走到自己的画笔');
      expect(painters.first.layout.tiles.length, 3);
    });
  });
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

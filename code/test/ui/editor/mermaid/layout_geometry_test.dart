import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/mermaid.dart';
import 'package:marktext_plus/utils/text_width.dart';

/// What the layout puts on the canvas, rather than what the parser read.
///
/// Every diagram type parses and fills its own model — that is checked
/// elsewhere. This is the half after it: boxes that overlap, coordinates off
/// the canvas, or a label wider than the box drawn around it are all "the
/// diagram renders wrong" to whoever is looking at it, and all of them pass a
/// parser test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final parser = MermaidParser();
  const style = MermaidStyle();

  /// Lays [source] out and returns the diagram with its geometry filled in.
  (MermaidDiagramData, Size) layout(String source) {
    final diagram = parser.parse(source);
    expect(diagram, isNotNull, reason: '解析失败：$source');
    final size =
        DagreLayout().computeLayout(diagram!, style, const Size(800, 600));
    return (diagram, size);
  }

  group('the boxes land somewhere sensible', () {
    const shapes = <String, String>{
      'a straight chain': 'graph TD\n A --> B\n B --> C\n',
      'a fan out': 'graph TD\n A --> B\n A --> C\n A --> D\n A --> E\n',
      'a fan in': 'graph TD\n B --> A\n C --> A\n D --> A\n',
      'a diamond': 'graph TD\n A --> B\n A --> C\n B --> D\n C --> D\n',
      'left to right': 'graph LR\n A --> B --> C --> D\n',
      'a self loop': 'graph TD\n A --> A\n A --> B\n',
      'a cycle': 'graph TD\n A --> B\n B --> C\n C --> A\n',
      'mixed shapes': 'graph TD\n A[方] --> B{菱}\n B --> C((圆))\n',
      'a wide fan': 'graph TD\n R --> A\n R --> B\n R --> C\n R --> D\n'
          ' R --> E\n R --> F\n R --> G\n R --> H\n',
      'a deep chain': 'graph TD\n A --> B\n B --> C\n C --> D\n D --> E\n'
          ' E --> F\n F --> G\n G --> H\n H --> I\n',
    };

    shapes.forEach((name, source) {
      test('$name has no overlapping boxes and stays on the canvas', () {
        final (diagram, size) = layout(source);
        expect(size.width, greaterThan(0));
        expect(size.height, greaterThan(0));

        for (final node in diagram.nodes) {
          expect(node.width, greaterThan(0), reason: '${node.id} 宽度为零');
          expect(node.height, greaterThan(0), reason: '${node.id} 高度为零');
          expect(node.x, greaterThanOrEqualTo(-1), reason: '${node.id} x 为负');
          expect(node.y, greaterThanOrEqualTo(-1), reason: '${node.id} y 为负');
          expect(node.x + node.width, lessThanOrEqualTo(size.width + 1),
              reason: '${node.id} 超出画布右侧');
          expect(node.y + node.height, lessThanOrEqualTo(size.height + 1),
              reason: '${node.id} 超出画布底部');
        }

        for (var i = 0; i < diagram.nodes.length; i++) {
          for (var j = i + 1; j < diagram.nodes.length; j++) {
            final a = diagram.nodes[i];
            final b = diagram.nodes[j];
            final overlapX =
                math.min(a.x + a.width, b.x + b.width) - math.max(a.x, b.x);
            final overlapY =
                math.min(a.y + a.height, b.y + b.height) - math.max(a.y, b.y);
            expect(overlapX > 1 && overlapY > 1, isFalse,
                reason: '${a.id} 与 ${b.id} 的方框重叠了');
          }
        }
      });
    });

    test('every edge joins two boxes that exist', () {
      final (diagram, _) = layout(
          'graph TD\n A --> B\n B --> C\n subgraph S\n  D --> E\n end\n C --> D\n');
      final ids = diagram.nodes.map((n) => n.id).toSet();
      for (final edge in diagram.edges) {
        expect(ids, contains(edge.from));
        expect(ids, contains(edge.to));
      }
    });
  });

  group('a label fits inside the box drawn around it', () {
    // The width was measured with `char > 0x4E00 && char < 0x9FFF`, so Chinese
    // came out right and Japanese kana, Korean Hangul, fullwidth punctuation
    // and the CJK extension blocks were all counted at six tenths of an em —
    // a little over half their real width. The label is painted at its
    // natural width with no maxWidth, so it neither wrapped nor clipped: it
    // hung out over the border of its own node.
    //
    // The labels below are sentences rather than words on purpose. A short
    // one is rescued by the padding around it, which is why this was not
    // visible on `A[中文]`.
    for (final label in [
      '这是一个相当长的中文标签用来测试',
      'ひらがなとカタカナのながいラベルです',
      '한국어로 된 긴 라벨입니다 정말로',
      '（全角括号）と［全角］の混在ラベル',
      '扩展汉字㐀㐁㐂㐃㐄㐅㐆㐇㐈㐉㐊㐋',
      'An English label of some length here',
    ]) {
      test('"$label" is not wider than its node', () {
        final (diagram, _) = layout('graph TD\n A[$label] --> B[b]\n');
        final node = diagram.nodes.firstWhere((n) => n.id == 'A');
        final needed =
            estimatedTextWidth(label, style.defaultNodeStyle.fontSize);
        expect(node.width, greaterThanOrEqualTo(needed),
            reason: '方框 ${node.width} 装不下约 $needed 宽的文字，标签会伸出边框');
      });
    }
  });
}

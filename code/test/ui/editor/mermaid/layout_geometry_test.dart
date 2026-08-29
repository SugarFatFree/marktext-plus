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

  group('the space reserved for a label is enough for a CJK one', () {
    // Five places measured text by character count times a fixed ratio —
    // 0.5, 0.6 or 0.7 depending on where. All of them are short for CJK,
    // which is about one em per character, and each one decides how much room
    // a label gets: a node's box, an edge's gap, a Gantt row's left column, a
    // pie chart's legend. Too little room does not clip anything here; the
    // text is drawn anyway, over whatever is beside it.

    /// The width the layout gave the widest thing it had to fit.
    double widestNode(MermaidDiagramData d) =>
        d.nodes.map((n) => n.width).fold<double>(0, math.max);

    test('a flowchart edge label gets room for its characters', () {
      const label = '这是一条相当长的中文连线标签';
      final (diagram, size) = layout('graph TD\n A -->|$label| B\n');
      // The label sits between the ranks, so the canvas has to be at least as
      // wide as the label needs — capped by the wrap width the layout uses.
      final needed = math.min(
        estimatedTextWidth(label, style.defaultEdgeStyle.labelFontSize),
        120.0,
      );
      expect(size.width, greaterThanOrEqualTo(needed),
          reason: '画布 ${size.width} 容不下约 $needed 宽的连线标签');
      expect(widestNode(diagram), greaterThan(0));
    });

    test('a sequence message in Chinese gets more room than Latin of the '
        'same length', () async {
      // Same number of characters, so the only thing that can move the answer
      // is the per-character width. Comparing a short message with a long one
      // would pass under any ratio at all.
      final (_, latin) = layout('sequenceDiagram\nA->>B: abcdefghijklmn\n');
      final (_, cjk) = layout('sequenceDiagram\nA->>B: 这是一条中文消息内容测试甲\n');
      expect(cjk.width, greaterThan(latin.width),
          reason: '同样 14 个字符，中文没有换来更宽的间距，消息会压到生命线上');
    });

    // The Gantt chart's label column and the pie chart's legend are measured
    // inside their painters, not by a layout that returns a size, so there is
    // nothing to assert about them from here. What changed in both is which
    // function they ask, and that function is checked directly below.
    test('the shared measurement charges CJK about an em and Latin about '
        'half', () {
      const fontSize = 14.0;
      // Fourteen characters either way, so only the per-character width can
      // separate them.
      final latin = estimatedTextWidth('abcdefghijklmn', fontSize);
      final chinese = estimatedTextWidth('这是一条中文消息内容测试甲', fontSize);
      expect(chinese, greaterThan(latin * 1.5),
          reason: '中文没有被算得更宽，靠它留白的地方都会不够');

      // The blocks that used to fall through to the narrow case.
      for (final wide in ['ひらがな', '한국어입니다', '（全角）', '㐀㐁㐂']) {
        expect(estimatedTextWidth(wide, fontSize),
            estimatedTextWidth('中' * wide.length, fontSize),
            reason: '$wide 没有被当作宽字符');
      }
      expect(estimatedTextWidth('一', fontSize), fontSize,
          reason: '边界字符 一 被漏掉了');
    });
  });
}

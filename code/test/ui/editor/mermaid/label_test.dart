import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/layout/dagre_layout.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/style.dart';
import 'package:marktext_plus/ui/editor/mermaid/parser/label.dart';
import 'package:marktext_plus/ui/editor/mermaid/parser/mermaid_parser.dart';

/// What a diagram writes between its delimiters, and what should be drawn.
///
/// Each parser used to do part of this job: node labels lost their quotes,
/// edge labels kept them, and nothing understood `<br/>` — the way every
/// mermaid document wraps text inside a box — so the tag was drawn as five
/// characters in the middle of the node.
void main() {
  const parser = MermaidParser();

  String labelOf(String source, String id) =>
      parser.parse(source)!.nodes.firstWhere((n) => n.id == id).label;

  String? edgeLabelOf(String source) => parser.parse(source)!.edges.first.label;

  group('cleanLabel', () {
    test('turns every spelling of a line break into one', () {
      for (final tag in ['<br>', '<br/>', '<br />', '<BR>', '<Br/>']) {
        expect(cleanLabel('a${tag}b'), 'a\nb', reason: '$tag 没有变成换行');
      }
    });

    test('drops the quotes that delimit a label', () {
      expect(cleanLabel('"with [brackets]"'), 'with [brackets]');
      expect(cleanLabel("'single'"), 'single');
      expect(cleanLabel('no quotes'), 'no quotes');
    });

    test('keeps a quote that is part of the text', () {
      expect(cleanLabel(r'say \"hi\"'), 'say "hi"');
    });

    test('decodes the entities a diagram carries', () {
      expect(cleanLabel('a &amp; b'), 'a & b');
      expect(cleanLabel('&lt;tag&gt;'), '<tag>');
      expect(cleanLabel('&quot;q&quot;'), '"q"');
    });

    test('decodes an escaped ampersand without going round twice', () {
      // `&amp;` is decoded last: doing it first turns `&amp;lt;` into `<`,
      // which is not what the author wrote.
      expect(cleanLabel('&amp;lt;'), '&lt;');
    });

    test('an absent label is empty, not the word null', () {
      expect(cleanLabel(null), '');
    });
  });

  group('through the parser', () {
    test('a node label breaks where the source says', () {
      expect(labelOf('flowchart TD\nA[one<br/>two] --> B\n', 'A'), 'one\ntwo');
    });

    test('an edge label loses its quotes, as a node label already did', () {
      expect(edgeLabelOf('flowchart TD\nA -- "spoken" --> B\n'), 'spoken');
      expect(labelOf('flowchart TD\nA["spoken"] --> B\n', 'A'), 'spoken');
    });

    test('an edge with no label has none, rather than an empty one', () {
      // The painter draws a background wherever there is a label, and an
      // empty one left a box floating on the line.
      expect(edgeLabelOf('flowchart TD\nA --> B\n'), isNull);
    });
  });

  group('every diagram type, not just the flowchart', () {
    // Only the flowchart parser cleaned its labels. Every other type drew the
    // tag: a sequence message, a state transition, a class name, an ER
    // relationship, a pie slice, a gantt task — all of them.
    const withBreak = {
      '时序 消息': 'sequenceDiagram\nA->>B: one<br/>two\n',
      '时序 参与者': 'sequenceDiagram\nparticipant A as one<br/>two\nA->>A: x\n',
      '状态 转换': 'stateDiagram-v2\n[*] --> S\nS --> T : one<br/>two\n',
      '状态 描述': 'stateDiagram-v2\nstate "one<br/>two" as S\nS --> [*]\n',
      '类图 类名': 'classDiagram\nclass A["one<br/>two"]\n',
      'ER 关系': 'erDiagram\nA ||--o{ B : one<br/>two\n',
      '流程图': 'flowchart TD\nA[one<br/>two] --> B\n',
    };

    for (final entry in withBreak.entries) {
      test('${entry.key} 的标签不再留着标签文字', () {
        final result = parser.parseWithData(entry.value)!;
        final texts = [
          ...result.diagram.nodes.map((n) => n.label),
          ...result.diagram.edges.map((e) => e.label ?? ''),
        ];

        expect(texts.where((t) => t.contains('<br')), isEmpty,
            reason: '${entry.key} 把 <br/> 当成文字画了出来');
        expect(texts.any((t) => t.contains('\n')), isTrue,
            reason: '${entry.key} 没有换行');
      });
    }

    test('a pie slice breaks too', () {
      final pie = parser
          .parseWithData('pie title t\n"one<br/>two" : 40\n"x" : 60\n')!
          .pieChartData!;
      expect(pie.slices.first.label, 'one\ntwo');
    });

    test('a gantt task breaks too', () {
      final gantt = parser
          .parseWithData('gantt\nsection S\none<br/>two :a1, 2024-01-01, 3d\n')!
          .ganttChartData!;
      expect(gantt.tasks.first.name, 'one\ntwo');
    });
  });

  group('a node is measured for the lines it holds', () {
    Size sizeOf(String label) {
      final diagram = parser.parse('flowchart TD\nA[$label] --> B\n')!;
      DagreLayout()
          .computeLayout(diagram, const MermaidStyle(), const Size(900, 700));
      final node = diagram.nodes.firstWhere((n) => n.id == 'A');
      return Size(node.width, node.height);
    }

    test('two lines are taller and narrower than one long one', () {
      // Measuring the whole string as a single line made the box far too
      // wide and one line too short, so the second line fell outside it.
      final one = sizeOf('firstsecond');
      final two = sizeOf('first<br/>second');

      expect(two.height, greaterThan(one.height));
      expect(two.width, lessThan(one.width));
    });

    test('height grows with each line', () {
      expect(sizeOf('a<br/>b<br/>c').height, greaterThan(sizeOf('a<br/>b').height));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/parser/mermaid_parser.dart';

/// Inputs that are valid enough to parse but degenerate enough to divide by
/// zero, index an empty list, or lay out an infinite box.
///
/// A diagram that throws here takes the whole preview down with it, so the bar
/// is only that layout completes and reports a finite, non-negative size.
void main() {
  const parser = MermaidParser();

  /// Every diagram type, at its most degenerate.
  const degenerate = <String, String>{
    'flowchart, one node': 'flowchart TD\n  A',
    'flowchart, self loop': 'flowchart TD\n  A --> A',
    'flowchart, long label': 'flowchart TD\n'
        '  A[a label long enough to force the node wider than any sane '
        'diagram would need it to be] --> B',
    'sequence, one message': 'sequenceDiagram\n  A->>B: hi',
    'class, no members': 'classDiagram\n  class Empty',
    'class, one relation': 'classDiagram\n  A <|-- B',
    'er, one entity': 'erDiagram\n  CUSTOMER {\n    string name\n  }',
    'er, no attributes': 'erDiagram\n  A ||--o{ B : has',
    'journey, one task': 'journey\n  section S\n    Task: 3',
    'git, one commit': 'gitGraph\n  commit',
    'mindmap, root only': 'mindmap\n  root((only))',
    'mindmap, deep chain':
        'mindmap\n  root\n    a\n      b\n        c\n          d',
    'pie, one slice': 'pie\n  "One" : 1',
    'gantt, one task':
        'gantt\n  dateFormat YYYY-MM-DD\n  section S\n    T :a1, 2026-01-01, 1d',
    'timeline, one event': 'timeline\n  2020 : Something',
    'kanban, empty column': 'kanban\n  Todo',
    'state, single transition': 'stateDiagram-v2\n  [*] --> Done',
  };

  group('Degenerate diagrams still lay out', () {
    degenerate.forEach((name, source) {
      test(name, () {
        final result = parser.parseWithData(source);
        expect(result, isNotNull, reason: '$name did not parse');

        // Parsing is the half that has tests elsewhere; what matters here is
        // that nothing throws and the reported size is usable.
        final diagram = result!.diagram;
        expect(diagram.type.toString(), isNotEmpty);

        for (final node in diagram.nodes) {
          expect(node.width, greaterThanOrEqualTo(0));
          expect(node.height, greaterThanOrEqualTo(0));
          expect(node.x.isFinite, isTrue, reason: '$name has a non-finite x');
          expect(node.y.isFinite, isTrue, reason: '$name has a non-finite y');
        }
      });
    });
  });

  group('Malformed input is rejected rather than crashing', () {
    const malformed = <String>[
      'flowchart TD',
      'classDiagram',
      'erDiagram',
      'journey',
      'gitGraph',
      'mindmap',
      'sequenceDiagram',
      'kanban',
      '',
      '   ',
      'graph TD\n  -->',
      'classDiagram\n  <|--',
      'erDiagram\n  ||--o{',
    ];

    for (final source in malformed) {
      test('"${source.replaceAll('\n', ' / ')}"', () {
        // Either a diagram or null, but never an exception: the renderer shows
        // a parse error for null, and a thrown one would break the preview.
        expect(() => parser.parseWithData(source), returnsNormally);
      });
    }
  });
}

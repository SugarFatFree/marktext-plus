import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/mermaid.dart';

/// The list of diagram types this app says it supports.
///
/// It is not decoration: `handlesLanguage` is derived from it, so a fence
/// tagged with a type missing from the list is drawn as a plain code block
/// rather than a diagram, and the "unrecognised type" message shows it to the
/// reader verbatim — telling them the app cannot draw something it can.
///
/// `packet-beta` and `architecture-beta` were both implemented and both left
/// out of it. The comment above the list says implementing a type cannot
/// leave the two disagreeing; it could, and it did, twice.
void main() {
  const parser = MermaidParser();

  /// One sample per type, enough for the header line to be recognised.
  const headers = <DiagramType, String>{
    DiagramType.flowchart: 'flowchart TD\n  A-->B\n',
    DiagramType.sequence: 'sequenceDiagram\n  A->>B: hi\n',
    DiagramType.classDiagram: 'classDiagram\n  A <|-- B\n',
    DiagramType.stateDiagram: 'stateDiagram-v2\n  [*] --> S\n',
    DiagramType.erDiagram: 'erDiagram\n  A ||--o{ B : has\n',
    DiagramType.journey: 'journey\n  title T\n  section S\n    Task: 5: Me\n',
    DiagramType.gitGraph: 'gitGraph\n  commit\n',
    DiagramType.mindmap: 'mindmap\n  root((core))\n    Leaf\n',
    DiagramType.pieChart: 'pie title T\n  "A" : 1\n',
    DiagramType.ganttChart:
        'gantt\n  dateFormat YYYY-MM-DD\n  section S\n  A :a1, 2014-01-01, 30d\n',
    DiagramType.timeline: 'timeline\n  title T\n  2002 : X\n',
    DiagramType.kanban: 'kanban\n  Todo\n    t1[Create]\n',
    DiagramType.radar: 'radar-beta\n  axis a["A"], b["B"]\n  curve x["X"]{1,2}\n',
    DiagramType.xyChart: 'xychart-beta\n  x-axis [jan]\n  bar [30]\n',
    DiagramType.quadrantChart:
        'quadrantChart\n  x-axis Low --> High\n  y-axis Low --> High\n  A: [0.3, 0.6]\n',
    DiagramType.requirementDiagram:
        'requirementDiagram\n  requirement r {\n  id: 1\n  text: t\n  risk: high\n  verifymethod: test\n  }\n',
    DiagramType.sankey: 'sankey-beta\n\nA,B,1\n',
    DiagramType.blockDiagram: 'block-beta\n  columns 1\n  a\n',
    DiagramType.c4Diagram: 'C4Context\n  Person(a, "U", "d")\n',
    DiagramType.packet: 'packet-beta\n  0-15: "Port"\n',
    DiagramType.architecture:
        'architecture-beta\n  service db(database)[DB]\n',
    DiagramType.treemap: 'treemap-beta\n  "Root"\n    "Leaf": 10\n',
  };

  test('every implemented type has a sample here', () {
    final covered = headers.keys.toSet();
    final all = DiagramType.values.toSet()..remove(DiagramType.unknown);
    expect(all.difference(covered), isEmpty,
        reason: '新增了图型但这张表没跟上，下面几条就形同虚设');
  });

  test('every implemented type is named in the supported list', () {
    // The list is what the reader is shown and what the fence tag is matched
    // against; a type missing from it is a type the app quietly disowns.
    final listed = MermaidParser.supportedTypes
        .expand((entry) => entry.split(' / '))
        .map((name) => name.trim().toLowerCase())
        .toSet();

    for (final entry in headers.entries) {
      final header = entry.value.split('\n').first.split(RegExp(r'[\s;]')).first;
      expect(listed, contains(header.toLowerCase()),
          reason: '${entry.key.name} 已实现，但支持列表里没有 "$header"');
    }
  });

  test('a fence tagged with the bare type name is drawn as a diagram', () {
    for (final entry in headers.entries) {
      final header = entry.value.split('\n').first.split(RegExp(r'[\s;]')).first;
      expect(MermaidParser.handlesLanguage(header), isTrue,
          reason: '```$header 会被当成普通代码块，而不是图');
    }
  });

  test('every listed type actually parses', () {
    // A state diagram comes back as a flowchart on purpose: it is drawn with
    // the flowchart's layout and painter, so that is the shape it carries.
    // Every other type reports itself.
    const drawnAs = {DiagramType.stateDiagram: DiagramType.flowchart};

    for (final entry in headers.entries) {
      final result = parser.parseWithData(entry.value);
      expect(result, isNotNull, reason: '${entry.key.name} 解析不出来');
      expect(result!.diagram.type, drawnAs[entry.key] ?? entry.key,
          reason: '${entry.key.name} 的表头被识别成了别的类型');
    }
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/mermaid.dart';

/// Every keyword and arrow mermaid's sequence grammar defines.
///
/// The keyword list is mermaid 11.16's own, not a guess. Checking them one by
/// one turned up `A<<->>B`: the sender pattern did not exclude `<`, so it
/// greedily became `A<<` — a participant nobody wrote got a lifeline of its
/// own, and the arrow lost the head at its near end.
void main() {
  const parser = MermaidParser();

  MermaidDiagramData diagram(String code) => parser.parse(code)!;

  group('arrows', () {
    const forms = <String, (ArrowType, LineType)>{
      '->': (ArrowType.arrow, LineType.solid),
      '-->': (ArrowType.arrow, LineType.dotted),
      '->>': (ArrowType.arrow, LineType.solid),
      '-->>': (ArrowType.arrow, LineType.dotted),
      '-x': (ArrowType.cross, LineType.solid),
      '--x': (ArrowType.cross, LineType.dotted),
      '-)': (ArrowType.arrow, LineType.solid),
      '--)': (ArrowType.arrow, LineType.dotted),
      '<<->>': (ArrowType.arrow, LineType.solid),
      '<<-->>': (ArrowType.arrow, LineType.dotted),
    };

    test('each form connects exactly the two participants written', () {
      for (final entry in forms.entries) {
        final d = diagram('sequenceDiagram\n  A${entry.key}B: msg\n');
        expect(d.nodes.map((n) => n.id).toList(), ['A', 'B'],
            reason: '${entry.key} 造出了写在图里没有的参与者');
        expect(d.edges.single.from, 'A', reason: entry.key);
        expect(d.edges.single.to, 'B', reason: entry.key);
      }
    });

    test('the line and the head are read from the form', () {
      for (final entry in forms.entries) {
        final edge = diagram('sequenceDiagram\n  A${entry.key}B: msg\n')
            .edges
            .single;
        expect(edge.arrowType, entry.value.$1, reason: entry.key);
        expect(edge.lineType, entry.value.$2, reason: entry.key);
      }
    });

    test('only the `<<` forms are bidirectional', () {
      for (final entry in forms.entries) {
        final edge = diagram('sequenceDiagram\n  A${entry.key}B: msg\n')
            .edges
            .single;
        expect(edge.bidirectional, entry.key.startsWith('<<'),
            reason: '${entry.key} 的双向标记读错了，画出来两端不一致');
      }
    });

    test('the label survives, whatever the arrow', () {
      for (final form in forms.keys) {
        expect(diagram('sequenceDiagram\n  A${form}B: hello there\n')
            .edges
            .single
            .label,
            'hello there',
            reason: form);
      }
    });
  });

  group('keywords', () {
    // mermaid 11.16's own keyword set for this diagram type.
    const samples = <String, String>{
      'participant': 'sequenceDiagram\n  participant A\n  participant B\n  A->>B: hi\n',
      'as': 'sequenceDiagram\n  participant A as Alice\n  A->>A: hi\n',
      'actor': 'sequenceDiagram\n  actor A\n  A->>A: hi\n',
      'create': 'sequenceDiagram\n  A->>B: hi\n  create participant C\n  A->>C: hello\n',
      'destroy': 'sequenceDiagram\n  A->>B: hi\n  destroy B\n',
      'box': 'sequenceDiagram\n  box Group\n  participant A\n  end\n  A->>A: hi\n',
      'activate': 'sequenceDiagram\n  A->>B: hi\n  activate B\n  B-->>A: ok\n  deactivate B\n',
      'note': 'sequenceDiagram\n  A->>B: hi\n  Note right of B: text\n',
      'note over': 'sequenceDiagram\n  A->>B: hi\n  Note over A,B: text\n',
      'loop': 'sequenceDiagram\n  loop Every minute\n    A->>B: ping\n  end\n',
      'alt/else': 'sequenceDiagram\n  alt ok\n    A->>B: yes\n  else no\n    A->>B: no\n  end\n',
      'opt': 'sequenceDiagram\n  opt maybe\n    A->>B: hi\n  end\n',
      'par/and': 'sequenceDiagram\n  par one\n    A->>B: a\n  and two\n    A->>C: b\n  end\n',
      'critical/option': 'sequenceDiagram\n  critical set up\n    A->>B: a\n  option fail\n    A->>B: b\n  end\n',
      'break': 'sequenceDiagram\n  A->>B: hi\n  break oops\n    A->>B: err\n  end\n',
      'rect': 'sequenceDiagram\n  rect rgb(200,200,255)\n    A->>B: hi\n  end\n',
      'autonumber': 'sequenceDiagram\n  autonumber\n  A->>B: hi\n',
      'title': 'sequenceDiagram\n  title My flow\n  A->>B: hi\n',
      'links': 'sequenceDiagram\n  participant A\n  links A: {"Dash": "https://x"}\n  A->>A: hi\n',
    };

    test('every keyword parses to a diagram with messages in it', () {
      for (final entry in samples.entries) {
        final result = parser.parseWithData(entry.value);
        expect(result, isNotNull, reason: '${entry.key} 解析不出来');
        expect(result!.sequenceData, isNotNull, reason: entry.key);
        expect(result.diagram.edges, isNotEmpty,
            reason: '${entry.key} 把消息一起吃掉了');
      }
    });

    test('a keyword line never becomes a participant', () {
      // The failure this guards against is silent: an unrecognised line that
      // falls through to the message pattern draws a lifeline named after the
      // keyword, which looks like a diagram until you read it.
      const keywords = [
        'participant', 'actor', 'create', 'destroy', 'box', 'activate',
        'deactivate', 'note', 'loop', 'alt', 'else', 'opt', 'par', 'and',
        'critical', 'option', 'break', 'rect', 'end', 'autonumber', 'title',
        'links',
      ];
      for (final entry in samples.entries) {
        final ids = parser.parse(entry.value)!.nodes.map((n) => n.id);
        for (final id in ids) {
          expect(keywords.contains(id.toLowerCase()), isFalse,
              reason: '${entry.key} 里 "$id" 成了参与者');
        }
      }
    });
  });
}

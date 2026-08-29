import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/mermaid.dart';

/// Every relation mermaid's class-diagram grammar can spell.
///
/// Its production is `[relationType] lineType [relationType]`: any of the five
/// relation types at either end of either kind of line. This was matched
/// against a hand-written list of sixteen spellings, and thirty-nine of the
/// legal combinations were missing from it — `..o` and `..*`, every two-ended
/// form such as `o--o`, and the lollipop `()` entirely.
///
/// The failure was silent, which is what makes it worth a test rather than a
/// one-off fix: a spelling the list did not know still matched the bare `--`
/// at its end, so the line was drawn without its heads and the relation's
/// meaning quietly disappeared.
void main() {
  const parser = MermaidParser();

  // The tokens mermaid allows at each end, and the shape each one draws.
  // The head each token draws. The plain arrow is the one that also depends
  // on the line: UML gives a dependency (dotted) an open head and an
  // association (solid) a closed one, and this project draws that difference.
  ArrowType headFor(String token, {required bool dotted}) => switch (token) {
        'o' => ArrowType.hollowDiamond,
        '<|' || '|>' => ArrowType.hollowTriangle,
        '*' => ArrowType.filledDiamond,
        '()' => ArrowType.circle,
        '<' || '>' => dotted ? ArrowType.openArrow : ArrowType.arrow,
        _ => ArrowType.none,
      };
  const startTokens = ['o', '<|', '*', '()', '<'];
  const endTokens = ['o', '|>', '*', '()', '>'];

  MermaidEdge? edgeFor(String relation) {
    final d = parser.parse('classDiagram\n  A $relation B\n');
    if (d == null || d.edges.length != 1 || d.nodes.length != 2) return null;
    return d.edges.single;
  }

  test('every combination the grammar allows is read', () {
    final unhandled = <String>[];
    for (final start in ['', ...startTokens]) {
      for (final line in ['--', '..']) {
        for (final end in ['', ...endTokens]) {
          if (start.isEmpty && end.isEmpty && line == '--') continue;
          final relation = '$start$line$end';
          final dotted = line == '..';
          final edge = edgeFor(relation);
          final ok = edge != null &&
              edge.startArrowType == headFor(start, dotted: dotted) &&
              edge.arrowType == headFor(end, dotted: dotted) &&
              edge.lineType ==
                  (dotted ? LineType.dotted : LineType.solid);
          if (!ok) unhandled.add(relation);
        }
      }
    }
    expect(unhandled, isEmpty,
        reason: '这些写法被当成了普通连线，关系的含义无声消失了');
  });

  test('the four everyday relations look the way UML draws them', () {
    // Inheritance points at the parent, and mermaid writes the parent first.
    final inherit = edgeFor('<|--')!;
    expect(inherit.startArrowType, ArrowType.hollowTriangle);
    expect(inherit.arrowType, ArrowType.none);
    expect(inherit.from, 'A', reason: '父类写在前面，方向不能被调换');

    expect(edgeFor('*--')!.startArrowType, ArrowType.filledDiamond);
    expect(edgeFor('o--')!.startArrowType, ArrowType.hollowDiamond);
    // A dependency is dotted with an open head; an association is solid with
    // a closed one. Same token, different head, because UML draws them so.
    expect(edgeFor('..>')!.arrowType, ArrowType.openArrow);
    expect(edgeFor('-->')!.arrowType, ArrowType.arrow);
    expect(edgeFor('..>')!.lineType, LineType.dotted);
  });

  test('a two-ended relation keeps both ends', () {
    final both = edgeFor('<|--|>')!;
    expect(both.startArrowType, ArrowType.hollowTriangle);
    expect(both.arrowType, ArrowType.hollowTriangle);
  });

  test('a plain link has no heads at all', () {
    expect(edgeFor('--')!.startArrowType, ArrowType.none);
    expect(edgeFor('--')!.arrowType, ArrowType.none);
    expect(edgeFor('..')!.lineType, LineType.dotted);
  });

  test('labels and cardinalities survive every spelling', () {
    for (final relation in ['<|--', 'o..', '--*', '<|--|>', '..>']) {
      final d = parser.parse('classDiagram\n  A "1" $relation "many" B : uses\n');
      expect(d, isNotNull, reason: relation);
      final edge = d!.edges.single;
      expect(edge.label, 'uses', reason: relation);
      expect(edge.startLabel, '1', reason: relation);
      expect(edge.endLabel, 'many', reason: relation);
    }
  });

  test('a class named with a relation character is not split on it', () {
    // The scan looks for a relation anywhere after the first character; a
    // name is not allowed to be mistaken for one.
    final d = parser.parse('classDiagram\n  Animal <|-- Duck\n');
    expect(d!.nodes.map((n) => n.id).toList(), ['Animal', 'Duck']);
  });
}

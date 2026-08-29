import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/mermaid.dart';

/// Every way mermaid lets an ER relationship be written.
///
/// Its grammar takes a cardinality at each end of an identifying or
/// non-identifying line, and each cardinality can be written as symbols
/// (`}|--|{`) or as words (`one or more to`). Only the symbols were read, so
/// a diagram written in words did not lose one relationship — the parse
/// failed outright and the whole diagram fell back to a grey code block.
void main() {
  const parser = MermaidParser();

  const lefts = <String, ArrowType>{
    '||': ArrowType.erExactlyOne,
    '|o': ArrowType.erZeroOrOne,
    '}o': ArrowType.erZeroOrMore,
    '}|': ArrowType.erOneOrMore,
  };
  const rights = <String, ArrowType>{
    '||': ArrowType.erExactlyOne,
    'o|': ArrowType.erZeroOrOne,
    'o{': ArrowType.erZeroOrMore,
    '|{': ArrowType.erOneOrMore,
  };

  MermaidEdge? edgeFor(String relation) {
    final d = parser.parse('erDiagram\n  A $relation B : has\n');
    if (d == null || d.edges.length != 1 || d.nodes.length != 2) return null;
    return d.edges.single;
  }

  test('every symbolic combination is read', () {
    final unhandled = <String>[];
    for (final left in lefts.entries) {
      for (final line in ['--', '..']) {
        for (final right in rights.entries) {
          final relation = '${left.key}$line${right.key}';
          final edge = edgeFor(relation);
          final ok = edge != null &&
              edge.startArrowType == left.value &&
              edge.arrowType == right.value &&
              edge.lineType ==
                  (line == '..' ? LineType.dotted : LineType.solid);
          if (!ok) unhandled.add(relation);
        }
      }
    }
    expect(unhandled, isEmpty);
  });

  group('written in words', () {
    // mermaid's own aliases, from its lexer.
    const words = <String, String>{
      'one or zero': '|o',
      'zero or one': '|o',
      'zero or more': '}o',
      'zero or many': '}o',
      'one or more': '}|',
      'one or many': '}|',
      'one': '||',
      'only one': '||',
    };

    test('each spelled-out cardinality means what the symbol means', () {
      for (final word in words.entries) {
        final spelled = edgeFor('${word.key} to ${word.key}');
        expect(spelled, isNotNull,
            reason: '"${word.key}" 整张图都解析不出来');
        final symbolic = edgeFor('${word.value}--${_mirror(word.value)}')!;
        expect(spelled!.startArrowType, symbolic.startArrowType,
            reason: word.key);
        expect(spelled.arrowType, symbolic.arrowType, reason: word.key);
      }
    });

    test('`to` identifies and `optionally to` does not', () {
      expect(edgeFor('one to one')!.lineType, LineType.solid);
      expect(edgeFor('one optionally to one')!.lineType, LineType.dotted);
    });

    test('the two ends may differ', () {
      final edge = edgeFor('one or more to zero or one')!;
      expect(edge.startArrowType, ArrowType.erOneOrMore);
      expect(edge.arrowType, ArrowType.erZeroOrOne);
    });

    test('the label survives', () {
      final d = parser.parse(
          'erDiagram\n  PERSON one to zero or more ADDRESS : lives\n');
      expect(d!.edges.single.label, 'lives');
      expect(d.nodes.map((n) => n.id).toList(), ['PERSON', 'ADDRESS']);
    });

    test('the longer spelling wins over the shorter one it contains', () {
      // `zero or one` contains `one`; reading the short one first would leave
      // `zero or` stuck to the entity's name.
      final d = parser.parse('erDiagram\n  A zero or one to one B : has\n');
      expect(d!.nodes.map((n) => n.id).toList(), ['A', 'B']);
      expect(d.edges.single.startArrowType, ArrowType.erZeroOrOne);
    });

    test('an entity whose name contains "one" is left alone', () {
      final d = parser.parse('erDiagram\n  MILESTONE ||--o{ TASK : has\n');
      expect(d!.nodes.map((n) => n.id).toList(), ['MILESTONE', 'TASK']);
    });
  });
}

/// The right-hand token that mirrors a left-hand one.
String _mirror(String left) => switch (left) {
      '|o' => 'o|',
      '}o' => 'o{',
      '}|' => '|{',
      _ => '||',
    };

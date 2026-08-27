import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/class_diagram.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/diagram.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/edge.dart';
import 'package:marktext_plus/ui/editor/mermaid/parser/mermaid_parser.dart';

void main() {
  const parser = MermaidParser();

  group('Diagram type detection', () {
    test('accepts flowchart headers that are not followed by a space', () {
      for (final header in [
        'graph TD',
        'graph TD;',
        'flowchart LR',
        'flowchart-elk LR',
      ]) {
        final result = parser.parseWithData('$header\n  A --> B');
        expect(
          result?.diagram.type,
          DiagramType.flowchart,
          reason: 'header "$header" should parse as a flowchart',
        );
      }
    });

    test('does not mistake an unrelated keyword for a flowchart', () {
      final result = parser.parseWithData('graphql\n  A --> B');
      expect(result?.diagram.type, isNot(DiagramType.flowchart));
    });
  });

  group('Comment handling', () {
    test('strips a trailing comment', () {
      final result = parser.parseWithData('graph TD\n  A --> B %% a comment');
      expect(result, isNotNull);
      expect(result!.diagram.nodes.length, 2);
    });

    test('keeps a percent sign inside a bracketed label', () {
      final result = parser.parseWithData('graph TD\n  A["50%% off"] --> B');
      expect(result, isNotNull);
      final labels = result!.diagram.nodes.map((n) => n.label).toList();
      expect(labels.any((l) => l.contains('50%% off') || l.contains('50%')),
          isTrue,
          reason: 'label was truncated at the %% marker: $labels');
    });

    test('drops an init directive without breaking the diagram', () {
      final result = parser.parseWithData(
        "%%{init: {'theme':'forest'}}%%\ngraph TD\n  A --> B",
      );
      expect(result, isNotNull);
      expect(result!.diagram.type, DiagramType.flowchart);
      expect(result.diagram.nodes.length, 2);
    });
  });

  group('ER diagrams', () {
    test('parses entities, attributes and keys', () {
      final result = parser.parseWithData("""
erDiagram
  CUSTOMER {
    string name
    string custNumber PK
    int age
  }
""");

      expect(result, isNotNull);
      expect(result!.diagram.type, DiagramType.erDiagram);

      final customer = result.erDiagramData!.byId('CUSTOMER')!;
      expect(customer.attributes.length, 3);
      expect(customer.attributes[0].type, 'string');
      expect(customer.attributes[0].name, 'name');
      expect(customer.attributes[1].keys, ['PK']);
      expect(customer.attributes[1].displayText, contains('PK'));
    });

    test('maps every cardinality token to its crow foot', () {
      final result = parser.parseWithData("""
erDiagram
  A ||--o{ B : has
  C |o--|| D : maybe
  E }o--o| F : loose
  G }|--|{ H : strict
""");

      final edges = result!.diagram.edges;
      expect(edges.length, 4);

      expect(edges[0].startArrowType, ArrowType.erExactlyOne);
      expect(edges[0].arrowType, ArrowType.erZeroOrMore);

      expect(edges[1].startArrowType, ArrowType.erZeroOrOne);
      expect(edges[1].arrowType, ArrowType.erExactlyOne);

      expect(edges[2].startArrowType, ArrowType.erZeroOrMore);
      expect(edges[2].arrowType, ArrowType.erZeroOrOne);

      expect(edges[3].startArrowType, ArrowType.erOneOrMore);
      expect(edges[3].arrowType, ArrowType.erOneOrMore);
    });

    test('reads the relationship label', () {
      final result =
          parser.parseWithData('erDiagram\n  CUSTOMER ||--o{ ORDER : places');
      expect(result!.diagram.edges.single.label, 'places');
    });

    test('treats .. as a non-identifying, dashed relationship', () {
      final result =
          parser.parseWithData('erDiagram\n  A }|..|{ B : uses');
      expect(result!.diagram.edges.single.lineType, LineType.dotted);
    });

    test('honours an entity alias', () {
      final result = parser.parseWithData("""
erDiagram
  CUSTOMER["Client record"] ||--o{ ORDER : places
""");

      final customer = result!.erDiagramData!.byId('CUSTOMER')!;
      expect(customer.displayName, 'Client record');
    });
  });

  group('Parse failure diagnosis', () {
    test('names the unrecognised type and lists what is supported', () {
      final message = parser.describeParseFailure('erDiagram\n  A ||--o{ B : has');

      expect(message, contains('erdiagram'));
      expect(message, contains('classDiagram'));
      expect(message, contains('sequenceDiagram'));
    });

    test('says the header was fine when only the body failed', () {
      // A recognised header with nothing under it: the type is known, the
      // content is not parseable.
      final message = parser.describeParseFailure('classDiagram');

      expect(message, contains('class diagram'));
      expect(message, isNot(contains('Unrecognised')));
    });

    test('reports an empty diagram as empty', () {
      expect(parser.describeParseFailure('   \n\n'), contains('empty'));
    });
  });

  group('Class diagrams', () {
    test('parses classes, members and visibility', () {
      final result = parser.parseWithData('''
classDiagram
  class Animal {
    +int age
    -String name
    #move()
    +isMammal() bool
  }
''');

      expect(result, isNotNull);
      expect(result!.diagram.type, DiagramType.classDiagram);

      final data = result.classDiagramData;
      expect(data, isNotNull);

      final animal = data!.byId('Animal');
      expect(animal, isNotNull);
      expect(animal!.attributes.length, 2);
      expect(animal.methods.length, 2);

      expect(animal.attributes[0].visibility, ClassMemberVisibility.public);
      expect(animal.attributes[1].visibility, ClassMemberVisibility.private);
      expect(animal.methods[0].visibility, ClassMemberVisibility.protected);
      expect(animal.methods[0].isMethod, isTrue);
      expect(animal.methods[1].type, 'bool');
    });

    test('parses the single-line member shorthand', () {
      final result = parser.parseWithData('''
classDiagram
  Animal : +int age
  Animal : +mate()
''');

      final animal = result!.classDiagramData!.byId('Animal')!;
      expect(animal.attributes.length, 1);
      expect(animal.methods.length, 1);
    });

    test('puts the inheritance head on the parent side', () {
      final result = parser.parseWithData('classDiagram\n  Animal <|-- Duck');

      final edge = result!.diagram.edges.single;
      // Animal stays the layout parent; the triangle is drawn at its end.
      expect(edge.from, 'Animal');
      expect(edge.to, 'Duck');
      expect(edge.startArrowType, ArrowType.hollowTriangle);
      expect(edge.arrowType, ArrowType.none);
    });

    test('distinguishes composition, aggregation and dependency', () {
      final result = parser.parseWithData('''
classDiagram
  Car *-- Engine
  Team o-- Player
  Service ..> Repository
''');

      final edges = result!.diagram.edges;
      expect(edges.length, 3);
      expect(edges[0].startArrowType, ArrowType.filledDiamond);
      expect(edges[1].startArrowType, ArrowType.hollowDiamond);
      expect(edges[2].arrowType, ArrowType.openArrow);
      expect(edges[2].lineType, LineType.dotted);
    });

    test('reads cardinality and relation labels', () {
      final result = parser.parseWithData(
        'classDiagram\n  Student "1" --> "1..*" Course : enrols in',
      );

      final edge = result!.diagram.edges.single;
      expect(edge.from, 'Student');
      expect(edge.to, 'Course');
      expect(edge.startLabel, '1');
      expect(edge.endLabel, '1..*');
      expect(edge.label, 'enrols in');
    });

    test('reads annotations in both spellings', () {
      final result = parser.parseWithData('''
classDiagram
  class Shape {
    <<interface>>
    draw()
  }
  <<enumeration>> Colour
''');

      final data = result!.classDiagramData!;
      expect(data.byId('Shape')!.stereotype, 'interface');
      expect(data.byId('Colour')!.stereotype, 'enumeration');
    });

    test('expands tilde generics', () {
      final result = parser.parseWithData('''
classDiagram
  class Box {
    +List~int~ items
  }
''');

      final box = result!.classDiagramData!.byId('Box')!;
      expect(box.attributes.single.displayText, contains('List<int>'));
    });

    test('attaches a note to its class', () {
      final result = parser.parseWithData('''
classDiagram
  class Duck
  note for Duck "can fly"
''');

      expect(result!.classDiagramData!.byId('Duck')!.note, 'can fly');
    });
  });
}

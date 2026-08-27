import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/class_diagram.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/diagram.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/edge.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/git_graph.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/mindmap.dart';
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

  group('Mindmap', () {
    test('builds a tree from indentation', () {
      final result = parser.parseWithData("""
mindmap
  root((Origins))
    History
      Long history
    Research
      Effectiveness
""");

      expect(result, isNotNull);
      expect(result!.diagram.type, DiagramType.mindmap);

      final root = result.mindmapData!.root;
      expect(root.label, 'Origins');
      expect(root.shape, MindmapShape.circle);
      expect(root.children.length, 2);
      expect(root.children[0].label, 'History');
      expect(root.children[0].children.single.label, 'Long history');
      expect(root.children[1].children.single.label, 'Effectiveness');
    });

    test('returns to the right parent when indentation drops', () {
      final result = parser.parseWithData("""
mindmap
  root
    A
      A1
        A2
    B
""");

      final root = result!.mindmapData!.root;
      expect(root.children.map((c) => c.label).toList(), ['A', 'B']);
      expect(root.children[0].children.single.label, 'A1');
      expect(root.children[0].children.single.children.single.label, 'A2');
    });

    test('reads each node shape', () {
      final result = parser.parseWithData("""
mindmap
  root
    [Square]
    (Rounded)
    ((Circle))
    {{Hexagon}}
""");

      final shapes =
          result!.mindmapData!.root.children.map((c) => c.shape).toList();
      expect(shapes, [
        MindmapShape.square,
        MindmapShape.rounded,
        MindmapShape.circle,
        MindmapShape.hexagon,
      ]);
    });

    test('records depth for every node', () {
      final result = parser.parseWithData("""
mindmap
  root
    A
      A1
""");

      final root = result!.mindmapData!.root;
      expect(root.depth, 0);
      expect(root.children.single.depth, 1);
      expect(root.children.single.children.single.depth, 2);
    });

    test('skips icon and class decoration lines', () {
      final result = parser.parseWithData("""
mindmap
  root
    Origins
    ::icon(fa fa-book)
""");

      expect(result!.mindmapData!.root.children.length, 1);
    });
  });

  group('Git graph', () {
    test('tracks branches, checkout and commit order', () {
      final result = parser.parseWithData("""
gitGraph
  commit
  commit id: "Alpha"
  branch develop
  commit
  checkout main
  commit
""");

      expect(result, isNotNull);
      expect(result!.diagram.type, DiagramType.gitGraph);

      final data = result.gitGraphData!;
      expect(data.branches, contains('main'));
      expect(data.branches, contains('develop'));
      expect(data.commits.length, 4);

      // `branch develop` checks it out, so the third commit lands there.
      expect(data.commits[1].id, 'Alpha');
      expect(data.commits[2].branch, 'develop');
      expect(data.commits[3].branch, 'main');

      // Columns advance one per commit, in source order.
      expect(data.commits.map((c) => c.column).toList(), [0, 1, 2, 3]);
    });

    test('records a merge and where it came from', () {
      final result = parser.parseWithData("""
gitGraph
  commit
  branch feature
  commit
  checkout main
  merge feature
""");

      final merge = result!.gitGraphData!.commits.last;
      expect(merge.type, GitCommitType.merge);
      expect(merge.branch, 'main');
      expect(merge.mergedFrom, 'feature');
    });

    test('reads commit tags and types', () {
      final result = parser.parseWithData("""
gitGraph
  commit tag: "v1.0"
  commit type: HIGHLIGHT
  commit type: REVERSE
""");

      final commits = result!.gitGraphData!.commits;
      expect(commits[0].tag, 'v1.0');
      expect(commits[1].type, GitCommitType.highlight);
      expect(commits[2].type, GitCommitType.reverse);
    });

    test('finds the source commit a merge should be drawn from', () {
      final result = parser.parseWithData("""
gitGraph
  commit
  branch feature
  commit id: "F1"
  checkout main
  merge feature
""");

      final data = result!.gitGraphData!;
      final merge = data.commits.last;
      final from = data.lastCommitOn('feature', merge.column);
      expect(from, isNotNull);
      expect(from!.id, 'F1');
    });
  });

  group('User journey', () {
    test('parses sections, scores and actors', () {
      final result = parser.parseWithData("""
journey
  title My working day
  section Go to work
    Make tea: 5: Me
    Go upstairs: 3: Me
    Do work: 1: Me, Cat
  section Go home
    Go downstairs: 5: Me
""");

      expect(result, isNotNull);
      expect(result!.diagram.type, DiagramType.journey);

      final data = result.journeyData!;
      expect(data.title, 'My working day');
      expect(data.sections.length, 2);
      expect(data.sections[0].name, 'Go to work');
      expect(data.sections[0].tasks.length, 3);
      expect(data.sections[1].tasks.single.name, 'Go downstairs');

      final work = data.sections[0].tasks[2];
      expect(work.score, 1);
      expect(work.actors, ['Me', 'Cat']);
    });

    test('accepts a task with no actors', () {
      final result = parser.parseWithData("""
journey
  section Solo
    Think: 4
""");

      final task = result!.journeyData!.sections.single.tasks.single;
      expect(task.score, 4);
      expect(task.actors, isEmpty);
    });

    test('collects distinct actors in first-appearance order', () {
      final result = parser.parseWithData("""
journey
  section S
    A: 3: Bob, Alice
    B: 4: Alice
    C: 5: Carol, Bob
""");

      expect(result!.journeyData!.actors, ['Bob', 'Alice', 'Carol']);
    });

    test('clamps an out-of-range score into 1..5', () {
      final result = parser.parseWithData("""
journey
  section S
    Way too good: 9
    Way too bad: 0
""");

      final tasks = result!.journeyData!.sections.single.tasks;
      expect(tasks[0].clampedScore, 5);
      expect(tasks[1].clampedScore, 1);
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
      // This example keeps going stale as types get implemented — erDiagram,
      // then mindmap. quadrantChart is far enough down the list to hold for
      // now; whoever implements it needs to change this line too.
      final message = parser.describeParseFailure(
        'quadrantChart\n  title Reach and engagement',
      );

      expect(message, contains('quadrantchart'));
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

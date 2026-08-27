import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/class_diagram.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/diagram.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/edge.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/git_graph.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/mindmap.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/requirement_diagram.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/sankey.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/sequence.dart';
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

  group('Language handling', () {
    test('accepts the canonical mermaid tag and bare type names', () {
      for (final lang in [
        'mermaid',
        'MERMAID',
        'classDiagram',
        'erDiagram',
        'journey',
        'gitGraph',
        'mindmap',
        'pie',
        'gantt',
      ]) {
        expect(
          MermaidParser.handlesLanguage(lang),
          isTrue,
          reason: '"$lang" should be rendered as a diagram',
        );
      }
    });

    test('leaves ordinary code languages alone', () {
      for (final lang in ['dart', 'json', 'bash', 'python', '']) {
        expect(
          MermaidParser.handlesLanguage(lang),
          isFalse,
          reason: '"$lang" should stay a code block',
        );
      }
    });

    test('splits the combined graph / flowchart entry', () {
      expect(MermaidParser.handlesLanguage('graph'), isTrue);
      expect(MermaidParser.handlesLanguage('flowchart'), isTrue);
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

  group('Kanban', () {
    test('accepts the column forms mermaid documents', () {
      // Bare titles and untitled brackets both appear in mermaid's own docs;
      // requiring `id[Title]` made a board copied from there parse to null.
      final result = parser.parseWithData("""
kanban
  Todo
    [Write docs]
  [In progress]
    id6[Fix the renderer]
  done[Done]
    Ship it
""");

      expect(result, isNotNull);
      expect(result!.diagram.type, DiagramType.kanban);

      final columns = result.kanbanChartData!.columns;
      expect(columns.map((c) => c.title).toList(),
          ['Todo', 'In progress', 'Done']);
      expect(columns[0].tasks.single.description, 'Write docs');
      expect(columns[1].tasks.single.description, 'Fix the renderer');
      expect(columns[2].tasks.single.description, 'Ship it');
    });

    test('reads a wip limit on any column form', () {
      final result = parser.parseWithData("""
kanban
  Doing wip:3
    [A task]
""");

      expect(result!.kanbanChartData!.columns.single.wipLimit, 3);
    });

    test('still reads task metadata', () {
      final result = parser.parseWithData("""
kanban
  Todo
    id1[Fix it] @{assigned: "sam", priority: "High"}
""");

      final task = result!.kanbanChartData!.columns.single.tasks.single;
      expect(task.description, 'Fix it');
      expect(task.assigned, 'sam');
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
      // Previous versions of this test named a real mermaid type that was not
      // implemented yet — erDiagram, then mindmap, then quadrantChart — and
      // each one broke the test the day it was implemented. A header that
      // mermaid itself will never define cannot go stale.
      final message = parser.describeParseFailure(
        'notARealDiagramType\n  some body line',
      );

      expect(message, contains('notarealdiagramtype'));
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

  group('Diagrams written in other scripts', () {
    MermaidDiagramData diagramOf(String source) =>
        parser.parseWithData(source)!.diagram;

    test('a flowchart with Chinese node names has nodes', () {
      // `\w` is ASCII-only in Dart, so this produced no nodes at all while
      // still producing an edge between them: an empty diagram.
      final diagram = diagramOf('graph TD\n  开始 --> 结束');

      expect(diagram.nodes.map((n) => n.id).toList(), ['开始', '结束']);
      expect(diagram.edges.single.from, '开始');
      expect(diagram.edges.single.to, '结束');
    });

    test('shapes work with Chinese ids and labels', () {
      final diagram = diagramOf('graph TD\n  甲[开始] --> 乙{判断}');

      expect(diagram.nodes.map((n) => n.label).toList(), ['开始', '判断']);
      expect(diagram.edges.single.to, '乙');
    });

    test('a sequence diagram in Chinese has participants', () {
      final diagram = diagramOf('sequenceDiagram\n  用户->>系统: 登录');

      expect(diagram.nodes, hasLength(2));
      expect(diagram.edges.single.label, '登录');
    });

    test('a kanban column may be named in Chinese with an id', () {
      // Neither branch of the column pattern matched, so the whole board
      // failed to parse rather than just that column.
      final board = parser
          .parseWithData('kanban\n  待办栏[待办事项]\n    任务一')!
          .kanbanChartData!;

      expect(board.columns.single.title, '待办事项');
      expect(board.columns.single.tasks, hasLength(1));
    });

    test('a git branch may be named in Chinese', () {
      final graph = parser
          .parseWithData('gitGraph\n  commit\n  branch 开发\n  commit')!
          .gitGraphData!;

      expect(graph.branches, contains('开发'));
    });

    test('a trailing semicolon is not part of the node name', () {
      // Node ids now accept anything that is not a delimiter, and a statement
      // may end with a semicolon.
      final diagram = diagramOf('graph TD;\n  A-->B;');

      expect(diagram.nodes.map((n) => n.id).toList(), ['A', 'B']);
    });
  });

  group('Sequence diagram messages', () {
    MermaidDiagramData diagramOf(String source) =>
        parser.parseWithData(source)!.diagram;

    test('a space before the target is allowed', () {
      // `A-x B` matched nothing, so the line was dropped entirely.
      final diagram = diagramOf('sequenceDiagram\n  A-x B: lost');

      expect(diagram.nodes, hasLength(2));
      expect(diagram.edges.single.label, 'lost');
    });

    test('activation markers do not stop the message parsing', () {
      // `A->>+B` and `B-->>-A` produced no participants and no messages.
      final diagram =
          diagramOf('sequenceDiagram\n  A->>+B: hi\n  B-->>-A: bye');

      expect(diagram.nodes, hasLength(2));
      expect(diagram.edges, hasLength(2));
      expect(diagram.edges.map((e) => e.label).toList(), ['hi', 'bye']);
    });

    test('a message may contain a colon', () {
      final diagram = diagramOf('sequenceDiagram\n  A->>B: ratio 3:1');
      expect(diagram.edges.single.label, 'ratio 3:1');
    });

    test('a +/- marker opens and closes an activation bar', () {
      final data = parser
          .parseWithData(
            'sequenceDiagram\n'
            '  Alice->>+John: Hello John\n'
            '  John-->>-Alice: Hi Alice',
          )!
          .sequenceData!;

      // `-` closes the bar on the *sender*, even though it is written in front
      // of the target.
      expect(data.activations, hasLength(1));
      expect(data.activations.single.participantId, 'John');
      expect(data.activations.single.startIndex, 0);
      expect(data.activations.single.endIndex, 1);
    });

    test('explicit activate lines mean the same as the +/- shorthand', () {
      final shorthand = parser
          .parseWithData(
            'sequenceDiagram\n'
            '  A->>+B: ask\n'
            '  B-->>-A: answer',
          )!
          .sequenceData!;

      final spelled = parser
          .parseWithData(
            'sequenceDiagram\n'
            '  A->>B: ask\n'
            '  activate B\n'
            '  B-->>A: answer\n'
            '  deactivate B',
          )!
          .sequenceData!;

      expect(spelled, shorthand);
    });

    test('a participant activated twice gets nested bars', () {
      final data = parser
          .parseWithData(
            'sequenceDiagram\n'
            '  A->>+B: one\n'
            '  A->>+B: two\n'
            '  B-->>-A: three\n'
            '  B-->>-A: four',
          )!
          .sequenceData!;

      final depths = data.activations.map((a) => a.depth).toList()..sort();
      expect(depths, [0, 1]);
      final outer = data.activations.firstWhere((a) => a.depth == 0);
      expect(outer.startIndex, 0);
      expect(outer.endIndex, 3);
    });

    test('a bar left open runs to the end of the diagram', () {
      final data = parser
          .parseWithData(
            'sequenceDiagram\n'
            '  A->>+B: start\n'
            '  B->>C: carry on',
          )!
          .sequenceData!;

      expect(data.activations.single.endIndex, 1);
    });

    test('a deactivate with nothing open is ignored', () {
      final data = parser
          .parseWithData('sequenceDiagram\n  A->>B: one\n  deactivate B')!
          .sequenceData!;

      expect(data.activations, isEmpty);
    });
    test('notes take a row of their own, in source order', () {
      final data = parser
          .parseWithData(
            'sequenceDiagram\n'
            '  participant A\n'
            '  participant B\n'
            '  Note left of A: start\n'
            '  A->>B: ask\n'
            '  Note over A,B: agreed\n'
            '  B-->>A: answer\n'
            '  Note right of B: done',
          )!
          .sequenceData!;

      expect(data.steps.map((s) => s.isNote).toList(),
          [true, false, true, false, true]);
      expect(data.steps.first.note!.placement, SequenceNotePlacement.leftOf);
      expect(data.steps.first.note!.text, 'start');
      expect(data.steps[2].note!.participantIds, ['A', 'B']);
      expect(data.steps.last.note!.placement, SequenceNotePlacement.rightOf);
    });

    test('an activation bar counts note rows too', () {
      // Bars are positioned in rows, not in messages: with the note ignored
      // the bar stopped one row short of the reply that closes it.
      final data = parser
          .parseWithData(
            'sequenceDiagram\n'
            '  A->>+B: ask\n'
            '  Note over B: working\n'
            '  B-->>-A: answer',
          )!
          .sequenceData!;

      expect(data.steps, hasLength(3));
      expect(data.activations.single.startIndex, 0);
      expect(data.activations.single.endIndex, 2);
    });

    test('note is recognised in lower case and without a colon', () {
      final data = parser
          .parseWithData('sequenceDiagram\n  A->>B: hi\n  note over A: fine')!
          .sequenceData!;

      expect(data.steps.last.note!.text, 'fine');
    });

  });

  group('Flowchart arrows and labels', () {
    MermaidDiagramData diagramOf(String source) =>
        parser.parseWithData(source)!.diagram;

    test('a label between the dashes keeps the source node', () {
      // `A -- label --> B` had no form in the pattern, so the arrow matched
      // partway through and node A was lost entirely.
      final diagram = diagramOf('graph TD\n  A -- yes --> B');

      expect(diagram.nodes.map((n) => n.id).toList(), ['A', 'B']);
      expect(diagram.edges.single.label, 'yes');
    });

    test('a dotted arrow can carry a label the same way', () {
      final diagram = diagramOf('graph TD\n  A -. maybe .-> B');

      expect(diagram.nodes, hasLength(2));
      expect(diagram.edges.single.label, 'maybe');
      expect(diagram.edges.single.lineType, LineType.dotted);
    });

    test('a long arrow is one arrow, not a short one plus text', () {
      // `---` was listed before `---->`, and alternation prefers the first
      // branch, so the target came out named "-> B".
      final diagram = diagramOf('graph TD\n  A ----> B');

      expect(diagram.nodes.map((n) => n.id).toList(), ['A', 'B']);
      expect(diagram.edges.single.to, 'B');
    });

    test('a two-headed arrow is marked at both ends', () {
      final edge = diagramOf('graph TD\n  A <--> B').edges.single;

      expect(edge.bidirectional, isTrue);
      expect(edge.startArrowType, ArrowType.arrow);
      expect(edge.arrowType, ArrowType.arrow);
    });

    test('circle and cross heads are recognised', () {
      expect(diagramOf('graph TD\n  A --o B').edges.single.arrowType,
          ArrowType.circle);
      expect(diagramOf('graph TD\n  A --x B').edges.single.arrowType,
          ArrowType.cross);
    });

    test('an ampersand names several nodes at once', () {
      final diagram = diagramOf('graph TD\n  A --> B & C');

      expect(diagram.nodes.map((n) => n.id).toList(), ['A', 'B', 'C']);
      expect(diagram.edges, hasLength(2));
      expect(diagram.edges.map((e) => e.to).toList(), ['B', 'C']);
    });

    test('an ampersand works on the left as well', () {
      final diagram = diagramOf('graph TD\n  A & B --> C');

      expect(diagram.edges.map((e) => e.from).toList(), ['A', 'B']);
      expect(diagram.edges.every((e) => e.to == 'C'), isTrue);
    });

    test('an ampersand inside a label is part of the label', () {
      final diagram = diagramOf('graph TD\n  A[Tom & Jerry] --> B');

      expect(diagram.nodes.first.label, 'Tom & Jerry');
      expect(diagram.edges, hasLength(1));
    });

    test('quotes around a label are delimiters, not text', () {
      // How a label containing a bracket or comma is written; the quote marks
      // were being drawn.
      final diagram = diagramOf('graph TD\n  A["with space"]');

      expect(diagram.nodes.single.label, 'with space');
    });
  });

  group('Requirement diagrams', () {
    test('parses requirements, elements and relationships', () {
      final result = parser.parseWithData('''
requirementDiagram
  requirement test_req {
    id: 1
    text: the test text.
    risk: high
    verifymethod: test
  }
  functionalRequirement test_req2 {
    id: 1.1
    text: the second test text.
    risk: low
    verifymethod: inspection
  }
  element test_entity {
    type: simulation
    docref: reference
  }
  test_entity - satisfies -> test_req2
  test_req - traces -> test_req2
''');

      expect(result, isNotNull);
      expect(result!.diagram.type, DiagramType.requirementDiagram);

      final data = result.requirementDiagramData!;
      expect(data.requirements, hasLength(2));
      expect(data.elements, hasLength(1));
      expect(data.relations, hasLength(2));

      final first = data.requirementByName('test_req')!;
      expect(first.kind, RequirementKind.requirement);
      expect(first.id, '1');
      expect(first.text, 'the test text.');
      expect(first.risk, RequirementRisk.high);
      expect(first.verifyMethod, VerifyMethod.test);

      expect(data.requirementByName('test_req2')!.kind.label,
          'Functional Requirement');
      expect(data.elementByName('test_entity')!.type, 'simulation');
    });

    test('a backwards relationship points from the right-hand name', () {
      // `a <- derives - b` reads "b derives a".
      final data = parser
          .parseWithData('requirementDiagram\n'
              '  requirement a {\n  }\n'
              '  requirement b {\n  }\n'
              '  a <- derives - b')!
          .requirementDiagramData!;

      expect(data.relations.single.source, 'b');
      expect(data.relations.single.target, 'a');
    });

    test('a value may contain a colon', () {
      final data = parser
          .parseWithData(
              'requirementDiagram\n  requirement a {\n    text: see: this\n  }')!
          .requirementDiagramData!;

      expect(data.requirementByName('a')!.text, 'see: this');
    });

    test('an unknown risk or relationship is dropped, not guessed', () {
      final data = parser
          .parseWithData('requirementDiagram\n'
              '  requirement a {\n    risk: bogus\n  }\n'
              '  a - bogus -> a')!
          .requirementDiagramData!;

      expect(data.requirementByName('a')!.risk, isNull);
      expect(data.relations, isEmpty);
    });

    test('an edge to something never declared is not drawn', () {
      final result = parser.parseWithData('requirementDiagram\n'
          '  requirement a {\n  }\n'
          '  a - traces -> ghost');

      expect(result!.diagram.edges, isEmpty);
    });

    test('a block left unclosed still describes a box', () {
      final data = parser
          .parseWithData('requirementDiagram\n  requirement a {\n    id: 9')!
          .requirementDiagramData!;

      expect(data.requirements, hasLength(1));
      expect(data.requirementByName('a')!.id, '9');
    });

    test('a header with nothing under it is not a diagram', () {
      expect(parser.parseWithData('requirementDiagram'), isNull);
    });

    test('is offered as a supported type', () {
      expect(MermaidParser.handlesLanguage('requirementDiagram'), isTrue);
    });
  });

  group('Quadrant charts', () {
    test('parses the full syntax from the mermaid docs', () {
      final result = parser.parseWithData('''
quadrantChart
    title Reach and engagement of campaigns
    x-axis Low Reach --> High Reach
    y-axis Low Engagement --> High Engagement
    quadrant-1 We should expand
    quadrant-2 Need to promote
    quadrant-3 Re-evaluate
    quadrant-4 May be improved
    Campaign A: [0.3, 0.6]
    Campaign C: [0.57, 0.69] radius: 10, color: #ff0000
''');

      expect(result, isNotNull);
      expect(result!.diagram.type, DiagramType.quadrantChart);

      final chart = result.quadrantChartData!;
      expect(chart.title, 'Reach and engagement of campaigns');
      expect(chart.xAxisLeft, 'Low Reach');
      expect(chart.xAxisRight, 'High Reach');
      expect(chart.yAxisBottom, 'Low Engagement');
      expect(chart.yAxisTop, 'High Engagement');
      expect(chart.quadrant1, 'We should expand');
      expect(chart.quadrant4, 'May be improved');

      expect(chart.points, hasLength(2));
      expect(chart.points[0].label, 'Campaign A');
      expect(chart.points[0].x, 0.3);
      expect(chart.points[0].y, 0.6);
      expect(chart.points[0].radius, isNull);
      expect(chart.points[1].radius, 10);
      expect(chart.points[1].color, 0xFFFF0000);
    });

    test('an axis without an arrow names only its low end', () {
      final chart = parser
          .parseWithData('quadrantChart\n  x-axis Reach\n  A: [0.5, 0.5]')!
          .quadrantChartData!;

      expect(chart.xAxisLeft, 'Reach');
      expect(chart.xAxisRight, isNull);
    });

    test('coordinates outside the plot are clamped to it', () {
      final chart = parser
          .parseWithData('quadrantChart\n  A: [1.8, -0.4]')!
          .quadrantChartData!;

      expect(chart.points.single.x, 1.0);
      expect(chart.points.single.y, 0.0);
    });

    test('accepts quoted labels and short hex colours', () {
      final chart = parser
          .parseWithData(
              'quadrantChart\n  "Campaign X": [0.1, 0.2] color: #f00')!
          .quadrantChartData!;

      expect(chart.points.single.label, 'Campaign X');
      expect(chart.points.single.color, 0xFFFF0000);
    });

    test('an unparseable colour falls back to the default', () {
      final chart = parser
          .parseWithData('quadrantChart\n  A: [0.1, 0.2] color: #zzz')!
          .quadrantChartData!;

      expect(chart.points.single.color, isNull);
    });

    test('quadrant labels alone still make a chart', () {
      // Axes and regions are worth drawing even before any point is plotted.
      final result =
          parser.parseWithData('quadrantChart\n  quadrant-1 Expand');
      expect(result?.quadrantChartData?.quadrant1, 'Expand');
    });

    test('a header with nothing under it is not a diagram', () {
      expect(parser.parseWithData('quadrantChart'), isNull);
    });

    test('is offered as a supported type', () {
      expect(MermaidParser.handlesLanguage('quadrantChart'), isTrue);
    });
  });

  group('Sankey diagrams', () {
    test('reads a CSV body into nodes and flows', () {
      final data = parser
          .parseWithData('sankey-beta\nA,B,10\nA,C,5\nB,D,10\nC,D,5')!
          .sankeyChartData!;

      // Nodes are never declared in Sankey source, so first mention is the
      // only ordering there is.
      expect(data.nodes, ['A', 'B', 'C', 'D']);
      expect(data.links, hasLength(4));
      expect(data.links.first.value, 10);
    });

    test('a quoted field may contain a comma and an escaped quote', () {
      final data = parser
          .parseWithData(
            'sankey-beta\n"Agricultural ""waste""","Liquid, refined",1.5',
          )!
          .sankeyChartData!;

      expect(data.nodes, ['Agricultural "waste"', 'Liquid, refined']);
      expect(data.links.single.value, 1.5);
    });

    test('the title comes from YAML frontmatter', () {
      final result = parser.parseWithData(
        '---\ntitle: 能源流向\n---\nsankey-beta\n煤炭,发电,100',
      )!;

      expect(result.diagram.type, DiagramType.sankey);
      expect(result.sankeyChartData!.title, '能源流向');
    });

    test('a row with an unparseable value is skipped, not fatal', () {
      final data =
          parser.parseWithData('sankey-beta\nA,B,x\nA,B,3')!.sankeyChartData!;

      expect(data.links.single.value, 3);
    });

    test('a body with no usable row falls back to the source', () {
      expect(parser.parseWithData('sankey-beta'), isNull);
    });

    test('layout puts each node in a column and scales bars by value', () {
      final data = parser
          .parseWithData('sankey-beta\nA,B,10\nA,C,5\nB,D,10\nC,D,5')!
          .sankeyChartData!;
      final layout = SankeyLayout.compute(data, availableWidth: 700);

      final byId = {for (final n in layout.nodes) n.id: n};
      expect(byId['A']!.layer, 0);
      expect(byId['B']!.layer, 1);
      expect(byId['C']!.layer, 1);
      // D only receives, so it is a sink and lines up on the right edge.
      expect(byId['D']!.layer, 2);

      // A carries 15 units and B carries 10, so their bars are in that ratio.
      expect(byId['B']!.height / byId['A']!.height, closeTo(10 / 15, 0.001));
      expect(layout.links, hasLength(4));
    });

    test('a cycle does not scatter the diagram across empty columns', () {
      // Longest-path depth keeps climbing around a cycle until the pass cap
      // stops it; without renumbering, three nodes landed in columns 7, 8, 9.
      final data = parser
          .parseWithData('sankey-beta\nA,B,1\nB,C,1\nC,A,1')!
          .sankeyChartData!;
      final layout = SankeyLayout.compute(data, availableWidth: 700);

      expect(layout.nodes.map((n) => n.layer).toSet(), {0, 1, 2});
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

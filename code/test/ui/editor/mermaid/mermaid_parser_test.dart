import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/class_diagram.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/diagram.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/edge.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/git_graph.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/mindmap.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/requirement_diagram.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/block_diagram.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/c4_diagram.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/gantt.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/timeline.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/sankey.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/node.dart';
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
    test('a loop frames the rows between it and its end', () {
      final data = parser
          .parseWithData(
            'sequenceDiagram\n'
            '  A->>B: start\n'
            '  loop every minute\n'
            '    B->>B: beat\n'
            '  end\n'
            '  B-->>A: done',
          )!
          .sequenceData!;

      final block = data.blocks.single;
      expect(block.kind, SequenceBlockKind.loop);
      expect(block.sections.single.label, 'every minute');
      expect(block.startIndex, 1);
      expect(block.endIndex, 1);
    });

    test('alt splits into one section per else', () {
      final data = parser
          .parseWithData(
            'sequenceDiagram\n'
            '  A->>B: query\n'
            '  alt hit\n'
            '    B-->>A: data\n'
            '  else miss\n'
            '    B-->>A: nothing\n'
            '  end',
          )!
          .sequenceData!;

      final block = data.blocks.single;
      expect(block.kind, SequenceBlockKind.alt);
      expect(block.sections.map((s) => s.label).toList(), ['hit', 'miss']);
      expect(block.sections.first.startIndex, 1);
      expect(block.sections.first.endIndex, 1);
      expect(block.sections.last.startIndex, 2);
      expect(block.sections.last.endIndex, 2);
    });

    test('frames nest, and the inner one records its depth', () {
      final data = parser
          .parseWithData(
            'sequenceDiagram\n'
            '  par first\n'
            '    A->>B: one\n'
            '    loop thrice\n'
            '      B->>C: two\n'
            '    end\n'
            '  and second\n'
            '    A->>C: three\n'
            '  end',
          )!
          .sequenceData!;

      expect(data.blocks.map((b) => b.depth).toList(), [0, 1]);
      expect(data.blocks.first.kind, SequenceBlockKind.par);
      expect(data.blocks.last.kind, SequenceBlockKind.loop);
      expect(data.blocks.last.startIndex, 1);
    });

    test('a frame with no end closes at the last row', () {
      final data = parser
          .parseWithData('sequenceDiagram\n  opt maybe\n    A->>B: one')!
          .sequenceData!;

      expect(data.blocks.single.endIndex, 0);
    });

    test('a box groups the participants declared inside it', () {
      final data = parser
          .parseWithData(
            'sequenceDiagram\n'
            '  box Purple Frontend\n'
            '    participant A as Page\n'
            '    participant B as Gateway\n'
            '  end\n'
            '  participant C as Database\n'
            '  A->>B: ask',
          )!
          .sequenceData!;

      final group = data.groups.single;
      expect(group.label, 'Frontend');
      expect(group.color, 0xFF800080);
      expect(group.participantIds, ['A', 'B']);
    });

    test('a box colour may be written as rgb, and may be left out', () {
      final tinted = parser
          .parseWithData(
            'sequenceDiagram\n'
            '  box rgb(200, 220, 255) Backend\n'
            '    participant S\n'
            '  end\n'
            '  S->>S: check',
          )!
          .sequenceData!;
      expect(tinted.groups.single.color, 0xFFC8DCFF);
      expect(tinted.groups.single.label, 'Backend');

      final plain = parser
          .parseWithData(
            'sequenceDiagram\n  box Team\n    participant A\n  end\n  A->>A: x',
          )!
          .sequenceData!;
      expect(plain.groups.single.color, isNull);
      expect(plain.groups.single.label, 'Team');
    });

    test('a box and a frame share the end keyword without confusing it', () {
      // A box that was not recognised would leave its `end` closing whichever
      // frame happened to be open.
      final data = parser
          .parseWithData(
            'sequenceDiagram\n'
            '  box Aqua Team\n'
            '    participant A\n'
            '    participant B\n'
            '  end\n'
            '  loop thrice\n'
            '    A->>B: one\n'
            '  end\n'
            '  B-->>A: two',
          )!
          .sequenceData!;

      expect(data.groups.single.participantIds, ['A', 'B']);
      expect(data.blocks.single.kind, SequenceBlockKind.loop);
      expect(data.blocks.single.startIndex, 0);
      expect(data.blocks.single.endIndex, 0);
    });

    test('autonumber stamps each message with its position', () {
      final diagram = diagramOf(
        'sequenceDiagram\n  autonumber\n  A->>B: one\n  B->>A: two',
      );

      expect(diagram.edges.map((e) => e.label).toList(), ['1 one', '2 two']);
    });

    test('autonumber takes a start and a step, and can be turned off', () {
      final stepped = diagramOf(
        'sequenceDiagram\n  autonumber 10 5\n  A->>B: one\n  B->>A: two',
      );
      expect(stepped.edges.map((e) => e.label).toList(), ['10 one', '15 two']);

      final stopped = diagramOf(
        'sequenceDiagram\n'
        '  autonumber\n'
        '  A->>B: one\n'
        '  autonumber off\n'
        '  B->>A: two',
      );
      expect(stopped.edges.map((e) => e.label).toList(), ['1 one', 'two']);
    });

    test('a participant whose name starts with a keyword still sends', () {
      // `looper->>B` begins with `loop`, `Andy` with `and`, `optimist` with
      // `opt` — the keyword only counts when whitespace or the line end
      // follows it.
      final diagram = diagramOf(
        'sequenceDiagram\n'
        '  looper->>B: one\n'
        '  Andy->>B: two\n'
        '  optimist->>B: three',
      );

      expect(diagram.edges, hasLength(3));
      expect(
        diagram.edges.map((e) => e.from).toList(),
        ['looper', 'Andy', 'optimist'],
      );
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

  group('Kanban task metadata', () {
    test('a task carrying metadata is not dropped', () {
      // Mermaid writes `Task@{ … }` with no space, and requiring one meant
      // the line matched nothing and the task vanished from the board.
      final board = parser
          .parseWithData(
            'kanban\n  Todo\n    Write it@{assigned: "Bob", priority: "High"}',
          )!
          .kanbanChartData!;

      final task = board.columns.single.tasks.single;
      expect(task.description, 'Write it');
      expect(task.assigned, 'Bob');
    });

    test('a space before the metadata is still allowed', () {
      final board = parser
          .parseWithData('kanban\n  Todo\n    Write it @{assigned: "Bob"}')!
          .kanbanChartData!;

      expect(board.columns.single.tasks.single.assigned, 'Bob');
    });

    test('a task with no metadata is unaffected', () {
      final board = parser
          .parseWithData('kanban\n  Todo\n    Write it\n    Ship it')!
          .kanbanChartData!;

      expect(
        board.columns.single.tasks.map((t) => t.description).toList(),
        ['Write it', 'Ship it'],
      );
    });
  });

  group('Timeline sections', () {
    List<String> bandsOf(String source) {
      final timeline = parser.parseWithData(source)!.timelineChartData!;
      return timeline.sections
          .map((s) => '${s.group ?? "-"}/${s.title}')
          .toList();
    }

    test('a section bands the periods that follow it', () {
      expect(
        bandsOf(
          'timeline\n'
          '  section Phase one\n'
          '    2021 : Started\n'
          '    2022 : Grew\n'
          '  section Phase two\n'
          '    2023 : Expanded\n',
        ),
        ['Phase one/2021', 'Phase one/2022', 'Phase two/2023'],
      );
    });

    test('periods before the first section stay unbanded', () {
      expect(
        bandsOf('timeline\n  2020 : Prologue\n  section Main\n    2021 : Go\n'),
        ['-/2020', 'Main/2021'],
      );
    });

    test('a section line is not swallowed as an event description', () {
      // It carries no colon, so it used to fall through and be attached as the
      // description of whichever event came last — the band name was drawn as
      // text inside an unrelated event box.
      final timeline = parser
          .parseWithData(
            'timeline\n  2021 : Started\n  section Phase two\n    2022 : Grew\n',
          )!
          .timelineChartData!;
      expect(timeline.sections.first.events.single.description, isNull);
    });

    test('a timeline without sections is unbanded', () {
      expect(
        bandsOf('timeline\n  2021 : Started\n  2022 : Grew\n'),
        ['-/2021', '-/2022'],
      );
    });

    test('an event description still works', () {
      final timeline = parser
          .parseWithData('timeline\n  2021 : Started\n  Some detail\n')!
          .timelineChartData!;
      expect(timeline.sections.single.events.single.description, 'Some detail');
    });
  });

  group('Diagrams containing a pathological line', () {
    /// A long line inside a diagram block used to take seconds to reject:
    /// the pie slice pattern was unanchored, so it tried every position on a
    /// line with no colon, and the entity alias pattern grew two lazy runs
    /// against each other. Fourteen and twenty-seven seconds respectively,
    /// with the preview frozen.
    void expectFast(String label, String source) {
      final watch = Stopwatch()..start();
      parser.parseWithData(source);
      watch.stop();
      expect(
        watch.elapsedMilliseconds,
        lessThan(2000),
        reason: '$label took ${watch.elapsedMilliseconds}ms',
      );
    }

    test('a pie chart with a line that is not a slice', () {
      expectFast('no colon', 'pie\n${'a' * 20000}');
      expectFast('brackets', 'pie\n${'[' * 20000}');
      expectFast('pipes', 'pie\n${'|' * 20000}');
    });

    test('an entity diagram with a line that is not an entity', () {
      expectFast('brackets', 'erDiagram\n${'[' * 20000}');
      expectFast('mixed', 'erDiagram\n${'[a](b' * 4000}');
    });

    test('the slice and alias patterns still read ordinary lines', () {
      final pie = parser
          .parseWithData('pie\n  "Dogs" : 386\n  Cats : 85\n')!
          .pieChartData!;
      expect(
        pie.slices.map((s) => '${s.label}=${s.value}').toList(),
        ['Dogs=386.0', 'Cats=85.0'],
      );

      final er = parser
          .parseWithData('erDiagram\n  CUSTOMER["顾客"] ||--o{ ORDER : places\n')!
          .erDiagramData!;
      final customer = er.entities.firstWhere((e) => e.name == 'CUSTOMER');
      expect(customer.alias, '顾客');
      expect(customer.displayName, '顾客');
    });
  });

  group('Pie chart titles', () {
    test('a title on the header line is kept', () {
      // Mermaid's own documentation opens with `pie title Pets adopted by
      // volunteers`. Only `showData` was read off that line, so the title
      // spelling most people copy was silently dropped.
      final pie = parser
          .parseWithData('pie title Pets adopted\n  "Dogs" : 386\n')!
          .pieChartData!;
      expect(pie.title, 'Pets adopted');
      expect(pie.slices, hasLength(1));
    });

    test('showData and a header title compose', () {
      final pie = parser
          .parseWithData('pie showData title Counts\n  "Dogs" : 386\n')!
          .pieChartData!;
      expect(pie.title, 'Counts');
      expect(pie.showValuesInLegend, isTrue);
    });

    test('a title on its own line still wins', () {
      final pie = parser
          .parseWithData('pie title Header\n  title Own line\n  "A" : 1\n')!
          .pieChartData!;
      expect(pie.title, 'Own line');
    });

    test('a chart with no title is unaffected', () {
      final pie =
          parser.parseWithData('pie\n  "A" : 1\n')!.pieChartData!;
      expect(pie.title, isNull);
      expect(pie.showValuesInLegend, isFalse);
    });
  });

  group('Kanban indentation', () {
    List<String> shapeOf(String source) {
      final board = parser.parseWithData(source)?.kanbanChartData;
      if (board == null) return ['(null)'];
      return board.columns
          .map((c) => '${c.title}(${c.tasks.length})')
          .toList();
    }

    test('columns may be indented four spaces', () {
      // Mermaid reads kanban indentation as relative depth. A fixed "four
      // spaces or more is a task" threshold made every column a task, left the
      // board with no columns, and the diagram failed to render at all.
      expect(
        shapeOf('kanban\n    Todo\n      Write it\n    Doing\n      Ship it'),
        ['Todo(1)', 'Doing(1)'],
      );
    });

    test('columns may sit at the left margin', () {
      expect(
        shapeOf('kanban\nTodo\n  Write it\nDoing\n  Ship it'),
        ['Todo(1)', 'Doing(1)'],
      );
    });

    test('tabs indent as well as spaces do', () {
      // The task test asked for four literal spaces, so a tab-indented task
      // was read as another column.
      expect(
        shapeOf('kanban\n\tTodo\n\t\tWrite it\n\tDoing\n\t\tShip it'),
        ['Todo(1)', 'Doing(1)'],
      );
    });

    test('the two-space form still works', () {
      expect(
        shapeOf('kanban\n  Todo\n    Write it\n  Doing\n    Ship it'),
        ['Todo(1)', 'Doing(1)'],
      );
    });

    test('a board with no columns is not a diagram', () {
      expect(parser.parseWithData('kanban\n'), isNull);
    });
  });

  group('Timelines', () {
    TimelineChartData timelineOf(String source) =>
        parser.parseWithData(source)!.timelineChartData!;

    test('several events on one period become several events', () {
      // Splitting on the first colon only left "Facebook : Google" as a
      // single box; mermaid draws one box per colon-separated entry.
      final chart = timelineOf(
        'timeline\n  title History\n  2004 : Facebook : Google',
      );

      final period = chart.sections.single;
      expect(period.title, '2004');
      expect(period.events.map((e) => e.title).toList(),
          ['Facebook', 'Google']);
    });

    test('a continuation line adds to the period above it', () {
      final chart = timelineOf('timeline\n  2002 : One\n       : Two');

      expect(chart.sections.single.events.map((e) => e.title).toList(),
          ['One', 'Two']);
    });

    test('periods stay separate', () {
      final chart =
          timelineOf('timeline\n  2002 : LinkedIn\n  2004 : Facebook');

      expect(chart.sections.map((s) => s.title).toList(), ['2002', '2004']);
    });
  });

  group('Flowchart style classes', () {
    test('a style class may be named in any script', () {
      // `\w` is ASCII-only in Dart, so `classDef 红色 …` matched nothing: the
      // style was dropped and so was the `class A 红色` referring to it.
      final result = parser.parseWithData(
        'graph TD\n  A --> B\n  classDef 红色 fill:#f96\n  class A 红色',
      )!;

      expect(result.diagram.style.classDefs.keys, contains('红色'));
      expect(
        result.diagram.nodes.firstWhere((n) => n.id == 'A').className,
        '红色',
      );
    });

    test('an ASCII class name still works', () {
      final result = parser.parseWithData(
        'graph TD\n  A --> B\n  classDef red fill:#f96\n  class A,B red',
      )!;

      expect(result.diagram.style.classDefs.keys, contains('red'));
      expect(
        result.diagram.nodes.map((n) => n.className).toList(),
        ['red', 'red'],
      );
    });
  });

  group('Gantt charts', () {
    GanttChartData ganttOf(String source) =>
        parser.parseWithData(source)!.ganttChartData!;

    test('a task written before any section still appears', () {
      // The painter draws sections, so a chart with no `section` line at all
      // came out completely blank.
      final chart = ganttOf(
        'gantt\n  dateFormat YYYY-MM-DD\n  First task :2024-01-01, 5d',
      );

      expect(chart.tasks, hasLength(1));
      expect(chart.sections.single.tasks.single.name, 'First task');
    });

    test('several status keywords are all consumed', () {
      // `crit, active` is ordinary mermaid. Reading only the first left
      // `active` to be taken as the task's id.
      final chart = ganttOf(
        'gantt\n'
        '  dateFormat YYYY-MM-DD\n'
        '  section Build\n'
        '    Coding :crit, active, 2024-02-20, 45d',
      );

      final task = chart.tasks.single;
      expect(task.status, GanttTaskStatus.critical);
      expect(task.id, isNot('active'));
    });

    test('a task named in another script keeps a usable id', () {
      // The id was built by stripping everything outside a-z0-9, which left a
      // Chinese task name as the empty string — so every such task shared one
      // id and `after <id>` could never find one.
      final chart = ganttOf(
        'gantt\n'
        '  dateFormat YYYY-MM-DD\n'
        '  section 甲\n'
        '    需求调研 :2024-01-01, 10d\n'
        '    原型设计 :after 需求调研, 5d',
      );

      expect(chart.tasks.first.id, isNotEmpty);
      // The dependency resolved, so the second task starts after the first
      // ends rather than at the chart's default date.
      expect(
        chart.tasks.last.startDate.isAfter(chart.tasks.first.endDate),
        isTrue,
      );
    });

    test('after may name several tasks', () {
      // `after a1 a2` starts once both have finished. The whole remainder was
      // taken as one id, so it matched no task and the start silently fell
      // back to "right after whatever came before me in the source".
      final chart = ganttOf(
        'gantt\n'
        '  dateFormat YYYY-MM-DD\n'
        '  section Build\n'
        '    A :a1, 2026-01-01, 5d\n'
        '    B :a2, 2026-01-10, 5d\n'
        '    C :after a1 a2, 3d',
      );

      final c = chart.tasks.last;
      expect(c.dependencies, ['a1', 'a2']);
      // The later of the two ends on the 14th, so C starts on the 15th.
      expect(c.startDate, DateTime(2026, 1, 15));
    });

    test('after resolves against the named task, not the previous one', () {
      final chart = ganttOf(
        'gantt\n'
        '  dateFormat YYYY-MM-DD\n'
        '  section Build\n'
        '    A :a1, 2026-01-01, 5d\n'
        '    B :a2, 2026-02-01, 5d\n'
        '    C :after a1, 3d',
      );

      expect(chart.tasks.last.startDate, DateTime(2026, 1, 6));
    });

    test('until ends a task where the referenced one begins', () {
      // `until` landed in the duration slot, parsed as no duration at all and
      // drew a zero-length bar.
      final chart = ganttOf(
        'gantt\n'
        '  dateFormat YYYY-MM-DD\n'
        '  section Build\n'
        '    A :a1, 2026-01-20, 5d\n'
        '    B :b1, 2026-01-01, until a1',
      );

      final b = chart.tasks.last;
      expect(b.startDate, DateTime(2026, 1, 1));
      // Day ranges are inclusive, so the bar stops the day before.
      expect(b.endDate, DateTime(2026, 1, 19));
      expect(b.dependencies, ['a1']);
    });

    test('after and until compose', () {
      final chart = ganttOf(
        'gantt\n'
        '  dateFormat YYYY-MM-DD\n'
        '  section Build\n'
        '    A :a1, 2026-01-01, 5d\n'
        '    C :c1, 2026-02-01, 3d\n'
        '    B :after a1, until c1',
      );

      final b = chart.tasks.last;
      expect(b.startDate, DateTime(2026, 1, 6));
      expect(b.endDate, DateTime(2026, 1, 31));
    });

    test('until against an unknown id does not collapse the chart', () {
      final chart = ganttOf(
        'gantt\n'
        '  dateFormat YYYY-MM-DD\n'
        '  section Build\n'
        '    A :a1, 2026-01-01, until nosuchtask',
      );

      final a = chart.tasks.single;
      expect(a.endDate.isBefore(a.startDate), isFalse);
    });

    test('a plain duration is unaffected', () {
      final chart = ganttOf(
        'gantt\n'
        '  dateFormat YYYY-MM-DD\n'
        '  section Build\n'
        '    A :a1, 2026-01-01, 30d',
      );

      expect(chart.tasks.single.endDate, DateTime(2026, 1, 30));
    });

    test('two tasks with the same name get different ids', () {
      final chart = ganttOf(
        'gantt\n'
        '  dateFormat YYYY-MM-DD\n'
        '  section 甲\n'
        '    Review :2024-01-01, 3d\n'
        '    Review :2024-02-01, 3d',
      );

      expect(chart.tasks.first.id, isNot(chart.tasks.last.id));
    });

    test('a milestone keeps zero length', () {
      final chart = ganttOf(
        'gantt\n'
        '  dateFormat YYYY-MM-DD\n'
        '  section Launch\n'
        '    Go live :milestone, m1, 2024-05-01, 0d',
      );

      final task = chart.tasks.single;
      expect(task.status, GanttTaskStatus.milestone);
      expect(task.startDate, task.endDate);
    });
  });

  group('State diagrams', () {
    MermaidDiagramData stateOf(String source) =>
        parser.parseWithData(source)!.diagram;

    test('a described state keeps its description, not its alias', () {
      // `state "…" as id` exists to give a state a readable name, and the
      // whole line was being ignored.
      final diagram = stateOf(
        'stateDiagram-v2\n  state "Sitting still" as idle\n  [*] --> idle',
      );

      final state = diagram.nodes.firstWhere((n) => n.id == 'idle');
      expect(state.label, 'Sitting still');
    });

    test('the two terminals are told apart', () {
      // Both were plain circles, so a reader could not see which end of a
      // diagram was the start and which was the finish.
      final diagram = stateOf(
        'stateDiagram-v2\n  [*] --> idle\n  idle --> [*]',
      );

      final start = diagram.nodes.firstWhere((n) => n.id == '__start__');
      final end = diagram.nodes.firstWhere((n) => n.id == '__end__');
      expect(start.shape, NodeShape.circle);
      expect(end.shape, NodeShape.doubleCircle);
      expect(end.shape, isNot(start.shape));
    });

    test('choice, fork and join are told apart', () {
      final diagram = stateOf(
        'stateDiagram-v2\n'
        '  state pick <<choice>>\n'
        '  state f <<fork>>\n'
        '  idle --> pick\n'
        '  idle --> f',
      );

      expect(
        diagram.nodes.firstWhere((n) => n.id == 'pick').shape,
        NodeShape.diamond,
      );
      // No bar shape exists here, so a fork stays a rectangle rather than
      // being drawn as something it is not.
      expect(
        diagram.nodes.firstWhere((n) => n.id == 'f').shape,
        NodeShape.rectangle,
      );
    });

    test('a composite state becomes a labelled group', () {
      final diagram = stateOf(
        'stateDiagram-v2\n'
        '  state Outer {\n'
        '    A --> B\n'
        '  }\n'
        '  B --> C',
      );

      final group = diagram.subgraphs.single;
      expect(group.label, 'Outer');
      expect(group.nodeIds, containsAll(['A', 'B']));
      expect(group.nodeIds, isNot(contains('C')));
    });

    test('composites nest, and the outer one holds the inner one members', () {
      final diagram = stateOf(
        'stateDiagram-v2\n'
        '  state Outer {\n'
        '    A --> B\n'
        '    state Inner {\n'
        '      C --> D\n'
        '    }\n'
        '  }',
      );

      final inner = diagram.subgraphs.firstWhere((g) => g.id == 'Inner');
      final outer = diagram.subgraphs.firstWhere((g) => g.id == 'Outer');
      expect(inner.nodeIds, ['C', 'D']);
      expect(outer.nodeIds, containsAll(['A', 'B', 'C', 'D']));

      // The subgraph box has an opaque fill, so the outer one has to be
      // painted first or it covers the inner box and its label completely.
      expect(diagram.subgraphs.map((g) => g.id).toList(), ['Outer', 'Inner']);
    });

    test('sibling composites keep the order they were written in', () {
      final diagram = stateOf(
        'stateDiagram-v2\n'
        '  state First {\n'
        '    A --> B\n'
        '  }\n'
        '  state Second {\n'
        '    C --> D\n'
        '  }',
      );

      expect(diagram.subgraphs.map((g) => g.id).toList(), ['First', 'Second']);
    });

    test('a start marker inside a composite is that composite own', () {
      // Sharing one start node across the diagram wired every composite's
      // entry point to the same circle.
      final diagram = stateOf(
        'stateDiagram-v2\n'
        '  [*] --> Outer\n'
        '  state Outer {\n'
        '    [*] --> A\n'
        '  }',
      );

      final starts = diagram.nodes.where((n) => n.id.startsWith('__start__'));
      expect(starts, hasLength(2));
    });

    test('direction is honoured', () {
      expect(
        stateOf('stateDiagram-v2\n  direction LR\n  A --> B').direction,
        DiagramDirection.leftToRight,
      );
    });

    test('the concurrency separator is not a transition', () {
      final diagram = stateOf(
        'stateDiagram-v2\n'
        '  state Both {\n'
        '    A --> B\n'
        '    --\n'
        '    C --> D\n'
        '  }',
      );

      expect(diagram.edges, hasLength(2));
    });

    test('a composite with no closing brace still groups what it got', () {
      final diagram =
          stateOf('stateDiagram-v2\n  state Outer {\n    A --> B');

      expect(diagram.subgraphs.single.nodeIds, ['A', 'B']);
    });
  });

  group('C4 diagrams', () {
    test('elements, their kinds and their external flag are read', () {
      final data = parser
          .parseWithData(
            'C4Context\n'
            '  title Internet Banking\n'
            '  Person(a, "Customer", "A customer of the bank")\n'
            '  Person_Ext(b, "Outside customer")\n'
            '  System(c, "Banking System")\n'
            '  SystemDb_Ext(d, "Mainframe")',
          )!
          .c4DiagramData!;

      expect(data.title, 'Internet Banking');
      final elements = data.nodes.cast<C4Element>();
      expect(elements.map((e) => e.kind).toList(), [
        C4ElementKind.person,
        C4ElementKind.person,
        C4ElementKind.system,
        C4ElementKind.database,
      ]);
      expect(elements.map((e) => e.isExternal).toList(),
          [false, true, false, true]);
      expect(elements.first.description, 'A customer of the bank');
    });

    test('a description may contain commas', () {
      // Splitting the arguments on every comma would cut this in three.
      final data = parser
          .parseWithData(
            'C4Context\n  Person(a, "Customer", "Has two accounts, both current")',
          )!
          .c4DiagramData!;

      expect(
        (data.nodes.single as C4Element).description,
        'Has two accounts, both current',
      );
    });

    test('Container puts its third argument in technology, not description',
        () {
      // Person and System take (alias, label, description); Container takes
      // (alias, label, technology, description).
      final data = parser
          .parseWithData(
            'C4Container\n  Container(w, "Web app", "Java", "Serves pages")',
          )!
          .c4DiagramData!;

      final element = data.nodes.single as C4Element;
      expect(element.technology, 'Java');
      expect(element.description, 'Serves pages');
    });

    test('a boundary holds what is written inside its braces', () {
      final data = parser
          .parseWithData(
            'C4Context\n'
            '  Person(a, "Outside")\n'
            '  Enterprise_Boundary(b1, "Bank") {\n'
            '    Person(b, "Inside")\n'
            '    System(c, "Core")\n'
            '  }',
          )!
          .c4DiagramData!;

      expect(data.nodes, hasLength(2));
      final boundary = data.nodes.last as C4Boundary;
      expect(boundary.label, 'Bank');
      expect(boundary.type, 'Enterprise');
      expect(boundary.children.map((c) => c.alias).toList(), ['b', 'c']);
    });

    test('boundaries nest, and the layout draws the outer one first', () {
      final data = parser
          .parseWithData(
            'C4Container\n'
            '  System_Boundary(outer, "Outer") {\n'
            '    Container(web, "Web", "Java")\n'
            '    Container_Boundary(inner, "Inner") {\n'
            '      ContainerDb(db, "Store", "Postgres")\n'
            '    }\n'
            '  }',
          )!
          .c4DiagramData!;
      final layout = C4Layout.compute(data, availableWidth: 900);

      expect(layout.boundaries.map((b) => b.boundary.alias).toList(),
          ['outer', 'inner']);
      final outer = layout.boundaries.first;
      final inner = layout.boundaries.last;
      expect(inner.left, greaterThan(outer.left));
      expect(inner.left + inner.width, lessThanOrEqualTo(outer.left + outer.width));
      expect(layout.find('db')!.left, greaterThan(inner.left));
    });

    test('relations read their direction and both arrowheads', () {
      final data = parser
          .parseWithData(
            'C4Context\n'
            '  Person(a, "A")\n'
            '  System(b, "B")\n'
            '  Rel(a, b, "Uses", "HTTPS")\n'
            '  BiRel(a, b, "Talks to")\n'
            '  Rel_U(b, a, "Answers")',
          )!
          .c4DiagramData!;

      expect(data.relations, hasLength(3));
      expect(data.relations[0].technology, 'HTTPS');
      expect(data.relations[0].bidirectional, isFalse);
      expect(data.relations[1].bidirectional, isTrue);
      expect(data.relations[2].direction, C4RelationDirection.up);
    });

    test('UpdateLayoutConfig sets how many boxes share a row', () {
      final data = parser
          .parseWithData(
            'C4Context\n'
            '  UpdateLayoutConfig(\$c4ShapeInRow="2")\n'
            '  System(a, "A")\n'
            '  System(b, "B")\n'
            '  System(c, "C")',
          )!
          .c4DiagramData!;
      final layout = C4Layout.compute(data, availableWidth: 900);

      expect(data.shapesPerRow, 2);
      expect(layout.find('c')!.top, greaterThan(layout.find('a')!.top));
      expect(layout.find('c')!.left, layout.find('a')!.left);
    });

    test('a boundary with no closing brace still keeps its contents', () {
      final data = parser
          .parseWithData(
            'C4Context\n  System_Boundary(b, "Edge") {\n    System(a, "A")',
          )!
          .c4DiagramData!;

      expect((data.nodes.single as C4Boundary).children, hasLength(1));
    });

    test('a header with nothing under it falls back to the source', () {
      expect(parser.parseWithData('C4Context'), isNull);
    });
  });

  group('Block diagrams', () {
    test('columns set the grid width and the rows wrap', () {
      final data = parser
          .parseWithData('block-beta\n  columns 3\n  a b c\n  d')!
          .blockDiagramData!;
      final layout = BlockLayout.compute(data, availableWidth: 600);

      expect(data.columns, 3);
      expect(layout.blocks, hasLength(4));
      // The fourth block wrapped, so it shares a left edge with the first and
      // sits a row lower.
      expect(layout.find('d')!.left, layout.find('a')!.left);
      expect(layout.find('d')!.top, greaterThan(layout.find('a')!.top));
    });

    test('a bracketed label and its shape are read', () {
      final data = parser
          .parseWithData(
            'block-beta\n'
            '  columns 3\n'
            '  a["Square"] b("Round") c(("Circle"))\n'
            '  d{"Diamond"} e{{"Hexagon"}} f[["Sub"]]\n'
            '  g(["Stadium"]) h[("Store")]',
          )!
          .blockDiagramData!;

      expect(data.items.map((i) => i.label).toList(), [
        'Square',
        'Round',
        'Circle',
        'Diamond',
        'Hexagon',
        'Sub',
        'Stadium',
        'Store',
      ]);
      expect(data.items.map((i) => i.shape).toList(), [
        NodeShape.rectangle,
        NodeShape.roundedRect,
        NodeShape.circle,
        NodeShape.diamond,
        NodeShape.hexagon,
        NodeShape.subroutine,
        NodeShape.stadium,
        NodeShape.cylinder,
      ]);
    });

    test('a label may contain spaces', () {
      // Splitting the row on every space would make three blocks of this one.
      final data = parser
          .parseWithData('block-beta\n  columns 2\n  a["two words"] b')!
          .blockDiagramData!;

      expect(data.items.map((i) => i.label).toList(), ['two words', 'b']);
    });

    test('a span makes a block wider and pushes the rest along', () {
      final data = parser
          .parseWithData('block-beta\n  columns 3\n  a["wide"]:2 b\n  c')!
          .blockDiagramData!;
      final layout = BlockLayout.compute(data, availableWidth: 600);

      expect(layout.find('a')!.width, greaterThan(layout.find('b')!.width));
      expect(layout.find('c')!.top, greaterThan(layout.find('a')!.top));
    });

    test('space reserves cells and draws nothing', () {
      final data = parser
          .parseWithData('block-beta\n  columns 3\n  a space b')!
          .blockDiagramData!;
      final layout = BlockLayout.compute(data, availableWidth: 600);

      expect(data.items, hasLength(3));
      expect(layout.blocks.map((b) => b.item.id).toList(), ['a', 'b']);
      // `b` sits in the third column, not the second.
      expect(layout.find('b')!.left, greaterThan(layout.find('a')!.left + 200));
    });

    test('arrows are read in both label spellings', () {
      final quoted = parser
          .parseWithData('block-beta\n  columns 2\n  a b\n  a -- "go" --> b')!
          .blockDiagramData!;
      expect(quoted.arrows.single.label, 'go');

      final piped = parser
          .parseWithData('block-beta\n  columns 2\n  a b\n  a -->|go| b')!
          .blockDiagramData!;
      expect(piped.arrows.single.from, 'a');
      expect(piped.arrows.single.to, 'b');
      expect(piped.arrows.single.label, 'go');
    });

    test('block ids may be written in any script', () {
      final data = parser
          .parseWithData('block-beta\n  columns 2\n  开始 结束\n  开始 --> 结束')!
          .blockDiagramData!;

      expect(data.items.map((i) => i.id).toList(), ['开始', '结束']);
      expect(data.arrows.single.to, '结束');
    });

    test('without columns everything sits on one row', () {
      final data =
          parser.parseWithData('block-beta\n  a b c')!.blockDiagramData!;
      final layout = BlockLayout.compute(data, availableWidth: 600);

      expect(layout.blocks.map((b) => b.top).toSet(), hasLength(1));
    });

    test('a header with no blocks falls back to the source', () {
      expect(parser.parseWithData('block-beta'), isNull);
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
      // Read once, by MermaidParser, and carried on the diagram: this parser
      // used to read the block a second time, which is why only this diagram
      // type could be titled that way.
      final result = parser.parseWithData(
        '---\ntitle: 能源流向\n---\nsankey-beta\n煤炭,发电,100',
      )!;

      expect(result.diagram.type, DiagramType.sankey);
      expect(result.diagram.title, '能源流向');
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

  group('A diagram with nothing in it is rejected, not drawn blank', () {
    const parser = MermaidParser();

    test('a mistyped arrow no longer draws an empty box', () {
      // Upstream MarkText hands this to `mermaid.parse`, which rejects it, and
      // shows an error node in its place. Ours understood the header, found no
      // node and no edge, and painted an empty box — which reads as a broken
      // renderer rather than as a typo.
      expect(parser.parseWithData('graph TD\n  A--->'), isNull);
      expect(
        parser.describeParseFailure('graph TD\n  A--->'),
        contains('check the syntax below it'),
      );
    });

    test('a header on its own says so, rather than blaming the body', () {
      expect(parser.parseWithData('flowchart TD'), isNull);
      expect(
        parser.describeParseFailure('flowchart TD'),
        contains('no content'),
      );
    });

    test('an unknown type still names what is supported', () {
      // zenuml, packet-beta, architecture-beta and treemap-beta are the four
      // mermaid 11 types not implemented here.
      expect(parser.parseWithData('architecture-beta\n  group api(cloud)[API]'),
          isNull);
      expect(
        parser.describeParseFailure('architecture-beta\n  group api(cloud)[API]'),
        contains('Unrecognised diagram type'),
      );
    });

    test('every implemented type still parses to something', () {
      // The guard rejects an empty result, so it has to be shown that no real
      // diagram falls into it. These are one sample per supported type.
      const samples = <String, String>{
        'flowchart': 'flowchart TD\n  A[Start] --> B{Choice}\n  B -->|yes| C[Do]',
        'sequence': 'sequenceDiagram\n  Alice->>John: Hello',
        'class': 'classDiagram\n  Animal <|-- Duck',
        'state': 'stateDiagram-v2\n  [*] --> Still\n  Still --> [*]',
        'er': 'erDiagram\n  CUSTOMER ||--o{ ORDER : places',
        'journey': 'journey\n  title My day\n  section Work\n    Tea: 5: Me',
        'gitGraph': 'gitGraph\n  commit\n  branch dev\n  checkout dev\n  commit',
        'mindmap': 'mindmap\n  root((core))\n    Origins',
        'pie': 'pie title Pets\n  "Dogs" : 386\n  "Cats" : 85',
        'gantt': 'gantt\n  dateFormat YYYY-MM-DD\n  section S\n  A :a1, 2014-01-01, 30d',
        'timeline': 'timeline\n  title History\n  2002 : LinkedIn',
        'kanban': 'kanban\n  Todo\n    t1[Create]',
        'radar': 'radar-beta\n  axis a["A"], b["B"], c["C"]\n  curve x["X"]{1,2,3}\n  max 5',
        'xychart': 'xychart-beta\n  x-axis [jan, feb]\n  bar [30, 60]',
        'quadrant': 'quadrantChart\n  x-axis Low --> High\n  y-axis Low --> High\n  A: [0.3, 0.6]',
        'requirement': 'requirementDiagram\n  requirement r {\n    id: 1\n    text: t\n    risk: high\n    verifymethod: test\n  }',
        'sankey': 'sankey-beta\n\nA,B,124.729',
        'block': 'block-beta\n  columns 3\n  a b c',
        'c4': 'C4Context\n  Person(a, "User", "d")\n  System(b, "Sys", "d")\n  Rel(a, b, "uses")',
      };
      for (final entry in samples.entries) {
        expect(parser.parseWithData(entry.value), isNotNull,
            reason: '${entry.key} 被空结果守卫误伤了');
      }
    });
  });

  group('The failure reason is reported without being worded', () {
    const parser = MermaidParser();

    test('each kind of failure is told apart', () {
      // The package cannot reach the app's translations without giving up its
      // one useful property — it depends on nothing but Flutter — so it hands
      // back the reason and lets the app word it. Twelve languages were all
      // reading the same English sentence before this.
      expect(parser.describeFailure('').kind, MermaidFailureKind.empty);
      expect(parser.describeFailure('   \n  %% just a comment\n').kind,
          MermaidFailureKind.empty);

      final unknown = parser.describeFailure('architecture-beta\n  group a');
      expect(unknown.kind, MermaidFailureKind.unknownType);
      expect(unknown.detail, 'architecture-beta',
          reason: '要引用回用户自己写的那一行');

      expect(parser.describeFailure('flowchart TD').kind,
          MermaidFailureKind.headerOnly);
      expect(parser.describeFailure('graph TD\n  A--->').kind,
          MermaidFailureKind.unparsedBody);
    });

    test('the English wording still agrees with the reason', () {
      // describeParseFailure is now built on describeFailure rather than
      // repeating the decision, so the two cannot drift apart.
      expect(parser.describeParseFailure(''), contains('empty'));
      expect(parser.describeParseFailure('architecture-beta\n  group a'),
          contains('Unrecognised diagram type'));
      expect(parser.describeParseFailure('flowchart TD'), contains('no content'));
      expect(parser.describeParseFailure('graph TD\n  A--->'),
          contains('check the syntax below it'));
    });
  });
}

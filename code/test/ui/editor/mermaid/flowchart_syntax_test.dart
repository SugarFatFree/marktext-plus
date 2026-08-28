import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/mermaid.dart';

/// Every node shape and link mermaid's flowchart grammar defines.
///
/// Checked one by one rather than by example: `A(((Double)))` was drawn as a
/// plain circle labelled `(Double)` — the greedy double-circle pattern
/// swallowed the inner parentheses into the text — and `A ~~~ B` was dropped
/// entirely, which loses the layout constraint the author wrote it for.
///
/// The link semantics are mermaid's own, read out of `destructLink` in
/// mermaid 11.16: the stroke comes from what the link starts with, `=` being
/// thick and `~` invisible, with a run of dots overriding both.
void main() {
  MermaidDiagramData chart(String body) =>
      const MermaidParser().parse('flowchart TD\n  $body\n')!;

  group('node shapes', () {
    const shapes = <String, (String, NodeShape)>{
      'A[Rect]': ('Rect', NodeShape.rectangle),
      'A(Round)': ('Round', NodeShape.roundedRect),
      'A([Stadium])': ('Stadium', NodeShape.stadium),
      'A[[Sub]]': ('Sub', NodeShape.subroutine),
      'A[(Db)]': ('Db', NodeShape.cylinder),
      'A((Circle))': ('Circle', NodeShape.circle),
      'A(((Double)))': ('Double', NodeShape.doubleCircle),
      'A>Flag]': ('Flag', NodeShape.asymmetric),
      'A{Decision}': ('Decision', NodeShape.diamond),
      'A{{Hex}}': ('Hex', NodeShape.hexagon),
      'A[/Para/]': ('Para', NodeShape.parallelogram),
      r'A[\Para\]': ('Para', NodeShape.parallelogramAlt),
      r'A[/Trap\]': ('Trap', NodeShape.trapezoid),
      r'A[\Trap/]': ('Trap', NodeShape.trapezoidAlt),
    };

    test('each written shape is the shape that is drawn', () {
      for (final entry in shapes.entries) {
        final node = chart('${entry.key} --> B')
            .nodes
            .firstWhere((n) => n.id == 'A');
        expect(node.shape, entry.value.$2, reason: entry.key);
        expect(node.label, entry.value.$1,
            reason: '${entry.key} 的标签把括号也算进去了');
      }
    });

    test('every shape the model defines can be written', () {
      // A shape no syntax produces is a shape the painter draws for nobody.
      final produced = shapes.values.map((v) => v.$2).toSet();
      expect(NodeShape.values.toSet().difference(produced), isEmpty,
          reason: '有形状没有对应的写法，或这张表没跟上');
    });
  });

  group('links', () {
    test('a run of dots makes the line dotted, whatever it starts with', () {
      expect(chart('A -.-> B').edges.single.lineType, LineType.dotted);
      expect(chart('A -.- B').edges.single.lineType, LineType.dotted);
    });

    test('`=` makes it thick and `~` makes it invisible', () {
      expect(chart('A ==> B').edges.single.lineType, LineType.thick);
      expect(chart('A === B').edges.single.lineType, LineType.thick);
      expect(chart('A ~~~ B').edges.single.lineType, LineType.invisible,
          reason: '隐形连线被整条丢掉，布局约束也跟着没了');
    });

    test('an invisible link still connects the nodes it names', () {
      // That is the whole point of it: the layout must honour the pairing.
      final d = chart('A ~~~ B');
      expect(d.edges.single.from, 'A');
      expect(d.edges.single.to, 'B');
      expect(d.nodes.map((n) => n.id), containsAll(['A', 'B']));
    });

    test('labels are read in both the inline and the piped form', () {
      expect(chart('A -- text --> B').edges.single.label, 'text');
      expect(chart('A -->|text| B').edges.single.label, 'text');
      expect(chart('A -. text .-> B').edges.single.label, 'text');
      expect(chart('A == text ==> B').edges.single.label, 'text');
    });

    test('a longer link is still one link', () {
      for (final arrow in ['-->', '--->', '---->', '----->']) {
        expect(chart('A $arrow B').edges.length, 1, reason: arrow);
      }
    });

    test('circle and cross ends are read', () {
      expect(chart('A --o B').edges.single.arrowType, ArrowType.circle);
      expect(chart('A --x B').edges.single.arrowType, ArrowType.cross);
    });
  });
}

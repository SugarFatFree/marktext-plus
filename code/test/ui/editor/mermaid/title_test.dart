import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/parser/mermaid_parser.dart';

/// `---\ntitle: …\n---` is how mermaid titles a diagram, and for a flowchart
/// it is the only way. The block was skipped to find the header line and then
/// thrown away, so the title disappeared for every type.
void main() {
  const parser = MermaidParser();

  String? titleOf(String source) => parser.parseWithData(source)?.diagram.title;

  group('a frontmatter title reaches the diagram', () {
    test('on a flowchart, which has no title syntax of its own', () {
      expect(titleOf('---\ntitle: 我的流程\n---\nflowchart TD\nA --> B\n'),
          '我的流程');
    });

    test('on a sequence diagram too', () {
      expect(titleOf('---\ntitle: seq\n---\nsequenceDiagram\nA->>B: hi\n'),
          'seq');
    });

    test('quoted, because YAML allows it', () {
      expect(titleOf('---\ntitle: "quoted"\n---\nflowchart TD\nA --> B\n'),
          'quoted');
      expect(titleOf("---\ntitle: 'quoted'\n---\nflowchart TD\nA --> B\n"),
          'quoted');
    });

    test('with a line break, like any other label', () {
      expect(titleOf('---\ntitle: one<br/>two\n---\nflowchart TD\nA --> B\n'),
          'one\ntwo');
    });

    test('a block without a title leaves the diagram untitled', () {
      expect(titleOf('---\nconfig:\n  theme: dark\n---\nflowchart TD\nA --> B\n'),
          isNull);
    });

    test('no block at all leaves it untitled', () {
      expect(titleOf('flowchart TD\nA --> B\n'), isNull);
    });

    test('a block that never closes fails visibly rather than half-parsing',
        () {
      // Mermaid treats an unterminated block as an error, and so does this:
      // null reaches the widget as a message the reader can act on. What it
      // must not do is render half a diagram, or throw.
      expect(parser.parseWithData('---\nflowchart TD\nA --> B\n'), isNull);
      expect(() => parser.parseWithData('---\n'), returnsNormally);
      expect(() => parser.parseWithData('---\n---\n'), returnsNormally);
    });
  });

  group('a title the diagram wrote itself wins', () {
    test('a pie keeps its own', () {
      final result = parser
          .parseWithData('---\ntitle: FM\n---\npie title mine\n"a" : 40\n')!;
      expect(result.pieChartData!.title, 'mine');
    });

    test('the header line is still read when a block precedes it', () {
      // The block used to be handed to the type parsers, so the first line
      // they saw was `---` and `pie title mine` was never found.
      final result =
          parser.parseWithData('---\ntitle: FM\n---\npie title mine\n"a" : 40\n')!;
      expect(result.pieChartData!.title, isNot('FM'));
    });

    test('a pie with no title of its own takes the block one', () {
      final result =
          parser.parseWithData('---\ntitle: FM\n---\npie\n"a" : 40\n')!;
      expect(result.diagram.title, 'FM');
    });
  });
}

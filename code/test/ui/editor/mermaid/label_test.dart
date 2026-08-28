import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/mermaid/layout/dagre_layout.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/style.dart';
import 'package:marktext_plus/ui/editor/mermaid/parser/label.dart';
import 'package:marktext_plus/ui/editor/mermaid/parser/mermaid_parser.dart';

/// What a diagram writes between its delimiters, and what should be drawn.
///
/// Each parser used to do part of this job: node labels lost their quotes,
/// edge labels kept them, and nothing understood `<br/>` — the way every
/// mermaid document wraps text inside a box — so the tag was drawn as five
/// characters in the middle of the node.
void main() {
  const parser = MermaidParser();

  String labelOf(String source, String id) =>
      parser.parse(source)!.nodes.firstWhere((n) => n.id == id).label;

  String? edgeLabelOf(String source) => parser.parse(source)!.edges.first.label;

  group('cleanLabel', () {
    test('turns every spelling of a line break into one', () {
      for (final tag in ['<br>', '<br/>', '<br />', '<BR>', '<Br/>']) {
        expect(cleanLabel('a${tag}b'), 'a\nb', reason: '$tag 没有变成换行');
      }
    });

    test('drops the quotes that delimit a label', () {
      expect(cleanLabel('"with [brackets]"'), 'with [brackets]');
      expect(cleanLabel("'single'"), 'single');
      expect(cleanLabel('no quotes'), 'no quotes');
    });

    test('keeps a quote that is part of the text', () {
      expect(cleanLabel(r'say \"hi\"'), 'say "hi"');
    });

    test('decodes the entities a diagram carries', () {
      expect(cleanLabel('a &amp; b'), 'a & b');
      expect(cleanLabel('&lt;tag&gt;'), '<tag>');
      expect(cleanLabel('&quot;q&quot;'), '"q"');
    });

    test('decodes an escaped ampersand without going round twice', () {
      // `&amp;` is decoded last: doing it first turns `&amp;lt;` into `<`,
      // which is not what the author wrote.
      expect(cleanLabel('&amp;lt;'), '&lt;');
    });

    test('an absent label is empty, not the word null', () {
      expect(cleanLabel(null), '');
    });
  });

  group('through the parser', () {
    test('a node label breaks where the source says', () {
      expect(labelOf('flowchart TD\nA[one<br/>two] --> B\n', 'A'), 'one\ntwo');
    });

    test('an edge label loses its quotes, as a node label already did', () {
      expect(edgeLabelOf('flowchart TD\nA -- "spoken" --> B\n'), 'spoken');
      expect(labelOf('flowchart TD\nA["spoken"] --> B\n', 'A'), 'spoken');
    });

    test('an edge with no label has none, rather than an empty one', () {
      // The painter draws a background wherever there is a label, and an
      // empty one left a box floating on the line.
      expect(edgeLabelOf('flowchart TD\nA --> B\n'), isNull);
    });
  });

  group('a node is measured for the lines it holds', () {
    Size sizeOf(String label) {
      final diagram = parser.parse('flowchart TD\nA[$label] --> B\n')!;
      DagreLayout()
          .computeLayout(diagram, const MermaidStyle(), const Size(900, 700));
      final node = diagram.nodes.firstWhere((n) => n.id == 'A');
      return Size(node.width, node.height);
    }

    test('two lines are taller and narrower than one long one', () {
      // Measuring the whole string as a single line made the box far too
      // wide and one line too short, so the second line fell outside it.
      final one = sizeOf('firstsecond');
      final two = sizeOf('first<br/>second');

      expect(two.height, greaterThan(one.height));
      expect(two.width, lessThan(one.width));
    });

    test('height grows with each line', () {
      expect(sizeOf('a<br/>b<br/>c').height, greaterThan(sizeOf('a<br/>b').height));
    });
  });
}

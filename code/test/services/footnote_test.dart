import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// Footnotes, checked against the scenarios upstream MarkText states in
/// `blocks/footnote-scenarios.spec.ts` plus the parts of the syntax that
/// scenario file does not reach: a body that runs over more than one line,
/// a body carrying inline markup, and an identifier with a space in it.
void main() {
  final parser = MarkdownParser();

  List<MarkdownNode> parse(String md) => parser.parse(md);
  String html(String md) => parse(md).map(ExportService.nodeToHtml).join();

  group('upstream scenarios', () {
    test('one definition serves every reference to it', () {
      final out = html('A[^a] B[^a] C[^a]\n\n[^a]: shared body\n');
      expect('#fn-a"'.allMatches(out), hasLength(3));
      expect(out, contains('id="fn-a"'));
      expect(out, contains('shared body'));
    });

    test('a definition placed before its reference still resolves', () {
      final out = html('[^a]: defined first\n\nLater[^a] paragraph\n');
      expect(out, contains('id="fn-a"'));
      expect(out, contains('href="#fn-a"'));
    });

    test('a definition nobody refers to is kept, not tidied away', () {
      final nodes = parse('Body text\n\n[^a]: orphan body\n');
      expect(nodes.map((n) => n.type),
          [NodeType.paragraph, NodeType.footnoteDefinition]);
    });
  });

  group('a definition that runs over several lines', () {
    test('an indented continuation stays inside the note', () {
      // Without this the second line broke out and became a paragraph, so it
      // read as body text of the document rather than part of the note.
      final nodes = parse('见[^a]\n\n[^a]: 第一行\n    第二行\n');
      expect(nodes.map((n) => n.type),
          [NodeType.paragraph, NodeType.footnoteDefinition]);
      final def = nodes.last as FootnoteDefinitionNode;
      expect(def.content, '第一行\n第二行');
    });

    test('a tab indents a continuation too', () {
      final def = parse('[^a]: one\n\ttwo\n').single as FootnoteDefinitionNode;
      expect(def.content, 'one\ntwo');
    });

    test('an unindented line is a new block, not a continuation', () {
      final nodes = parse('[^a]: one\ntwo\n');
      expect(nodes, hasLength(2));
      expect((nodes.first as FootnoteDefinitionNode).content, 'one');
    });

    test('a blank line ends the note', () {
      final nodes = parse('[^a]: one\n\n    two\n');
      expect(nodes.first.type, NodeType.footnoteDefinition);
      expect((nodes.first as FootnoteDefinitionNode).content, 'one');
      expect(nodes, hasLength(2));
    });
  });

  group('the body is markdown, not plain text', () {
    test('a link in the body arrives as a link', () {
      // This is the ordinary case, not an exotic one: a footnote is where a
      // citation goes. The body used to be escaped wholesale, so a reader saw
      // the brackets and the address.
      expect(
        html('x[^a]\n\n[^a]: see [the paper](https://example.com)\n'),
        contains('<a href="https://example.com">the paper</a>'),
      );
    });

    test('emphasis in the body is emphasis', () {
      expect(
        html('x[^a]\n\n[^a]: **粗** 和 `代码`\n'),
        allOf(contains('<strong>粗</strong>'), contains('<code>代码</code>')),
      );
    });

    test('the body is still escaped where it is not markup', () {
      expect(html('x[^a]\n\n[^a]: 5 < 6 & 7\n'),
          allOf(contains('5 &lt; 6'), contains('&amp; 7')));
    });
  });

  group('the identifier', () {
    test('a space in it does not break the anchor', () {
      // `[^my note]` is a valid identifier, but a space is not valid in an
      // HTML id and makes the fragment in the href point nowhere. Both ends
      // are written the same way so they still match.
      final out = html('x[^my note]\n\n[^my note]: 注\n');
      expect(out, contains('id="fn-my-note"'));
      expect(out, contains('href="#fn-my-note"'));
      expect(out, contains('[my note]'), reason: '显示的标识不该被改写');
    });

    test('a numeric identifier works', () {
      expect(html('x[^1]\n\n[^1]: 注\n'), contains('id="fn-1"'));
    });
  });

  test('the round-trip form keeps the caret', () {
    // `[a]: body` without it is a link reference definition — a different
    // construct that merely looks similar. The preview showed the same thing.
    final def = parse('[^a]: body\n').single as FootnoteDefinitionNode;
    expect(def.rawContent, '[^a]: body');
  });
}

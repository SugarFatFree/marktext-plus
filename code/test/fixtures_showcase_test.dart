import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/diagram.dart';
import 'package:marktext_plus/ui/editor/mermaid/parser/mermaid_parser.dart';

/// End-to-end check over a document that uses every construct at once.
///
/// The per-feature tests each parse a snippet in isolation; this one exists to
/// catch the cases where constructs interfere — a fence swallowing the section
/// after it, a table ending a list early, and so on.
void main() {
  late String markdown;
  late MarkdownParser parser;

  setUpAll(() {
    markdown = File('test/fixtures/showcase.md').readAsStringSync();
  });

  setUp(() => parser = MarkdownParser());

  test('every block type survives being parsed together', () {
    final nodes = parser.parse(markdown);
    final types = nodes.map((n) => n.type).toSet();

    for (final expected in [
      NodeType.frontMatter,
      NodeType.heading,
      NodeType.paragraph,
      NodeType.codeBlock,
      NodeType.orderedList,
      NodeType.unorderedList,
      NodeType.blockquote,
      NodeType.horizontalRule,
      NodeType.table,
      NodeType.mathBlock,
      NodeType.footnoteDefinition,
      NodeType.htmlBlock,
    ]) {
      expect(types, contains(expected), reason: '$expected went missing');
    }
  });

  test('source line ranges stay ordered and within the document', () {
    final nodes = parser.parse(markdown);
    final lineCount = markdown.split('\n').length;

    var previousEnd = 0;
    for (final node in nodes) {
      expect(node.sourceStart, greaterThanOrEqualTo(previousEnd),
          reason: '${node.type} starts before the previous block ended');
      expect(node.sourceEnd, greaterThan(node.sourceStart),
          reason: '${node.type} has an empty range');
      expect(node.sourceEnd, lessThanOrEqualTo(lineCount));
      previousEnd = node.sourceEnd;
    }
  });

  test('every block round-trips through sourceOfBlock', () {
    final nodes = parser.parse(markdown);
    for (final node in nodes) {
      final source = MarkdownParser.sourceOfBlock(markdown, node);
      expect(source, isNotEmpty, reason: '${node.type} produced no source');
      // Replacing a block with its own source must leave the document alone.
      expect(
        MarkdownParser.replaceBlock(markdown, node, source),
        markdown,
        reason: '${node.type} does not round-trip',
      );
    }
  });

  test('every mermaid block parses to a known diagram type', () {
    final nodes = parser.parse(markdown);
    final codeBlocks = nodes.whereType<CodeBlockNode>().toList();

    // Report what was actually found: this assertion came back with zero once,
    // and the message needs to say why rather than just restate the count.
    expect(
      codeBlocks,
      isNotEmpty,
      reason: 'no code blocks at all in ${nodes.length} nodes; '
          'types were ${nodes.map((n) => n.type).toSet()}',
    );

    final diagrams = codeBlocks
        .where((c) => c.language.toLowerCase() == 'mermaid')
        .toList();

    expect(
      diagrams.length,
      20,
      reason: 'fence languages found: ${codeBlocks.map((c) => c.language).toList()}',
    );

    // Collect every failure before asserting: stopping at the first one means
    // each CI run reveals a single broken diagram, and there are fourteen.
    const mermaid = MermaidParser();
    final failures = <String>[];

    for (final block in diagrams) {
      final firstLine = block.code.trim().split('\n').first;
      final result = mermaid.parseWithData(block.code);
      if (result == null) {
        failures.add('did not parse: $firstLine');
      } else if (result.diagram.type == DiagramType.unknown) {
        failures.add('unknown type: $firstLine');
      }
    }

    expect(failures, isEmpty, reason: failures.join('; '));
  });

  test('exports the whole document to HTML without leaking raw markers', () {
    final nodes = parser.parse(markdown);
    final html = nodes.map(ExportService.nodeToHtml).join('\n');

    expect(html, contains('<strong>bold</strong>'));
    expect(html, contains('<em>italic</em>'));
    expect(html, contains('<del>strikethrough</del>'));
    expect(html, contains('<a href="https://example.com"'));

    // Escaping must survive: the fixture contains a < b and x & y.
    expect(html, contains('a &lt; b'));
    expect(html, contains('x &amp; y'));
  });
}

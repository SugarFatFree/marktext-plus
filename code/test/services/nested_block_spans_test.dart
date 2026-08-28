import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// A block inside a quote, or under a list item, is parsed from text that has
/// been lifted out of the document. It used to come back numbered from zero,
/// which meant the preview's "edit source" wrote the edit over the *top* of
/// the document instead of over the block.
void main() {
  T only<T extends MarkdownNode>(List<MarkdownNode> ast) =>
      MarkdownParser.walk(ast).whereType<T>().first;

  test('a diagram inside a quote reports its own lines', () {
    const doc = 'intro paragraph\n'
        '\n'
        '> ```mermaid\n'
        '> graph TD\n'
        '> A-->B\n'
        '> ```\n';
    final ast = MarkdownParser().parse(doc);
    final code = only<CodeBlockNode>(ast);
    expect(code.language, 'mermaid');
    expect(MarkdownParser.sourceOfBlock(doc, code),
        '> ```mermaid\n> graph TD\n> A-->B\n> ```');
  });

  test('editing a quoted block leaves the rest of the document alone', () {
    const doc = 'intro paragraph\n'
        '\n'
        '> ```mermaid\n'
        '> graph TD\n'
        '> ```\n';
    final ast = MarkdownParser().parse(doc);
    final code = only<CodeBlockNode>(ast);
    final edited = MarkdownParser.replaceBlock(doc, code, '> replaced');
    expect(edited, 'intro paragraph\n\n> replaced\n');
  });

  test('a code fence under a numbered step reports its own lines', () {
    const doc = 'intro\n'
        '\n'
        '1. step one\n'
        '\n'
        '   ```dart\n'
        '   void main() {}\n'
        '   ```\n';
    final ast = MarkdownParser().parse(doc);
    final code = only<CodeBlockNode>(ast);
    expect(code.language, 'dart');
    expect(MarkdownParser.sourceOfBlock(doc, code),
        '   ```dart\n   void main() {}\n   ```');
  });

  test('the second step\'s carried block is not the first step\'s', () {
    const doc = '1. step one\n'
        '\n'
        '   first block\n'
        '\n'
        '2. step two\n'
        '\n'
        '   second block\n';
    final ast = MarkdownParser().parse(doc);
    final carried = MarkdownParser.walk(ast)
        .whereType<ParagraphNode>()
        .where((n) => n.content.contains('block'))
        .toList();
    expect(carried.length, 2);
    expect(MarkdownParser.sourceOfBlock(doc, carried[0]).trim(), 'first block');
    expect(MarkdownParser.sourceOfBlock(doc, carried[1]).trim(), 'second block');
  });

  test('a quote inside a quote still lands on its own lines', () {
    const doc = 'top\n'
        '\n'
        '> outer\n'
        '>\n'
        '> > inner quote\n';
    final ast = MarkdownParser().parse(doc);
    final inner = MarkdownParser.walk(ast)
        .whereType<BlockquoteNode>()
        .firstWhere((n) => n.depth == 1);
    expect(MarkdownParser.sourceOfBlock(doc, inner).trim(), '> > inner quote');
  });
}

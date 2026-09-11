import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// A line that begins with a number and a dot, inside a paragraph, is prose.
///
/// Prose wraps. "The number of windows in my house is / 14. The number of
/// doors is 6." is one sentence that happened to break before the fourteen,
/// and reading the second line as a list took the paragraph apart in front of
/// the reader: the first half left as a paragraph, the second half numbered
/// from fourteen with the sentence as its only item.
///
/// CommonMark's rule is that an ordered list may interrupt a paragraph only
/// when it is numbered 1 — the one number somebody starting a list would
/// write. GitHub and Typora render it that way too, so this is also what a
/// reader expects from having seen the same document elsewhere.
void main() {
  List<MarkdownNode> parse(String source) => MarkdownParser().parse(source);

  test('a wrapped sentence beginning with a number stays one paragraph', () {
    final nodes = parse(
      'The number of windows in my house is\n'
      '14.  The number of doors is 6.\n',
    );
    expect(nodes, hasLength(1), reason: '被拆成了 ${nodes.map((n) => n.type)}');
    expect(nodes.single.type, NodeType.paragraph);
  });

  test('and one numbered 1 still interrupts, because that is a list', () {
    // The other half of the rule. Somebody who writes a list directly under a
    // line of prose writes `1.`, and refusing that would be worse than the
    // fault this fixes.
    final nodes = parse('Steps:\n1. first\n2. second\n');
    expect(nodes.map((n) => n.type),
        containsAllInOrder([NodeType.paragraph, NodeType.orderedList]));
  });

  test('a bullet still interrupts a paragraph', () {
    // Bullets may; only numbers carry the restriction. `_ulRe` requires
    // content, so an empty marker cannot interrupt either way.
    final nodes = parse('Steps:\n- first\n- second\n');
    expect(nodes.map((n) => n.type),
        containsAllInOrder([NodeType.paragraph, NodeType.unorderedList]));
  });

  test('a numbered list that begins a block starts wherever it likes', () {
    // The rule is about interrupting, and only about interrupting. `10) foo`
    // with nothing above it is a list from ten.
    final nodes = parse('10) foo\n11) bar\n');
    expect(nodes.single.type, NodeType.orderedList);
  });

  test('and after a blank line, any number starts a list', () {
    // A blank line ends the paragraph, so nothing is being interrupted.
    final nodes = parse('Some prose.\n\n14. fourteen\n');
    expect(nodes.map((n) => n.type),
        containsAllInOrder([NodeType.paragraph, NodeType.orderedList]));
  });
}

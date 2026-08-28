import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// The outline the sidebar lists and the headings the preview draws.
///
/// The preview maps its Nth heading widget to the Nth outline entry, so the
/// two have to read the document the same way. They did not: a `# comment`
/// inside front matter was listed although nothing is drawn for it, and a
/// setext heading was drawn although nothing was listed. From the first
/// disagreement on, every entry scrolled to the wrong heading.
void main() {
  final parser = MarkdownParser();

  List<String> drawn(String source) => [
        for (final node in parser.parse(source))
          if (node is HeadingNode) 'L${node.level}:${node.content}',
      ];

  List<String> listed(String source) => [
        for (final h in MarkdownParser.headingOutline(source))
          'L${h.level}:${h.text}',
      ];

  void agree(String name, String source) {
    test(name, () => expect(listed(source), drawn(source), reason: source));
  }

  group('the outline lists what the preview draws', () {
    agree('plain headings', '# one\n## two\n### three\n');
    agree('a setext heading', 'Title\n===\n\nbody\n');
    agree('both setext levels', 'One\n===\nTwo\n---\n');
    agree('setext mixed with atx', '# a\n\nB\n---\n\n## c\n');
    agree('a comment in front matter', '---\ntitle: x\n# not a heading\n---\n\n# real\n');
    agree('a hash inside a fence', '# real\n\n```python\n# comment\n```\n');
    agree('trailing hashes', '## two ##\n');
    agree('a hash with no space', '#hashtag\n');
    agree('seven hashes', '####### too many\n');
    agree('a bare rule, which is not a heading', 'para\n\n---\n\n# real\n');
  });

  group('the outline counts what the preview counts', () {
    // The preview allocates one anchor per top-level heading and maps the Nth
    // to the Nth outline entry, so anything the outline lists that the
    // preview does not draw at the top level shifts every entry after it.
    List<String> topLevel(String source) => [
          for (final node in parser.parse(source))
            if (node is HeadingNode) 'L${node.level}:${node.content}',
        ];

    void matchesTopLevel(String name, String source) {
      test(name, () => expect(listed(source), topLevel(source), reason: source));
    }

    matchesTopLevel('a heading carried by a step is neither counted',
        '# one\n\n1. step\n\n   ### inside\n\n## two\n');
    matchesTopLevel('nor a setext one carried by a step',
        '# one\n\n1. step\n\n   Title\n   ===\n');
    matchesTopLevel('nor one inside a quote',
        '# one\n\n> ## quoted\n\n## two\n');
  });

  group('the line numbers point at the heading', () {
    test('an atx heading', () {
      expect(MarkdownParser.headingOutline('a\n\n# two\n').single.line, 3);
    });

    test('a setext heading points at the text, not the underline', () {
      // Scrolling to the underline puts the heading off the top of the view.
      expect(MarkdownParser.headingOutline('a\n\nTitle\n===\n').single.line, 3);
    });

    test('front matter does not shift the numbers', () {
      final outline =
          MarkdownParser.headingOutline('---\ntitle: x\n---\n\n# real\n');
      expect(outline.single.line, 5);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
import 'package:marktext_plus/ui/editor/syntax_highlighter.dart';

/// The two panes have to agree about where a code block ends.
///
/// The rule — a closing fence uses the same character, is at least as long,
/// and carries nothing after it — is written out five times: the parser's
/// `_closesFence`, the link-definition scan, the outline, the prefix cut, and
/// the highlighter's hand-rolled `fenceStates`, which cannot use the others
/// because it runs on every keystroke over every line.
///
/// Two of them had drifted. The outline toggled on any fence at all, so the
/// ``` a document shows inside a ```` block ended it and the prose underneath
/// was listed as headings the preview draws nothing for — and from the first
/// disagreement on, every outline entry scrolled to the wrong place.
///
/// Nothing tied the highlighter's copy to the others at all. This does.
void main() {
  /// The headings the source pane leaves un-greyed: not inside a fence, by
  /// the highlighter's own reckoning.
  List<String> bySourcePane(String source) {
    final lines = source.split('\n');
    final inFence = MarkdownSyntaxHighlighter.fenceStates(lines);
    return [
      for (var i = 0; i < lines.length; i++)
        if (!inFence[i] && MarkdownParser.headingLevelOf(lines[i]) != null)
          MarkdownParser.headingTextOf(lines[i])!,
    ];
  }

  List<String> byOutline(String source) => [
    for (final h in MarkdownParser.headingOutline(source)) h.text,
  ];

  void agree(String name, String source) {
    test(name, () {
      expect(byOutline(source), bySourcePane(source), reason: source);
    });
  }

  agree('a plain fence', '# a\n```\n# b\n```\n# c\n');

  // A longer fence is how a document shows ``` inside a code block. This
  // project's own README does it.
  agree('a fence inside a longer one', '# a\n````\n```\n# b\n```\n````\n# c\n');
  agree('a shorter run does not close', '# a\n`````\n```\n# b\n`````\n# c\n');

  // Different characters never close each other.
  agree(
    'backticks inside a tilde block',
    '# a\n~~~\n```\n# b\n```\n~~~\n# c\n',
  );
  agree(
    'tildes inside a backtick block',
    '# a\n```\n~~~\n# b\n~~~\n```\n# c\n',
  );

  // A closing fence carries no info string, so this one is content.
  agree('a tagged fence does not close', '# a\n```\n```js\n# b\n```\n# c\n');

  // Up to three columns of indentation still opens and closes a block.
  agree('an indented fence', '# a\n   ```\n# b\n   ```\n# c\n');

  // Unclosed: everything to the end of the document is code.
  agree('a fence that is never closed', '# a\n```\n# b\n# c\n');

  agree('two blocks in a row', '# a\n```\n# b\n```\n# c\n```\n# d\n```\n# e\n');
}

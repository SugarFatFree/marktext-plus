import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// Ctrl+1..6 / 转为正文 on a line the preview already draws as a heading.
///
/// The heading actions carried their own `^(#{1,6})\s+`, a rule narrower than
/// the parser's. Every line the two disagreed about came out wrong: the action
/// saw a paragraph, prepended a marker, and left the heading that was already
/// there sitting in the text.
void main() {
  /// What the preview makes of [line]: its heading level, or 0 for anything
  /// else. The point of the fix is that this agrees with the editor.
  int rendered(String line) {
    final nodes = MarkdownParser().parse(line);
    final first = nodes.isEmpty ? null : nodes.first;
    return first is HeadingNode ? first.level : 0;
  }

  String renderedText(String line) =>
      (MarkdownParser().parse(line).first as HeadingNode).content.trim();

  group('applyHeadingLevel', () {
    test('makes a paragraph a heading', () {
      expect(SourceEditor.applyHeadingLevel('标题', 1), '# 标题');
      expect(rendered(SourceEditor.applyHeadingLevel('标题', 1)), 1);
    });

    test('changes an existing level instead of stacking a marker', () {
      expect(SourceEditor.applyHeadingLevel('# 标题', 3), '### 标题');
    });

    test('an indented heading changes level like any other', () {
      // Up to three columns of indentation is still a heading — the preview
      // draws `   ## 标题` as H2. The action used to read it as a paragraph
      // and produce `###    ## 标题`: an H3 whose text is `## 标题`.
      expect(rendered('   ## 标题'), 2, reason: '前提：预览把它当作二级标题');
      final out = SourceEditor.applyHeadingLevel('   ## 标题', 3);
      expect(out, '### 标题');
      expect(rendered(out), 3);
      expect(renderedText(out), '标题');
    });

    test('an indented heading can be turned back into a paragraph', () {
      // 转为正文 used to leave the line untouched.
      expect(SourceEditor.applyHeadingLevel('   ## 标题', null), '标题');
      expect(rendered(SourceEditor.applyHeadingLevel('   ## 标题', null)), 0);
    });

    test('the empty heading a line passes through while typed', () {
      // `#` on its own is a heading with no text yet. Demoting it used to
      // give `## #`.
      expect(SourceEditor.applyHeadingLevel('#', 2), '## ');
      expect(SourceEditor.applyHeadingLevel('###', null), '');
    });

    test('a closing run of hashes is marker, not text', () {
      expect(SourceEditor.applyHeadingLevel('# 标题 #', 2), '## 标题');
    });

    test('a tag is not a heading', () {
      // `#标签` has no space, so the preview draws a paragraph. Stripping the
      // `#` would edit the user's text.
      expect(rendered('#标签'), 0, reason: '前提：预览不把它当标题');
      expect(SourceEditor.applyHeadingLevel('#标签', 1), '# #标签');
    });

    test('seven hashes are not a heading either', () {
      expect(rendered('####### 七'), 0, reason: '前提：最多六级');
      expect(SourceEditor.applyHeadingLevel('####### 七', 2), '## ####### 七');
    });
  });

  group('headingTextOf', () {
    test('answers null for what is not a heading', () {
      expect(MarkdownParser.headingTextOf('正文'), isNull);
      expect(MarkdownParser.headingTextOf('#标签'), isNull);
    });

    test('drops the marker on both sides', () {
      expect(MarkdownParser.headingTextOf('   ## 标题 ##'), '标题');
      expect(MarkdownParser.headingTextOf('#'), '');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// Ctrl+B over a selection covering more than one block.
///
/// Dragging across two paragraphs, or a whole list, and pressing Ctrl+B is an
/// ordinary thing to do. Wrapping the selection whole put the markers around
/// a blank line, around a list's own bullets, around a heading's `#` — none of
/// which is emphasis anywhere. What came back was asterisks on screen and, in
/// the heading's case, a heading that had stopped being one.
void main() {
  String bolded(String text) =>
      SourceEditor.toggleWrap(text, 0, text.length, '**', '**').text;

  int boldRuns(String source) => '<strong>'
      .allMatches(
        MarkdownParser().parse(source).map(ExportService.nodeToHtml).join(),
      )
      .length;

  group('each block is marked on its own', () {
    test('two paragraphs', () {
      expect(bolded('第一段\n\n第二段'), '**第一段**\n\n**第二段**');
      expect(boldRuns(bolded('第一段\n\n第二段')), 2);
    });

    test('a bulleted list keeps its bullets', () {
      expect(bolded('- 甲\n- 乙'), '- **甲**\n- **乙**');
    });

    test('a numbered list keeps its numbers', () {
      expect(bolded('1. 甲\n2. 乙'), '1. **甲**\n2. **乙**');
    });

    test('a task list keeps its boxes', () {
      expect(bolded('- [ ] 甲\n- [x] 乙'), '- [ ] **甲**\n- [x] **乙**');
    });

    test('a quote keeps its markers', () {
      expect(bolded('> 甲\n> 乙'), '> **甲**\n> **乙**');
    });

    test('a heading stays a heading', () {
      // `**# 标题**` is a paragraph beginning with two asterisks.
      final out = bolded('# 标题\n正文');
      expect(out, '# **标题**\n**正文**');
      expect(
        MarkdownParser().parse(out).first.type,
        NodeType.heading,
        reason: '标题被加粗标记吃掉了',
      );
    });

    test('sentence punctuation still goes outside, per block', () {
      expect(bolded('第一段。\n\n第二段。'), '**第一段**。\n\n**第二段**。');
    });
  });

  group('what stays one run', () {
    test('two lines of the same paragraph', () {
      // Emphasis crosses a line break inside a block, so marking the two
      // halves separately would add markers the document does not need.
      expect(bolded('第一行\n第二行'), '**第一行\n第二行**');
    });

    test('one line', () {
      expect(bolded('一行文字'), '**一行文字**');
    });

    test('half a line selected from the middle', () {
      // No marker is taken off a line the selection starts inside: what looks
      // like a bullet there is just text.
      expect(
        SourceEditor.toggleWrap('说明 - 甲', 3, 6, '**', '**').text,
        '说明 **- 甲**',
      );
    });
  });

  test('a second press takes the marking off every block', () {
    const marked = '- **甲**\n- **乙**';
    expect(bolded(marked), '- 甲\n- 乙');
  });
}

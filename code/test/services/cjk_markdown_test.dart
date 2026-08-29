import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// Markdown as it is actually written in Chinese, Japanese and Korean.
///
/// The inline grammar is one very large regular expression, and the emphasis
/// rules in it have been changed three times in one day — twice with side
/// effects that only turned up later. Its rules are also written in terms of
/// "word characters" and "punctuation", both of which have Latin defaults
/// that quietly do the wrong thing elsewhere.
///
/// So: the ordinary shapes of a CJK document, asserted directly.
void main() {
  List<InlineSpan> spansOf(String source) {
    final ast = MarkdownParser().parse('$source\n');
    expect(ast, hasLength(1), reason: source);
    return (ast.single as ParagraphNode).inlineSpans;
  }

  void expectSpans(String source, List<(InlineType, String)> expected) {
    final spans = spansOf(source);
    expect(spans.map((s) => (s.type, s.text)).toList(), expected,
        reason: source);
  }

  group('emphasis beside CJK text', () {
    test('bold and italic work with no spaces around them', () {
      // Chinese is written without spaces, so every delimiter has a letter
      // hard against it — the case the flanking rules are most likely to get
      // wrong.
      expectSpans('中文**加粗**中文', [
        (InlineType.text, '中文'),
        (InlineType.bold, '加粗'),
        (InlineType.text, '中文'),
      ]);
      expectSpans('中文*斜体*中文', [
        (InlineType.text, '中文'),
        (InlineType.italic, '斜体'),
        (InlineType.text, '中文'),
      ]);
    });

    test('CJK punctuation on either side does not stop it', () {
      expectSpans('（**括号内**）', [
        (InlineType.text, '（'),
        (InlineType.bold, '括号内'),
        (InlineType.text, '）'),
      ]);
      expectSpans('**加粗**，后面', [
        (InlineType.bold, '加粗'),
        (InlineType.text, '，后面'),
      ]);
      expectSpans('标题**加粗**：说明', [
        (InlineType.text, '标题'),
        (InlineType.bold, '加粗'),
        (InlineType.text, '：说明'),
      ]);
    });

    test('a script boundary is not a word boundary problem', () {
      expectSpans('中文**加粗**English', [
        (InlineType.text, '中文'),
        (InlineType.bold, '加粗'),
        (InlineType.text, 'English'),
      ]);
      expectSpans('第**1**章', [
        (InlineType.text, '第'),
        (InlineType.bold, '1'),
        (InlineType.text, '章'),
      ]);
    });

    test('an underscore inside CJK text is not emphasis, alone it is', () {
      expectSpans('中文_不该强调_中文', [
        (InlineType.text, '中文_不该强调_中文'),
      ]);
      expectSpans('_下划强调_', [(InlineType.italic, '下划强调')]);
      expectSpans('ファイル_名前_です', [
        (InlineType.text, 'ファイル_名前_です'),
      ]);
      expectSpans('한국어_밑줄_입니다', [
        (InlineType.text, '한국어_밑줄_입니다'),
      ]);
    });

    test('an unclosed delimiter stays on screen as written', () {
      expectSpans('**未闭合', [(InlineType.text, '**未闭合')]);
      expectSpans('未闭合*', [(InlineType.text, '未闭合*')]);
    });
  });

  group('other inline markup in CJK prose', () {
    test('code, strikethrough and links', () {
      expectSpans('`代码`和**加粗**', [
        (InlineType.code, '代码'),
        (InlineType.text, '和'),
        (InlineType.bold, '加粗'),
      ]);
      expectSpans('~~删除线~~', [(InlineType.strikethrough, '删除线')]);

      final link = spansOf('见[使用手册](/guide)').last;
      expect(link.type, InlineType.link);
      expect(link.text, '使用手册');
      expect(link.href, '/guide');
    });
  });

  group('blocks written in CJK', () {
    test('a heading keeps its text and level', () {
      final ast = MarkdownParser().parse('## 第二章 标题\n');
      final heading = ast.single as HeadingNode;
      expect(heading.level, 2);
      expect(heading.content, '第二章 标题');
    });

    test('a list and a quote read the same as in English', () {
      final ast = MarkdownParser().parse('- 第一项\n- 第二项\n\n> 引用的话\n');
      expect(ast.whereType<ListNode>().single.items, hasLength(2));
      expect(ast.whereType<BlockquoteNode>().single.children, hasLength(1));
    });

    test('a full-width space does not open a code block', () {
      // U+3000 is what an IME inserts; four of them are not an indented code
      // block, and reading them as one would swallow the paragraph.
      final ast = MarkdownParser().parse('　　　　正文\n');
      expect(ast.single, isA<ParagraphNode>());
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// Link reference definitions and the blocks that are parsed inside blocks.
///
/// A quote's contents, and the blocks a list item carries, are parsed by
/// calling `parse` again on the same parser — and `parse` began by emptying
/// the definitions it had collected for the document. So a quote anywhere
/// above a reference link took every definition in the document with it: the
/// link came out as the characters `[手册][doc]`, and the definition below it
/// was simply gone.
///
/// The specification's own examples never caught this. They are single
/// constructs, one to an example; this needs two of them in one document,
/// which is what a real document looks like.
void main() {
  String html(String md) =>
      MarkdownParser().parse(md).map(ExportService.nodeToHtml).join();

  const definition = '\n\n[doc]: /doc "使用手册"\n';

  group('a definition survives whatever is parsed inside another block', () {
    test('a quote above the link', () {
      expect(html('> 引用\n\n见 [手册][doc]。$definition'),
          contains('<a href="/doc" title="使用手册">手册</a>'));
    });

    test('a quote with a lazy continuation line', () {
      expect(html('> 引用第一行\n引用续行。\n\n见 [手册][doc]。$definition'),
          contains('<a href="/doc"'));
    });

    test('a list item carrying a second paragraph', () {
      expect(html('- 甲\n\n  第二段\n\n见 [手册][doc]。$definition'),
          contains('<a href="/doc"'));
    });

    test('a list inside a quote', () {
      expect(html('> - 甲\n>   - 乙\n\n见 [手册][doc]。$definition'),
          contains('<a href="/doc"'));
    });

    test('quotes inside quotes, and a list, all before the link', () {
      expect(html('> > 甲\n\n- 乙\n\n  丙\n\n见 [手册][doc]。$definition'),
          contains('<a href="/doc"'));
    });
  });

  group('what must not change', () {
    test('a definition above the quote still works', () {
      expect(html('[doc]: /doc "使用手册"\n\n> 引用\n\n见 [手册][doc]。\n'),
          contains('<a href="/doc"'));
    });

    test('parsing a second document forgets the first one\'s definitions', () {
      // The clearing exists for a reason: a parser is reused, and a label
      // defined in one document must not resolve in the next.
      final parser = MarkdownParser();
      parser.parse('见 [手册][doc]。$definition');
      final second =
          parser.parse('见 [手册][doc]。\n').map(ExportService.nodeToHtml).join();
      expect(second, isNot(contains('<a href="/doc"')),
          reason: '上一篇文档的定义泄漏到了下一篇');
      expect(second, contains('[手册][doc]'));
    });

    test('an undefined label is still prose', () {
      expect(html('> 引用\n\n见 [手册][doc]。\n'), contains('[手册][doc]'));
    });
  });
}

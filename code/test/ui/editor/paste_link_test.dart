import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// Pasting over a selection.
///
/// The framework replaces the selection with the clipboard's plain flavour
/// and the editor then puts something better in its place — markdown built
/// from the HTML flavour, or a link. Both need to know exactly which
/// characters the paste put there.
void main() {
  group('where the pasted text landed', () {
    test('with nothing selected', () {
      // 100 characters, caret at 5, twenty pasted.
      final r = SourceEditor.pastedRange(
        lengthBefore: 100,
        selectionStart: 5,
        selectionEnd: 5,
        lengthAfter: 120,
      );
      expect(r, (start: 5, end: 25));
    });

    test('with text selected', () {
      // Five characters replaced by twenty: the document grew by fifteen, but
      // twenty were pasted. Reading the growth as the pasted length left five
      // characters of the raw paste behind and wrote over the text after it.
      final r = SourceEditor.pastedRange(
        lengthBefore: 100,
        selectionStart: 5,
        selectionEnd: 10,
        lengthAfter: 115,
      );
      expect(r, (start: 5, end: 25));
    });

    test('when the paste is shorter than what it replaced', () {
      final r = SourceEditor.pastedRange(
        lengthBefore: 100,
        selectionStart: 5,
        selectionEnd: 30,
        lengthAfter: 80,
      );
      expect(r, (start: 5, end: 10));
    });

    test('when nothing arrived', () {
      final r = SourceEditor.pastedRange(
        lengthBefore: 100,
        selectionStart: 5,
        selectionEnd: 10,
        lengthAfter: 95,
      );
      expect(r.end, r.start);
    });
  });

  group('a web address pasted over some words becomes a link', () {
    test('the ordinary case', () {
      expect(SourceEditor.linkFromPaste('使用手册', 'https://example.com/guide'),
          '[使用手册](https://example.com/guide)');
    });

    test('and the preview draws it as one', () {
      final md = SourceEditor.linkFromPaste('使用手册', 'https://example.com')!;
      expect(
        MarkdownParser().parse(md).map(ExportService.nodeToHtml).join(),
        contains('<a href="https://example.com">使用手册</a>'),
      );
    });

    test('other schemes', () {
      expect(SourceEditor.linkFromPaste('邮件', 'mailto:a@b.com'),
          '[邮件](mailto:a@b.com)');
      expect(SourceEditor.linkFromPaste('下载', 'ftp://host/f.zip'),
          '[下载](ftp://host/f.zip)');
    });

    test('a trailing newline from the clipboard is not part of the address',
        () {
      expect(SourceEditor.linkFromPaste('手册', 'https://example.com\n'),
          '[手册](https://example.com)');
    });

    test('an address with brackets in it, which is what wikipedia writes', () {
      final md = SourceEditor.linkFromPaste(
          '条目', 'https://zh.wikipedia.org/wiki/C_(程序语言)')!;
      expect(
        MarkdownParser().parse(md).map(ExportService.nodeToHtml).join(),
        contains('href="https://zh.wikipedia.org/wiki/C_(程序语言)"'),
      );
    });
  });

  group('what stays an ordinary paste', () {
    test('nothing was selected', () {
      expect(SourceEditor.linkFromPaste('', 'https://example.com'), isNull);
    });

    test('the clipboard is not an address', () {
      expect(SourceEditor.linkFromPaste('文字', '另一段文字'), isNull);
      expect(SourceEditor.linkFromPaste('文字', 'https://a b'), isNull);
    });

    test('an address without a scheme is prose', () {
      // `www.example.com` in a sentence is words, not a link waiting to
      // happen; guessing would rewrite what the reader pasted.
      expect(SourceEditor.linkFromPaste('文字', 'www.example.com'), isNull);
    });

    test('the selection spans more than one line', () {
      // A link's text cannot hold a newline.
      expect(SourceEditor.linkFromPaste('第一行\n第二行', 'https://x.com'), isNull);
    });

    test('the selection is already a link', () {
      expect(
        SourceEditor.linkFromPaste('[手册](/guide)', 'https://example.com'),
        isNull,
      );
    });
  });
}

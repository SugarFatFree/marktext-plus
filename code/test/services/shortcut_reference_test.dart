import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// The four ways of writing a link all mark up their text the same way.
///
/// Markdown has four: `[t](/url)`, `[t][label]`, `[t][]` and the shortcut
/// `[t]`. Each is a separate branch in the parser, and each had to learn on
/// its own that a link's text can hold emphasis — a download button is
/// written `[**下载**](/url)`. Three of them had; the shortcut had not, so the
/// same words came out with their asterisks showing, but only when the URL
/// was kept at the bottom of the document.
void main() {
  String html(String md) =>
      MarkdownParser().parse(md).map(ExportService.nodeToHtml).join();

  group('a link marks up its text whichever way it is written', () {
    const definition = '\n\n[**下载**]: /url';

    test('inline', () {
      expect(html('[**下载**](/url)'),
          '<p><a href="/url"><strong>下载</strong></a></p>');
    });

    test('full reference', () {
      expect(html('[**下载**][r]\n\n[r]: /url'),
          '<p><a href="/url"><strong>下载</strong></a></p>');
    });

    test('collapsed reference', () {
      expect(html('[**下载**][]$definition'),
          '<p><a href="/url"><strong>下载</strong></a></p>');
    });

    test('shortcut reference', () {
      expect(html('[**下载**]$definition'),
          '<p><a href="/url"><strong>下载</strong></a></p>');
    });

    test('and the other inline markers too', () {
      expect(html('[*重点*]\n\n[*重点*]: /url'),
          '<p><a href="/url"><em>重点</em></a></p>');
      expect(html('[`code`]\n\n[`code`]: /url'),
          '<p><a href="/url"><code>code</code></a></p>');
      expect(html('[~~旧~~]\n\n[~~旧~~]: /url'),
          '<p><a href="/url"><del>旧</del></a></p>');
    });
  });

  group('what must not change', () {
    test('a label that resolves to nothing stays as it was written', () {
      // Prose is full of brackets that are not links.
      expect(html('见 [sic] 处'), '<p>见 [sic] 处</p>');
      // The brackets stay literal; the emphasis inside them is ordinary
      // prose emphasis and is drawn as such — it is not a link's text.
      expect(html('注 [**1**] 条'), '<p>注 [<strong>1</strong>] 条</p>');
    });

    test('plain text in a shortcut link is still plain', () {
      expect(html('[文档]\n\n[文档]: /url'), '<p><a href="/url">文档</a></p>');
    });

    test('a shortcut image describes itself without the markers', () {
      // Alt text is what a reader sees when the picture does not load, so it
      // is text — `![**图**]` describes it as 图, not as `**图**`.
      expect(html('[**图**]\n\n[**图**]: /i.png').contains('<strong>'), isTrue);
      expect(html('![**图**]\n\n[**图**]: /i.png'),
          '<p><img src="/i.png" alt="图"></p>');
    });

    test('a link inside a shortcut link does not nest an anchor', () {
      // CommonMark forbids it and a browser will not draw it.
      final out = html('[看 [别处](/two) 的说明]\n\n'
          '[看 [别处](/two) 的说明]: /one');
      expect('<a '.allMatches(out).length, 1, reason: '出现了嵌套的 <a>');
      expect(out, contains('/one'));
    });
  });
}

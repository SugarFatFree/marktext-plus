import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// A link reference definition written across more than one line.
///
/// Keeping addresses at the bottom of a document is what reference links are
/// for, and wrapping a long one is an ordinary thing to do. Only the
/// single-line form was recognised, so a wrapped definition stopped being
/// metadata: its title was lost and the rest of it — `"the title"`, and every
/// definition under it — was drawn in the document as a paragraph for the
/// reader to see.
void main() {
  String html(String md) =>
      MarkdownParser().parse(md).map(ExportService.nodeToHtml).join();

  group('a definition may wrap', () {
    test('its title on the next line', () {
      expect(html('见 [甲][a]。\n\n[a]: /url\n   "标题"\n'),
          '<p>见 <a href="/url" title="标题">甲</a>。</p>');
    });

    test('its address on the next line', () {
      expect(html('见 [甲][a]。\n\n[a]:\n/url\n'),
          '<p>见 <a href="/url">甲</a>。</p>');
    });

    test('and the definitions under it are still definitions', () {
      // The failure that made this worth fixing: one wrapped definition took
      // the ones below it down with it, and their source became a paragraph.
      final out = html('见 [甲][a] 与 [乙][b]。\n\n'
          '[a]: /a\n'
          '  "标题"\n'
          '[b]: /b\n');
      expect(out, '<p>见 <a href="/a" title="标题">甲</a> 与 '
          '<a href="/b">乙</a>。</p>');
      expect(out, isNot(contains('[b]')), reason: '定义的源码漏进了正文');
    });

    test('a title in single quotes or parentheses counts too', () {
      expect(html("[a]: /url\n'标题'\n\n[甲][a]\n"),
          contains('title="标题"'));
      expect(html('[a]: /url\n(标题)\n\n[甲][a]\n'), contains('title="标题"'));
    });
  });

  group('what must not change', () {
    test('the ordinary one-line form', () {
      expect(html('见 [甲][a]。\n\n[a]: /url "标题"\n'),
          '<p>见 <a href="/url" title="标题">甲</a>。</p>');
    });

    test('a footnote definition is not a link definition', () {
      // `[^1]: note` matched the old pattern first, and since a link
      // definition is dropped rather than drawn, every footnote vanished.
      final out = html('正文[^1]\n\n[^1]: 注释\n');
      expect(out, contains('注释'));
    });

    test('a blank line ends it, whatever follows', () {
      final out = html('[a]: /url\n\n"不是标题"\n\n[甲][a]\n');
      expect(out, contains('不是标题'), reason: '空行之后的内容被当成标题吃掉了');
      expect(out, contains('href="/url"'));
    });

    test('brackets in prose are still prose', () {
      expect(html('见 [注1] 处\n'), '<p>见 [注1] 处</p>');
    });

    test('a definition shown inside a code fence stays an example', () {
      final out = html('```\n[a]: /url\n```\n\n[甲][a]\n');
      expect(out, contains('<pre><code'));
      expect(out, contains('[甲][a]'), reason: '示例里的定义被当真了');
    });
  });
}

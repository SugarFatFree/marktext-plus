import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// `<pre>`, `<script>`, `<style>`, `<textarea>` — the four tags whose content
/// is text, not markdown.
///
/// An HTML block ends at the first blank line, which is what lets the markdown
/// inside a `<details>` be read as markdown. These four are the exception the
/// format names: a blank line inside one of them belongs to the text. Ending
/// there cut a script or a preformatted sample in half and read the rest as
/// prose — the asterisks in the sample became italics, and the closing tag
/// arrived as `&lt;/pre&gt;`.
void main() {
  late MarkdownParser parser;
  setUp(() => parser = MarkdownParser());

  String htmlOf(String source) =>
      parser.parse(source).map(ExportService.nodeToHtml).join();

  group('a blank line inside one of the four is part of it', () {
    // Asserted on the block the parser builds, not on the exported HTML: the
    // export strips `<script>` and `<style>` on purpose, so reading the answer
    // there would say the block was lost when it was only sanitised.
    for (final tag in ['pre', 'script', 'style', 'textarea']) {
      test('<$tag>', () {
        final nodes =
            parser.parse('<$tag>\n第一段\n\n第二段 *星号*\n</$tag>\n后面的正文\n');
        final block = nodes.first as HtmlBlockNode;
        expect(block.html, contains('</$tag>'), reason: '块在空行处被截断了');
        expect(block.html, contains('第二段 *星号*'),
            reason: '空行之后的内容没有留在块里');
        expect(nodes.last.type, NodeType.paragraph,
            reason: '块后面的正文丢了');
      });
    }

    test('a preformatted sample survives to the export', () {
      final html = htmlOf('<pre>\n第一行\n\n第二行 *星号*\n</pre>\n后面的正文\n');
      expect(html, contains('</pre>'));
      expect(html, isNot(contains('<em>星号</em>')),
          reason: 'pre 里的内容被当成 markdown 解析了');
      expect(html, contains('后面的正文'));
    });
  });

  group('every other tag still ends at a blank line', () {
    test('markdown inside details is still markdown', () {
      // The reason the blank-line rule exists: a `<details>` block is opened
      // and closed around prose that should be read as prose.
      final html = htmlOf('<details>\n\n*强调*\n\n</details>\n');
      expect(html, contains('<em>强调</em>'));
    });

    test('a div does not swallow what comes after it', () {
      final html = htmlOf('<div>\n里面\n\n外面的段落\n');
      expect(html, contains('外面的段落'));
    });
  });

  test('a pre that never closes costs one line, not the document', () {
    // The guard on the change: with no closing tag and no blank line to stop
    // at, the scan must not take the rest of the file.
    final nodes = parser.parse('<pre>\n开头\n\n中间\n\n# 后面的标题\n');
    expect(nodes.any((n) => n.type == NodeType.heading), isTrue,
        reason: '后面的标题被没有闭合的 pre 吞掉了');
  });
}

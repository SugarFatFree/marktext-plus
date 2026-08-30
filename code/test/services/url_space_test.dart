import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// A space in a link's destination.
///
/// `[文档](</我的 文件.md>)` is how markdown writes a file name with a space in
/// it — the angle brackets exist for exactly this. The space reached the
/// exported HTML as it was, which is not valid in the attribute it sits in.
void main() {
  late MarkdownParser parser;
  setUp(() => parser = MarkdownParser());

  String htmlOf(String source) =>
      parser.parse(source).map(ExportService.nodeToHtml).join();

  group('the export encodes it', () {
    test('a link', () {
      expect(htmlOf('[文档](</我的 文件.md>)'),
          contains('href="/我的%20文件.md"'));
    });

    test('an image', () {
      expect(htmlOf('![图](<我的 图.png>)'), contains('src="我的%20图.png"'));
    });

    test('an address that already carries %20 is left alone', () {
      // Encoding it again would give `%2520`, which names a different file.
      expect(htmlOf('[文档](/my%20file.md)'), contains('href="/my%20file.md"'));
    });

    test('an ordinary address is unchanged', () {
      expect(htmlOf('[链接](https://example.com/a/b)'),
          contains('href="https://example.com/a/b"'));
    });
  });

  test('the document itself keeps the space', () {
    // The preview resolves the file from what the document says, so the
    // address in the span must stay as written.
    final span = (parser.parse('[文档](</我的 文件.md>)').first as ParagraphNode)
        .inlineSpans
        .single;
    expect(span.href, '/我的 文件.md');
  });

  test('a dangerous scheme is still refused', () {
    // The guard: this sits inside the same function that blocks scripts.
    expect(htmlOf('[x](javascript:alert(1))'), isNot(contains('javascript')));
  });

  group('brackets inside a link text', () {
    test('one level, which was already read', () {
      expect(htmlOf('见 [附录 [A]](/url) 与正文'), contains('<a href="/url"'));
    });

    test('two levels', () {
      // `[参见 [附录 [A]]](/url)` — a reference inside a reference. One level
      // was allowed and the second left the whole thing as characters.
      final html = htmlOf('见 [附录 [A [1]]](/url) 与正文');
      expect(html, contains('<a href="/url"'));
      expect(html, contains('附录'));
    });

    test('an unclosed bracket is still just a bracket', () {
      expect(htmlOf('[未闭合 (/url)'), isNot(contains('<a ')));
    });
  });
}

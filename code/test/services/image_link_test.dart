import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/image_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// The markdown an inserted image turns into.
///
/// A bare destination cannot contain a space: `![](my photo.png)` is not an
/// image, it is that text, and the reader is left with a line of brackets
/// where a picture should be. The names come from their own files, and on
/// Windows a screenshot arrives called "屏幕截图 2026-08-28.png".
void main() {
  final parser = MarkdownParser();

  InlineSpan? onlySpan(String markdown) {
    for (final node in parser.parse('$markdown\n\n')) {
      if (node is ParagraphNode && node.inlineSpans.length == 1) {
        return node.inlineSpans.single;
      }
    }
    return null;
  }

  test('a plain path is left exactly as it was', () {
    expect(ImageService.markdownDestination('images/photo.png'),
        'images/photo.png');
  });

  test('a path with a space is wrapped so it stays a link', () {
    const path = 'images/屏幕截图 2026-08-28.png';
    final destination = ImageService.markdownDestination(path);

    expect(destination, '<$path>');

    // The point of the wrapping, checked against the parser rather than
    // assumed: the same text without brackets does not parse as an image.
    final wrapped = onlySpan('![image]($destination)');
    expect(wrapped?.type, InlineType.image);
    expect(wrapped?.href, path);

    final bare = onlySpan('![image]($path)');
    expect(bare?.type, InlineType.text,
        reason: '没有尖括号时本来就该解析失败，否则这条测试证明不了什么');
  });

  test('a path holding an angle bracket falls back to encoding the space', () {
    final destination = ImageService.markdownDestination('a >b/my photo.png');

    expect(destination, isNot(startsWith('<')));
    expect(destination, contains('%20'));
  });

  test('tabs and newlines count as spaces for this purpose', () {
    expect(ImageService.markdownDestination('a\tb.png'), startsWith('<'));
  });
}

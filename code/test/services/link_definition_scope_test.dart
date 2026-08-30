import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// Where a link reference definition counts, and where it only looks like one.
///
/// Definitions are gathered before anything is parsed, because a reference may
/// be written above the definition it uses. That pass read every line of the
/// document, code included — so a document explaining markdown, which shows a
/// definition inside a fence, quietly defined it for real.
void main() {
  late MarkdownParser parser;
  setUp(() => parser = MarkdownParser());

  String htmlOf(String source) =>
      parser.parse(source).map(ExportService.nodeToHtml).join();

  group('a definition inside a code fence is an example, not a definition', () {
    test('a backtick fence', () {
      final html = htmlOf('```\n[foo]: /url\n```\n\n[foo]\n');
      expect(html, contains('[foo]'), reason: '正文里的 [foo] 变成了链接');
      expect(html, isNot(contains('<a href="/url"')));
    });

    test('a tilde fence', () {
      final html = htmlOf('~~~\n[foo]: /url\n~~~\n\n[foo]\n');
      expect(html, isNot(contains('<a href="/url"')));
    });

    test('a fence with a language, as documentation writes it', () {
      // The shape this project's own documentation uses.
      final html = htmlOf(
        '例子：\n\n```markdown\n[示例]: https://example.com\n```\n\n'
        '正文里的 [示例] 不该变成链接。\n',
      );
      expect(html, isNot(contains('<a href="https://example.com"')));
    });

    test('a longer fence closes only on one at least as long', () {
      // ```` … ``` … ```` is how a document shows a fence inside a fence; the
      // inner one must not be read as the end of the outer.
      final html = htmlOf('````\n```\n[foo]: /url\n```\n````\n\n[foo]\n');
      expect(html, isNot(contains('<a href="/url"')));
    });

    test('a definition after the fence still counts', () {
      // The guard: the fence closes, and what follows is the document again.
      final html = htmlOf('```\ncode\n```\n\n[foo]: /url\n\n[foo]\n');
      expect(html, contains('<a href="/url"'));
    });

    test('an ordinary definition is unaffected', () {
      expect(htmlOf('[foo]: /url\n\n[foo]\n'), contains('<a href="/url"'));
    });
  });

  group('a label defined twice', () {
    test('the first definition wins', () {
      // CommonMark's rule. Taking the last meant that when a document defined
      // a label twice by mistake, the mistake won.
      expect(htmlOf('[foo]: first\n[foo]: second\n\n[foo]\n'),
          contains('href="first"'));
    });

    test('case does not make a second label', () {
      expect(htmlOf('[Foo]: first\n[FOO]: second\n\n[foo]\n'),
          contains('href="first"'));
    });
  });
}

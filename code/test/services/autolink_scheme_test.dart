import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// `<scheme:…>` — an address written inside angle brackets.
///
/// Four schemes were listed by name, so every other one was shown as angle
/// brackets: a `tel:` number, a `file:///` path, an editor's own `vscode://`
/// link, an intranet `localhost:8080/…`. The format allows any scheme.
void main() {
  late MarkdownParser parser;
  setUp(() => parser = MarkdownParser());

  InlineSpan spanOf(String source) =>
      (parser.parse(source).first as ParagraphNode).inlineSpans.first;

  String htmlOf(String source) =>
      parser.parse(source).map(ExportService.nodeToHtml).join();

  group('any scheme is an address', () {
    for (final url in [
      'irc://foo.bar:2233/baz',
      'tel:+8613800138000',
      'file:///home/me/notes.md',
      'vscode://file/tmp/a.dart:12',
      'made-up-scheme://foo,bar',
      'localhost:5001/foo',
      'a+b+c:d',
    ]) {
      test(url, () {
        final span = spanOf('<$url>');
        expect(span.type, InlineType.link, reason: url);
        expect(span.href, url);
        expect(span.text, url);
      });
    }
  });

  group('what is still not an address', () {
    test('an uppercase MAILTO: keeps its own scheme', () {
      // Read as an email address, it was given a second `mailto:` in front of
      // it — `mailto:MAILTO:FOO@BAR.BAZ`, which goes nowhere.
      final span = spanOf('<MAILTO:FOO@BAR.BAZ>');
      expect(span.href, 'MAILTO:FOO@BAR.BAZ');
      expect(span.href, isNot(startsWith('mailto:M')));
    });

    test('a plain address still becomes a mailto', () {
      final span = spanOf('<foo@example.com>');
      expect(span.href, 'mailto:foo@example.com');
    });

    test('an HTML tag is not a scheme', () {
      // `<a href="x">` and `<span style="color:red">` both have a colon
      // somewhere; neither is an autolink.
      final html = htmlOf('文字 <span style="color:red">x</span> 文字\n');
      expect(html, isNot(contains('<a href="span')));
    });

    test('a scheme with a space after it is not an address', () {
      expect(htmlOf('<https://foo.bar/baz bim>\n'),
          isNot(contains('href="https://foo.bar/baz bim"')));
    });
  });
}

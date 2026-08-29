import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// An exported HTML file is opened in a browser, usually by someone other than
/// the person who wrote the markdown. Anything in the document that would run
/// code there has to be inert by the time it reaches the file.
///
/// The rules mirror upstream MarkText's `security/sanitize.spec.ts`.
String render(String markdown) =>
    MarkdownParser().parse(markdown).map(ExportService.nodeToHtml).join();

void main() {
  group('exported HTML carries no executable URL', () {
    test('javascript: link loses its destination but keeps its text', () {
      final html = render('[click](javascript:alert(1))\n');
      expect(html, contains('click'));
      expect(html.toLowerCase(), isNot(contains('javascript:')));
    });

    test('the scheme is matched whatever its case', () {
      expect(
        render('[c](JaVaScRiPt:alert(1))\n').toLowerCase(),
        isNot(contains('javascript')),
      );
    });

    test('whitespace inside the scheme does not smuggle it through', () {
      // `java\tscript:` is a form browsers have accepted.
      final html = render('[c](<java\tscript:alert(1)>)\n');
      expect(html.toLowerCase(), isNot(contains('script:alert')));
    });

    test('vbscript: is refused as well', () {
      expect(
        render('[c](vbscript:msgbox(1))\n').toLowerCase(),
        isNot(contains('vbscript')),
      );
    });

    test('an image src is checked like a link href', () {
      final html = render('![x](javascript:alert(1))\n');
      expect(html, contains('<img'));
      expect(html.toLowerCase(), isNot(contains('javascript')));
    });

    test('a badge — an image wrapped in a link — checks the outer href', () {
      final html = render('[![b](https://ok.png)](javascript:alert(1))\n');
      expect(html.toLowerCase(), isNot(contains('javascript')));
    });

    test('data:text/html is a page in disguise and is refused', () {
      expect(
        render('[c](data:text/html,<b>hi</b>)\n'),
        isNot(contains('data:text/html')),
      );
    });

    test('data:image/svg+xml is refused — an SVG can carry a script', () {
      expect(
        render('![i](data:image/svg+xml;base64,PHN2Zz48L3N2Zz4=)\n'),
        isNot(contains('svg+xml')),
      );
    });
  });

  group('ordinary destinations are untouched', () {
    test('an http URL keeps its query, with & escaped for the attribute', () {
      expect(
        render('[a](https://example.com/?x=1&y=2)\n'),
        contains('href="https://example.com/?x=1&amp;y=2"'),
      );
    });

    test('a relative path survives', () {
      expect(render('[a](./notes.md)\n'), contains('href="./notes.md"'));
    });

    test('an anchor survives, including a non-ASCII one', () {
      expect(render('[a](#锚点)\n'), contains('href="#锚点"'));
    });

    test('mailto: survives', () {
      expect(render('[a](mailto:x@y.com)\n'), contains('href="mailto:x@y.com"'));
    });

    test('an inline raster image survives — base64 must not be escaped', () {
      expect(
        render('![i](data:image/png;base64,iVBORw0KGgo=)\n'),
        contains('src="data:image/png;base64,iVBORw0KGgo="'),
      );
    });
  });

  group('inline HTML in the document', () {
    test('a script block does not reach the export', () {
      expect(
        render('<script>alert(1)</script>\n').toLowerCase(),
        isNot(contains('alert(1)')),
      );
    });

    test('an event-handler attribute is dropped', () {
      expect(
        render('<img src=x onerror="alert(1)">\n').toLowerCase(),
        isNot(contains('onerror')),
      );
    });

    test('an iframe does not reach the export', () {
      expect(
        render('<iframe src="https://evil.test"></iframe>\n').toLowerCase(),
        isNot(contains('<iframe')),
      );
    });
  });
}

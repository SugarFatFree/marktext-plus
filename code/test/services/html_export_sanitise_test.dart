import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';

/// Raw HTML in a document is passed through to the exported HTML file, which
/// is then opened in a browser. A note written by someone else — a README, a
/// shared document — can carry a script the reader never sees in the editor
/// (the preview shows an HTML block as plain monospace text) and that runs the
/// moment they open the export. Upstream MarkText sanitises the same path and
/// has a test named for it.
///
/// Best effort, not a security boundary: this is regular expressions over
/// text, not an HTML parser. What these tests pin down is that the obvious
/// cases no longer go straight through, and that ordinary markup still does.
void main() {
  String clean(String html) => ExportService.sanitiseHtmlForExport(html);

  test('a script element and its contents are removed', () {
    expect(clean('<p>hi</p><script>alert(1)</script>'), '<p>hi</p>');
    expect(clean('<SCRIPT>alert(1)</SCRIPT>'), isEmpty);
    expect(clean('<script\n  type="text/javascript">\nbad()\n</script>'),
        isEmpty);
  });

  test('an unclosed script tag does not survive as an opening tag', () {
    // Left behind, the rest of the exported document becomes script source.
    expect(clean('<p>a</p><script src="x.js">'), '<p>a</p>');
  });

  test('frames and embedded objects are removed', () {
    for (final tag in ['iframe', 'object', 'embed', 'applet']) {
      expect(clean('<$tag src="x"></$tag>'), isEmpty, reason: tag);
    }
  });

  test('event handler attributes are stripped, the element is kept', () {
    expect(clean('<img src="a.png" onerror="steal()">'),
        '<img src="a.png">');
    expect(clean("<div onclick='go()'>text</div>"), '<div>text</div>');
    expect(clean('<div onmouseover=go()>text</div>'), '<div>text</div>');
  });

  test('addresses that are really code are dropped', () {
    expect(clean('<a href="javascript:alert(1)">click</a>'),
        '<a>click</a>');
    expect(clean('<a href="JavaScript:alert(1)">click</a>'), '<a>click</a>');
  });

  test('ordinary markup is left exactly as written', () {
    // The export is meant to look like the document. Taking out more than the
    // parts that execute would be its own kind of wrong.
    const kept = [
      '<details><summary>more</summary><p>body</p></details>',
      '<kbd>Ctrl</kbd>+<kbd>S</kbd>',
      '<img src="diagram.png" alt="diagram" width="400">',
      '<a href="https://example.com">link</a>',
      '<table><tr><td>a</td></tr></table>',
      '<div class="note" style="color: red">note</div>',
    ];
    for (final html in kept) {
      expect(clean(html), html);
    }
  });
}

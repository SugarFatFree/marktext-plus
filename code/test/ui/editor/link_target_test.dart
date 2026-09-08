import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/link_target.dart';

/// What the preview does with a link, decided apart from doing it.
///
/// The deciding used to live inside the handler, where testing it meant a
/// rendered paragraph, a span tree, a held modifier key and an awaited call.
/// So it was never tested, and the anchor case was missing from it for a long
/// time: `[see below](#conclusion)` fell through to the path branch, resolved
/// against the document's folder, found no such file and returned. The click
/// did nothing, silently, while every other kind of link worked.
void main() {
  test('an anchor is an anchor', () {
    expect(linkKindOf('#conclusion'), LinkKind.anchor);
    expect(linkKindOf('#中文标题'), LinkKind.anchor);
    expect(linkKindOf('#'), LinkKind.anchor);
  });

  test('a scheme the desktop handles is handed over', () {
    for (final href in [
      'https://example.invalid/a',
      'http://example.invalid',
      'mailto:someone@example.invalid',
      'tel:+8613800000000',
      'HTTPS://EXAMPLE.INVALID',
    ]) {
      expect(linkKindOf(href), LinkKind.launchable, reason: href);
    }
  });

  test('a scheme that runs code is refused', () {
    for (final href in [
      'javascript:alert(1)',
      'JavaScript:alert(1)',
      'vbscript:msgbox',
      'data:text/html,<script>',
      // Whitespace inside the scheme is how this gets past a naive check;
      // a browser reads it as the scheme anyway.
      'java\nscript:alert(1)',
      'java script:alert(1)',
    ]) {
      expect(linkKindOf(href), LinkKind.refused, reason: href);
    }
  });

  test('anything else is a path', () {
    for (final href in [
      'notes.md',
      './notes.md',
      '../other/notes.md',
      'sub dir/notes.md',
    ]) {
      expect(linkKindOf(href), LinkKind.path, reason: href);
    }
  });

  test('a refusal outranks everything, including an anchor', () {
    // Order matters: a document is data, including one someone else sent.
    expect(linkKindOf('javascript:void#x'), LinkKind.refused);
  });

  test('an anchor is not mistaken for a path', () {
    // This is the whole defect. A path branch that sees `#conclusion` builds
    // a filename out of it and finds nothing.
    expect(linkKindOf('#conclusion'), isNot(LinkKind.path));
  });
}

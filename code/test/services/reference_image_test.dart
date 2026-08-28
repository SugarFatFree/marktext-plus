import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// Reference images: `![alt][label]`.
///
/// The inline form `![alt](src)` has had a branch of its own since a stray `!`
/// in front of a link gave it away. The reference form never did, so
/// `![alt][img]` matched the reference *link* branch from its `[` and came out
/// as a link with the `!` beside it as text — the same fault, in the sibling
/// nobody had looked at. Upstream MarkText tests this case explicitly, which
/// is where the check came from.
void main() {
  final parser = MarkdownParser();

  List<InlineSpan> spansOf(String source) {
    for (final node in parser.parse(source)) {
      if (node is ParagraphNode) return node.inlineSpans;
    }
    return const [];
  }

  test('resolves to an image, not a link with a loose exclamation mark', () {
    final spans = spansOf('![alt][img]\n\n[img]: https://a.com/x.png\n');

    expect(spans, hasLength(1), reason: '拆成了多个 span，说明 ! 被单独留下了');
    expect(spans.single.type, InlineType.image);
    expect(spans.single.text, 'alt');
    expect(spans.single.href, 'https://a.com/x.png');
  });

  test('the label is matched without regard to case', () {
    final spans = spansOf('![alt][IMG]\n\n[img]: https://a.com/x.png\n');

    expect(spans.single.type, InlineType.image);
    expect(spans.single.href, 'https://a.com/x.png');
  });

  test('an empty label uses the alt text', () {
    final spans = spansOf('![logo][]\n\n[logo]: https://a.com/logo.png\n');

    expect(spans.single.type, InlineType.image);
    expect(spans.single.text, 'logo');
    expect(spans.single.href, 'https://a.com/logo.png');
  });

  test('an unresolved reference stays exactly as written', () {
    // Not an image to nowhere, and not a broken link either.
    final spans = spansOf('![alt][missing]\n\n');

    expect(spans.single.type, InlineType.text);
    expect(spans.single.text, '![alt][missing]');
  });

  test('a reference link beside a reference image still resolves as a link',
      () {
    final spans = spansOf(
      'see [docs][d] and ![shot][s]\n\n[d]: https://a.com\n[s]: https://a.com/s.png\n',
    );

    expect(spans.where((s) => s.type == InlineType.link), hasLength(1));
    expect(spans.where((s) => s.type == InlineType.image), hasLength(1));
    expect(spans.firstWhere((s) => s.type == InlineType.image).href,
        'https://a.com/s.png');
  });

  test('the inline forms are untouched', () {
    // The new branch is appended after every existing one, so nothing that
    // matched before may match differently now.
    final inline = spansOf('![alt](https://a.com/x.png)\n\n');
    expect(inline.single.type, InlineType.image);
    expect(inline.single.href, 'https://a.com/x.png');

    final link = spansOf('[text](https://a.com)\n\n');
    expect(link.single.type, InlineType.link);
    expect(link.single.href, 'https://a.com');
  });
}

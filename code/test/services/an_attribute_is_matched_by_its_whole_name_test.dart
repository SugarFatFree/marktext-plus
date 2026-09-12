import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/html_to_markdown.dart';

/// `src` is not `data-src`, and which one a paste used to read was decided by
/// which came first in the tag.
///
/// The attribute pattern was built from the name with nothing in front of it, so
/// asking for `src` matched `data-src`, asking for `href` matched `data-href`,
/// and asking for `title` matched `data-title`. Whichever the page happened to
/// write first won.
///
/// Matching the whole name would, on its own, be a step backwards for the web as
/// it is: a lazily loaded image keeps its real address in `data-src` and a
/// placeholder in `src`, so a picture pasted from a news site or a blog would
/// arrive as the placeholder. That fallback is a decision now rather than an
/// accident of attribute order — and it is only taken when `src` has nothing
/// usable in it, so an image the editor itself inlined as a data URI is left
/// alone.
void main() {
  String md(String html) => (HtmlToMarkdown.convert(html) ?? '').trim();

  group('the whole name has to match', () {
    test('src is read, not data-src, when src has a real address', () {
      expect(
        md('<p><img data-src="https://wrong/a.png" '
            'src="https://right/b.png" alt="x"></p>'),
        '![x](https://right/b.png)',
      );
    });

    test('href is read, not data-href', () {
      expect(
        md('<p><a data-href="https://wrong" href="https://right">t</a></p>'),
        '[t](https://right)',
      );
    });

    test('title is read, not data-title', () {
      expect(
        md('<p><a data-title="wrong" title="right" href="https://x">t</a></p>'),
        '[t](https://x "right")',
      );
    });

    test('srcset is not read as src', () {
      expect(
        md('<p><img srcset="https://wrong/a.png 1x" '
            'src="https://right/b.png" alt="x"></p>'),
        '![x](https://right/b.png)',
      );
    });
  });

  group('a lazily loaded image', () {
    test('a placeholder in src gives way to data-src', () {
      expect(
        md('<p><img src="data:image/gif;base64,R0lGODlhAQABAAAAACw=" '
            'data-src="https://right/b.png" alt="x"></p>'),
        '![x](https://right/b.png)',
      );
    });

    test('no src at all falls back to data-src', () {
      expect(
        md('<p><img data-src="https://right/b.png" alt="x"></p>'),
        '![x](https://right/b.png)',
      );
    });

    test('data-original is read too', () {
      expect(
        md('<p><img src="" data-original="https://right/b.png" alt="x"></p>'),
        '![x](https://right/b.png)',
      );
    });

    /// The editor inlines its own images as data URIs when it exports, so a data
    /// URI is only a placeholder when something else offers a real address.
    test('an inlined image with nothing else on offer keeps its data URI', () {
      final out = md('<p><img src="data:image/png;base64,iVBORw0KGgo=" '
          'alt="x"></p>');
      expect(out, contains('data:image/png;base64,iVBORw0KGgo='));
    });
  });

  /// Reading an attribute compiles a pattern, and one was compiled on every
  /// call. This is asked several times of every tag in a paste — `class` of each
  /// span, `href` and `title` of each link, up to five names for one lazily
  /// loaded image — and a clipboard of six thousand spans spent 12% of its time
  /// rebuilding the same dozen patterns (96.7 ms against 87.4 ms here).
  ///
  /// A ratio test was tried and dropped: the clearest framing separated a
  /// cached run from an uncached one by 1.19 against 1.32, which is not enough
  /// margin to hold a threshold on someone else's machine. This asks the
  /// structural question instead. It catches the cache being removed, and it
  /// catches the cache being keyed by something that grows with the document;
  /// it does not catch a cache that is filled and then ignored.
  group('the patterns are kept, not rebuilt', () {
    test('a conversion leaves patterns behind', () {
      md('<p><a href="https://x" title="t">a</a></p>');
      expect(HtmlToMarkdown.keptPatternCount, greaterThan(0),
          reason: 'nothing was kept, so a pattern is being compiled per call');
    });

    test('the cache is keyed by the name, so it stays small', () {
      final many = StringBuffer();
      for (var i = 0; i < 2000; i++) {
        many.write('<p><img src="https://x/$i.png" alt="a $i" title="t $i">'
            '<a href="https://y/$i" title="u $i" class="c$i">l</a></p>');
      }
      md(many.toString());
      expect(
        HtmlToMarkdown.keptPatternCount,
        lessThan(24),
        reason: 'the cache grew with the document, so it is keyed by the '
            'attribute string and not by the name — every tag of every paste '
            'would be held for the life of the process',
      );
    });
  });
}

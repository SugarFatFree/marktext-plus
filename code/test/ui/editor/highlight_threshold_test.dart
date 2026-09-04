import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/syntax_highlighter.dart';

/// Where highlighting gives up, and why it gives up there.
///
/// Timed to the first painted frame, opening Markdown with the usual amount of
/// `code` and **emphasis** in it:
///
///     64 KB   1.2 s        256 KB   8.0 s
///     128 KB  1.3 s        384 KB    24 s
///                          512 KB    45 s
///
/// Superlinear in the number of spans, so the number is a cliff rather than a
/// slope. The limit used to be two megabytes, which no real document reached:
/// a 739 KB file took seven seconds to open and the limit that was meant to
/// prevent exactly that never came into play.
void main() {
  const colors = HighlightColors(
    heading: Colors.blue,
    bold: Colors.black,
    code: Colors.red,
    link: Colors.blue,
    defaultColor: Colors.black,
    quote: Colors.grey,
    comment: Colors.grey,
  );

  String markdown(int bytes) {
    const line = 'Line with a **reasonable** amount of `text` on it.\n';
    return line * (bytes ~/ line.length);
  }

  test('the limit is where opening still takes about a second', () {
    expect(
      IncrementalMarkdownHighlighter.maxHighlightedLength,
      lessThanOrEqualTo(128 * 1024),
      reason: '128 KB 以上开一次要好几秒，往上每翻一倍要三四倍的时间',
    );
    expect(
      IncrementalMarkdownHighlighter.maxHighlightedLength,
      greaterThanOrEqualTo(64 * 1024),
      reason: '定得太低就把本来毫无问题的文档也变成没有高亮的',
    );
  });

  test('a document under the limit is highlighted', () {
    final highlighter = IncrementalMarkdownHighlighter();
    final spans = highlighter.build(markdown(64 * 1024), colors);
    expect(highlighter.isSuspended, isFalse);
    expect(spans, isNotEmpty);
    // Coloured, not one flat run.
    expect(
      spans.any((line) => (line.children?.length ?? 0) > 1),
      isTrue,
      reason: '限额以内的文档应当是有颜色的',
    );
  });

  test('a document over it is shown unstyled, and still editable', () {
    final highlighter = IncrementalMarkdownHighlighter();
    final document = markdown(512 * 1024);
    final spans = highlighter.build(document, colors);
    expect(highlighter.isSuspended, isTrue);

    // The spans still have to add up to the document, or the caret and the
    // selection land in the wrong place.
    final length = spans.fold<int>(
      0,
      (total, line) =>
          total +
          (line.text?.length ?? 0) +
          (line.children?.fold<int>(
                0,
                (n, run) => n + ((run as TextSpan).text?.length ?? 0),
              ) ??
              0),
    );
    expect(length, document.length, reason: '不上色也要一个字都不少');
  });

  test('giving up is not permanent', () {
    // Deleting most of a large file gets the colours back.
    final highlighter = IncrementalMarkdownHighlighter();
    highlighter.build(markdown(512 * 1024), colors);
    expect(highlighter.isSuspended, isTrue);
    highlighter.build(markdown(32 * 1024), colors);
    expect(highlighter.isSuspended, isFalse);
  });
}

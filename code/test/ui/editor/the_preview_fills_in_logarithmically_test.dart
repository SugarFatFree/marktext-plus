import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// How many passes the preview takes to finish drawing a document.
///
/// A pass costs work in proportion to the blocks already on screen rather than
/// to the ones it adds — they are all in one Column inside a scroll view that
/// draws its whole child, so each is walked, reconciled and painted again. A
/// ceiling on the step therefore shortens no pass and adds passes: with one of
/// 2000, a 25 368-block document took 19 passes over 198 918 blocks. Doubling
/// takes 10 passes over 50 918.
///
/// Measured on real hardware through the editor's own stopwatch before this
/// changed: 1 MB / 25 368 blocks filled in 14.0 s, and 2 MB / 50 736 blocks in
/// 37.8 s — 2× the document for 2.7× the time, which is what a quadratic term
/// looks like from outside.
///
/// The fill itself runs across frames and cannot be timed from a test. The
/// number of passes it asks for can be, which is why the arithmetic has a name.
void main() {
  /// The sequence of counts the preview would draw, starting from its first
  /// batch of 50.
  List<int> passes(int total) {
    final seen = <int>[];
    var rendered = total > 50 ? 50 : total;
    seen.add(rendered);
    var guard = 0;
    while (rendered < total) {
      rendered = MarkdownRenderer.nextRenderedCount(rendered, total);
      seen.add(rendered);
      if (++guard > 1000) fail('填充没有收敛：$seen');
    }
    return seen;
  }

  test('a large document finishes in a handful of passes', () {
    final seen = passes(25368);
    expect(seen.last, 25368);
    expect(seen.length, lessThanOrEqualTo(11),
        reason: '25 368 块用了 ${seen.length} 趟。封顶时是 24 趟左右，'
            '而每一趟都在重建已经画好的全部块：$seen');
  });

  test('twice the document is one more pass, not twice as many', () {
    // The property that matters: passes grow with the logarithm of the
    // document, so a document twice the size costs one extra pass rather than
    // twice the passes. A ceiling turns this into a straight line.
    final small = passes(25368).length;
    final large = passes(50736).length;
    expect(large - small, lessThanOrEqualTo(1),
        reason: '文档翻倍多出了 ${large - small} 趟');
  });

  test('the total work is about twice the document, not many times it', () {
    // Each pass walks `rendered` blocks, so the sum of the sequence is the
    // repeated work the fill does. Doubling sums to about 2N; a ceiling of
    // 2000 summed to 7.8N at a megabyte and 13.5N at two.
    final seen = passes(25368);
    final work = seen.fold<int>(0, (a, b) => a + b);
    expect(work, lessThan(25368 * 3),
        reason: '总构建量 $work，约为文档的 ${(work / 25368).toStringAsFixed(1)} 倍');
  });

  test('a document that fits in one batch never starts filling', () {
    expect(passes(40), [40]);
  });

  test('it always finishes exactly on the last block', () {
    for (final total in [51, 99, 100, 101, 3000, 12345]) {
      final seen = passes(total);
      expect(seen.last, total, reason: '$total 块收在了 ${seen.last}');
      expect(seen.toSet().length, seen.length, reason: '$total 块出现了重复的一趟');
    }
  });
}

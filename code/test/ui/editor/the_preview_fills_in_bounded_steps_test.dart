import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// How the preview cuts a long document into frames.
///
/// Each frame's whole duration is a frozen window, so the two things worth
/// pinning pull against each other: a pass must not build so much that the
/// window stops for a visible age, and the passes together must not walk the
/// drawn blocks so many times that finishing takes far longer.
///
/// Profiled on a 25 000-block document — per-frame timings, not a total, since
/// a total hides exactly what matters here:
///
///     ceiling   worst frame   total
///     none          24.3 s    40.1 s
///     4000          10.3 s    42.9 s
///     2000           7.4 s    48.2 s
///     1000           4.8 s    55.5 s
///      500           3.0 s    70.0 s
///
/// The ceiling was once removed on the strength of the walked-block arithmetic
/// alone — 2N against 7.8N, worst frame walking all of them either way — which
/// left out that a pass also *builds* what it adds, at about fourteen times the
/// cost per block. Without a ceiling one pass builds half the document. Hence a
/// test that reads the timings rather than only the counts.
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
      if (++guard > 10000) fail('填充没有收敛：$seen');
    }
    return seen;
  }

  test('no pass builds more than the ceiling', () {
    // The one that matters most: this is the 24 second frame.
    for (final total in [5000, 25368, 50736, 250000]) {
      final seen = passes(total);
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i] - seen[i - 1],
            lessThanOrEqualTo(MarkdownRenderer.maxBatchSize),
            reason: '$total 块的第 $i 趟一次建了 ${seen[i] - seen[i - 1]} 个块');
      }
    }
  });

  test('a document smaller than the ceiling doubles all the way', () {
    // Nearly every document. The ceiling must not cost the common case
    // anything: 2000 blocks is a long article and should take seven passes,
    // not one per two thousand.
    final seen = passes(2000);
    expect(seen.length, lessThanOrEqualTo(7), reason: '$seen');
    expect(seen.take(4).toList(), [50, 100, 200, 400]);
  });

  test('the repeated walking stays a small multiple of the document', () {
    // The sum of the sequence is how many already-drawn blocks get walked
    // across the whole fill. Unbounded passes walk about 2N; a ceiling of 500
    // walked 25N at this size and took 70 seconds.
    const total = 25368;
    final work = passes(total).fold<int>(0, (a, b) => a + b);
    expect(work, lessThan(total * 9),
        reason: '走过 $work，约为文档的 ${(work / total).toStringAsFixed(1)} 倍');
  });

  test('it finishes, exactly on the last block, without repeating one', () {
    for (final total in [1, 50, 51, 99, 100, 101, 3000, 12345, 25368]) {
      final seen = passes(total);
      expect(seen.last, total, reason: '$total 块收在了 ${seen.last}');
      expect(seen.toSet().length, seen.length, reason: '$total 块出现了重复的一趟');
    }
  });

  test('a document that fits in one batch never starts filling', () {
    expect(passes(40), [40]);
  });
}

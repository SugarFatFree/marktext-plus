import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
import 'package:marktext_plus/services/text_search_service.dart';
import '../support/cost_limits.dart';

/// Doubling the document must not more than double the work.
///
/// The README says parsing, highlighting and search are "budgeted by tests
/// that fail if a change makes them slower". They were not. Two tests in the
/// whole suite asserted a duration, both about one small thing, and neither
/// about these. The sentence had been true of the intent and never of the
/// suite — and it is the reason nobody built this: it said the guard existed.
///
/// Wall-clock limits are the obvious way and the wrong one. A limit loose
/// enough for a slow CI box lets a real regression through — this repository
/// has had a 1.4-second parse pass a 2-second limit — and a tight one fails on
/// a busy machine for no reason. A ratio does not care how fast the machine
/// is: it asks whether the cost tracks the input, which is the property that
/// broke four times in this file's history when a pattern went quadratic.
///
/// Four times the document, not twice. The span matters more than the limit:
/// at 2x a quadratic step has to be most of the run before the ratio crosses
/// 2.5 — measured, a tenth of the work going quadratic passed at 2.18 — while
/// at 4x the quadratic part grows sixteenfold against the rest's four.
///
/// The limit is 8x on 4x the work, and the headroom was bought three times: 5
/// failed on an idle machine here within the first handful of runs, and 6
/// passed here five times in a row and then failed on CI at 6.05. Five green
/// runs on one machine say nothing about a shared runner.
///
/// What that headroom costs is worth being clear about. Real quadratic growth
/// is 16x at this span, which any of these limits catches; the limit only
/// decides how small a *partial* regression is caught, and those are hard to
/// catch here anyway — a fifth of parsing going quadratic was the smallest
/// this could see even at 6. So the choice is between catching slightly less
/// and going red on its own, and a performance test that goes red on its own
/// is worse than none: it teaches everyone to keep going when it does.
///
/// Search is measured twenty searches at a time. On its own a search of 160 KB
/// takes about 320 µs here, small enough that the fixed cost of getting into
/// the function is a visible share of it — and a share that does not grow with
/// the document, so it flatters the smaller run and inflates the ratio. That
/// is what went over the line on CI.
///
/// What it catches, measured rather than assumed: a quadratic scan added to
/// search takes the ratio to 9.0 and fails it. Parsing is less sensitive
/// because its own cost is the denominator — 160 KB takes about 110 ms here,
/// and a regression has to be a fifth of that before four times the input
/// crosses six times the time. The sizes below were raised until the
/// denominator stopped moving: at 60 KB the same parse varied 30% run to run,
/// at 160 KB it varies 8%.
void main() {
  /// A document with the constructs that have gone quadratic before: emphasis
  /// runs, footnote markers, comments, fences, links and quotes.
  String document(int sections) => List.generate(
    sections,
    (i) =>
        '## Heading $i\n\n'
        'Text with **bold**, *italic*, `code`, [a link](https://e.invalid/$i) '
        'and a footnote[^$i]. <!-- a comment --> More words after it.\n\n'
        '> A quote that runs on\n> across two lines.\n\n'
        '- item one\n- item two\n  - nested\n\n'
        '```dart\nvoid f$i() {}\n```\n\n'
        '[^$i]: the note.\n\n',
  ).join();

  /// The fastest of [runs] attempts, which is the one least polluted by
  /// whatever else the machine was doing.
  int fastest(int runs, void Function() work) {
    var best = 1 << 30;
    for (var i = 0; i < runs; i++) {
      final watch = Stopwatch()..start();
      work();
      watch.stop();
      if (watch.elapsedMicroseconds < best) best = watch.elapsedMicroseconds;
    }
    return best;
  }

  test('parsing tracks the size of the document', () {
    final unit = document(600);
    final four = document(2400);
    expect(four.length, greaterThan(unit.length * 3.9));

    MarkdownParser().parse(unit); // warm the JIT before either measurement

    final one = fastest(3, () => MarkdownParser().parse(unit));
    final many = fastest(3, () => MarkdownParser().parse(four));

    expect(
      many,
      lessThan(one * costGrowthLimit),
      reason:
          '四倍的文档花了 ${(many / one).toStringAsFixed(1)} 倍的时间'
          '（$one µs → $many µs）——代价不再跟着输入走，多半是某处退化成了二次方',
    );
  });

  test('search tracks the size of the document', () {
    final unit = document(600);
    final four = document(2400);

    TextSearch.matches(unit, 'item');

    // Twenty at a time: one search is short enough that the constant cost of
    // the call is a measurable part of it, and that part does not grow with
    // the document.
    void search(String text) {
      for (var i = 0; i < 20; i++) {
        TextSearch.matches(text, 'item');
      }
    }

    final one = fastest(3, () => search(unit));
    final many = fastest(3, () => search(four));

    expect(
      many,
      lessThan(one * costGrowthLimit),
      reason:
          '搜索的代价不再跟着文档走：四倍的文档花了 '
          '${(many / one).toStringAsFixed(1)} 倍（$one µs → $many µs）',
    );
  });

  test('the documents are big enough for the ratio to mean anything', () {
    // Guards the guard. Two documents that both parse in under a millisecond
    // would compare timer resolution rather than work, and the ratio would
    // pass whatever the parser did.
    final unit = document(600);
    expect(unit.length, greaterThan(150000));

    final took = fastest(2, () => MarkdownParser().parse(unit));
    expect(
      took,
      greaterThan(1000),
      reason: '小到一毫秒以内的话，比的是计时器精度不是工作量',
    );
  });
}

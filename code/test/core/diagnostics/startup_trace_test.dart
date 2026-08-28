import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/diagnostics/startup_trace.dart';

/// The trace file keeps the last few launches instead of being overwritten.
///
/// Answering "is it only the first launch that is slow, or every launch?"
/// decides whether a slow start is Windows reading a cold binary off disk or
/// something the program is doing — and with an overwritten file that question
/// cost the person reporting it four manual steps.
void main() {
  String run(int n) => '${StartupTrace.runSeparator}\n2026-01-0${n}T00:00:00\n'
      'build: test\n     0 ms  (+    0 ms)  run $n';

  test('an empty or absent previous log carries nothing over', () {
    expect(StartupTrace.recentRuns(''), '');
    expect(StartupTrace.recentRuns('   \n\n  '), '');
  });

  test('a single earlier run is kept whole', () {
    final carried = StartupTrace.recentRuns(run(1));
    expect(carried, contains('run 1'));
    expect(StartupTrace.runSeparator.allMatches(carried).length, 1);
  });

  test('the oldest runs are dropped once the file is full', () {
    // Five earlier runs, room for three alongside the one about to be written.
    final existing = List.generate(5, (i) => run(i + 1)).join('\n\n');
    final carried = StartupTrace.recentRuns(existing);

    expect(carried, isNot(contains('run 1')), reason: '最旧的应该被丢掉');
    expect(carried, isNot(contains('run 2')));
    for (final kept in ['run 3', 'run 4', 'run 5']) {
      expect(carried, contains(kept));
    }
    expect(StartupTrace.runSeparator.allMatches(carried).length, 3);
  });

  test('what is carried over ends ready for the next run to be appended', () {
    final carried = StartupTrace.recentRuns(run(1));
    expect(carried.endsWith('\n\n'), isTrue,
        reason: '没有留出空行，下一次运行会紧贴着上一次的最后一行');
  });
}

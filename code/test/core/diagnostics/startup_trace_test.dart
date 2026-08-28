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

  group('runner timings arrive as entrypoint arguments', () {
    test('the values are picked out and the file arguments left alone', () {
      // Environment variables were tried first and Dart's Platform.environment
      // never saw them: the trace said "runner not instrumented" on a build
      // that certainly was.
      StartupTrace.readRunnerArguments([
        'C:\\notes\\readme.md',
        '--mt-trace-runner-entry=1200',
        '--mt-trace-engine-start=1450',
      ]);

      expect(StartupTrace.runnerMarkForTesting('runner-entry'), 1200);
      expect(StartupTrace.runnerMarkForTesting('engine-start'), 1450);
    });

    test('nonsense is ignored rather than reported as a timing', () {
      StartupTrace.readRunnerArguments([
        '--mt-trace-runner-entry=-1',
        '--mt-trace-engine-start=',
        '--mt-trace-broken',
      ]);

      // -1 is what the runner writes when Windows would not tell it when the
      // process started; it is an absence, not a measurement.
      expect(StartupTrace.runnerMarkForTesting('broken'), isNull);
      expect(StartupTrace.runnerMarkForTesting('engine-start'), isNot(-1));
    });
  });

  group('the renderer line', () {
    String rendererLine(List<String> args) {
      // The timings come too: without runner-entry the trace reports "not
      // instrumented" and never reaches the renderer line.
      StartupTrace.readRunnerArguments([
        '--mt-trace-runner-entry=100',
        '--mt-trace-engine-start=150',
        ...args,
      ]);
      return StartupTrace.preDartLinesForTesting()
          .firstWhere((l) => l.contains('renderer:'), orElse: () => '');
    }

    test('says which renderer the run got', () {
      expect(rendererLine(['--mt-trace-impeller=0', '--mt-trace-impeller-built=0']),
          contains('Impeller off'));
      expect(rendererLine(['--mt-trace-impeller=1', '--mt-trace-impeller-built=1']),
          contains('Impeller on'));
    });

    test('says so when the environment overrode what was built', () {
      // Two installers were built one each way and both reported "off",
      // because a MARKTEXT_IMPELLER left over on the machine outranks the
      // built-in default. The line could not say that, and working it out
      // cost a round of measurement.
      final line =
          rendererLine(['--mt-trace-impeller=0', '--mt-trace-impeller-built=1']);

      expect(line, contains('Impeller off'));
      expect(line, contains('built on'));
      expect(line, contains('MARKTEXT_IMPELLER'));
    });

    test('stays quiet when they agree', () {
      final line =
          rendererLine(['--mt-trace-impeller=1', '--mt-trace-impeller-built=1']);
      expect(line, isNot(contains('overridden')));
    });

    test('an old runner that sends no built value still reports one', () {
      final line = rendererLine(['--mt-trace-impeller=0']);
      expect(line, contains('Impeller off'));
      expect(line, isNot(contains('overridden')));
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/diagnostics/startup_trace.dart';

/// A build a reader runs has to be able to say which build it is.
///
/// `StartupTrace.buildStamp` exists because of a real diagnosis that went
/// wrong: a slow launch was chased against the source as it stood, and the
/// binary that produced it turned out to be several commits older. The stamp
/// is read from `--dart-define=BUILD_SHA`, which the CI workflow passes on
/// every build it makes.
///
/// The release workflow — the one whose output is the only binary anybody
/// installs — passed none of them. So the stamp fired on throwaway CI
/// binaries nobody ships and stayed dark on every binary a reader actually
/// runs, where it printed "this is not a CI build" about a build CI made.
/// Exactly the wrong way round, and exactly the case the feature was written
/// for.
///
/// This reconciles the two: the defines are declared in Dart and supplied in
/// YAML, by two different kinds of author, and nothing compared them.
void main() {
  /// The workflow files, from `code/` where the tests run.
  final workflows = {
    'ci.yml': File('../.github/workflows/ci.yml'),
    'release.yml': File('../.github/workflows/release.yml'),
  };

  /// Skipped rather than failed when they are not there: a checkout of `code/`
  /// alone is a thing people do, and a guard that always fails there teaches
  /// people to ignore it.
  bool present() => workflows.values.every((f) => f.existsSync());

  /// The whole command starting at [start], following shell continuations —
  /// `\` in bash, a backtick in PowerShell. Taking only the first line would
  /// read `flutter build windows --release` and miss every flag under it.
  String commandAt(List<String> lines, int start) {
    final buffer = StringBuffer(lines[start]);
    var i = start;
    while (i < lines.length - 1) {
      final trimmed = lines[i].trimRight();
      if (!trimmed.endsWith(r'\') && !trimmed.endsWith('`')) break;
      i++;
      buffer.write('\n${lines[i]}');
    }
    return buffer.toString();
  }

  test('every build in every workflow is stamped with its commit', () {
    if (!present()) return;
    // Not "the first build": this file has been wrong once before in exactly
    // that way — a guard over release.yml read only the first match and let a
    // second, unfixed copy through. There are five build steps across the two
    // workflows and each one produces a binary somebody may run.
    final unstamped = <String>[];
    var seen = 0;
    for (final entry in workflows.entries) {
      final lines = entry.value.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        // Both spellings count: a step's own line, and the inline
        // `run: flutter build …` form the release workflow uses. Anchoring
        // at the start of the line found two of the five.
        if (lines[i].trimLeft().startsWith('#')) continue;
        if (!RegExp(r'(^|\s)flutter build \w+').hasMatch(lines[i])) continue;
        seen++;
        final command = commandAt(lines, i);
        if (!command.contains('--dart-define=BUILD_SHA=')) {
          unstamped.add('${entry.key}:${i + 1} ${lines[i].trim()}');
        }
      }
    }
    expect(
      seen,
      greaterThanOrEqualTo(5),
      reason: '两个 workflow 一共至少有五处构建；数不到说明取法失效了，'
          '而失效的取法会让下面那条断言在空集合上通过',
    );
    expect(
      unstamped,
      isEmpty,
      reason: '这些构建产出的二进制无法说出自己是哪个提交',
    );
  });

  test('a build with nothing stamped in says so, rather than guessing', () {
    // The tests themselves are such a build, so this is the value under test
    // here. It has to read as "no stamp", not as a stamp: a trace whose header
    // invents a commit is worse than one that admits it has none.
    expect(StartupTrace.buildStamp, contains('local'));
    expect(StartupTrace.buildStamp, isNot(contains('CI run #')));
  });
}

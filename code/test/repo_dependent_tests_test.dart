import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tests that need a sibling repository have to say so.
///
/// The plugin and SDK repositories sit beside the editor's checkout on the
/// machine this was written on, and nowhere on CI. A test that reads one
/// without a `skip` does not fail with "the repository is not here" — it fails
/// with `LateInitializationError`, in CI only, after everything passed
/// locally. That has now happened twice.
void main() {
  test('every test that needs a sibling repository skips without it', () {
    final offenders = <String>[];

    for (final file
        in Directory('test')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('_test.dart'))) {
      final source = file.readAsStringSync();
      // The marker every such file uses: it walks up looking for a repository
      // and records whether it found one. This file talks about that marker
      // rather than using it, so it excludes itself by looking for the
      // assignment with a value after it.
      if (file.path.endsWith('repo_dependent_tests_test.dart')) continue;

      // Anything that reads a sibling repository has to skip somewhere. This
      // is the cheap half of the check and it is the one with reach: the
      // strict half below only sees files written with the idiom below it,
      // and four of the seven files that read a sibling repository are not —
      // they keep that path in variables of their own naming. Their skips are
      // correct today; nothing was watching them.
      if (source.contains('marktext-plus-plugins') &&
          !source.contains('skip:')) {
        offenders.add('${file.path}: 读了兄弟仓库，但一个 skip 都没有');
        continue;
      }

      // The strict half. It counts, so it needs every case in the file to
      // need the skip — which is true of the files written this way, and not
      // true in general: a file can hold one case that reads only `lib/`.
      // That is why the reach comes from the check above rather than from
      // widening this one.
      if (!source.contains('final present = repo != null;')) continue;

      // Every case in the file must carry a skip. Counting is enough — a file
      // where the two numbers differ has one that runs regardless.
      // `\b` does not hold before `(`, so the boundary is spelled out: not
      // preceded by a letter, which keeps `expectLater(` and the like out.
      final tests = RegExp(
        r'(?<![A-Za-z_])test(?:Widgets)?\(',
      ).allMatches(source).length;
      final skips = RegExp(r'skip: present').allMatches(source).length;
      if (tests != skips) {
        offenders.add('${file.path}: $tests 个用例，只有 $skips 个带 skip');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          '这些用例在 CI 上会以 LateInitializationError 失败，'
          '而不是被跳过：\n${offenders.join('\n')}',
    );
  });
}

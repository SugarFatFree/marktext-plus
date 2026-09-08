import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/diagnostics/resident_memory.dart';

/// The third claim, measured.
///
/// Starting in under a second and handling large files are both reported now.
/// Small footprint was not measured anywhere — there was no number to compare
/// one version against the next with, and no way to answer "what did opening
/// that document cost".
void main() {
  test('it reports megabytes, and a plausible number of them', () {
    final mb = ResidentMemory.megabytes();

    // Null is allowed — a platform that will not say is a real answer — but
    // this one does, and a test that accepted null everywhere would pass on a
    // machine where the reading had silently broken.
    expect(mb, isNotNull, reason: '这台机器读得到 RSS，读不到说明取法坏了');
    expect(mb, greaterThan(0));
    expect(
      mb,
      lessThan(100000),
      reason: '一个 100 GB 的读数说明单位换算错了，不是编辑器胖了',
    );
  });

  test('the suffix carries the unit, and is a suffix', () {
    final said = ResidentMemory.suffix();

    expect(said, isNotEmpty);
    expect(said, startsWith(' ('), reason: '要能直接接在一句话后面');
    expect(said, endsWith('MB resident)'));
    // The shape, not a value. Asserting this holds the same number as another
    // `megabytes()` call compares two readings of something that changes
    // between them — it passed here and failed on CI, where thousands of
    // tests were moving the figure across a megabyte boundary in between.
    expect(
      said,
      matches(RegExp(r'^ \(\d+ MB resident\)$')),
      reason: '这一句要能原样接在日志行后面，且带着单位',
    );
  });

  test('nothing is said rather than a zero', () {
    // `currentRss` answers 0 where a platform has no implementation instead of
    // throwing, and "0 MB" in a log reads as a measurement rather than as an
    // absence. This is the reason `megabytes` returns null rather than 0 —
    // stated here because the branch cannot be reached on a machine that does
    // report.
    // `contains` would be wrong here: "150 MB resident" holds "0 MB resident"
    // as a substring, and this test passed until a machine happened to report
    // a round number.
    expect(
      ResidentMemory.suffix(),
      isNot(' (0 MB resident)'),
      reason: '把「问不出来」写成「零」，比不写更糟',
    );
    expect(ResidentMemory.megabytes(), isNot(0));
  });

  test('it is asked from a few places, and none of them is a hot path', () {
    // 10 µs a call: nothing beside the two on the startup path, and real in a
    // `build` or a keystroke handler, where "small footprint" would be paid
    // for by the thing it claims to describe.
    //
    // The count is the guard, and it is the exact count rather than a ceiling
    // with room in it: a limit with slack lets the first new caller through in
    // silence, which is the one that would have wanted this comment. A third
    // caller is not necessarily wrong — it is a reason to read this first.
    final callers = <String, int>{};
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      if (file.path.endsWith('resident_memory.dart')) continue;
      final count = 'ResidentMemory.'.allMatches(file.readAsStringSync()).length;
      if (count > 0) callers[file.path] = count;
    }

    expect(
      callers.values.fold(0, (a, b) => a + b),
      2,
      reason: '读内存要 10 µs，放进每帧或每次按键的路径上就会被它自己拖慢：$callers',
    );
    expect(callers, isNotEmpty, reason: '一处都没有的话，这个类是死代码');
  });
}

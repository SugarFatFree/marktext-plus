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
    expect(
      said,
      contains('${ResidentMemory.megabytes()}'),
      reason: '两处该说同一个数',
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
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Work started and not waited for.
///
/// Twice now this has been a defect rather than a choice. BUG-149: the disk
/// stamp was topped up by an unawaited call after a tab was built, leaving a
/// window in which the tab had a path and no stamp — short enough to pass
/// here and long enough to fail on CI. BUG-159: the same shape after a save,
/// so a second save compared the file against a stamp older than this
/// application's own write and called it somebody else's change.
///
/// Both were invisible in review because `unawaited(...)` reads as a decision
/// even when nobody made one. So each occurrence has to say why, in the lines
/// just above it — which is the point at which someone has to think about it.
void main() {
  test('every unawaited call says why it is not awaited', () {
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('unawaited(')) continue;
        // The reason goes in the comment block immediately above.
        final from = i - 8 < 0 ? 0 : i - 8;
        final above = lines.sublist(from, i);
        final hasReason = above.any((l) {
          final t = l.trim();
          return t.startsWith('//') &&
              (t.contains('not awaited') ||
                  t.contains('Deliberately') ||
                  t.contains('deliberately'));
        });
        if (!hasReason) offenders.add('${file.path}:${i + 1}');
      }
    }

    expect(offenders, isEmpty,
        reason: '这些 unawaited 没有写明为什么不等——'
            '而"发起后不等"已经两次被证明是缺陷而不是选择');
  });
}

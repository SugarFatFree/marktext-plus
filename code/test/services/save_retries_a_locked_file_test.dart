import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/file_service.dart';

/// Saving survives a file that is briefly held open.
///
/// On Windows a virus scanner routinely holds a newly written file for a few
/// dozen milliseconds, and the rename at the end of an atomic save fails with
/// a sharing violation that is gone by the next attempt. Without the retry,
/// the atomic save would be *less* reliable than the truncating write it
/// replaced — the reader would be told their document could not be saved,
/// on a machine where the old code would have saved it.
///
/// The retry was there and nothing held it: deleting it left the whole suite
/// green, because a scanner's hold cannot be staged on a machine with no
/// scanner. `renameWithRetry` takes the move and the wait so it can be.
void main() {
  late Directory dir;
  late File temp;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('rename_retry');
    temp = File('${dir.path}/doc.md.tmp')..writeAsStringSync('saved\n');
  });
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  /// A move that fails [failures] times before it works, and counts its tries.
  ({Future<void> Function(File, String) move, List<int> tries}) flaky(
    int failures,
  ) {
    final tries = <int>[];
    return (
      move: (file, target) async {
        tries.add(tries.length);
        if (tries.length <= failures) {
          throw const FileSystemException('the file is in use', 'doc.md');
        }
        await file.rename(target);
      },
      tries: tries,
    );
  }

  test('a hold that clears on the second try still saves', () async {
    final attempt = flaky(1);
    final waits = <Duration>[];

    await FileService.renameWithRetry(
      temp,
      '${dir.path}/doc.md',
      rename: attempt.move,
      wait: (d) async => waits.add(d),
    );

    expect(attempt.tries.length, 2, reason: '第一次失败之后应该再试一次');
    expect(File('${dir.path}/doc.md').readAsStringSync(), 'saved\n');
    expect(waits, isNotEmpty, reason: '立刻重试等于没有等那个占用放开');
  });

  test('a hold that clears on the third try still saves', () async {
    final attempt = flaky(2);

    await FileService.renameWithRetry(
      temp,
      '${dir.path}/doc.md',
      rename: attempt.move,
      wait: (_) async {},
    );

    expect(attempt.tries.length, 3);
    expect(File('${dir.path}/doc.md').existsSync(), isTrue);
  });

  test('a hold that never clears is reported, not retried forever', () async {
    final attempt = flaky(99);

    await expectLater(
      FileService.renameWithRetry(
        temp,
        '${dir.path}/doc.md',
        rename: attempt.move,
        wait: (_) async {},
      ),
      throwsA(isA<FileSystemException>()),
    );

    // Three tries, not an unbounded loop: a lock that is not going away has
    // to reach the reader rather than hang the save.
    expect(attempt.tries.length, 3);
  });

  test('each wait is longer than the one before', () async {
    final attempt = flaky(2);
    final waits = <Duration>[];

    await FileService.renameWithRetry(
      temp,
      '${dir.path}/doc.md',
      rename: attempt.move,
      wait: (d) async => waits.add(d),
    );

    expect(waits, hasLength(2));
    expect(waits[1], greaterThan(waits[0]),
        reason: '两次都等一样久的话，第二次多半也撞在同一个占用上');
  });
}

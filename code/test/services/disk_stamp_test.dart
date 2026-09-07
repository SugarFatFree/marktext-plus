import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/file_service.dart';

/// What counts as "the file changed underneath us".
///
/// The stamp is a modification time and a size, and both halves matter. These
/// three behaviours are all written into the production code and were all
/// still passing when it was broken: dropping the time from the comparison,
/// answering "unchanged" for a file that has gone, and normalising only
/// `\r\n` each left the whole suite green.
///
/// The first is the one that costs a document. Another program edits the file
/// without changing its length — a typo of the same width, a formatter, a
/// tool rewriting a field — and an editor comparing sizes alone sees nothing,
/// saves over it, and says nothing to anybody.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('disk_stamp'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('an edit that keeps the size still counts as a change', () async {
    final file = File('${root.path}/note.md')..writeAsStringSync('abcd');
    final stamp = await FileService.stampOf(file.path);
    expect(stamp, isNotNull);

    // The same number of bytes, written later. Some filesystems record the
    // time in seconds, so the difference is made large rather than relying on
    // how long the test takes.
    file.writeAsStringSync('wxyz');
    file.setLastModifiedSync(
      stamp!.modified.add(const Duration(hours: 1)),
    );

    expect(await FileService.stampOf(file.path).then((s) => s!.size),
        stamp.size,
        reason: '前提是大小确实没变，否则测的是另一件事');
    expect(await FileService.hasChangedSince(file.path, stamp), isTrue,
        reason: '改了内容但长度没变，仍旧是别人动过这个文件——'
            '只比大小就会把对方的修改静默覆盖掉');
  });

  test('a file that has gone counts as a change', () async {
    final file = File('${root.path}/note.md')..writeAsStringSync('abcd');
    final stamp = await FileService.stampOf(file.path);
    file.deleteSync();

    expect(await FileService.hasChangedSince(file.path, stamp), isTrue,
        reason: '文件不见了是最大的一种变化，不能当作「没变过」');
  });

  test('no stamp is not evidence of a change', () async {
    // The other direction, and it has bitten before: answering true here made
    // a document with no stamp impossible to save, ever.
    final file = File('${root.path}/note.md')..writeAsStringSync('abcd');
    expect(await FileService.hasChangedSince(file.path, null), isFalse);
  });

  test('a lone carriage return is a line ending too', () {
    // Classic Mac files. Rare, and handled — but nothing held it there.
    expect(FileService.normalizeLineEndings('a\rb'), 'a\nb');
    expect(FileService.normalizeLineEndings('a\r\nb'), 'a\nb');
    expect(FileService.normalizeLineEndings('a\r\n\rb'), 'a\n\nb');
    expect(FileService.normalizeLineEndings('plain'), 'plain');
  });
}

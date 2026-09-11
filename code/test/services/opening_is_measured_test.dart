import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/models/file_encoding.dart';
import 'package:marktext_plus/services/app_log.dart';
import 'package:marktext_plus/services/file_service.dart';

/// Opening a document leaves a number behind.
///
/// The front page calls 128 KB the last size that still opens in about a
/// second, and nothing anywhere measured opening. The editor writes one
/// per-document line and it belongs to the preview — while the default view is
/// the source pane, so the ordinary way of opening a large file produced no
/// measurement at all. A reader reporting "it took ages" could be answered
/// with nothing, and a change that made it worse would arrive unannounced.
///
/// Two halves, kept apart on purpose: this line covers the read and the
/// decode, the preview's covers the drawing. Which half was slow is the first
/// thing anyone needs to know.
void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('opening_');
    AppLog.instance.clear();
  });
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  List<String> opened() => AppLog.instance
      .recent()
      .where((line) => line.message.startsWith('opened '))
      .map((line) => line.message)
      .toList();

  test('it says what was opened, how big, in what encoding, and how long',
      () async {
    final path = '${root.path}/notes.md';
    File(path).writeAsBytesSync(
      FileEncoding.gbk.encode('# 标题\n\n${'正文。' * 400}\n'),
    );

    await FileService().readFileWithLineEnding(path);

    expect(opened(), hasLength(1));
    final said = opened().single;
    expect(said, contains('notes.md'), reason: '哪个文件');
    expect(said, contains('KB'), reason: '多大');
    expect(said, contains(FileEncoding.gbk.label), reason: '什么编码');
    expect(said, contains('characters'), reason: '多少字符');
    expect(said, contains(' ms'), reason: '用了多久');
  });

  test('the size is of the bytes, not of the characters', () async {
    // Not the same number in any encoding that is not ASCII. Reporting the
    // character count as kilobytes is how "opened 2 KB in 300 ms" becomes a
    // line nobody can act on — and a first version of this test only compared
    // the two numbers to each other, which a log saying either one passes.
    final path = '${root.path}/wide.md';
    final text = '中文' * 3000; // 6000 characters
    final bytes = FileEncoding.gbk.encode(text); // two bytes each in GBK
    File(path).writeAsBytesSync(bytes);

    final fromBytes = bytes.length ~/ 1024;
    final fromCharacters = text.length ~/ 1024;
    expect(fromBytes, isNot(fromCharacters),
        reason: '样例要让两个数字不同，否则这条测试什么也没问');

    await FileService().readFileWithLineEnding(path);

    expect(opened().single, contains('$fromBytes KB'));
    expect(opened().single, isNot(contains('$fromCharacters KB')),
        reason: '报的是字符数当千字节——那行数字就没有意义了');
  });

  test('a file it cannot read leaves no line claiming it opened one', () async {
    await expectLater(
      FileService().readFileWithLineEnding('${root.path}/nosuch.md'),
      throwsA(anything),
    );
    expect(opened(), isEmpty,
        reason: '读失败却记了一行「已打开」，日志就成了第二个说谎的地方');
  });
}

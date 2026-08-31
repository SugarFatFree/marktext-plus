import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/models/file_encoding.dart';
import 'package:marktext_plus/services/file_service.dart';

/// What the editor says a document is, against what was written.
///
/// A character the document's encoding cannot carry is written as UTF-8
/// instead — keeping the character matters more than keeping the encoding.
/// The status bar reads the document's encoding, so unless the save says what
/// it did, the editor goes on naming an encoding the file is no longer in.
void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('save_enc'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<FileEncoding> saveAs(FileEncoding encoding, String content) =>
      FileService.saveDocument('${dir.path}/note.md', content,
          encoding: encoding);

  test('a GBK note that stays GBK reports GBK', () async {
    expect(await saveAs(FileEncoding.gbk, '这是一段普通的中文笔记。'),
        FileEncoding.gbk);
  });

  test('a GBK note with an emoji reports UTF-8', () async {
    // The file really is UTF-8 now; saying GBK would be saying something
    // untrue about it.
    expect(await saveAs(FileEncoding.gbk, '旧笔记 🎉 新内容'),
        FileEncoding.utf8Encoding);
  });

  test('a Latin-1 note with Chinese in it reports UTF-8', () async {
    expect(await saveAs(FileEncoding.latin1Encoding, 'café 中文'),
        FileEncoding.utf8Encoding);
  });

  test('what is reported is what the file turns out to be', () async {
    // The check that matters: read the file back with no hints and see
    // whether the encoding the save named is the one detection finds.
    for (final content in ['普通中文笔记', '旧笔记 🎉 新内容']) {
      final used = await saveAs(FileEncoding.gbk, content);
      final bytes = File('${dir.path}/note.md').readAsBytesSync();
      final (text, detected) = FileEncoding.decode(bytes);
      expect(text, content, reason: content);
      expect(detected, used, reason: '保存说是 $used，读回来却是 $detected');
    }
  });

  test('an ordinary UTF-8 save reports UTF-8', () async {
    expect(await saveAs(FileEncoding.utf8Encoding, '# 标题\n正文\n'),
        FileEncoding.utf8Encoding);
  });
}

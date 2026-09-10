import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/models/file_encoding.dart';
import 'package:marktext_plus/models/line_ending.dart';
import 'package:marktext_plus/services/file_service.dart';

/// A file opens in the encoding it was written in and is written back in it.
///
/// The front page promises that in one sentence — "detected on open (with or
/// without a byte order mark) and written back as they were found" — and the
/// second half was tested for three of the eight. Detection had all eight;
/// saving had UTF-8, GBK and Latin-1. A regression in the UTF-16 arm would
/// convert a reader's file to something else on the first save, and their
/// other tools would be the ones to notice.
///
/// The samples are checked before they are used. Twice while writing this,
/// text was chosen that the encoding could not carry: `encodeWithFallback`
/// quietly wrote UTF-8 instead — correctly, since keeping the character
/// matters more — and the round trip then measured UTF-8 against UTF-8 and
/// passed for the wrong reason. So each sample has to encode *as itself*
/// first, and a sample that cannot is a failure of this test rather than a
/// silent pass.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('encodings'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  /// Text the encoding can actually hold, and that is not plain ASCII —
  /// ASCII alone is valid in all of them, so it would prove nothing about
  /// which one was detected.
  String sampleFor(FileEncoding encoding) => switch (encoding) {
        // Latin-1 has no CJK. Accented letters are what distinguish it.
        FileEncoding.latin1Encoding => 'Café résumé naïve\nZweite Zeile\n',
        // Everything else here reaches the CJK planes, and GBK is a Chinese
        // encoding: accented Latin letters are the thing *it* cannot hold.
        _ => 'Hello 世界\n第二行\n',
      };

  test('every encoding is detected as itself and written back unchanged',
      () async {
    final wrong = <String>[];

    for (final encoding in FileEncoding.values) {
      final text = sampleFor(encoding);

      // The sample must survive this encoding, or the round trip below is
      // measuring UTF-8 against UTF-8.
      final written = encoding.encodeWithFallback(text);
      if (written.used != encoding) {
        wrong.add('${encoding.name}: 样例装不进这个编码，'
            '实际写成了 ${written.used.name}——换一段这个编码带得动的文本');
        continue;
      }

      final path = '${root.path}/${encoding.name}.md';
      await File(path).writeAsBytes(written.bytes);

      final (decoded, detected) =
          FileEncoding.decode(await File(path).readAsBytes());
      if (detected != encoding) {
        wrong.add('${encoding.name}: 打开时被认成了 ${detected.name}');
        continue;
      }
      if (decoded != text) {
        wrong.add('${encoding.name}: 读回来的文本变了');
        continue;
      }

      final saved = await FileService.saveDocument(
        path,
        decoded,
        encoding: detected,
        lineEnding: LineEnding.lf,
      );
      if (saved != encoding) {
        wrong.add('${encoding.name}: 保存时改成了 ${saved.name}');
        continue;
      }

      final after = await File(path).readAsBytes();
      if (after.length != written.bytes.length ||
          List.generate(after.length, (i) => after[i] == written.bytes[i])
              .contains(false)) {
        wrong.add('${encoding.name}: 存回去的字节与原来的不同'
            '（${written.bytes.length} → ${after.length} 字节）');
      }
    }

    expect(wrong, isEmpty,
        reason: '这些编码没能原样往返：\n${wrong.join('\n')}');
  });

  test('there are eight encodings to check', () {
    // So that adding a ninth adds a row above rather than passing quietly.
    expect(FileEncoding.values, hasLength(8));
  });
}

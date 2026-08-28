import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/models/file_encoding.dart';

/// Reading a note that was written before UTF-8 won.
///
/// Anything that is not UTF-8 used to be read as Latin-1, which turns every
/// Chinese character into two wrong ones. Telling GBK from Latin-1 is the
/// whole difficulty: both are bytes above 0x7F, and `é` followed by a letter
/// looks exactly like a valid GBK pair. What separates them is how much of
/// the file is made of such pairs — Chinese is almost all of it, French is
/// ASCII with the occasional accent.
void main() {
  /// gbk: `# 中文标题` and a sentence.
  const gbkChinese = <int>[
    0x23, 0x20, 0xD6, 0xD0, 0xCE, 0xC4, 0xB1, 0xEA, 0xCC, 0xE2, 0x0A, 0x0A,
    0xD5, 0xE2, 0xCA, 0xC7, 0xD2, 0xBB, 0xB6, 0xCE, 0xD3, 0xC3, 0x20, 0x47,
    0x42, 0x4B, 0x20, 0xB1, 0xA3, 0xB4, 0xE6, 0xB5, 0xC4, 0xBE, 0xC9, 0xB1,
    0xCA, 0xBC, 0xC7, 0xA1, 0xA3, 0x0A,
  ];

  /// gbk: markdown with Chinese mixed into it.
  const gbkMixed = <int>[
    0x54, 0x69, 0x74, 0x6C, 0x65, 0x20, 0xB1, 0xEA, 0xCC, 0xE2, 0x0A, 0x0A,
    0x63, 0x6F, 0x64, 0x65, 0x20, 0x60, 0x78, 0x60, 0x20, 0xD3, 0xEB, 0xD6,
    0xD0, 0xCE, 0xC4, 0xBB, 0xEC, 0xC5, 0xC5, 0xA1, 0xA3, 0x0A,
  ];

  /// latin-1: `L'été est arrivé.`
  const latin1French = <int>[
    0x43, 0x61, 0x66, 0x65, 0x2C, 0x20, 0x64, 0x65, 0x6A, 0x61, 0x20, 0x76,
    0x75, 0x2E, 0x20, 0x4C, 0x27, 0xE9, 0x74, 0xE9, 0x20, 0x65, 0x73, 0x74,
    0x20, 0x61, 0x72, 0x72, 0x69, 0x76, 0xE9, 0x2E, 0x0A,
  ];

  /// latin-1: `Grüße aus München, Straße 5.`
  const latin1German = <int>[
    0x47, 0x72, 0xFC, 0xDF, 0x65, 0x20, 0x61, 0x75, 0x73, 0x20, 0x4D, 0xFC,
    0x6E, 0x63, 0x68, 0x65, 0x6E, 0x2C, 0x20, 0x53, 0x74, 0x72, 0x61, 0xDF,
    0x65, 0x20, 0x35, 0x2E, 0x0A,
  ];

  (String, FileEncoding) read(List<int> bytes) =>
      FileEncoding.decode(Uint8List.fromList(bytes));

  group('a GBK document is read as GBK', () {
    test('Chinese prose', () {
      final (text, encoding) = read(gbkChinese);

      expect(encoding, FileEncoding.gbk);
      expect(text, startsWith('# 中文标题'));
      expect(text, contains('旧笔记'));
    });

    test('markdown with Chinese mixed into it', () {
      final (text, encoding) = read(gbkMixed);

      expect(encoding, FileEncoding.gbk);
      expect(text, contains('标题'));
      expect(text, contains('`x`'), reason: 'ASCII 部分不该被动过');
    });

    test('what it writes back is what it read', () {
      final (text, encoding) = read(gbkChinese);

      expect(encoding.encode(text), Uint8List.fromList(gbkChinese),
          reason: '存回去的字节与原文件不一致');
    });
  });

  group('Latin-1 stays Latin-1', () {
    test('French, whose accents look like GBK lead bytes', () {
      final (text, encoding) = read(latin1French);

      expect(encoding, FileEncoding.latin1Encoding, reason: '法语被当成了中文');
      expect(text, contains('été'));
    });

    test('German', () {
      final (text, encoding) = read(latin1German);

      expect(encoding, FileEncoding.latin1Encoding);
      expect(text, contains('Grüße'));
    });
  });

  group('what must not have changed', () {
    test('UTF-8 is still read first', () {
      final (text, encoding) = read('# 中文标题\n'.codeUnits.isEmpty
          ? const <int>[]
          : const Utf8Encoder().convert('# 中文标题\n'));

      expect(encoding, FileEncoding.utf8Encoding);
      expect(text, '# 中文标题\n');
    });

    test('plain ASCII is UTF-8, not GBK', () {
      final (text, encoding) = read('# Title\n\nplain.\n'.codeUnits);

      expect(encoding, FileEncoding.utf8Encoding);
      expect(text, '# Title\n\nplain.\n');
    });

    test('an empty file is not guessed at', () {
      expect(read(const []).$2, FileEncoding.utf8Encoding);
    });
  });
  group('a short word with accents is not mistaken for Chinese', () {
    // The share of paired bytes alone lets these through: in a word this
    // short two accented letters are a third of the file. Two things settle
    // it — the decoder marks what it cannot read, and the mark lands in the
    // private use area; and below a dozen bytes there is not enough evidence
    // to prefer GBK at all, which is what `Öl` needs, its two bytes being a
    // valid sequence for a real character.
    for (final entry in {
      'Grüße': [0x47, 0x72, 0xFC, 0xDF, 0x65, 0x0A],
      'Öl': [0xD6, 0x6C, 0x0A],
      'ÿ alone': [0xFF, 0x0A],
    }.entries) {
      test(entry.key, () {
        expect(read(entry.value).$2, FileEncoding.latin1Encoding,
            reason: '${entry.key} 被当成了中文');
      });
    }
  });

}

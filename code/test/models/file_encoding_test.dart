import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/models/file_encoding.dart';

void main() {
  _bomlessUtf16();
  group('FileEncoding', () {
    test('plain UTF-8 round-trips byte for byte', () {
      final bytes = Uint8List.fromList(utf8.encode('# 标题\n正文\n'));
      final (text, encoding) = FileEncoding.decode(bytes);

      expect(encoding, FileEncoding.utf8Encoding);
      expect(text, '# 标题\n正文\n');
      expect(encoding.encode(text), bytes);
    });

    test('a UTF-8 byte order mark is remembered and written back', () {
      // Dart's decoder swallows the mark, so without recording it a file
      // written by Notepad lost its BOM the first time it was saved.
      final bytes = Uint8List.fromList([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode('# 标题\n'),
      ]);
      final (text, encoding) = FileEncoding.decode(bytes);

      expect(encoding, FileEncoding.utf8Bom);
      expect(text, '# 标题\n', reason: 'the mark is not part of the text');
      expect(encoding.encode(text), bytes);
    });

    test('UTF-16 is decoded from its byte order mark, both ways round', () {
      for (final encoding in [FileEncoding.utf16le, FileEncoding.utf16be]) {
        final bytes = encoding.encode('# 标题\n');
        final (text, detected) = FileEncoding.decode(bytes);

        expect(detected, encoding);
        expect(text, '# 标题\n');
      }
    });

    test('a GBK document is read as GBK, not as Latin-1', () {
      // It used to open as Latin-1 — two wrong characters for every real one
      // — because Latin-1 at least re-encoded to the same bytes. Reading it
      // properly does that too, and shows what was written.
      // A real document rather than a fragment: below a dozen bytes there is
      // not enough evidence to prefer GBK, and Latin-1 — which writes back
      // byte for byte — is the safer answer.
      final bytes = Uint8List.fromList([
        0x23, 0x20, 0xB1, 0xEA, 0xCC, 0xE2, 0x0A, 0x0A, 0xD5, 0xE2, 0xCA,
        0xC7, 0xD2, 0xBB, 0xB6, 0xCE, 0xD6, 0xD0, 0xCE, 0xC4, 0xA1, 0xA3,
        0x0A,
      ]);
      final (text, encoding) = FileEncoding.decode(bytes);

      expect(encoding, FileEncoding.gbk);
      expect(text, '# 标题\n\n这是一段中文。\n');
      expect(encoding.encode(text), bytes);
    });

    test('bytes in no encoding it knows open as Latin-1 rather than throwing',
        () {
      // 0xFF opens no GBK sequence, so the shape test rejects it and the
      // last resort takes over. Refusing to open made the tab vanish without
      // a word; Latin-1 re-encodes to the same bytes, so nothing outside the
      // edit is corrupted.
      final bytes = Uint8List.fromList([0x23, 0x20, 0xFF, 0xFE, 0x41]);
      final (text, encoding) = FileEncoding.decode(bytes);

      expect(encoding, FileEncoding.latin1Encoding);
      expect(encoding.encode(text), bytes);
    });

    test('a Latin-1 file keeps its accents', () {
      final bytes = Uint8List.fromList(latin1.encode('# Café\n'));
      final (text, encoding) = FileEncoding.decode(bytes);

      expect(encoding, FileEncoding.latin1Encoding);
      expect(text, '# Café\n');
      expect(encoding.encode(text), bytes);
    });

    test(
      'a character outside Latin-1 falls back rather than losing the save',
      () {
        // Typing Chinese into a file opened as Latin-1: the bytes cannot be
        // written in that encoding, and throwing would lose the document.
        final written = FileEncoding.latin1Encoding.encode('中文');

        expect(written, isNotEmpty);
        expect(utf8.decode(written), '中文');
      },
    );

    test('an empty file is UTF-8', () {
      final (text, encoding) = FileEncoding.decode(Uint8List(0));

      expect(text, isEmpty);
      expect(encoding, FileEncoding.utf8Encoding);
    });
  });
}

/// UTF-16 written without a byte order mark.
///
/// Notepad writes the mark; plenty of tools do not. Without it such a file was
/// read as Latin-1, and every Chinese character came out as two pieces of
/// nonsense — the document opened, looked ruined, and saving it would have
/// made that permanent.
void _bomlessUtf16() {
  Uint8List utf16(String text, {required bool big}) {
    final out = BytesBuilder();
    for (final unit in text.codeUnits) {
      out.addByte(big ? unit >> 8 : unit & 0xFF);
      out.addByte(big ? unit & 0xFF : unit >> 8);
    }
    return out.toBytes();
  }

  const sample = '# 中文标题\n\n这是一段用 UTF-16 写的正文，含**加粗**。\n';

  group('a file with no mark is still read', () {
    test('little endian', () {
      final (text, encoding) = FileEncoding.decode(utf16(sample, big: false));
      expect(encoding, FileEncoding.utf16le);
      expect(text, sample);
    });

    test('big endian', () {
      final (text, encoding) = FileEncoding.decode(utf16(sample, big: true));
      expect(encoding, FileEncoding.utf16be);
      expect(text, sample);
    });

    test('a word whose lower half is zero does not throw it off', () {
      // `一` is U+4E00, so its low byte lands on the side that should be
      // empty. Requiring that side to be empty would miss any document with
      // the commonest word in the language in it.
      final (text, encoding) = FileEncoding.decode(
          utf16('# 第一章\n\n第一段落，写了一些话。\n\n- 一条\n- 两条\n', big: false));
      expect(encoding, FileEncoding.utf16le);
      expect(text, contains('第一段落'));
    });

    test('what this cannot tell, stated rather than hidden', () {
      // The signal is the zero byte an ASCII character brings, so a short run
      // of nothing but Chinese carries almost none. Real markdown always has
      // ASCII in it — the `#`, the brackets, the blank lines — which is why
      // the case above works and this one does not. Written down so the limit
      // is a decision rather than a surprise.
      final (_, encoding) =
          FileEncoding.decode(utf16('第一段。\n第二段。\n', big: false));
      expect(encoding, isNot(FileEncoding.utf16le));
    });
  });

  group('what is not UTF-16', () {
    test('UTF-8 Chinese', () {
      final (_, encoding) =
          FileEncoding.decode(Uint8List.fromList(utf8.encode(sample)));
      expect(encoding, FileEncoding.utf8Encoding);
    });

    test('ASCII', () {
      final (_, encoding) = FileEncoding.decode(
          Uint8List.fromList(utf8.encode('# Title\n\nplain text here\n')));
      expect(encoding, FileEncoding.utf8Encoding);
    });

    test('a file too short to tell', () {
      final (_, encoding) =
          FileEncoding.decode(Uint8List.fromList([0x23, 0x20, 0x41]));
      expect(encoding, isNot(FileEncoding.utf16le));
    });

    test('an odd number of bytes is not UTF-16', () {
      final bytes = utf16(sample, big: false).toList()..add(0x41);
      final (_, encoding) = FileEncoding.decode(Uint8List.fromList(bytes));
      expect(encoding, isNot(FileEncoding.utf16le));
    });
  });
}

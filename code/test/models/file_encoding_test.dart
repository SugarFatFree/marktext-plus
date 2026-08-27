import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/models/file_encoding.dart';

void main() {
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

    test('bytes that are not UTF-8 open as Latin-1 rather than throwing', () {
      // A GBK document. Refusing to open it made the tab vanish without a
      // word; Latin-1 shows it wrongly but re-encodes to the same bytes, so
      // nothing outside the edit is corrupted.
      final gbk = Uint8List.fromList([0x23, 0x20, 0xB1, 0xEA, 0xCC, 0xE2]);
      final (text, encoding) = FileEncoding.decode(gbk);

      expect(encoding, FileEncoding.latin1Encoding);
      expect(encoding.encode(text), gbk);
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

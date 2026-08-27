import 'dart:convert';
import 'dart:typed_data';

/// The byte encoding a document uses on disk.
///
/// The editor holds text as Dart strings regardless; this records what to
/// write back. Without it, opening anything that is not UTF-8 threw and the
/// tab vanished without a word — and saving would have rewritten the file as
/// UTF-8, which corrupts a legacy document rather than editing it.
enum FileEncoding {
  /// The default, and what a new document is written in.
  utf8Encoding('UTF-8'),

  /// UTF-8 with a byte order mark, which is what several Windows tools write.
  ///
  /// Dart's decoder swallows the mark, so without recording it here a file
  /// saved from Notepad lost its BOM the first time it was written back.
  utf8Bom('UTF-8 BOM'),

  /// UTF-16, little-endian, which is what Windows tools call "Unicode".
  utf16le('UTF-16 LE'),

  /// UTF-16, big-endian.
  utf16be('UTF-16 BE'),

  /// One byte per character, used as the last resort.
  ///
  /// Anything decodes as Latin-1 and re-encodes to exactly the same bytes, so
  /// a file in an encoding this app cannot read — GBK, Shift-JIS — opens
  /// looking wrong but is written back byte for byte wherever it was not
  /// edited. Refusing to open it, or converting it to UTF-8, are both worse.
  latin1Encoding('Latin-1');

  const FileEncoding(this.label);

  /// What the status bar shows.
  final String label;

  /// Reads [bytes] as text, and says which encoding was used.
  ///
  /// UTF-8 first, since that is what almost every document is. A UTF-16 byte
  /// order mark is unambiguous and checked before falling back.
  static (String, FileEncoding) decode(Uint8List bytes) {
    if (_hasUtf16Bom(bytes, big: false)) {
      return (_decodeUtf16(bytes.sublist(2), big: false), FileEncoding.utf16le);
    }
    if (_hasUtf16Bom(bytes, big: true)) {
      return (_decodeUtf16(bytes.sublist(2), big: true), FileEncoding.utf16be);
    }

    final hasUtf8Bom =
        bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF;

    try {
      // The decoder drops the mark itself, so the text is the same either way.
      return (
        utf8.decode(bytes),
        hasUtf8Bom ? FileEncoding.utf8Bom : FileEncoding.utf8Encoding,
      );
    } on FormatException {
      return (latin1.decode(bytes), FileEncoding.latin1Encoding);
    }
  }

  /// Turns [content] back into bytes in this encoding.
  Uint8List encode(String content) {
    switch (this) {
      case FileEncoding.utf8Encoding:
        return Uint8List.fromList(utf8.encode(content));
      case FileEncoding.utf8Bom:
        return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(content)]);
      case FileEncoding.latin1Encoding:
        // A character outside Latin-1 cannot be written; those bytes were
        // never Latin-1 to begin with, so fall back rather than throw and
        // lose the save.
        try {
          return Uint8List.fromList(latin1.encode(content));
        } on ArgumentError {
          return Uint8List.fromList(utf8.encode(content));
        }
      case FileEncoding.utf16le:
        return _encodeUtf16(content, big: false);
      case FileEncoding.utf16be:
        return _encodeUtf16(content, big: true);
    }
  }

  static bool _hasUtf16Bom(Uint8List bytes, {required bool big}) {
    if (bytes.length < 2) return false;
    return big
        ? bytes[0] == 0xFE && bytes[1] == 0xFF
        : bytes[0] == 0xFF && bytes[1] == 0xFE;
  }

  static String _decodeUtf16(Uint8List bytes, {required bool big}) {
    final units = <int>[];
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      units.add(
        big ? (bytes[i] << 8) | bytes[i + 1] : (bytes[i + 1] << 8) | bytes[i],
      );
    }
    return String.fromCharCodes(units);
  }

  static Uint8List _encodeUtf16(String content, {required bool big}) {
    final units = content.codeUnits;
    // Two bytes per code unit, after the byte order mark this writes back.
    final out = Uint8List(2 + units.length * 2);
    out[0] = big ? 0xFE : 0xFF;
    out[1] = big ? 0xFF : 0xFE;
    for (var i = 0; i < units.length; i++) {
      final unit = units[i];
      out[2 + i * 2] = big ? unit >> 8 : unit & 0xFF;
      out[3 + i * 2] = big ? unit & 0xFF : unit >> 8;
    }
    return out;
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:charset/charset.dart' as charset;

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

  /// UTF-16, little-endian, with a byte order mark — what Windows tools call
  /// "Unicode".
  utf16le('UTF-16 LE BOM'),

  /// UTF-16, big-endian, with a byte order mark.
  utf16be('UTF-16 BE BOM'),

  /// The same two without the mark, kept apart so a file that arrived without
  /// one does not gain one by being saved.
  ///
  /// Plenty of tools write UTF-16 with no mark. Reading it is a guess from
  /// where the zero bytes fall; writing it back is not a guess, and a file
  /// that grew two bytes it never had would show up as a change in every
  /// tool that compares files.
  utf16leNoBom('UTF-16 LE'),

  /// Big-endian, no mark.
  utf16beNoBom('UTF-16 BE'),

  /// The encoding most Chinese documents were written in before UTF-8.
  ///
  /// Read as Latin-1 it comes out as two wrong characters per real one, which
  /// is what every legacy note looked like. Told apart from Latin-1 by the
  /// share of high bytes: Chinese is almost all double-byte, while French or
  /// German is ordinary ASCII with the occasional accent.
  gbk('GBK'),

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

    // UTF-16 with no byte order mark. Notepad writes one, plenty of tools do
    // not, and without it such a file was read as Latin-1 — every Chinese
    // character came out as two pieces of nonsense.
    //
    // A text file never contains a zero byte, and UTF-16 is full of them:
    // every ASCII character brings one, always on the same side of its pair.
    // Markdown is never all Chinese — the `#`, the line breaks, the brackets
    // are all ASCII — so there is always something to see.
    final bomless = _looksLikeBomlessUtf16(bytes);
    if (bomless != null) {
      return (
        _decodeUtf16(bytes, big: !bomless),
        bomless ? FileEncoding.utf16leNoBom : FileEncoding.utf16beNoBom,
      );
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
      if (_looksLikeGbk(bytes)) {
        try {
          final text = charset.gbk.decode(bytes);
          // The decoder marks what it cannot read rather than refusing, and
          // the mark lands in the private use area — where nothing a document
          // is actually written in belongs. `Grüße` is the case that needs
          // this: 0xFC 0xDF has the shape of a pair without being one, and in
          // a word that short it is a third of the bytes, so the share test
          // lets it through.
          if (!_hasPrivateUse(text)) return (text, FileEncoding.gbk);
        } catch (_) {
          // The shape fitted but the bytes did not; Latin-1 still reads them.
        }
      }
      return (latin1.decode(bytes), FileEncoding.latin1Encoding);
    }
  }

  /// Reads [bytes] as [encoding], whatever the guess would have been.
  ///
  /// Detection is a guess — the share of double-byte pairs tells GBK from
  /// Latin-1 well but not perfectly — so the reader has to be able to say
  /// what a file really is. Malformed bytes are shown rather than thrown:
  /// picking the wrong encoding should look wrong, not close the document.
  static String decodeAs(Uint8List bytes, FileEncoding encoding) {
    switch (encoding) {
      case FileEncoding.utf8Encoding:
      case FileEncoding.utf8Bom:
        return utf8.decode(bytes, allowMalformed: true);
      // Both variants read a mark if one is there: the reader may be telling
      // this app what a file is, and being wrong about the mark should not
      // put two stray characters at the top of the document.
      case FileEncoding.utf16le:
      case FileEncoding.utf16leNoBom:
        return _decodeUtf16(
          _hasUtf16Bom(bytes, big: false) ? bytes.sublist(2) : bytes,
          big: false,
        );
      case FileEncoding.utf16be:
      case FileEncoding.utf16beNoBom:
        return _decodeUtf16(
          _hasUtf16Bom(bytes, big: true) ? bytes.sublist(2) : bytes,
          big: true,
        );
      case FileEncoding.gbk:
        try {
          return charset.gbk.decode(bytes);
        } catch (_) {
          return latin1.decode(bytes);
        }
      case FileEncoding.latin1Encoding:
        return latin1.decode(bytes);
    }
  }

  /// Whether [text] holds a character from the private use area.
  ///
  /// That is where the decoder puts bytes it could not read, and nothing a
  /// document is genuinely written in lives there.
  static bool _hasPrivateUse(String text) =>
      text.runes.any((rune) => rune >= 0xE000 && rune <= 0xF8FF);

  /// Whether [bytes] look like GBK rather than a single-byte encoding.
  ///
  /// Every byte at or above 0x80 has to open a valid two-byte sequence, and
  /// enough of the file has to be made of them. The first test alone is not
  /// enough: `é` followed by a letter is a valid-looking pair too, so French
  /// read this way would come out as Chinese. Chinese text is mostly
  /// double-byte, and accented European text is mostly ASCII, which is what
  /// the share measures.
  /// Whether [bytes] look like UTF-16 with no mark: true for little endian,
  /// false for big endian, null for anything else.
  ///
  /// Judged on where the zero bytes fall rather than how many: a byte-oriented
  /// text encoding has none at all, so a file with them heaped on one side of
  /// every pair is not one. A small share is asked for as well, so that a
  /// single stray zero in a damaged file does not decide it.
  ///
  /// The other side is allowed a few rather than none: a character whose lower
  /// half is zero — `一` is U+4E00 — puts one there, and a document with a
  /// common word in it would otherwise be missed.
  static bool? _looksLikeBomlessUtf16(Uint8List bytes) {
    if (bytes.length < 8 || bytes.length.isOdd) return null;

    // A few kilobytes is plenty to tell, and bounds the cost on a large file.
    final limit = bytes.length < 4096 ? bytes.length : 4096;
    var evenZeros = 0;
    var oddZeros = 0;
    for (var i = 0; i < limit; i++) {
      if (bytes[i] != 0) continue;
      if (i.isEven) {
        evenZeros++;
      } else {
        oddZeros++;
      }
    }

    final pairs = limit ~/ 2;
    final enough = pairs * 0.05;
    // Twice as many on one side as the other. In little endian the odd byte
    // of each pair is the upper half: zero for every ASCII character, never
    // zero for a Chinese one. The even byte is the lower half, zero only for
    // a character whose code point ends in `00` — `一` is U+4E00, and it is
    // common enough that demanding none of those missed ordinary documents.
    if (oddZeros >= enough && oddZeros > evenZeros * 2) return true;
    if (evenZeros >= enough && evenZeros > oddZeros * 2) return false;
    return null;
  }

  static bool _looksLikeGbk(Uint8List bytes) {
    // Too short to tell. `Öl` is three bytes, two of which are a valid GBK
    // sequence for a real character — no test can separate that from German
    // on the evidence available. Latin-1 is the safer answer because it
    // writes back byte for byte, and the status bar lets the reader say
    // otherwise.
    if (bytes.length < 12) return false;

    var paired = 0;
    var i = 0;
    while (i < bytes.length) {
      final lead = bytes[i];
      if (lead < 0x80) {
        i++;
        continue;
      }
      if (lead < 0x81 || lead > 0xFE || i + 1 >= bytes.length) return false;
      final trail = bytes[i + 1];
      if (trail < 0x40 || trail > 0xFE || trail == 0x7F) return false;
      paired += 2;
      i += 2;
    }
    return paired * 10 >= bytes.length * 3;
  }

  /// Turns [content] back into bytes in this encoding.
  Uint8List encode(String content) {
    switch (this) {
      case FileEncoding.utf8Encoding:
        return Uint8List.fromList(utf8.encode(content));
      case FileEncoding.utf8Bom:
        return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(content)]);
      case FileEncoding.gbk:
        try {
          return Uint8List.fromList(charset.gbk.encode(content));
        } catch (_) {
          // A character GBK cannot hold — an emoji, say, typed into an old
          // note. Writing UTF-8 keeps the character; refusing would lose the
          // save.
          return Uint8List.fromList(utf8.encode(content));
        }

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
        return _encodeUtf16(content, big: false, bom: true);
      case FileEncoding.utf16be:
        return _encodeUtf16(content, big: true, bom: true);
      case FileEncoding.utf16leNoBom:
        return _encodeUtf16(content, big: false, bom: false);
      case FileEncoding.utf16beNoBom:
        return _encodeUtf16(content, big: true, bom: false);
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

  static Uint8List _encodeUtf16(
    String content, {
    required bool big,
    required bool bom,
  }) {
    final units = content.codeUnits;
    // A mark only when the file had one. Adding one to a file that arrived
    // without it would change two bytes nobody asked to change.
    final start = bom ? 2 : 0;
    final out = Uint8List(start + units.length * 2);
    if (bom) {
      out[0] = big ? 0xFE : 0xFF;
      out[1] = big ? 0xFF : 0xFE;
    }
    for (var i = 0; i < units.length; i++) {
      final unit = units[i];
      out[start + i * 2] = big ? unit >> 8 : unit & 0xFF;
      out[start + i * 2 + 1] = big ? unit & 0xFF : unit >> 8;
    }
    return out;
  }
}

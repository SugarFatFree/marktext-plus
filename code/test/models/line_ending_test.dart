import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/models/line_ending.dart';

void main() {
  group('LineEnding.detect', () {
    test('recognises CRLF and LF', () {
      expect(LineEnding.detect('a\r\nb'), LineEnding.crlf);
      expect(LineEnding.detect('a\nb'), LineEnding.lf);
    });

    test('a file with no line break is LF', () {
      expect(LineEnding.detect('abc'), LineEnding.lf);
      expect(LineEnding.detect(''), LineEnding.lf);
    });

    test('one CRLF anywhere makes the file CRLF', () {
      expect(LineEnding.detect('a\nb\r\nc'), LineEnding.crlf);
    });
  });

  group('LineEnding.apply', () {
    test('LF leaves the text alone', () {
      expect(LineEnding.lf.apply('a\nb\nc'), 'a\nb\nc');
    });

    test('CRLF expands every break exactly once', () {
      expect(LineEnding.crlf.apply('a\nb'), 'a\r\nb');
      expect(LineEnding.crlf.apply('a\nb').contains('\r\r'), isFalse);
    });
  });

  test('a CRLF document survives a round trip byte for byte', () {
    // Normalising on read and saving LF rewrote every line of the file, so a
    // one-word edit showed up as a whole-file diff.
    const original = 'line1\r\nline2\r\nline3';
    final detected = LineEnding.detect(original);
    final normalised = original.replaceAll('\r\n', '\n');

    expect(detected.apply(normalised), original);
  });

  test('an LF document survives a round trip byte for byte', () {
    const original = 'line1\nline2\n';
    expect(LineEnding.detect(original).apply(original), original);
  });
}

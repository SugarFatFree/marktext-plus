import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/code_highlighting.dart';

/// Cutting highlighted code into lines, so a gutter of numbers can line up
/// with it.
///
/// A highlighter hands back runs that pay no attention to where the lines
/// are: one run can span several, and one line can be made of several runs.
/// Highlighting each line separately would line up too, and would lose every
/// construct that runs past the end of a line.
void main() {
  List<String> textOf(List<List<TextSpan>> lines) =>
      [for (final line in lines) line.map((s) => s.text).join()];

  group('splitByLine', () {
    test('a run that spans lines becomes one piece per line', () {
      final lines = CodeHighlighting.splitByLine([
        const TextSpan(text: 'one\ntwo\nthree'),
      ]);

      expect(textOf(lines), ['one', 'two', 'three']);
    });

    test('several runs on one line stay on it', () {
      final lines = CodeHighlighting.splitByLine([
        const TextSpan(text: 'var '),
        const TextSpan(text: 'x'),
        const TextSpan(text: ' = 1;'),
      ]);

      expect(textOf(lines), ['var x = 1;']);
    });

    test('each piece keeps the style its run had', () {
      const keyword = TextStyle(fontWeight: FontWeight.bold);
      final lines = CodeHighlighting.splitByLine([
        const TextSpan(text: 'if\nelse', style: keyword),
      ]);

      expect(lines.every((l) => l.single.style == keyword), isTrue,
          reason: '跨行的高亮在切开之后丢了样式');
    });

    test('a child without a style of its own inherits its parent\'s', () {
      const parent = TextStyle(color: Color(0xFF123456));
      final lines = CodeHighlighting.splitByLine([
        const TextSpan(style: parent, children: [TextSpan(text: 'a\nb')]),
      ]);

      expect(lines.map((l) => l.single.style).toList(), [parent, parent]);
    });

    test('an empty line is a line, not a gap', () {
      // Blank lines have numbers too; dropping them shifts every number after.
      final lines = CodeHighlighting.splitByLine([
        const TextSpan(text: 'a\n\nb'),
      ]);

      expect(textOf(lines), ['a', '', 'b']);
    });

    test('nothing at all is still one line', () {
      expect(CodeHighlighting.splitByLine(const []), hasLength(1));
    });

    test('the count matches what the source says', () {
      const source = 'one\ntwo\nthree\nfour';
      final lines = CodeHighlighting.splitByLine(
        [const TextSpan(text: source)],
      );

      expect(lines.length, source.split('\n').length);
    });
  });
}

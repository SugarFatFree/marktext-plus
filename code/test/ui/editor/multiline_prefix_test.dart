import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// Turning several lines into a list at once.
///
/// Reported as #3, which asked for Alt-drag column editing; the example given
/// was adding `- ` to three lines. Selecting the lines and asking for a list
/// is how every editor does that, and here it marked only the line the caret
/// happened to be on.
///
/// The per-line function is pure and already toggles; these pin its
/// behaviour, and the widget test below pins that the selection is what
/// decides the range.
void main() {
  group('one line at a time', () {
    test('a plain line gets the marker', () {
      expect(SourceEditor.applyLinePrefix('one', '- '), '- one');
    });

    test('a line that already has it loses it', () {
      expect(SourceEditor.applyLinePrefix('- one', '- '), 'one');
    });

    test('indentation is kept in front of the marker', () {
      expect(SourceEditor.applyLinePrefix('    one', '- '), '    - one');
      expect(SourceEditor.applyLinePrefix('    - one', '- '), '    one');
    });

    test('a different marker replaces the one that is there', () {
      // Not stacked: `1. - one` is not what asking for a numbered list means.
      expect(SourceEditor.applyLinePrefix('- one', '1. '), '1. one');
      expect(SourceEditor.applyLinePrefix('- [x] one', '- '), '- one',
          reason: '把任务框换成普通项，而不是留下 [x]');
    });

    test('a quote marker is its own family', () {
      expect(SourceEditor.applyLinePrefix('one', '> '), '> one');
      expect(SourceEditor.applyLinePrefix('> one', '> '), 'one');
      // A quote and a list are different families, so one does not remove the
      // other.
      expect(SourceEditor.applyLinePrefix('- one', '> '), '> - one');
    });
  });

  group('a block of lines', () {
    /// What the editor now does across a selection: all on, unless every line
    /// already has it, in which case all off.
    List<String> applyBlock(List<String> lines, String prefix) {
      final allMarked = lines.every((line) =>
          SourceEditor.applyLinePrefix(line, prefix).length < line.length);
      return [
        for (final line in lines)
          allMarked ||
                  SourceEditor.applyLinePrefix(line, prefix).length >
                      line.length
              ? SourceEditor.applyLinePrefix(line, prefix)
              : line,
      ];
    }

    test('every line in the block gets the marker', () {
      expect(applyBlock(['1111', '2222', '3333'], '- '),
          ['- 1111', '- 2222', '- 3333']);
    });

    test('a fully marked block is unmarked', () {
      expect(applyBlock(['- 1111', '- 2222'], '- '), ['1111', '2222']);
    });

    test('a half marked block is finished, not inverted', () {
      // Deciding line by line would turn this into `1111` / `- 2222` — the
      // same block, still not uniform, and pressing again would swap them
      // back forever.
      expect(applyBlock(['- 1111', '2222'], '- '), ['- 1111', '- 2222']);
    });

    test('blank lines inside the block are left alone as blanks', () {
      expect(applyBlock(['1111', '', '3333'], '- '),
          ['- 1111', '- ', '- 3333']);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// Toggling one emphasis inside another must not take the other one away.
///
/// `SourceEditor.toggleWrap` already says this in a comment — "applying italic
/// to bold text should nest, giving `***bold***`" — and guards it on the branch
/// that unwraps markers found *inside* the selection. The branch that unwraps
/// markers found just *outside* it, which is what happens when the reader
/// selects the words rather than the syntax, had no such guard: it saw one `*`
/// on each side of `bold` and took it, leaving `*bold*`. The bold was gone and
/// nothing said so.
///
/// Which syntax a run of markers carries depends on how long the run is, so
/// that is what decides it: `*` is emphasis when the run is odd (two is
/// strong, three is strong around emphasis), `**` is strong once the run
/// reaches two. The rule lives in one place and both branches ask it.
void main() {
  ({String text, int start, int end}) toggle(
    String text,
    int start,
    int end,
    FormatAction action,
  ) {
    final (before, after) = SourceEditor.wrapMarkers[action]!;
    return SourceEditor.toggleWrap(text, start, end, before, after);
  }

  group('markers just outside the selection', () {
    test('italic on the words inside bold nests instead of undoing it', () {
      final result = toggle('**bold**', 2, 6, FormatAction.italic);
      expect(result.text, '***bold***');
    });

    test('subscript on the words inside strikethrough replaces it', () {
      final result = toggle('~~struck~~', 2, 8, FormatAction.subscript);
      expect(result.text, '~struck~');
    });

    test('bold on the words inside bold still turns it off', () {
      final result = toggle('**bold**', 2, 6, FormatAction.bold);
      expect(result.text, 'bold');
    });

    test('italic on the words inside bold-italic turns the italic off', () {
      final result = toggle('***both***', 3, 7, FormatAction.italic);
      expect(result.text, '**both**');
    });

    test('italic on the words inside italic still turns it off', () {
      final result = toggle('*it*', 1, 3, FormatAction.italic);
      expect(result.text, 'it');
    });

    test('bold on the words inside bold-italic leaves the italic', () {
      final result = toggle('***both***', 3, 7, FormatAction.bold);
      expect(result.text, '*both*');
    });
  });

  group('markers inside the selection', () {
    test('italic over a whole bold span nests', () {
      final result = toggle('**bold**', 0, 8, FormatAction.italic);
      expect(result.text, '***bold***');
    });

    test('italic over a whole bold-italic span turns the italic off', () {
      final result = toggle('***both***', 0, 10, FormatAction.italic);
      expect(result.text, '**both**');
    });

    test('bold over a whole bold span turns it off', () {
      final result = toggle('**bold**', 0, 8, FormatAction.bold);
      expect(result.text, 'bold');
    });
  });

  /// Markers whose length means nothing keep the behaviour they had: only `*`
  /// and `~` appear at two lengths in [SourceEditor.wrapMarkers], so only they
  /// are counted. A code span is not emphasis and does not nest.
  group('markers whose run length decides nothing', () {
    test('inline code on the words inside a code span turns it off', () {
      final result = toggle('`code`', 1, 5, FormatAction.inlineCode);
      expect(result.text, 'code');
    });

    test('highlight on the words inside a highlight turns it off', () {
      final result = toggle('==mark==', 2, 6, FormatAction.highlight);
      expect(result.text, 'mark');
    });

    // These two pin the gate itself. A doubled backtick is one code span and a
    // doubled `$` is display maths, not two nested inline ones, so counting
    // the run and asking about parity would answer "not there, add another" and
    // hand the reader ```` ```code``` ````. Backticks and `$` appear at one
    // length in [SourceEditor.wrapMarkers], so the run is not counted and the
    // markers found are taken as the ones the action owns.
    test('inline code inside a doubled code span takes markers away', () {
      final result = toggle('``code``', 2, 6, FormatAction.inlineCode);
      expect(result.text, '`code`');
    });

    test('inline maths inside display maths takes markers away', () {
      final result = toggle(r'$$x$$', 2, 3, FormatAction.inlineMath);
      expect(result.text, r'$x$');
    });
  });

  /// A selection covering more than one block is marked block by block, by a
  /// second reading of "are the markers already there" that had no guard at
  /// all — not even the crude one. Two bold paragraphs selected together and
  /// given italic lost the bold in both at once.
  group('a selection covering more than one block', () {
    const bold = '**first**\n\n**second**';

    test('italic over two bold paragraphs nests in both', () {
      final result = toggle(bold, 0, bold.length, FormatAction.italic);
      expect(result.text, '***first***\n\n***second***');
    });

    test('bold over two bold paragraphs still turns both off', () {
      final result = toggle(bold, 0, bold.length, FormatAction.bold);
      expect(result.text, 'first\n\nsecond');
    });

    test('italic over two bold-italic paragraphs turns the italic off', () {
      const both = '***x***\n\n***y***';
      final result = toggle(both, 0, both.length, FormatAction.italic);
      expect(result.text, '**x**\n\n**y**');
    });

    test('a marker of another character wraps both without reading the run', () {
      final result = toggle(bold, 0, bold.length, FormatAction.subscript);
      expect(result.text, '~**first**~\n\n~**second**~');
    });
  });

  /// A tilde run is never lengthened, because `~~~` at the start of a line is
  /// a code fence rather than a longer emphasis. Subscript inside strikethrough
  /// cannot be written in this flavour at all, so the marker pressed replaces
  /// the run it finds: the reader gets what they asked for and the paragraph
  /// stays a paragraph.
  group('tilde runs', () {
    String rendered(String source) => MarkdownParser()
        .parse(source)
        .map(ExportService.nodeToHtml)
        .join();

    test('strikethrough on a subscripted word replaces the subscript', () {
      final result = toggle('~sub~', 1, 4, FormatAction.strikethrough);
      expect(result.text, '~~sub~~');
    });

    test('strikethrough over a whole subscript replaces it', () {
      final result = toggle('~sub~', 0, 5, FormatAction.strikethrough);
      expect(result.text, '~~sub~~');
    });

    test('subscript over a whole strikethrough replaces it', () {
      final result = toggle('~~struck~~', 0, 10, FormatAction.subscript);
      expect(result.text, '~struck~');
    });

    /// The reason the three tests above are worth having: what the editor
    /// writes, the editor has to be able to read. `~~~struck~~~` parses as a
    /// fenced code block whose info string is `struck~~~`, and the paragraph —
    /// with everything after it — disappears inside it.
    test('nothing these presses write turns the paragraph into a fence', () {
      const documents = ['~sub~', '~~struck~~'];
      const presses = [
        FormatAction.subscript,
        FormatAction.strikethrough,
      ];
      for (final document in documents) {
        for (final press in presses) {
          for (final range in [(0, document.length), (1, document.length - 1)]) {
            final result = toggle(document, range.$1, range.$2, press);
            expect(
              rendered('${result.text}\n\nafter'),
              isNot(contains('<pre><code')),
              reason: '$press on "$document" at $range wrote '
                  '"${result.text}", which opened a code block',
            );
          }
        }
      }
    });

    test('a fence is what three tildes would have been', () {
      expect(rendered('~~~struck~~~\n\nafter'), contains('<pre><code'));
    });
  });

  /// The set of characters this rule has to have an answer for, reconciled
  /// against the table it is read from. `SourceEditor` keeps a private list of
  /// which characters' runs compose; a marker added at a second length of a
  /// character nobody has thought about would be answered by whatever that list
  /// happens to say, so this fails until someone has looked.
  test('every character used at two lengths has been decided about', () {
    final lengths = <String, Set<int>>{};
    for (final pair in SourceEditor.wrapMarkers.values) {
      final marker = pair.$1;
      if (marker.isEmpty) continue;
      final char = marker[0];
      if (!marker.split('').every((unit) => unit == char)) continue;
      lengths.putIfAbsent(char, () => <int>{}).add(marker.length);
    }
    final shared = lengths.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) => entry.key)
        .toSet();
    expect(
      shared,
      {'*', '~'},
      reason: 'a marker now shares a character with another at a different '
          'length. Decide whether its runs compose, the way `*` does because '
          '`***bold***` is strong around emphasis, or replace each other, the '
          'way `~` does because `~~~` opens a code fence — then say so in '
          "SourceEditor's _composingRuns and add the cases here.",
    );
  });

  /// Pressing the same key twice returns the document to what it was. This is
  /// the invariant the two defects above broke: the first press moved to a
  /// document the second press read differently.
  test('every marker round-trips on a plain word', () {
    for (final entry in SourceEditor.wrapMarkers.entries) {
      final (before, after) = entry.value;
      final once = SourceEditor.toggleWrap('a word b', 2, 6, before, after);
      final twice = SourceEditor.toggleWrap(
        once.text,
        once.start,
        once.end,
        before,
        after,
      );
      expect(twice.text, 'a word b', reason: entry.key.name);
    }
  });
}

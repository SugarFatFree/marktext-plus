import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

void main() {
  group('toggleWrap', () {
    test('wraps a plain selection', () {
      final r = SourceEditor.toggleWrap('bold', 0, 4, '**', '**');
      expect(r.text, '**bold**');
      expect(r.text.substring(r.start, r.end), 'bold');
    });

    test('unwraps when the selection includes the markers', () {
      // The bug this guards: wrapping used to be unconditional, so this
      // produced `****bold****`.
      final r = SourceEditor.toggleWrap('**bold**', 0, 8, '**', '**');
      expect(r.text, 'bold');
    });

    test('unwraps when the markers sit just outside the selection', () {
      // What happens when the user selects the words, not the syntax.
      final r = SourceEditor.toggleWrap('**bold**', 2, 6, '**', '**');
      expect(r.text, 'bold');
      expect(r.text.substring(r.start, r.end), 'bold');
    });

    test('nests italic inside bold rather than stripping a marker', () {
      // `**bold**` starts and ends with `*`, so a naive check would read it
      // as an italic wrapper and strip one layer.
      final r = SourceEditor.toggleWrap('**bold**', 0, 8, '*', '*');
      expect(r.text, '***bold***');
    });

    test('handles the other inline markers', () {
      expect(SourceEditor.toggleWrap('s', 0, 1, '~~', '~~').text, '~~s~~');
      expect(SourceEditor.toggleWrap('~~s~~', 0, 5, '~~', '~~').text, 's');
      expect(SourceEditor.toggleWrap('code', 0, 4, '`', '`').text, '`code`');
      expect(SourceEditor.toggleWrap('`code`', 0, 6, '`', '`').text, 'code');
    });

    test('toggles off in the middle of a line', () {
      final r = SourceEditor.toggleWrap('a **b** c', 2, 7, '**', '**');
      expect(r.text, 'a b c');
    });

    test('inserts an empty pair at a collapsed cursor', () {
      final r = SourceEditor.toggleWrap('ab', 1, 1, '**', '**');
      expect(r.text, 'a****b');
      expect(r.start, 3, reason: 'cursor should land between the markers');
    });
  });

  group('applyLinePrefix', () {
    test('adds a marker to a plain line', () {
      expect(SourceEditor.applyLinePrefix('item', '- '), '- item');
      expect(SourceEditor.applyLinePrefix('quote', '> '), '> quote');
    });

    test('toggles the same marker back off', () {
      expect(SourceEditor.applyLinePrefix('- item', '- '), 'item');
      expect(SourceEditor.applyLinePrefix('> quote', '> '), 'quote');
      expect(SourceEditor.applyLinePrefix('- [ ] item', '- [ ] '), 'item');
    });

    test('replaces a marker of the same family rather than stacking', () {
      // The bug this guards: prefixes used to be prepended unconditionally,
      // so this produced `- 1. item`.
      expect(SourceEditor.applyLinePrefix('1. item', '- '), '- item');
      expect(SourceEditor.applyLinePrefix('- item', '1. '), '1. item');
      expect(SourceEditor.applyLinePrefix('* star', '- '), '- star');
      expect(SourceEditor.applyLinePrefix('2) paren', '- '), '- paren');
    });

    test('drops the task box when a task becomes a plain bullet', () {
      // `- [x] item` starts with `- `, so a naive startsWith check would
      // toggle only that off and leave `[x] item`.
      expect(SourceEditor.applyLinePrefix('- [x] item', '- '), '- item');
      expect(SourceEditor.applyLinePrefix('- [x] item', '- [ ] '), '- [ ] item');
    });

    test('keeps indentation, which carries list nesting', () {
      expect(SourceEditor.applyLinePrefix('    item', '- '), '    - item');
      expect(SourceEditor.applyLinePrefix('    - nested', '- '), '    nested');
    });

    test('treats quotes and lists as separate families', () {
      expect(SourceEditor.applyLinePrefix('- item', '> '), '> - item');
    });
  });
}

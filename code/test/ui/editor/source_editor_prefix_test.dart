import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

void main() {
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

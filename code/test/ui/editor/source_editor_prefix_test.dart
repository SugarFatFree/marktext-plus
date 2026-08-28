import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
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

  group('toggleLooseList', () {
    String toggle(String source, int line) =>
        SourceEditor.toggleLooseList(source, line);

    test('a tight list gains a blank line between its items', () {
      expect(toggle('- a\n- b\n- c\n', 0), '- a\n\n- b\n\n- c\n');
    });

    test('a loose list loses them again', () {
      expect(toggle('- a\n\n- b\n\n- c\n', 0), '- a\n- b\n- c\n');
    });

    test('toggling twice returns the document unchanged', () {
      const cases = <(String, int)>[
        ('- a\n- b\n', 0),
        ('1. a\n2. b\n', 0),
        ('- a\n  - a1\n- b\n', 0),
        ('- a\n  a continuation\n- b\n', 0),
        ('- [ ] a\n- [x] b\n', 0),
        ('before\n\n- a\n- b\n\nafter\n', 2),
        ('- a\n\n- b\n', 0),
      ];
      for (final (source, line) in cases) {
        expect(toggle(toggle(source, line), line), source, reason: source);
      }
    });

    test('a nested item is not spaced out with the outer ones', () {
      // It belongs to the item above it, not to the list's top level.
      expect(toggle('- a\n  - a1\n- b\n', 0), '- a\n  - a1\n\n- b\n');
    });

    test('a caret outside any list changes nothing', () {
      const source = 'text\n\n- a\n- b\n';
      expect(toggle(source, 0), source);
    });

    test('a one-item list has nothing to space out', () {
      const source = '- only\n';
      expect(toggle(source, 0), source);
    });

    test('the list still parses as one list with the same items', () {
      final loose = toggle('- a\n- b\n- c\n', 0);
      final list = MarkdownParser().parse(loose).single as ListNode;
      expect(list.isLoose, isTrue);
      expect(list.items, hasLength(3));
    });

    test('a document without a trailing newline keeps not having one', () {
      expect(toggle('- a\n- b', 0), '- a\n\n- b');
    });
  });

  group('createParagraphBelow', () {
    test('opens a blank line below the block, with the caret on it', () {
      final (text, line) = SourceEditor.createParagraphBelow('# Title\n', 0);
      expect(text, '# Title\n\n\n');
      expect(line, 2);
    });

    test('keeps a blank line either side when content follows', () {
      // Otherwise what gets typed runs into the block below.
      final (text, line) =
          SourceEditor.createParagraphBelow('# Title\n\nbody\n', 0);
      expect(text, '# Title\n\n\n\nbody\n');
      expect(line, 2);
    });

    test('anchors on the outermost block', () {
      // A caret inside a blockquote gets a paragraph after the whole quote,
      // not a line inside it — which is what upstream does.
      final (text, _) =
          SourceEditor.createParagraphBelow('> quoted\n\nafter\n', 0);
      expect(text, '> quoted\n\n\n\nafter\n');
    });

    test('a caret already on a blank line changes nothing', () {
      const source = 'a\n\nb\n';
      expect(SourceEditor.createParagraphBelow(source, 1), (source, 1));
    });
  });

  group('deleteParagraphAt', () {
    test('removes the block and the blank line after it', () {
      final (text, line) =
          SourceEditor.deleteParagraphAt('# Title\n\nbody\n', 0);
      expect(text, 'body\n');
      expect(line, 0);
    });

    test('removes the blank line before it when the block is last', () {
      final (text, _) =
          SourceEditor.deleteParagraphAt('# Title\n\nbody\n', 2);
      expect(text, '# Title\n');
    });

    test('deleting the only block leaves an empty document', () {
      expect(SourceEditor.deleteParagraphAt('only\n', 0), ('', 0));
    });

    test('a multi-line block goes as a whole', () {
      final (text, _) =
          SourceEditor.deleteParagraphAt('> q1\n> q2\n\nafter\n', 1);
      expect(text, 'after\n');
    });

    test('a caret on a blank line changes nothing', () {
      const source = 'a\n\nb\n';
      expect(SourceEditor.deleteParagraphAt(source, 1), (source, 1));
    });
  });

  group('SourceEditor.listPrefixFor', () {
    // The bullet the reader chose, for every kind of bullet. A task list
    // wrote a dash whatever the setting said, so choosing `*` gave one list
    // written with stars and the next with dashes in the same document.
    test('a bullet list uses the chosen marker', () {
      for (final marker in ['-', '*', '+']) {
        expect(
          SourceEditor.listPrefixFor(FormatAction.unorderedList, marker),
          '$marker ',
        );
      }
    });

    test('a task list uses it too', () {
      expect(SourceEditor.listPrefixFor(FormatAction.taskList, '*'), '* [ ] ');
      expect(SourceEditor.listPrefixFor(FormatAction.taskList, '-'), '- [ ] ');
    });

    test('a numbered list is numbered, whatever the bullet is', () {
      expect(
        SourceEditor.listPrefixFor(FormatAction.orderedList, '*'),
        '1. ',
      );
    });

    test('the two bullet kinds agree with each other', () {
      // A document that mixes markers reads as two lists to some parsers.
      for (final marker in ['-', '*', '+']) {
        final bullet =
            SourceEditor.listPrefixFor(FormatAction.unorderedList, marker);
        final task = SourceEditor.listPrefixFor(FormatAction.taskList, marker);
        expect(task.startsWith(bullet), isTrue,
            reason: '$marker：任务列表与普通列表用了不同的标记');
      }
    });
  });

}

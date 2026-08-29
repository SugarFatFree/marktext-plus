import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/block_move_service.dart';

/// Reordering blocks from the source.
///
/// Upstream MarkText does this by dragging one paragraph over another; its
/// `drag/paragraph-reorder` spec asks only that the two end up swapped in the
/// markdown. Here it is a command on the block under the caret.
void main() {
  int offsetOf(String text, int line, [int column = 0]) {
    var offset = 0;
    final lines = text.split('\n');
    for (var i = 0; i < line; i++) {
      offset += lines[i].length + 1;
    }
    return offset + column;
  }

  String? up(String text, int line, [int column = 0]) {
    final o = offsetOf(text, line, column);
    return BlockMoveService.move(text, o, o, up: true)?.text;
  }

  String? down(String text, int line, [int column = 0]) {
    final o = offsetOf(text, line, column);
    return BlockMoveService.move(text, o, o, up: false)?.text;
  }

  group('two paragraphs swap, which is what upstream reorders', () {
    const doc = 'PARA-A\n\nPARA-B\n';

    test('moving the first one down puts it after the second', () {
      final out = down(doc, 0)!;
      expect(out.indexOf('PARA-B'), lessThan(out.indexOf('PARA-A')));
    });

    test('moving the second one up puts it before the first', () {
      final out = up(doc, 2)!;
      expect(out.indexOf('PARA-B'), lessThan(out.indexOf('PARA-A')));
    });

    test('and moving it back returns the document it started as', () {
      expect(up(down(doc, 0)!, 2), doc);
    });
  });

  group('a block moves whole', () {
    test('a fenced code block keeps its blank line', () {
      // The blank line inside the fence looks exactly like a block boundary.
      // Moving by lines would leave the fence behind and break the document.
      const doc = 'first\n'
          '\n'
          '```dart\n'
          'a();\n'
          '\n'
          'b();\n'
          '```\n';
      expect(
        up(doc, 3),
        '```dart\n'
        'a();\n'
        '\n'
        'b();\n'
        '```\n'
        '\n'
        'first\n',
      );
    });

    test('a table moves whole', () {
      const doc = 'text\n'
          '\n'
          '| A | B |\n'
          '| --- | --- |\n'
          '| 1 | 2 |\n';
      final out = up(doc, 3)!;
      expect(out.startsWith('| A | B |\n| --- | --- |\n| 1 | 2 |\n'), isTrue,
          reason: '表格被拆开了：$out');
    });

    test('a multi-line paragraph moves whole', () {
      const doc = 'one\ntwo\n\nafter\n';
      expect(down(doc, 0), 'after\n\none\ntwo\n');
    });
  });

  group('a selection moves exactly the lines it touches', () {
    test('two of three lines move together', () {
      const doc = 'a\nb\nc\nd\n';
      final result = BlockMoveService.move(
        doc,
        offsetOf(doc, 1),
        offsetOf(doc, 2, 1),
        up: false,
      );
      expect(result?.text, 'a\nd\nb\nc\n');
    });

    test('the selection still covers the same text afterwards', () {
      const doc = 'a\nb\nc\nd\n';
      final result = BlockMoveService.move(
        doc,
        offsetOf(doc, 1),
        offsetOf(doc, 2, 1),
        up: false,
      )!;
      expect(
        result.text.substring(result.base, result.extent),
        'b\nc',
      );
    });
  });

  group('the edges of the document', () {
    test('the first block cannot go up', () {
      expect(up('a\n\nb\n', 0), isNull);
    });

    test('the last block cannot go down', () {
      expect(down('a\n\nb\n', 2), isNull);
    });

    test('a document with one block cannot move at all', () {
      expect(up('only\n', 0), isNull);
      expect(down('only\n', 0), isNull);
    });

    test('a document that does not end in a newline still works', () {
      expect(down('a\n\nb', 0), 'b\n\na');
    });
  });

  test('the caret follows the block it moved', () {
    const doc = 'PARA-A\n\nPARA-B\n';
    final result =
        BlockMoveService.move(doc, offsetOf(doc, 0), offsetOf(doc, 0),
            up: false)!;
    final line = result.text
        .substring(result.base, result.text.indexOf('\n', result.base));
    expect(line, 'PARA-A', reason: '光标没有跟着移动的块走');
  });
}

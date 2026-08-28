import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// What Enter carries to the next line inside a list.
///
/// Without it the writer types the marker again on every line, and numbers
/// the steps by hand. Upstream gives every block its own Enter handler; this
/// is the part of that a plain text editor needs.
void main() {
  ({String marker, bool isEmpty})? carry(String line) =>
      MarkdownParser.listContinuation(line);

  group('the marker carries on', () {
    test('a bullet repeats', () {
      expect(carry('- item')?.marker, '- ');
      expect(carry('* item')?.marker, '* ');
      expect(carry('+ item')?.marker, '+ ');
    });

    test('a number advances', () {
      expect(carry('1. step')?.marker, '2. ');
      expect(carry('9. step')?.marker, '10. ');
    });

    test('the delimiter the author chose is kept', () {
      expect(carry('1) step')?.marker, '2) ');
    });

    test('indentation and spacing are kept', () {
      expect(carry('   - item')?.marker, '   - ');
      expect(carry('-  wide gap')?.marker, '-  ');
      expect(carry('  2. step')?.marker, '  3. ');
    });

    test('a task carries an unticked box, never a ticked one', () {
      expect(carry('- [ ] todo')?.marker, '- [ ] ');
      expect(carry('- [x] done')?.marker, '- [ ] ');
      expect(carry('1. [X] done')?.marker, '2. [ ] ');
    });
  });

  group('an empty item ends the list instead', () {
    test('a bullet with nothing after it', () {
      expect(carry('- ')?.isEmpty, isTrue);
      expect(carry('   - ')?.isEmpty, isTrue);
    });

    test('a number with nothing after it', () {
      expect(carry('1. ')?.isEmpty, isTrue);
    });

    test('a task with nothing written in it', () {
      expect(carry('- [ ] ')?.isEmpty, isTrue);
      expect(carry('- [x] ')?.isEmpty, isTrue);
    });

    test('an item with text is not empty', () {
      expect(carry('- item')?.isEmpty, isFalse);
      expect(carry('- [ ] todo')?.isEmpty, isFalse);
    });
  });

  group('lines that are not list items', () {
    test('plain text', () => expect(carry('just words'), isNull));
    test('a heading', () => expect(carry('# Heading'), isNull));
    test('a rule, which looks like a bullet', () {
      // `---` and `***` open no list; carrying one on would put a marker
      // under every horizontal rule.
      expect(carry('---'), isNull);
      expect(carry('***'), isNull);
      // Spaced out, which this parser still reads as a list item — the list
      // branch is tried before the rule — but which no editor should put a
      // marker under.
      expect(carry('- - -'), isNull);
      expect(carry('* * *'), isNull);
      expect(carry('  _ _ _  '), isNull);
    });
    test('a quote', () => expect(carry('> quoted'), isNull));
    test('an empty line', () => expect(carry(''), isNull));
  });
}

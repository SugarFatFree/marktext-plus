import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// Showing the top of a large document while the rest is still being parsed.
///
/// Parsing costs about 0.02–0.04 ms per block with no hot spot to remove, so a
/// five megabyte document takes roughly three seconds during which the screen
/// is empty. A prefix parsed first puts the top up immediately.
///
/// The prefix has to be a *prefix*: its line numbers are then the same numbers
/// as in the whole document, so the blocks carry the right source ranges with
/// no arithmetic — and those ranges are what editing a block in the preview
/// depends on. These tests are mostly about that.
void main() {
  final parser = MarkdownParser();

  String doc(int paragraphs) => List.generate(
        paragraphs,
        (i) => '## Heading $i\n\nParagraph $i with **bold** and `code`.\n',
      ).join('\n');

  test('a short document is not split at all', () {
    expect(MarkdownParser.safePrefix(doc(10)), isNull,
        reason: '短文档整篇解析更快，切开只是徒增一次解析');
  });

  test('the prefix keeps the whole-document line numbering', () {
    final source = doc(1200);
    final prefix = MarkdownParser.safePrefix(source);
    expect(prefix, isNotNull);

    final fromPrefix = parser.parse(prefix!);
    final fromWhole = parser.parse(source);
    expect(fromPrefix.length, lessThan(fromWhole.length));

    for (var i = 0; i < fromPrefix.length; i++) {
      expect(fromPrefix[i].runtimeType, fromWhole[i].runtimeType,
          reason: '第 $i 块的类型和整篇解析不一致');
      expect(fromPrefix[i].sourceStart, fromWhole[i].sourceStart,
          reason: '第 $i 块的起始行和整篇解析不一致 —— 块编辑会改错行');
      expect(fromPrefix[i].sourceEnd, fromWhole[i].sourceEnd);
    }
  });

  /// A document whose fenced block straddles the cut.
  ///
  /// The block has to *contain* the first blank line the cut is allowed to
  /// take, which means it has to start just before line 1500 and run past it.
  /// Filling with 1490 paragraph-and-blank pairs — as this did — puts the
  /// fence at line 2980, a thousand lines past a cut that had already been
  /// taken among the filler: the fence was never in the prefix, so counting
  /// its markers there counted zero of them and passed no matter what.
  String straddling(String open, String inner, String close) {
    final source = StringBuffer();
    // No blank lines here: the cut may not be taken before line 1500 anyway,
    // and a blank one inside the filler would only make the test depend on
    // where exactly it fell.
    for (var i = 0; i < 1495; i++) {
      source.writeln('line $i');
    }
    source.writeln(open);
    source.writeln(inner);
    // Blank lines from here on, so the first one the cut may take is inside
    // the block. A reader of this fixture should be able to see that a cut
    // taken at all is a cut taken in the wrong place.
    for (var i = 0; i < 200; i++) {
      source.writeln('  var x$i = $i;');
      source.writeln();
    }
    source.writeln(inner);
    source.writeln(close);
    source.writeln();
    source.writeln('after');
    return source.toString();
  }

  test('the cut is never inside a fenced code block', () {
    final prefix = MarkdownParser.safePrefix(straddling('```dart', 'x', '```'));
    expect(prefix, isNotNull);
    expect(RegExp(r'^```', multiLine: true).allMatches(prefix!).length.isEven,
        isTrue,
        reason: '前缀里的代码围栏没有配对，说明切在了围栏中间');
  });

  test('a fence shown inside a longer fence does not end it', () {
    // A document explaining markdown puts ``` inside a ```` block — this
    // project's own README does. The cut compared only the fence character,
    // so the inner run ended the block here while the parser kept it open,
    // and the cut landed in the middle of the code it must never halve.
    final prefix =
        MarkdownParser.safePrefix(straddling('````markdown', '```', '````'));
    expect(prefix, isNotNull);
    expect(RegExp(r'^````', multiLine: true).allMatches(prefix!).length.isEven,
        isTrue,
        reason: '前缀里的外层围栏没有配对，说明切在了 ```` 块中间');
  });

  test('a tilde block is not closed by backticks', () {
    final prefix = MarkdownParser.safePrefix(straddling('~~~', '```', '~~~'));
    expect(prefix, isNotNull);
    expect(RegExp(r'^~~~', multiLine: true).allMatches(prefix!).length.isEven,
        isTrue,
        reason: '``` 不能闭合 ~~~，它们是不同的字符');
  });

  test('front matter is never cut in half', () {
    final source = StringBuffer()
      ..writeln('---')
      ..writeln('title: test')
      ..writeln('---')
      ..writeln();
    for (var i = 0; i < 1600; i++) {
      source.writeln('paragraph $i');
      source.writeln();
    }

    final prefix = MarkdownParser.safePrefix(source.toString())!;
    final nodes = parser.parse(prefix);
    expect(nodes.first, isA<FrontMatterNode>());
  });

  test('every fixture either stays whole or splits cleanly', () {
    final files = [
      File('test/fixtures/showcase.md'),
      ...Directory('../docs')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.md')),
    ];

    for (final file in files) {
      final source = file.readAsStringSync();
      final prefix = MarkdownParser.safePrefix(source);
      if (prefix == null) continue;

      final fromPrefix = parser.parse(prefix);
      final fromWhole = parser.parse(source);
      for (var i = 0; i < fromPrefix.length; i++) {
        expect(fromPrefix[i].sourceStart, fromWhole[i].sourceStart,
            reason: '${file.path} 第 $i 块的行号对不上');
      }
    }
  });
}

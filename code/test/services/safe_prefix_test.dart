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

  test('the cut is never inside a fenced code block', () {
    // A fence long enough to straddle the cut, so a naive split would land in
    // the middle of it and render half a code block.
    final source = StringBuffer();
    for (var i = 0; i < 1490; i++) {
      source.writeln('line $i');
      source.writeln();
    }
    source.writeln('```dart');
    for (var i = 0; i < 200; i++) {
      source.writeln('  var x$i = $i;');
      source.writeln();
    }
    source.writeln('```');
    source.writeln();
    source.writeln('after');

    final prefix = MarkdownParser.safePrefix(source.toString());
    expect(prefix, isNotNull);
    expect('```'.allMatches(prefix!).length.isEven, isTrue,
        reason: '前缀里的代码围栏没有配对，说明切在了围栏中间');
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

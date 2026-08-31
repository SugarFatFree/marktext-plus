import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// Blocks that reach further down the document than their first line.
///
/// A list item and a quotation both carry on when the next line simply
/// continues the sentence, so a block now covers lines that carry no marker of
/// their own. The preview takes a block's source out of the document by line
/// range and writes the edited version back over the same range — a range one
/// line short would drop the rest of the sentence, one line long would eat the
/// paragraph after it. Neither shows up in a parse test.
void main() {
  late MarkdownParser parser;
  setUp(() => parser = MarkdownParser());

  /// Takes every block out and puts it straight back; the document must not
  /// move.
  void survivesRoundTrip(String source) {
    var document = source;
    for (final node in parser.parse(source)) {
      final piece = MarkdownParser.sourceOfBlock(document, node);
      expect(source, contains(piece.trim()),
          reason: '取出的片段不在原文里：${piece.replaceAll('\n', '⏎')}');
      document = MarkdownParser.replaceBlock(document, node, piece);
    }
    expect(document, source);
  }

  test('a bullet continued on the next line', () {
    survivesRoundTrip('前言\n\n- 这是很长的一条，\n在源文件里换了行。\n- 第二条\n\n后记\n');
  });

  test('a quotation continued on the next line', () {
    survivesRoundTrip('前言\n\n> 引用第一行\n引用续行\n\n后记\n');
  });

  test('a quotation with a heading in it, continued', () {
    survivesRoundTrip('> # 标题\n> 正文\n续行\n\n后记\n');
  });

  test('a list with an empty item in the middle', () {
    survivesRoundTrip('- 甲\n-\n- 乙\n\n后记\n');
  });

  test('a code sample indented under a step', () {
    survivesRoundTrip('1. 步骤\n\n      代码一行\n\n后记\n');
  });

  test('a raw-text tag holding a blank line', () {
    survivesRoundTrip('<pre>\n第一行\n\n第二行\n</pre>\n\n后记\n');
  });
}

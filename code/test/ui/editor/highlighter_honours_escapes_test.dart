import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
import 'package:marktext_plus/ui/editor/syntax_highlighter.dart';

/// A backslash means the same thing in both panes.
///
/// This file's rules are copied from the parser on purpose, and its comments
/// say so at every turn: the `_` patterns exist because "the parser has always
/// read both", the maths rule is "the parser's own rule, so a line about money
/// stays a line about money", the bracket nesting matches "so the two agree".
///
/// Escapes were the gap. `\*not italic\*` was drawn in italics, `` \`not
/// code\` `` in the code colour, and `\$5` — which is how a person writes a
/// price so it is *not* a formula — was drawn as a formula, taking "5 和 \$"
/// with it. In every one of those the preview shows plain text.
void main() {
  const colors = HighlightColors(
    heading: Colors.red,
    bold: Colors.blue,
    code: Colors.green,
    link: Colors.purple,
    defaultColor: Colors.black,
    quote: Colors.grey,
    comment: Colors.brown,
  );

  /// Whether any run of [line] is drawn as something other than plain text.
  bool anythingStyled(String line) =>
      MarkdownSyntaxHighlighter.highlightLine(line, colors).any((span) {
        final style = span.style;
        return style?.fontWeight == FontWeight.bold ||
            style?.fontStyle == FontStyle.italic ||
            style?.decoration == TextDecoration.lineThrough ||
            (style?.color != null && style!.color != colors.defaultColor);
      });

  /// Whether the parser reads anything in [line] as markup.
  bool parserSeesMarkup(String line) {
    final html = MarkdownParser().parse(line).map(ExportService.nodeToHtml).join();
    return html.contains('<em>') ||
        html.contains('<strong>') ||
        html.contains('<code>') ||
        html.contains('class="math');
  }

  for (final line in <String>[
    r'\*不是斜体\*',
    r'\`不是代码\`',
    r'价格 \$5 和 \$10',
    r'\_也不是斜体\_',
    r'\~\~不是删除线\~\~',
  ]) {
    test('escaped markers are plain text in both panes: $line', () {
      expect(parserSeesMarkup(line), isFalse,
          reason: '前提：解析器确实把它当普通文字，否则测的是别的东西');
      expect(anythingStyled(line), isFalse,
          reason: '源码窗格染色了预览会画成普通文字的东西——'
              '两个窗格对同一行说了不同的话');
    });
  }

  test('an unescaped marker is still coloured', () {
    // The point is not to stop colouring, only to stop colouring what the
    // backslash took away.
    expect(anythingStyled('普通 *斜体* 普通'), isTrue);
    expect(anythingStyled('普通 `代码` 普通'), isTrue);
    expect(anythingStyled(r'公式 $E = mc^2$ 在这里'), isTrue);
  });

  test('a backslash before a backslash does not escape the marker', () {
    // The marker has to sit *directly* after the pair, or both readings agree
    // and the test proves nothing — which is what the first version did.
    // `C:\\*斜体*` is an escaped backslash and then live emphasis, and the
    // parser reads it that way.
    expect(parserSeesMarkup(r'C:\\*斜体*'), isTrue,
        reason: '前提：解析器认为这里有强调');
    expect(anythingStyled(r'C:\\*斜体*'), isTrue,
        reason: '数反斜杠不分奇偶，就会把这个真强调当成被转义的');
  });

  test('an escaped closer is enough too', () {
    // The mirror of the case below, and the one that proves the second half
    // of the check: the opening marker is live and the closing one is not.
    // The parser reads no emphasis, so neither should this pane.
    expect(parserSeesMarkup(r'*只有结尾转义\*'), isFalse,
        reason: '前提：解析器不认这是强调');
    expect(anythingStyled(r'*只有结尾转义\*'), isFalse);
  });

  test('an escaped opener is enough to refuse the whole run', () {
    // Only the opening marker is escaped here; the closing one is live. The
    // parser draws no emphasis, so neither should this pane — and checking
    // only the closing marker would let it through.
    expect(parserSeesMarkup(r'\*只有开头转义*'), isFalse,
        reason: '前提：解析器不认这是强调');
    expect(anythingStyled(r'\*只有开头转义*'), isFalse);
  });
}

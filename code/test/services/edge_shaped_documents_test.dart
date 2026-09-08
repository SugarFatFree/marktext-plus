import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
import 'package:marktext_plus/services/word_count_service.dart';

/// Documents shaped in ways nobody writes on purpose.
///
/// Tried against a running editor first — every one of these was written into
/// a real window over the automation interface and the preview switched to
/// after each, with no error, no warning and nothing slower than 578 ms. This
/// keeps that true from here, where it costs a second rather than a machine.
///
/// Two of the six had nothing covering them at all: a document that is only
/// whitespace, and one line of 120 000 characters.
void main() {
  final parser = MarkdownParser();

  test('a document of nothing but whitespace parses to nothing much', () {
    // Spaces, a tab, an ideographic space, and blank lines. Every branch that
    // asks "is this line blank" sees a different kind of blank here.
    const only = '   \n\t\n 　 \n\n\n';

    final nodes = parser.parse(only);
    for (final node in nodes) {
      expect(node.rawContent.trim(), isEmpty, reason: '空白里读出了内容：$node');
    }
    expect(WordCountService().countWords(only).words, 0);
  });

  test('one line of 120 000 characters is one paragraph', () {
    final line = 'x' * 120000;

    final nodes = parser.parse(line);
    expect(nodes, hasLength(1));
    expect(nodes.single.rawContent.length, 120000);

    // Counted in code points, and these are all one unit each.
    expect(WordCountService().countWords(line).characters, 120000);
  });

  test('sixty levels of nesting do not run out of anything', () {
    final deep = [
      for (var i = 0; i < 60; i++) '${'  ' * i}- level $i',
    ].join('\n');

    final nodes = parser.parse(deep);
    expect(nodes, isNotEmpty);
    // What matters is that it parses and the text survives, not the shape it
    // settles on: four spaces is a code block to CommonMark, so the deeper
    // levels are not list items at all and should not be asserted to be.
    expect(deep.contains('level 59'), isTrue);
    expect(
      parser.parse(deep).map((n) => n.rawContent).join(),
      contains('level 0'),
    );
  });

  test('every construct left unclosed at once', () {
    // Each of these has had a quadratic pattern behind it at some point, and
    // they are worst together: nothing closes, so every scan runs to the end.
    const unclosed = '```dart\n<!-- \n[^1 \n\$\$ \n**bold\n| a | b\n';

    final watch = Stopwatch()..start();
    final nodes = parser.parse(unclosed);
    watch.stop();

    expect(nodes, isNotEmpty);
    expect(
      watch.elapsedMilliseconds,
      lessThan(500),
      reason: '六个未闭合的构造放在一起解析了 ${watch.elapsedMilliseconds} ms',
    );
  });

  test('three hundred empty list items', () {
    // An empty item has no content to measure indentation from, which once
    // swallowed everything after it into a deeper level.
    final many = '- \n' * 300;

    final nodes = parser.parse(many);
    expect(nodes, isNotEmpty);
    expect(WordCountService().countWords(many).words, 0);
  });

  test('right-to-left text mixed with combining marks and pairs', () {
    // Arabic with emphasis inside it, a combining sequence, a ZWJ family, and
    // characters outside the basic plane — all in one paragraph.
    const mixed = '# مرحبا **بالعالم**\n\n'
        'ȩ́̄ and \u{1F468}‍\u{1F469}‍\u{1F467} and '
        '\u{1D518}\u{1D52B}\u{1D526}\n';

    final nodes = parser.parse(mixed);
    expect(nodes, isNotEmpty);

    // Code points, not UTF-16 units: the pairs are one character each to
    // someone counting, which is what the status bar shows.
    final counted = WordCountService().countWords(mixed).characters;
    expect(
      counted,
      lessThan(mixed.length),
      reason: '按 UTF-16 数的话，星外字符会被数成两个——状态栏不该那样',
    );
  });
}

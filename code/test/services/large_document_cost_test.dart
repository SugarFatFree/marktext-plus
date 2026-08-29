import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// What a large document costs, and where.
///
/// Measured on a five megabyte document: parsing it takes about 3.5 s and
/// reading its outline about 400 ms. Both used to run on the UI isolate — the
/// parse once per pause in typing, the outline once per keystroke — so a large
/// document meant a window that stopped answering.
///
/// These are not timing assertions; a shared CI machine cannot promise a
/// millisecond figure. They pin the structural facts the fix rests on.
void main() {
  String doc(int targetBytes) {
    final b = StringBuffer();
    var i = 0;
    while (b.length < targetBytes) {
      b.writeln('## Section $i');
      b.writeln();
      b.writeln('Prose about topic $i, with a few words in it.');
      b.writeln();
      i++;
    }
    return b.toString();
  }

  test('a large document is parsed in pieces, so the first frame is cheap',
      () {
    final text = doc(2 * 1024 * 1024);
    final prefix = MarkdownParser.safePrefix(text);

    expect(prefix, isNotNull,
        reason: '大文档必须只先解析开头一段，否则首帧要等整篇');
    expect(prefix!.length, lessThan(text.length));

    // The prefix keeps the document's own line numbering, which is what lets
    // a block parsed from it be edited and written back to the right lines.
    final fromPrefix = MarkdownParser().parse(prefix);
    final whole = MarkdownParser().parse(text);
    expect(fromPrefix.first.sourceStart, whole.first.sourceStart);
  });

  test('a small document is parsed whole, with no second pass', () {
    expect(MarkdownParser.safePrefix('# hi\n\nsome text\n'), isNull,
        reason: '小文档不该走两段式，那只是白白多一次解析');
  });

  test('the whole AST survives being handed between isolates', () async {
    // The preview finishes its parse on another isolate. That is only
    // possible because the parser depends on nothing but dart:convert and
    // dart:math, and the blocks it produces are plain objects.
    const text =
        '# Title\n\n> quoted\n>\n> - item\n\n```dart\nvoid main() {}\n```\n';
    final here = MarkdownParser().parse(text);
    final there = await Isolate.run(() => MarkdownParser().parse(text));

    expect(there.length, here.length);
    for (var i = 0; i < here.length; i++) {
      expect(there[i].runtimeType, here[i].runtimeType);
      expect(there[i].sourceStart, here[i].sourceStart);
      expect(there[i].sourceEnd, here[i].sourceEnd);
    }
  });

  test('the parser depends on nothing that cannot cross an isolate', () {
    final source = File('lib/services/markdown_parser.dart').readAsStringSync();
    final imports = RegExp(r"^import '([^']+)';", multiLine: true)
        .allMatches(source)
        .map((m) => m.group(1)!)
        .toList();
    expect(imports, everyElement(startsWith('dart:')),
        reason: '解析器一旦依赖 Flutter，就不能再放到另一个 isolate 上跑');
  });

  test('heading lines read from the AST agree with the outline', () {
    // The preview used to scan the text a second time for heading lines — a
    // second implementation of "what counts as a heading", which had already
    // disagreed with the first twice.
    const text = '---\n'
        'title: front matter\n'
        '# not a heading\n'
        '---\n'
        '\n'
        '# Real\n'
        '\n'
        'Setext\n'
        '======\n'
        '\n'
        '```\n'
        '## inside a fence\n'
        '```\n'
        '\n'
        '## Second\n';

    final fromAst = [
      for (final node in MarkdownParser().parse(text))
        if (node is HeadingNode) node.sourceStart + 1,
    ];
    final fromOutline =
        MarkdownParser.headingOutline(text).map((h) => h.line).toList();

    expect(fromAst, fromOutline);
  });

  test('neither the preview nor the sidebar reads the outline in build', () {
    final sidebar = File('lib/ui/widgets/side_bar.dart').readAsStringSync();
    expect(sidebar.contains('MarkdownParser.headingOutline'), isFalse,
        reason: '目录面板又在 build 里算整篇大纲了');
    expect(sidebar, contains('ref.watch(outlineProvider)'));

    final renderer =
        File('lib/ui/editor/markdown_renderer.dart').readAsStringSync();
    expect(renderer.contains('headingOutline'), isFalse,
        reason: '预览又在扫第二遍文本找标题行了');
  });
}

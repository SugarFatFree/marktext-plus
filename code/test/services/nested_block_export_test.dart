import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// Everything a list item can carry, carried all the way to the file.
///
/// Three separate faults came from routines that walked only the top level of
/// the document after items gained blocks of their own — a diagram with no
/// picture, a formula with no KaTeX, a picture left as a relative path. This
/// asks the same question of every construct at once, so the next one is
/// caught by a failing test rather than by a reader.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('nested_blocks'));
  tearDown(() => root.deleteSync(recursive: true));

  Future<String> exportedHtml(String markdown) async {
    final out = '${root.path}/out.html';
    await ExportService.exportToHtml(markdown, out);
    return File(out).readAsStringSync();
  }

  /// The same construct written twice: once on its own, once under a step.
  const constructs = <String, ({String body, String expected})>{
    // The words themselves are split across highlight spans, so the block
    // is what to look for.
    'a fenced code block': (
      body: '```dart\nvoid main() {}\n```',
      expected: '<pre>',
    ),
    'a quote': (body: '> quoted words', expected: '<blockquote>'),
    'a table': (
      body: '| a | b |\n|---|---|\n| 1 | 2 |',
      expected: '<table>',
    ),
    'a heading': (body: '### deep', expected: 'deep'),
    'a horizontal rule': (body: '---', expected: '<hr>'),
    'a second paragraph': (body: 'more words', expected: 'more words'),
  };

  /// A deeper list item is not a block the step carries — it is another item
  /// of the same list, told apart by its depth. Exported all the same.
  const deeperItem = '- inner';

  /// Indents [body] to sit under a numbered step.
  String underAStep(String body) =>
      '1. step\n\n${body.split('\n').map((l) => '   $l').join('\n')}\n';

  group('a construct written under a step reaches the exported file', () {
    for (final entry in constructs.entries) {
      test(entry.key, () async {
        final alone = await exportedHtml('${entry.value.body}\n');
        expect(alone, contains(entry.value.expected),
            reason: '这个构造单独写时就没出来，测试本身立不住');

        final nested = await exportedHtml(underAStep(entry.value.body));
        expect(nested, contains(entry.value.expected),
            reason: '${entry.key} 写在步骤下面就丢了');
      });
    }
  });

  group('the parser sees it as the step\'s own block', () {
    for (final entry in constructs.entries) {
      test(entry.key, () {
        final nodes = MarkdownParser().parse(underAStep(entry.value.body));
        final list = nodes.whereType<ListNode>().single;

        expect(list.items.single.children, isNotEmpty,
            reason: '${entry.key} 没有成为这一步携带的块');
      });
    }
  });

  test('a deeper item is still exported, as an item rather than a block',
      () async {
    final html = await exportedHtml(underAStep(deeperItem));
    expect(html, contains('inner'));

    final list = MarkdownParser().parse(underAStep(deeperItem))
        .whereType<ListNode>()
        .single;
    expect(list.items.map((i) => i.depth).toList(), [0, 1],
        reason: '缩进的条目应当是同一个列表里更深的一项');
  });

  group('the other two formats still produce a file', () {
    test('PDF', () async {
      final bytes = await ExportService.pdfBytes(
        underAStep('```dart\nvoid main() {}\n```'),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('Word', () async {
      final path = '${root.path}/out.docx';
      await ExportService.exportToDocx(
        underAStep('| a | b |\n|---|---|\n| 1 | 2 |'),
        path,
      );
      final bytes = await File(path).readAsBytes();
      expect(bytes.take(2).toList(), [0x50, 0x4B]);
    });
  });
}

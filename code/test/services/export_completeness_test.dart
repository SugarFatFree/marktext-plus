import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';

/// One document holding every construct this editor can draw, exported to all
/// three formats.
///
/// Not a test of how the output looks — it is a test that nothing has fallen
/// out of it. A construct that stops being exported produces a file that is
/// still valid, still opens, and is quietly missing a table; that is the kind
/// of loss nobody notices until they need the document.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late String markdown;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('exportall');
    markdown = File('test/fixtures/export_everything.md').readAsStringSync();
  });
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('every format produces a file with something in it', () async {
    for (final (name, export) in <(String, Future<void> Function(String))>[
      ('html', (out) => ExportService.exportToHtml(markdown, out)),
      ('pdf', (out) => ExportService.exportToPdf(markdown, out)),
      ('docx', (out) => ExportService.exportToDocx(markdown, out)),
    ]) {
      final out = '${dir.path}/out.$name';
      await export(out);
      final file = File(out);
      expect(file.existsSync(), isTrue, reason: '$name 没有产出文件');
      expect(file.lengthSync(), greaterThan(500), reason: '$name 的文件太小');
    }
  });

  test('the HTML carries every construct the document has', () async {
    final out = '${dir.path}/out.html';
    await ExportService.exportToHtml(markdown, out);
    final html = File(out).readAsStringSync();

    // Each entry is one construct and the alternatives that would show it is
    // there. Written as alternatives because how a thing is marked up is
    // allowed to change; that it survives the trip is not.
    const constructs = <String, List<String>>{
      'heading': ['<h1'],
      'bold': ['<strong>'],
      'italic': ['<em>'],
      'inline code': ['<code>'],
      'strikethrough': ['<del>'],
      'link': ['href="https://example.com"'],
      'bullet list': ['<ul>'],
      'ordered list': ['<ol>'],
      'nested list': ['<li>项目二\n<ul>', '<ul>\n<ul>', '<li><ul>'],
      'task list': ['checkbox', 'task'],
      'blockquote': ['<blockquote>'],
      'table': ['<table>'],
      'column alignment': ['text-align', 'align='],
      'code block': ['language-dart', 'class="dart"', '<pre'],
      'math block': ['math', 'katex'],
      'inline math': ['math-inline', 'katex'],
      'mermaid diagram': ['mermaid'],
      'front matter': ['front-matter'],
      'footnote definition': ['fn-a'],
      'footnote reference': ['#fn-a'],
      'horizontal rule': ['<hr'],
      'CJK in a table cell': ['中文'],
    };

    final missing = <String>[];
    constructs.forEach((name, alternatives) {
      if (!alternatives.any(html.contains)) missing.add(name);
    });
    expect(missing, isEmpty, reason: '这些东西没能进入导出的 HTML');
  });
}

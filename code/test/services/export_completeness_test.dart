import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

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

  test('the Word file carries every construct the document has', () async {
    // The HTML arm has been walked construct by construct since a table
    // stopped being exported. The other two arms were only ever asked whether
    // a file had appeared and began with the right magic number — which, as
    // the comment in `export_survives_new_constructs_test` says, a file with
    // nothing useful in it also satisfies. A .docx is a zip of XML, so the
    // same question can be asked of it properly.
    final out = '${dir.path}/out.docx';
    await ExportService.exportToDocx(markdown, out);
    final archive = ZipDecoder().decodeBytes(File(out).readAsBytesSync());
    // Every entry, not just `word/document.xml`. A hyperlink's target belongs
    // in `word/_rels/document.xml.rels` — that is where OOXML keeps it and
    // where this exporter correctly puts it — so looking in the document alone
    // reported the link as dropped when it was there and working.
    //
    // Decoded as UTF-8, not code units: the fixture is Chinese, and reading
    // the bytes as characters turns every needle into something that matches
    // nothing, which looks exactly like a construct having been dropped.
    final xml = [
      for (final file in archive.files)
        utf8.decode(file.content as List<int>, allowMalformed: true),
    ].join('\n');

    // The words themselves, since Word's markup is the docx_creator
    // package's business and is allowed to change; that the text arrives is
    // not. Each is unique to one construct in the fixture.
    const constructs = <String, String>{
      'heading': '标题一',
      'bold': '粗体',
      'italic': '斜体',
      'inline code': '代码',
      'strikethrough': '删除线',
      'link': 'example.com',
      'bullet list': '项目一',
      'nested list': '嵌套',
      'ordered list': '有序',
      'task list': '未完成',
      'blockquote': '引用第一行',
      'table header': '列 A',
      'table cell': '中文',
      'code block': "print('hi')",
      'maths block': 'E = mc^2',
      'inline maths': 'a^2 + b^2',
      'inline HTML': '原始 HTML',
      'footnote': '脚注内容',
      'front matter': '测试',
    };

    final missing = [
      for (final e in constructs.entries)
        if (!xml.contains(e.value)) '${e.key}（找不到「${e.value}」）',
    ];
    expect(missing, isEmpty,
        reason: 'Word 导出里少了这些构造：\n${missing.join('\n')}');
  });

  test('no block turns into nothing on the way into a PDF', () async {
    // The PDF arm cannot be read back the way the other two can: its text
    // sits in a compressed stream, encoded through an embedded font's glyph
    // ids, so searching the bytes for a word finds nothing whether or not the
    // word is there. Tried, and recorded here so it is not tried again.
    //
    // What can be asked is the question one level up. The arm switches over
    // NodeType and the compiler already refuses a kind with no case, so what
    // is left is a case that returns nothing — the shape this project has
    // been caught by before, where a guard checked that something was drawn
    // and an empty canvas passed.
    final nodes = MarkdownParser().parse(markdown);
    expect(nodes.length, greaterThan(8), reason: '样例文档读出的块太少');

    final empty = <String>[];
    for (final node in nodes) {
      if (ExportService.nodeToPdfWidgets(node).isEmpty) {
        empty.add('${node.type.name}: ${node.rawContent.split('\n').first}');
      }
    }
    expect(empty, isEmpty,
        reason: 'PDF 导出把这些块变成了零个 widget：\n${empty.join('\n')}');
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

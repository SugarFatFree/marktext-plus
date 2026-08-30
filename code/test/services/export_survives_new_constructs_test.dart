import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';

/// Every export path over the constructs whose handling changed this week.
///
/// A construct the parser learned to read has to survive four more journeys —
/// HTML, PDF, Word, and the preview — and three of them end in a file the
/// reader opens somewhere else. A new span type that no export arm knows
/// about throws there and nowhere else; the existing export tests assert the
/// file begins with the right magic number, which a file with nothing useful
/// in it also does.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('export_new'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  /// Everything changed this week, in one document.
  const document = '''
# 标题里的 **加粗** 与 [链接](/url)

**加粗里有 [链接](/url) 和 *斜体* 与 `代码`**，还有 <ruby>漢<rt>hàn</rt></ruby> 注音。

<img src="a.png" alt="图" width="120">

- [ ] 任务里的 **加粗 [链接](/url)**
- 换行续写的一条，
在下一行继续。

> 引用第一行
引用续行，里面有 **加粗**。

| 表头 **粗** | 说明 |
|---|---|
| `代码` | [链接](/url) |
''';

  test('HTML carries the constructs, not just the characters', () async {
    final path = '${dir.path}/out.html';
    await ExportService.exportToHtml(document, path, enableHtml: true);
    final html = File(path).readAsStringSync();

    expect(html, contains('<ruby>'), reason: '注音没有导出');
    expect(html, contains('width="120"'), reason: '图片尺寸没有导出');
    expect(html, contains('<strong>'), reason: '嵌套的强调没有导出');
    expect(html, contains('<a href="/url">'), reason: '链接没有导出');
  });

  test('PDF is written and is a PDF', () async {
    // The arms that draw these spans are separate from the HTML ones: a span
    // type none of them knows throws here alone.
    final path = '${dir.path}/out.pdf';
    await ExportService.exportToPdf(document, path, enableHtml: true);
    final bytes = File(path).readAsBytesSync();
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(2000), reason: 'PDF 小得不像有内容');
  });

  test('Word is written and is a Word file', () async {
    final path = '${dir.path}/out.docx';
    await ExportService.exportToDocx(document, path, enableHtml: true);
    final bytes = File(path).readAsBytesSync();
    expect(bytes.take(2).toList(), [0x50, 0x4B]);
    expect(bytes.length, greaterThan(2000), reason: 'docx 小得不像有内容');
  });

  test('with inline HTML off, the ruby stays as written', () async {
    // The setting decides, and all three exports read it — so this is what a
    // reader who has turned HTML off should get, rather than nothing.
    final path = '${dir.path}/plain.html';
    await ExportService.exportToHtml(document, path);
    final html = File(path).readAsStringSync();
    expect(html, isNot(contains('<ruby>')));
    expect(html, contains('&lt;ruby&gt;'));
  });
}

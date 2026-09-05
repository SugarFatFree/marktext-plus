import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';

/// Every export path over the constructs whose handling changed recently.
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

  /// Everything that changed recently, in one document.
  ///
  /// Grown rather than replaced each version: a construct that broke an export
  /// arm once can break it again, and the cost of carrying it here is nothing.
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

见 [手册][doc] 与 [仓库][repo]。

[doc]: /doc
  "使用手册"
[repo]: /repo

- 制表符缩进的项

\t乙丙丁戊

\t```dart
\tvar x = 1;
\t```

- 平铺一
 - 平铺二
  - 平铺三

==高亮==、^上标^、~下标~、++下划线++、~~删除线~~，
行内公式 \$E = mc^2\$，以及一个脚注[^n]。

**加粗里有 ==高亮==、^上标^ 与 ~下标~**，==高亮里有 **加粗** 和 [链接](/url)==。

[^n]: 脚注定义本身。
''';

  test('HTML carries the constructs, not just the characters', () async {
    final path = '${dir.path}/out.html';
    await ExportService.exportToHtml(document, path, enableHtml: true);
    final html = File(path).readAsStringSync();

    expect(html, contains('<ruby>'), reason: '注音没有导出');
    expect(html, contains('width="120"'), reason: '图片尺寸没有导出');
    expect(html, contains('<strong>'), reason: '嵌套的强调没有导出');
    expect(html, contains('<a href="/url">'), reason: '链接没有导出');

    // Added with v1.5.7's parser fixes, which all three exports read through
    // the same nodes.
    expect(html, contains('title="使用手册"'),
        reason: '折行写的链接定义，标题没有导出');
    expect(html, contains('乙丙丁戊'), reason: '制表符缩进的段落丢了字');
    expect(html, contains('<pre><code'), reason: '制表符缩进的围栏没有导出成代码块');
    expect(html, contains('平铺三'), reason: '漂移缩进的列表项没有导出');
    expect('<ul>'.allMatches(html).length, lessThan(6),
        reason: '平铺的列表被导出成了层层嵌套');

    // The kinds of emphasis the source pane learned to colour in v1.6.2. Each
    // has its own arm in each export, and an arm that throws or drops the run
    // shows up nowhere else.
    expect(html, contains('<mark>'), reason: '==高亮== 没有导出');
    expect(html, contains('<sup>'), reason: '^上标^ 没有导出');
    expect(html, contains('<sub>'), reason: '~下标~ 没有导出');
    expect(html, contains('<u>'), reason: '++下划线++ 没有导出');
    expect(html, contains('<del>'), reason: '~~删除线~~ 没有导出');
    expect(html, contains('脚注定义本身'), reason: '脚注定义没有导出');
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

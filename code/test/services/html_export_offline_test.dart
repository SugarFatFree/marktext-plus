import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';

/// What an exported HTML file still has to fetch to display itself.
///
/// It began at six: mermaid, three KaTeX resources and two for highlight.js.
/// Every one of them is a blank diagram, unrendered maths or uncoloured code
/// for anyone reading offline — or on a network that does not reach jsdelivr,
/// which is most company networks.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('html_offline_'));
  tearDown(() => root.deleteSync(recursive: true));

  Future<String> export(String markdown) async {
    final path = '${root.path}/out.html';
    await ExportService.exportToHtml(markdown, path);
    return File(path).readAsStringSync();
  }

  Iterable<String> externals(String html) =>
      RegExp(r'https?://[^"' "'" r'\s]+').allMatches(html).map((m) => m.group(0)!);

  test('an ordinary document fetches nothing at all', () async {
    final html = await export('''# Title

Some text with **bold**, a [link](https://example.com) and a list:

- one
- two

```dart
void main() {}
```
''');

    // The link in the document is content, not something the file loads.
    expect(externals(html).where((u) => u.contains('jsdelivr')), isEmpty,
        reason: '普通文档不该为了显示自己去连网');
  });

  test('a document with maths asks for KaTeX, and only then', () async {
    final without = await export('# no maths here\n');
    expect(without.contains('katex'), isFalse);

    final withBlock = await export('\$\$\nE = mc^2\n\$\$\n');
    expect(withBlock.contains('katex'), isTrue);

    final withInline = await export('Einstein wrote \$E = mc^2\$ once.\n');
    expect(withInline.contains('katex'), isTrue,
        reason: '行内公式也要算 —— 只看公式块会漏掉一半');
  });

  test('maths inside a table cell still counts', () async {
    // Cells are raw text until the export parses them, so a check that reads
    // them any other way disagrees with what ends up in the file.
    final html = await export('| a | b |\n|---|---|\n| \$x^2\$ | y |\n');

    expect(html.contains('katex'), isTrue);
  });

  test('maths inside a list item and a heading still counts', () async {
    expect((await export('- item \$a+b\$\n')).contains('katex'), isTrue);
    expect((await export('# heading \$a+b\$\n')).contains('katex'), isTrue);
  });
}

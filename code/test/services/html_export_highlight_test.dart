import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';

/// Code colouring in an exported HTML file.
///
/// The export used to emit plain `<pre><code>` and leave highlight.js to be
/// fetched from a CDN and run in the reader's browser: offline, or on a network
/// that does not reach jsdelivr, the code arrived uncoloured. The highlighter
/// is compiled into the app already — the preview uses it — so colouring at
/// export time costs nothing that has not been paid for, and the file stops
/// depending on the network for it.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('html_hl_'));
  tearDown(() => root.deleteSync(recursive: true));

  Future<String> export(String markdown) async {
    final path = '${root.path}/out.html';
    await ExportService.exportToHtml(markdown, path);
    return File(path).readAsStringSync();
  }

  test('a code block comes out coloured, with the theme in the file', () async {
    final html = await export('```dart\nvoid main() { print(1); }\n```\n');

    expect(html, contains('hljs-'), reason: '没有着色标记，代码是纯的');
    expect(html, contains('.hljs-keyword'), reason: '主题没有写进文件');
  });

  test('nothing is fetched to colour it', () async {
    final html = await export('```dart\nvar x = 1;\n```\n');

    expect(html, isNot(contains('highlight.js')));
    expect(html, isNot(contains('hljs.highlightAll')));
  });

  test('an unknown language keeps the code rather than losing it', () async {
    final html = await export('```no-such-language\nkeep me\n```\n');

    expect(html, contains('keep me'));
  });

  test('a fence with no language still shows its code', () async {
    final html = await export('```\nplain text\n```\n');

    expect(html, contains('plain text'));
  });

  test('code is escaped, not injected', () async {
    // The highlighter walks the source and this rebuilds the markup around it,
    // which is exactly where an unescaped `<` would become a tag.
    final html = await export('```html\n<script>bad()</script>\n```\n');

    expect(html, isNot(contains('<script>bad()')));
    expect(html, contains('&lt;script&gt;'));
  });

  test('the generated stylesheet is real CSS, not Dart colour values', () {
    final css = ExportService.highlightCss();

    expect(css, contains('.hljs {'));
    expect(RegExp(r'#[0-9a-f]{6}').hasMatch(css), isTrue);
    expect(css, isNot(contains('Color(')));
    expect(css, isNot(contains('0xff')));
  });
}

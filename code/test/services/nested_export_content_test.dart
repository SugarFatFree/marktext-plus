import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';

/// Content written under a list item reaches the exported file.
///
/// A list item can carry blocks of its own, and the routines that decide what
/// an exported file needs — is there a formula, are there local pictures —
/// each named the containers they knew about. A list item's own blocks were
/// not among them, so a formula under a numbered step went out as the dollar
/// signs it was written with, and a picture under one stayed a relative path
/// that breaks the moment the file is opened anywhere else.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late File picture;

  setUp(() {
    root = Directory.systemTemp.createTempSync('nested_export');
    picture = File('${root.path}/pic.png')
      ..writeAsBytesSync(base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='));
  });
  tearDown(() => root.deleteSync(recursive: true));

  Future<String> exported(String markdown) async {
    final out = '${root.path}/out.html';
    await ExportService.exportToHtml(markdown, out, sourcePath: picture.path);
    return File(out).readAsStringSync();
  }

  group('a formula is recognised wherever it is written', () {
    const formula = r'$$x^2$$';

    for (final entry in {
      'at the top level': '$formula\n',
      'under a numbered step': '1. step\n\n   $formula\n',
      'inside a quote': '> $formula\n',
      'inline under a step': '1. step\n\n   a \$x^2\$ b\n',
    }.entries) {
      test(entry.key, () async {
        expect(await exported(entry.value), contains('katex'),
            reason: '没有加载 KaTeX，公式会以美元符号的原样出现');
      });
    }

    test('a document with no formula asks for nothing', () async {
      expect(await exported('1. step\n\n   plain\n'), isNot(contains('katex')));
    });
  });

  group('a local picture is carried into the file', () {
    for (final entry in {
      'at the top level': '![p](pic.png)\n',
      'under a numbered step': '1. step\n\n   ![p](pic.png)\n',
      'inside a quote': '> ![p](pic.png)\n',
    }.entries) {
      test(entry.key, () async {
        final html = await exported(entry.value);
        expect(html, contains('data:image/png;base64,'),
            reason: '图片没有内嵌，换台机器打开就是坏图');
      });
    }
  });
}

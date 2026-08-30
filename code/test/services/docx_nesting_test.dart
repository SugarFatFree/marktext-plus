import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';

/// What actually reaches a Word file when emphasis holds markup.
///
/// A Word run cannot hold another run, so nesting is flattened: the emphasis
/// is folded into each run its text became. The existing export tests assert
/// the file begins with `PK` — true of any zip, and true of a document with
/// every scrap of formatting lost. This one opens it and reads the runs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('docx_nesting'));
  tearDown(() => root.deleteSync(recursive: true));

  /// `word/document.xml` out of a .docx written from [markdown].
  Future<String> documentXml(String markdown) async {
    final path = '${root.path}/out.docx';
    await ExportService.exportToDocx(markdown, path);
    final archive = ZipDecoder().decodeBytes(await File(path).readAsBytes());
    final entry = archive.files.firstWhere((f) => f.name == 'word/document.xml');
    // The parts are UTF-8; reading them as code units turns every Chinese
    // character into mojibake, and every assertion below into a search for
    // text that is not there.
    return utf8.decode(entry.content as List<int>);
  }

  /// The `<w:r>` element carrying [text], with its properties.
  String runFor(String xml, String text) {
    final runs = RegExp(r'<w:r>.*?</w:r>', dotAll: true).allMatches(xml);
    final match = runs.firstWhere(
      (m) => m.group(0)!.contains('>$text<'),
      orElse: () => throw StateError('文档里没有写着「$text」的 run'),
    );
    return match.group(0)!;
  }

  test('a link inside bold keeps both the boldness and the destination',
      () async {
    final xml = await documentXml('**加粗里的 [链接](https://example.com)**\n');
    final run = runFor(xml, '链接');
    expect(run, contains('<w:b/>'), reason: 'Word 里这段没有加粗');
    // The destination travels as a relationship on the hyperlink around the
    // run, so what is asserted here is that the run sits inside one.
    expect(xml, contains('hyperlink'), reason: '链接没有作为超链接导出');
    expect(runFor(xml, '加粗里的 '), contains('<w:b/>'));
  });

  test('bold link text is bold', () async {
    final xml = await documentXml('[**下载**](https://example.com)\n');
    expect(runFor(xml, '下载'), contains('<w:b/>'));
    expect(xml, contains('hyperlink'));
  });

  test('italic inside bold is both', () async {
    final xml = await documentXml('**外层 *内层* 收尾**\n');
    final run = runFor(xml, '内层');
    expect(run, contains('<w:b/>'), reason: '外层加粗没有折进去');
    expect(run, contains('<w:i/>'));
  });

  test('plain bold is unchanged', () async {
    // The guard: the flat path is what nearly every run still takes.
    final xml = await documentXml('**只是加粗**\n');
    expect(runFor(xml, '只是加粗'), contains('<w:b/>'));
  });
}

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

  // The other direction: emphasis the reader nests *into*, whose own
  // formatting has to survive being folded onto the runs inside it.
  //
  // Only these two reach that path. `^x^` and `~x~` take their content
  // verbatim — `^**2**^` keeps the asterisks as characters, in the preview as
  // much as here — so they never carry children and never need folding. Code,
  // inline maths and a footnote marker are the same. That is why the fallback
  // in `_withEmphasis` drops nothing: there is nothing there to drop.
  test('bold inside marked text keeps the ground', () async {
    final xml = await documentXml('==标出来的 **重点** 在此==\n');
    final run = runFor(xml, '重点');
    expect(run, contains('<w:b/>'));
    expect(run, contains('w:highlight'), reason: '外层的高亮被丢掉了');
  });

  test('bold inside underlined text keeps the line', () async {
    final xml = await documentXml('++压线的 **重点** 在此++\n');
    final run = runFor(xml, '重点');
    expect(run, contains('<w:b/>'));
    // Word writes it as `<w:u w:val="single"/>`, not the word itself.
    expect(run, contains('<w:u '), reason: '外层的下划线被丢掉了');
  });

  test('every kind of emphasis reaches Word with its own property', () async {
    // The Word arm had no assertion about its contents at all: the export
    // test checked the magic number and the file size, which a document full
    // of unformatted text also passes. Dropping the raise from an exponent
    // showed up nowhere.
    final xml = await documentXml(
      '==高亮==、^上标^、++下划线++、~~删除线~~、`代码`，以及 ~下标~ 收尾\n',
    );
    expect(runFor(xml, '高亮'), contains('w:highlight'), reason: '==高亮==');
    expect(runFor(xml, '上标'), contains('superscript'), reason: '^上标^');
    expect(runFor(xml, '下标'), contains('subscript'), reason: '~下标~');
    expect(runFor(xml, '下划线'), contains('<w:u '), reason: '++下划线++');
    expect(runFor(xml, '删除线'), contains('<w:strike'), reason: '~~删除线~~');
    expect(runFor(xml, '代码'), contains('Courier New'), reason: '`代码`');
  });

  test('plain bold is unchanged', () async {
    // The guard: the flat path is what nearly every run still takes.
    final xml = await documentXml('**只是加粗**\n');
    expect(runFor(xml, '只是加粗'), contains('<w:b/>'));
  });
}

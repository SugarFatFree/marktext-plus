import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';

/// Exporting over a file the reader already has.
///
/// The picker invites it — it asks whether to replace — so a write that fails
/// partway must not be able to take the previous export with it.
/// `FileService.writeBytesAtomically` is what the other two formats use, and its
/// doc comment says it was made public "because the exports need it too": a
/// plain `writeAsBytes` truncates the destination the moment it opens it, so a
/// failure after that leaves nothing where the reader's file was.
///
/// Word was the one that did not go through it, because its write was inside
/// `docx_creator` — `DocxExporter.exportToFile` calls the package's own
/// `FileSaver.save`, a bare `File(path).writeAsBytes` — where a search of `lib/`
/// does not find it. On Windows the case is not hypothetical: a `.docx` open in
/// Word is locked, so the write fails, after the truncation.
///
/// The observable difference used here is a destination the process may replace
/// but not open for writing. A rename needs permission on the *directory*; an
/// open for writing needs it on the *file*. So a read-only file in a writable
/// directory is replaced by the atomic write and refused by the plain one —
/// measured on this filesystem before the test was written, rather than assumed.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('exportatomic'));
  tearDown(() {
    if (dir.existsSync()) {
      // Put the permissions back or the recursive delete cannot finish.
      for (final f in dir.listSync().whereType<File>()) {
        try {
          Process.runSync('chmod', ['644', f.path]);
        } on ProcessException {
          // Best effort; the directory is in the system temp area either way.
        }
      }
      dir.deleteSync(recursive: true);
    }
  });

  const markdown = '# Title\n\nA paragraph, and a list:\n\n- one\n- two\n';

  /// A file the process owns, may rename over, and may not open for writing.
  File readOnlyFile(String name, String content) {
    final file = File('${dir.path}/$name')..writeAsStringSync(content);
    final chmod = Process.runSync('chmod', ['444', file.path]);
    expect(chmod.exitCode, 0, reason: 'chmod 没成功，这个用例什么也没造出来');
    expect(
      () => file.openSync(mode: FileMode.write),
      throwsA(isA<FileSystemException>()),
      reason: '这个文件还能被打开写入——那两种写法在这里就没有分别了',
    );
    return file;
  }

  test('Word replaces a file it could not have opened for writing', () async {
    final target = readOnlyFile('report.docx', 'the previous export');

    await ExportService.exportToDocx(markdown, target.path);

    final bytes = target.readAsBytesSync();
    expect(bytes.length, greaterThan(1000),
        reason: '导出的 .docx 不该只有几个字节');
    // A .docx is a ZIP: `PK`.
    expect(bytes.sublist(0, 2), [0x50, 0x4B],
        reason: '写出来的不是一个 ZIP——导出坏了，不只是写法变了');
  });

  test('HTML and PDF do the same, which is where the rule came from', () async {
    final html = readOnlyFile('report.html', 'the previous export');
    await ExportService.exportToHtml(markdown, html.path);
    expect(html.readAsStringSync(), contains('Title'));

    final pdf = readOnlyFile('report.pdf', 'the previous export');
    await ExportService.exportToPdf(markdown, pdf.path);
    expect(pdf.readAsBytesSync().sublist(0, 4), [0x25, 0x50, 0x44, 0x46],
        reason: '%PDF 开头');
  });

  test('nothing is left beside the file that was written', () async {
    // The scratch file is named `<target>.<pid>_<n>.mtsave`, and leaving one in
    // the reader's folder is its own small defect.
    await ExportService.exportToDocx(markdown, '${dir.path}/fresh.docx');
    final leftovers = dir
        .listSync()
        .map((e) => e.path.split('/').last)
        .where((name) => name.endsWith('.mtsave'))
        .toList();
    expect(leftovers, isEmpty, reason: '临时文件留在了读者的目录里：$leftovers');
  });
}

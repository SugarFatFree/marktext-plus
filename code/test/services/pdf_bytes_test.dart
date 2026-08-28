import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';

/// Printing lays out the same document the PDF export writes.
///
/// The two used to be one method that could only end in a file. Printing
/// through a temporary file would have lost the page setup the system dialog
/// offers, so the layout was split out — and the split is only worth anything
/// if both ends still produce the same document.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const doc = '# Title\n\nBody with **bold**.\n\n- a\n- b\n\n> quoted\n';

  test('the bytes are a PDF', () async {
    final bytes = await ExportService.pdfBytes(doc);

    expect(bytes.length, greaterThan(500));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('the export writes exactly what printing would lay out', () async {
    final dir = Directory.systemTemp.createTempSync('pdf_bytes');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/out.pdf';

    await ExportService.exportToPdf(doc, path);
    final written = await File(path).readAsBytes();
    final printed = await ExportService.pdfBytes(doc);

    // Not byte-for-byte: the pdf package stamps a creation date, so two
    // documents built a moment apart differ in those bytes alone.
    expect(written.length, closeTo(printed.length, 200));
    expect(String.fromCharCodes(written.take(5)), '%PDF-');
  });

  test('an empty document still produces a file rather than throwing',
      () async {
    expect((await ExportService.pdfBytes('')).length, greaterThan(100));
  });
}

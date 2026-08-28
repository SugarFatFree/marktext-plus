import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// What the preview shows and what the exported file shows.
///
/// Column alignment was honoured on screen and dropped by every exporter, so
/// a right-aligned column of figures came out left-aligned in the file the
/// reader sent on. Word had the worse half of it: cells were handed over as
/// plain strings, so `**bold**` arrived with its asterisks showing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const aligned = '| L | C | R |\n|:--|:-:|--:|\n| 1 | 2 | 3 |\n';

  String htmlOf(String markdown) =>
      MarkdownParser().parse(markdown).map(ExportService.nodeToHtml).join();

  group('HTML keeps the column alignment', () {
    test('each of the three, on header and body alike', () {
      final html = htmlOf(aligned);

      expect(html, contains('<th style="text-align:left">'));
      expect(html, contains('<th style="text-align:center">'));
      expect(html, contains('<th style="text-align:right">'));
      expect(html, contains('<td style="text-align:right">3</td>'));
    });

    test('a column with no alignment gets no attribute', () {
      expect(htmlOf('| a |\n|---|\n| 1 |\n'), isNot(contains('text-align')));
    });

    test('a row shorter than the header still lines the columns up', () {
      // The cell is filled in, so the third column's alignment stays with the
      // third column.
      final html = htmlOf('| a | b |\n|--:|:-:|\n| 1 |\n');
      expect(html, contains('<td style="text-align:right">1</td>'));
      expect(html, contains('<td style="text-align:center"></td>'));
    });
  });

  group('Word gets a real table', () {
    test('the file is written and is a zip, not a crash', () async {
      final dir = Directory.systemTemp.createTempSync('table_docx');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/t.docx';

      await ExportService.exportToDocx(
        '$aligned\n| a |\n|---|\n| **bold** |\n',
        path,
      );

      final bytes = await File(path).readAsBytes();
      expect(bytes.length, greaterThan(500));
      // Every .docx is a zip; the signature is the cheapest proof it is one.
      expect(bytes.take(2).toList(), [0x50, 0x4B]);
    });
  });

  group('PDF still lays the table out', () {
    test('an aligned table produces a document', () async {
      final bytes = await ExportService.pdfBytes(aligned);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}

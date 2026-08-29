import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/services/export_service.dart';

/// Exporting to somewhere it cannot be written.
///
/// The three exports and Print are `async void` event handlers that call
/// something which throws — an unwritable path, a folder where a file was
/// expected, a document the writer cannot lay out. None of them caught it, so
/// the throw escaped as an unhandled asynchronous error: the reader chose a
/// filename, pressed Export, and nothing whatever happened. The save paths
/// were given a message long ago; these were not.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const document = '# Title\n\nSome text.\n';

  group('every export reports a failure rather than swallowing it', () {
    // `/proc` exists and refuses writes on Linux, which is a real version of
    // "the place you chose cannot be written to".
    const unwritable = '/proc/marktext-plus-should-not-exist/out';

    test('HTML throws rather than failing silently', () {
      expect(ExportService.exportToHtml(document, '$unwritable.html'),
          throwsA(anything));
    });

    test('PDF throws rather than failing silently', () {
      expect(ExportService.exportToPdf(document, '$unwritable.pdf'),
          throwsA(anything));
    });

    test('Word throws rather than failing silently', () {
      expect(ExportService.exportToDocx(document, '$unwritable.docx'),
          throwsA(anything));
    });

    test('a path that is a folder is a failure too', () {
      final dir = Directory.systemTemp.createTempSync('exportdir');
      addTearDown(() => dir.deleteSync(recursive: true));
      expect(ExportService.exportToHtml(document, dir.path),
          throwsA(anything));
    });
  });

  test('every language can say that an export failed', () async {
    // The message is shown at the one moment the reader needs to be told
    // something; an untranslated one would be English in the middle of a
    // localised application.
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      final message = l10n.exportFailed('disk full');
      expect(message, isNotEmpty, reason: '$locale');
      expect(message, contains('disk full'),
          reason: '$locale 的文案没有带上原因');
    }
  });

  test('every export entry point catches what it calls', () {
    // A structural check, because the behaviour cannot be reached without a
    // file picker and a printer. It covers an export added later, which is
    // the case that would otherwise repeat this bug.
    final source =
        File('lib/ui/widgets/app_menu_bar.dart').readAsStringSync();
    for (final entry in ['_exportHtml', '_exportPdf', '_exportWord', '_print']) {
      final start = source.indexOf('void $entry(WidgetRef');
      expect(start, isNot(-1), reason: '找不到 $entry');
      final end = source.indexOf('\n  }', start);
      final body = source.substring(start, end);
      expect(body, contains('reportExportFailure'),
          reason: '$entry 没有报告失败：导出失败时用户什么都不会看到');
    }
  });
}

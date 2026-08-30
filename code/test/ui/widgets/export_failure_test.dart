import 'dart:io';

import 'package:path/path.dart' as p;

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

  test('no async void handler does file work without catching it', () {
    // The general form of this bug. A `void ... async` method is an event
    // handler: nothing awaits it, so anything it throws becomes an unhandled
    // asynchronous error and the reader sees a button that did nothing. Four
    // exports had it, then Open, Open Recent and the Help menu's link.
    //
    // Scanning for the shape rather than listing the methods, so a handler
    // added later is covered — which is the only way this stops coming back.
    //
    // What it can and cannot see, checked by breaking the code: removing a
    // whole try/catch is caught at once; emptying the catch body is not,
    // because a `catch` that swallows still reads as handled here. The
    // per-export test below is the one that insists something is actually
    // reported.
    // `File` alone also matches `await FilePicker.platform...`, which throws
    // nothing and is how two handlers were flagged that did not need it. The
    // call has to be a call.
    final risky = RegExp(
      r'await\s+(?:File\(|File\.|Directory\(|Directory\.|FileService\('
      r'|ImageService\.|ExportService\.|Printing\.|Process\.|launchUrl\()',
    );
    final offenders = <String>[];
    for (final path in [
      'lib/ui/widgets/app_menu_bar.dart',
      'lib/ui/widgets/side_bar.dart',
      'lib/ui/widgets/editor_tab_bar.dart',
      'lib/ui/screens/home_screen.dart',
    ]) {
      final lines = File(path).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!RegExp(r'\bvoid\s+(\w+)\([^)]*\)\s*async\s*\{')
            .hasMatch(lines[i])) {
          continue;
        }
        var depth = 0;
        var started = false;
        var end = i;
        for (var j = i; j < lines.length && j < i + 200; j++) {
          depth += '{'.allMatches(lines[j]).length;
          depth -= '}'.allMatches(lines[j]).length;
          if (lines[j].contains('{')) started = true;
          if (started && depth <= 0) {
            end = j;
            break;
          }
        }
        final body = lines.sublist(i, end + 1).join('\n');
        if (risky.hasMatch(body) && !body.contains('catch')) {
          final name = RegExp(r'void\s+(\w+)').firstMatch(lines[i])!.group(1);
          offenders.add('$path:${i + 1} $name');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: '这些事件处理器做了文件/进程操作却不捕获异常，'
            '失败时用户只会看到"点了没反应"');
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

  group('a failed export leaves the previous one alone', () {
    // The picker invites replacing a file that already exists. A plain write
    // truncates it the moment it opens it — measurable: open a thousand-byte
    // file for writing and it is zero bytes before anything has been written
    // — so an export that fails part way through destroyed the export that
    // was there, and produced nothing to replace it.
    late Directory dir;
    late String target;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('exportatomic');
      target = '${dir.path}/out.html';
      File(target).writeAsStringSync('the previous export\n' * 100);
    });
    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('an export that cannot be written keeps what was there', () async {
      final before = File(target).readAsStringSync();
      // The *directory* is made read-only, not the file. Making the file
      // read-only proves nothing: the scratch file is created in the
      // directory and renamed over the target, and a rename over a read-only
      // file succeeds — which is the atomic write working, not failing. An
      // unwritable directory is what actually stops it.
      await Process.run('chmod', ['555', dir.path]);
      try {
        await ExportService.exportToHtml(document, target);
      } catch (_) {
        // Expected.
      }
      await Process.run('chmod', ['755', dir.path]);
      expect(File(target).readAsStringSync(), before,
          reason: '导出失败，但之前那份导出被毁了');
    });

    test('an export that succeeds does replace it', () async {
      await ExportService.exportToHtml(document, target);
      final now = File(target).readAsStringSync();
      expect(now, isNot(contains('the previous export')));
      expect(now, contains('Title'));
    });

    test('no scratch file is left beside the reader\'s documents', () async {
      await ExportService.exportToHtml(document, target);
      final leftovers = dir
          .listSync()
          .map((e) => p.basename(e.path))
          .where((n) => n.contains('.mtsave'))
          .toList();
      expect(leftovers, isEmpty, reason: '临时文件留在了用户的文件夹里');
    });
  });
}

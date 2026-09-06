import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/open_document_watcher.dart';
import 'package:path/path.dart' as p;

import '../support/wait_for.dart';

/// Filesystem notifications arrive asynchronously and the watcher debounces
/// them, so each check waits rather than asserting immediately.
///
/// Waiting for something to arrive asks — [waitFor] returns the moment it
/// does, and on a loaded runner keeps asking long after a fixed sleep would
/// have given up. Proving nothing arrives cannot ask, so those checks sit out
/// the full stretch below.
Future<void> settle() =>
    Future<void>.delayed(const Duration(milliseconds: 700));

void main() {
  late Directory root;
  late File watched;
  late File other;
  late OpenDocumentWatcher service;
  late List<String> reported;

  setUp(() {
    root = Directory.systemTemp.createTempSync('open_doc_watch_');
    watched = File('${root.path}/open.md')..writeAsStringSync('one');
    other = File('${root.path}/closed.md')..writeAsStringSync('one');
    service = OpenDocumentWatcher();
    reported = [];
    service.changes.listen(reported.add);
  });

  tearDown(() {
    service.dispose();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('reports a change to a watched file', () async {
    service.watch([watched.path]);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    watched.writeAsStringSync('two');
    await waitFor(() => reported.isNotEmpty);

    // By name, not by full path: a temp directory can come back resolved
    // through a symlink on some platforms.
    expect(reported.map(p.basename).toList(), ['open.md']);
  });

  test(
    'says nothing about a file in the same folder that is not open',
    () async {
      service.watch([watched.path]);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      other.writeAsStringSync('two');
      await settle();

      expect(reported, isEmpty);
    },
  );

  test(
    'notices a save made by renaming a temporary file over the original',
    () async {
      // How a great many tools write a file. A watch held on the file itself
      // would go silent here, which is why the directory is watched instead.
      service.watch([watched.path]);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final temp = File('${root.path}/open.md.tmp')..writeAsStringSync('two');
      temp.renameSync(watched.path);
      await waitFor(() => reported.isNotEmpty);

      // By name, not by full path: a temp directory can come back resolved
      // through a symlink on some platforms.
      expect(reported.map(p.basename).toList(), ['open.md']);
    },
  );

  test('a burst of writes is reported once', () async {
    service.watch([watched.path]);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    for (var i = 0; i < 5; i++) {
      watched.writeAsStringSync('write $i');
    }
    await waitFor(() => reported.isNotEmpty);

    // By name, not by full path: a temp directory can come back resolved
    // through a symlink on some platforms.
    expect(reported.map(p.basename).toList(), ['open.md']);
  });

  test('watching again drops the file that is no longer open', () async {
    service.watch([watched.path, other.path]);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    service.watch([other.path]);
    watched.writeAsStringSync('two');
    await settle();

    expect(reported, isEmpty);
  });
}

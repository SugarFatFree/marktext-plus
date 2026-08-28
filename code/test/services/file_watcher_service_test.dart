import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/file_watcher_service.dart';

/// Filesystem notifications arrive asynchronously and the service debounces
/// them, so each check waits rather than asserting immediately.
Future<void> settle() =>
    Future<void>.delayed(const Duration(milliseconds: 900));

void main() {
  late Directory root;
  late Directory a;
  late Directory b;
  late FileWatcherService service;
  late int events;

  setUp(() {
    root = Directory.systemTemp.createTempSync('watcher_test_');
    a = Directory('${root.path}/a')..createSync();
    b = Directory('${root.path}/b')..createSync();
    service = FileWatcherService();
    events = 0;
    service.events.listen((_) => events++);
  });

  tearDown(() {
    service.dispose();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('reports changes only in the watched folders', () async {
    service.watch([a.path]);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    File('${b.path}/untouched.md').writeAsStringSync('hi');
    await settle();
    expect(events, 0, reason: 'b is not watched');

    File('${a.path}/watched.md').writeAsStringSync('hi');
    await settle();
    expect(events, 1);
  });

  test('watching again reconciles instead of resubscribing', () async {
    service.watch([a.path]);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    service.watch([b.path]);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    File('${a.path}/dropped.md').writeAsStringSync('hi');
    await settle();
    expect(events, 0, reason: 'a was dropped from the watch set');

    File('${b.path}/added.md').writeAsStringSync('hi');
    await settle();
    expect(events, 1);
  });

  test('a folder that does not exist is skipped quietly', () {
    // The tree is read asynchronously, so a folder can vanish between being
    // listed and being watched.
    expect(() => service.watch(['${root.path}/missing', a.path]),
        returnsNormally);
  });

  test('deleting a watched folder does not raise an unhandled error', () async {
    final doomed = Directory('${root.path}/doomed')..createSync();
    service.watch([doomed.path]);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    doomed.deleteSync();
    await settle();

    // Still usable afterwards.
    service.watch([a.path]);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    File('${a.path}/after.md').writeAsStringSync('hi');
    await settle();
    expect(events, greaterThan(0));
  });

  test('stop drops every watch', () async {
    service.watch([a.path]);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    service.stop();

    File('${a.path}/ignored.md').writeAsStringSync('hi');
    await settle();
    expect(events, 0);
  });
}

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/file_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:path/path.dart' as p;

/// Work that is still running when the thing it reports to has gone.
///
/// A notifier that touches `state` after `dispose` throws "Tried to use X
/// after `dispose` was called", and because these are started without being
/// awaited the throw escapes as an unhandled asynchronous error — nothing
/// catches it and nothing is shown. It happens for real: open a large folder
/// or double-click a batch of files, then quit.
///
/// This is the same shape as BUG-149, where the disk stamp was refreshed
/// after a tab had been closed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('closing while a folder is being read does not throw', () async {
    final root = Directory.systemTemp.createTempSync('disposefolder');
    addTearDown(() => root.deleteSync(recursive: true));
    // Big enough that the read is still going when dispose lands.
    for (var i = 0; i < 40; i++) {
      final dir = Directory(p.join(root.path, 'd$i'))..createSync();
      for (var j = 0; j < 20; j++) {
        File(p.join(dir.path, 'f$j.md')).writeAsStringSync('x');
      }
    }

    final container = ProviderContainer();
    final reading = container.read(fileProvider.notifier)
        .loadDirectory(root.path); // deliberately not awaited by the caller
    container.dispose();

    await expectLater(reading, completes,
        reason: '读目录途中退出应用抛了未捕获的异步错误');
  });

  test('closing while files are being opened does not throw', () async {
    final root = Directory.systemTemp.createTempSync('disposefiles');
    addTearDown(() => root.deleteSync(recursive: true));
    final files = [
      for (var i = 0; i < 30; i++)
        (File(p.join(root.path, 'n$i.md'))..writeAsStringSync('x' * 20000))
            .path,
    ];

    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: root.path),
          AppConfig(autoSave: false),
        ),
      ),
    ]);
    final notifier = container.read(tabProvider.notifier);
    notifier.addTab(TabInfo(id: 'seed', fileName: 'seed'));

    final opening = notifier.openFilesFromSecondInstance(files);
    container.dispose();

    await expectLater(opening, completes,
        reason: '批量打开文件途中退出应用抛了未捕获的异步错误');
  });

  test('a notifier that writes state after an await checks it is still there',
      () {
    // The two above are the cases that exist today. This one covers the ones
    // written tomorrow: a `state = ...` reached after an `await`, with no
    // `mounted` between them, is the shape of both.
    final offenders = <String>[];
    for (final file in Directory('lib/providers')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final lines = file.readAsLinesSync();
      final source = lines.join('\n');
      if (!source.contains('StateNotifier<')) continue;

      for (var i = 0; i < lines.length; i++) {
        final signature = RegExp(
          r'\b(Future<[^>]*>|void)\s+\w+\([^)]*\)\s*async',
        );
        if (!signature.hasMatch(lines[i])) continue;

        var depth = 0;
        var started = false;
        var end = i;
        for (var j = i; j < lines.length && j < i + 160; j++) {
          depth += '{'.allMatches(lines[j]).length;
          depth -= '}'.allMatches(lines[j]).length;
          if (lines[j].contains('{')) started = true;
          if (started && depth <= 0) {
            end = j;
            break;
          }
        }
        final body = lines.sublist(i, end + 1);
        final firstAwait = body.indexWhere((l) => l.contains('await '));
        if (firstAwait == -1) continue;
        final after = body.sublist(firstAwait);
        final lastWrite =
            after.lastIndexWhere((l) => RegExp(r'^\s*state = ').hasMatch(l));
        if (lastWrite == -1) continue;
        final guarded =
            after.sublist(0, lastWrite + 1).any((l) => l.contains('mounted'));
        if (!guarded) {
          final name = RegExp(r'\s(\w+)\(').firstMatch(lines[i])?.group(1);
          offenders.add('${file.path}:${i + 1} $name');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: '这些方法在 await 之后写 state 却没检查 mounted，'
            '应用在它们跑完之前退出就会抛未捕获的异步错误');
  });
}

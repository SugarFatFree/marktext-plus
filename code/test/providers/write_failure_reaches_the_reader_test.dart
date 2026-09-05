import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/file_encoding.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';

/// A write that fails has to reach whoever asked for it.
///
/// `overwriteOnDisk` is what the reader chooses when their document and the
/// file on disk have diverged and they decide their own version wins. It
/// answered `false` both when there was nothing to write to and when the
/// write itself had failed, and its one caller looked at neither — so a
/// refused write cleared the conflict banner and left the old bytes on disk,
/// which is the shape of losing work.
///
/// The two answers are told apart now: `false` is "there was nothing to do",
/// and a failure is thrown, the way saving from the tab bar already did it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late ProviderContainer container;

  setUp(() {
    root = Directory.systemTemp.createTempSync('write_failure');
    container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: root.path),
            AppConfig(autoSave: false),
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  TabInfo addTab({required String? path, bool modified = false}) {
    container
        .read(tabProvider.notifier)
        .addTab(
          TabInfo(
            id: 'note',
            filePath: path,
            fileName: 'note.md',
            content: 'mine',
            isModified: modified,
          ),
        );
    return container.read(tabProvider).tabs.single;
  }

  group('overwriting the file on disk', () {
    test('a write that cannot happen is thrown, not answered false', () async {
      // A path that is a directory. Not a missing one: `saveDocument`
      // creates the folders it needs, so writing to `nowhere/note.md`
      // succeeds — the first version of this test used exactly that and
      // asserted a throw that never came.
      addTab(path: root.path);

      await expectLater(
        container.read(tabProvider.notifier).overwriteOnDisk('note'),
        throwsA(isA<Object>()),
        reason: '写失败要传出去，不能和「无事可做」共用一个 false',
      );
    });

    test('nothing to write to is still false', () async {
      // An untitled tab has no file: nothing failed, there was nothing to do.
      addTab(path: null);

      expect(
        await container.read(tabProvider.notifier).overwriteOnDisk('note'),
        isFalse,
      );
    });

    test('a write that works clears the conflict', () async {
      final file = File('${root.path}/note.md')..writeAsStringSync('theirs');
      addTab(path: file.path);
      container.read(tabProvider.notifier).markDiskConflict('note');

      expect(
        await container.read(tabProvider.notifier).overwriteOnDisk('note'),
        isTrue,
      );
      expect(file.readAsStringSync(), 'mine');
      expect(container.read(tabProvider).tabs.single.diskConflict, isFalse);
    });
  });

  group('rereading in another encoding', () {
    test('a file that cannot be read is thrown, not answered false', () async {
      addTab(path: '${root.path}/gone.md');

      await expectLater(
        container
            .read(tabProvider.notifier)
            .rereadAs('note', FileEncoding.utf8Encoding),
        throwsA(isA<Object>()),
        reason: '读失败要传出去，读者才知道为什么编码没变',
      );
    });

    test('a tab with unsaved edits is still false', () async {
      final file = File('${root.path}/note.md')..writeAsStringSync('x');
      addTab(path: file.path, modified: true);

      expect(
        await container
            .read(tabProvider.notifier)
            .rereadAs('note', FileEncoding.utf8Encoding),
        isFalse,
        reason: '有未保存修改就不重读，这不是失败',
      );
    });
  });
}

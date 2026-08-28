import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:path/path.dart' as p;

/// Renaming or deleting from the sidebar only touched the filesystem; whatever
/// was open kept pointing at a path that had moved or gone. A folder does it to
/// every file beneath it at once.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory configDir;
  late ProviderContainer container;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('tab_path_test');
    container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(autoSave: false),
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  String path(List<String> parts) => p.joinAll([p.rootPrefix('/'), ...parts]);

  void open(String id, String filePath) {
    container.read(tabProvider.notifier).addTab(
          TabInfo(
            id: id,
            filePath: filePath,
            fileName: p.basename(filePath),
            content: '',
          ),
        );
  }

  List<String?> tabPaths() =>
      container.read(tabProvider).tabs.map((t) => t.filePath).toList();

  List<String> openedPaths() =>
      container.read(tabProvider).openedFiles.map((f) => f.filePath).toList();

  group('pathRenamed', () {
    test('a renamed file takes its tab and its sidebar entry with it', () {
      final before = path(['docs', 'a.md']);
      final after = path(['docs', 'b.md']);
      open('t1', before);

      container.read(tabProvider.notifier).pathRenamed(before, after);

      expect(tabPaths(), [after]);
      expect(openedPaths(), [after]);
      expect(container.read(tabProvider).tabs.single.fileName, 'b.md');
    });

    test('renaming a folder moves every file under it', () {
      final oldDir = path(['docs']);
      final newDir = path(['papers']);
      open('t1', p.join(oldDir, 'a.md'));
      open('t2', p.join(oldDir, 'nested', 'b.md'));

      container.read(tabProvider.notifier).pathRenamed(oldDir, newDir);

      expect(tabPaths(), [
        p.join(newDir, 'a.md'),
        p.join(newDir, 'nested', 'b.md'),
      ]);
    });

    test('a file that merely starts with the same characters is left', () {
      // "/docs2/a.md" is not inside "/docs".
      final inside = path(['docs', 'a.md']);
      final sibling = path(['docs2', 'a.md']);
      open('t1', inside);
      open('t2', sibling);

      container
          .read(tabProvider.notifier)
          .pathRenamed(path(['docs']), path(['papers']));

      expect(tabPaths(), [path(['papers', 'a.md']), sibling]);
    });

    test('renaming something nothing is open on changes nothing', () {
      final only = path(['docs', 'a.md']);
      open('t1', only);

      container
          .read(tabProvider.notifier)
          .pathRenamed(path(['elsewhere']), path(['moved']));

      expect(tabPaths(), [only]);
    });
  });

  group('pathDeleted', () {
    test('a deleted file closes its tab and drops its entry', () {
      final gone = path(['docs', 'a.md']);
      open('t1', gone);

      container.read(tabProvider.notifier).pathDeleted(gone);

      expect(tabPaths(), isEmpty);
      expect(openedPaths(), isEmpty);
    });

    test('deleting a folder closes every tab under it', () {
      final dir = path(['docs']);
      open('t1', p.join(dir, 'a.md'));
      open('t2', p.join(dir, 'nested', 'b.md'));
      open('t3', path(['other', 'c.md']));

      container.read(tabProvider.notifier).pathDeleted(dir);

      expect(tabPaths(), [path(['other', 'c.md'])]);
    });

    test('the active tab moves to one that still exists', () {
      open('t1', path(['docs', 'a.md']));
      open('t2', path(['other', 'b.md']));
      container.read(tabProvider.notifier).setActiveTab('t1');

      container.read(tabProvider.notifier).pathDeleted(path(['docs', 'a.md']));

      expect(container.read(tabProvider).activeTabId, 't2');
    });

    test('a sibling with the same prefix is left alone', () {
      open('t1', path(['docs', 'a.md']));
      open('t2', path(['docs2', 'a.md']));

      container.read(tabProvider.notifier).pathDeleted(path(['docs']));

      expect(tabPaths(), [path(['docs2', 'a.md'])]);
    });
  });
}

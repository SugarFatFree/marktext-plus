import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:path/path.dart' as p;

/// Reopening the documents that were on screen when the application closed.
///
/// Tabs were only ever created from command-line arguments or from something
/// the reader did, so closing the application with five documents open and
/// reopening it gave an empty window — the files listed in the sidebar, to be
/// clicked one at a time. Upstream MarkText restores the session.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('session'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  String write(String name, String content) {
    final file = File(p.join(dir.path, name))..writeAsStringSync(content);
    return file.path;
  }

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: dir.path),
          AppConfig(autoSave: false),
        ),
      ),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('the documents come back, with their contents', () async {
    final a = write('a.md', 'first\n');
    final b = write('b.md', 'second\n');
    final container = makeContainer();

    await container.read(tabProvider.notifier).restoreSession([a, b], b);

    final tabs = container.read(tabProvider).tabs;
    expect(tabs, hasLength(2));
    expect(tabs.map((t) => t.filePath), [a, b]);
    expect(tabs.map((t) => t.content), ['first\n', 'second\n']);
    expect(tabs.every((t) => t.isLoading), isFalse,
        reason: '内容读完后不该还停在加载中');
  });

  test('the one that was in front comes back in front', () async {
    final a = write('a.md', 'x');
    final b = write('b.md', 'y');
    final container = makeContainer();

    await container.read(tabProvider.notifier).restoreSession([a, b], b);

    final state = container.read(tabProvider);
    final active = state.tabs.firstWhere((t) => t.id == state.activeTabId);
    expect(active.filePath, b);
  });

  test('a document deleted since last time is passed over', () async {
    final a = write('a.md', 'x');
    final gone = p.join(dir.path, 'gone.md');
    final container = makeContainer();

    await container.read(tabProvider.notifier).restoreSession([a, gone], gone);

    final tabs = container.read(tabProvider).tabs;
    expect(tabs, hasLength(1), reason: '不该为一个不存在的文件开标签页');
    expect(tabs.single.filePath, a);
    // The one that was in front is gone, so the first of what is left takes
    // its place rather than nothing being active at all.
    expect(container.read(tabProvider).activeTabId, tabs.single.id);
  });

  test('a session of nothing but missing files opens nothing', () async {
    final container = makeContainer();
    await container.read(tabProvider.notifier).restoreSession(
      [p.join(dir.path, 'x.md'), p.join(dir.path, 'y.md')],
      '',
    );
    expect(container.read(tabProvider).tabs, isEmpty);
  });

  test('restoring does not disturb a tab that is already open', () async {
    // The command-line case: a document opened by double-clicking it must
    // stay in front, not be pushed behind last week's session.
    final a = write('a.md', 'x');
    final opened = write('opened.md', 'y');
    final container = makeContainer();
    container.read(tabProvider.notifier).addTab(TabInfo(
          id: 'cli',
          filePath: opened,
          fileName: 'opened.md',
          content: 'y',
        ));

    await container.read(tabProvider.notifier).restoreSession([a], a);

    expect(container.read(tabProvider).activeTabId, 'cli',
        reason: '命令行打开的文档被会话挤到后面了');
  });

  group('what gets written down', () {
    test('opening and closing tabs keeps the session current', () async {
      final a = write('a.md', 'x');
      final b = write('b.md', 'y');
      final container = makeContainer();
      final tabs = container.read(tabProvider.notifier);

      tabs.addTab(TabInfo(id: '1', filePath: a, fileName: 'a.md'));
      tabs.addTab(TabInfo(id: '2', filePath: b, fileName: 'b.md'));
      expect(container.read(settingsProvider).sessionTabs, [a, b]);
      expect(container.read(settingsProvider).sessionActiveTab, b);

      tabs.setActiveTab('1');
      expect(container.read(settingsProvider).sessionActiveTab, a);

      tabs.removeTab('2');
      expect(container.read(settingsProvider).sessionTabs, [a]);
    });

    test('a document never saved to disk is not in the session', () async {
      // It has no path to reopen from; recording it would restore a tab that
      // could never be filled.
      final container = makeContainer();
      container
          .read(tabProvider.notifier)
          .addTab(TabInfo(id: 'scratch', fileName: 'Untitled'));
      expect(container.read(settingsProvider).sessionTabs, isEmpty);
    });
  });

  test('a restored document is watched like any other', () async {
    // Restored tabs go through the same state setter as any other, which is
    // where the watch set is kept — but "it goes through the same place" is
    // read from the code, and this is the part that checks it.
    final a = write('a.md', 'first\n');
    final container = makeContainer();
    await container.read(tabProvider.notifier).restoreSession([a], a);

    // The watcher needs a moment to start; then a change made by something
    // else is picked up, since the restored tab has no unsaved edits.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    File(a).writeAsStringSync('changed elsewhere\n');
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(
      container.read(tabProvider).tabs.single.content,
      'changed elsewhere\n',
      reason: '恢复出来的标签页没有被监听，外部改动看不到',
    );
  });
}

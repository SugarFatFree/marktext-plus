import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:marktext_plus/services/file_service.dart';

/// Saving over a file that changed underneath the editor.
///
/// Auto-save is on by default with a five second delay, so this needs no
/// deliberate act by the reader: open a file, type, have something else
/// rewrite it — a git checkout, a sync client, another editor — and five
/// seconds later the editor writes over that change without a word.
void main() {
  late Directory dir;
  late String path;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('saveconflict');
    path = '${dir.path}/note.md';
    File(path).writeAsStringSync('original\n');
  });
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('a stamp taken at read time survives an unchanged file', () async {
    final stamp = await FileService.stampOf(path);
    expect(stamp, isNotNull);
    expect(await FileService.hasChangedSince(path, stamp), isFalse);
  });

  test('rewriting the file is noticed', () async {
    final stamp = await FileService.stampOf(path);
    // A different length, so the check does not depend on clock resolution.
    File(path).writeAsStringSync('changed by somebody else\n');
    expect(await FileService.hasChangedSince(path, stamp), isTrue);
  });

  test('a save that expects an unchanged file writes it', () async {
    final stamp = await FileService.stampOf(path);
    await FileService.saveDocumentIfUnchanged(path, 'mine\n',
        expect: stamp);
    expect(File(path).readAsStringSync(), 'mine\n');
  });

  test('a save refuses to overwrite a file that changed', () async {
    final stamp = await FileService.stampOf(path);
    File(path).writeAsStringSync('changed by somebody else\n');

    await expectLater(
      FileService.saveDocumentIfUnchanged(path, 'mine\n', expect: stamp),
      throwsA(isA<FileChangedOnDiskException>()),
    );
    expect(File(path).readAsStringSync(), 'changed by somebody else\n',
        reason: '别人的改动被覆盖了');
  });

  test('a save with no expectation writes regardless', () async {
    // "Overwrite" after being asked, and every save of a document that was
    // never read from disk.
    File(path).writeAsStringSync('changed\n');
    await FileService.saveDocument(path, 'mine\n');
    expect(File(path).readAsStringSync(), 'mine\n');
  });

  test('saving a file that does not exist yet is not a conflict', () async {
    final fresh = '${dir.path}/new.md';
    await FileService.saveDocumentIfUnchanged(fresh, 'hello\n',
        expect: await FileService.stampOf(fresh));
    expect(File(fresh).readAsStringSync(), 'hello\n');
  });

  group('a tab does not overwrite a file that changed underneath it', () {
    /// Opens [path] into a tab the way the application does, and waits for
    /// the stamp to be recorded.
    Future<(ProviderContainer, String)> openTab() async {
      final container = ProviderContainer(overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: dir.path),
            // Auto-save off: these tests drive the save paths directly, and a
            // timer firing in the middle would write for reasons of its own.
            AppConfig(autoSave: false),
          ),
        ),
      ]);
      addTearDown(container.dispose);
      final opened = await FileService().readFileWithLineEnding(path);
      container.read(tabProvider.notifier).addTab(TabInfo(
            id: 'tab',
            filePath: path,
            fileName: 'note.md',
            content: opened.content,
            lineEnding: opened.lineEnding,
            encoding: opened.encoding,
          ));
      await container.read(tabProvider.notifier).refreshDiskStamp('tab');
      return (container, 'tab');
    }

    TabInfo tabOf(ProviderContainer c) =>
        c.read(tabProvider).tabs.firstWhere((t) => t.id == 'tab');

    test('the stamp is recorded when the tab is opened', () async {
      final (container, _) = await openTab();
      expect(tabOf(container).diskStamp, isNotNull,
          reason: '没有记录磁盘戳，之后的检查等于没做');
    });

    test('overwriting on request writes and clears the conflict', () async {
      final (container, id) = await openTab();
      container.read(tabProvider.notifier).updateContent(id, 'mine\n');
      File(path).writeAsStringSync('theirs\n');

      final ok = await container.read(tabProvider.notifier).overwriteOnDisk(id);
      expect(ok, isTrue);
      expect(File(path).readAsStringSync(), 'mine\n');
      expect(tabOf(container).diskConflict, isFalse);
      expect(tabOf(container).isModified, isFalse);
    });

    test('reloading throws away the edits and takes what is on disk',
        () async {
      final (container, id) = await openTab();
      container.read(tabProvider.notifier).updateContent(id, 'mine\n');
      File(path).writeAsStringSync('theirs\n');

      final ok = await container.read(tabProvider.notifier).reloadFromDisk(id);
      expect(ok, isTrue);
      expect(tabOf(container).content, 'theirs\n');
      expect(tabOf(container).isModified, isFalse);
      expect(tabOf(container).diskConflict, isFalse);
      expect(File(path).readAsStringSync(), 'theirs\n');
    });

    test('after a save the next one compares against that write', () async {
      // Saving updates the stamp; without that every save after the first
      // would look like a conflict, since the editor itself changed the file.
      final (container, id) = await openTab();
      container.read(tabProvider.notifier).updateContent(id, 'first\n');
      expect(await container.read(tabProvider.notifier).overwriteOnDisk(id),
          isTrue);
      final stamp = tabOf(container).diskStamp;
      expect(stamp, isNotNull);
      expect(await FileService.hasChangedSince(path, stamp), isFalse,
          reason: '保存后没有更新戳，下一次保存会被误判为冲突');
    });
  });

  test('auto-save does not write over a file that changed underneath it',
      () async {
    // The case that needs no deliberate act by the reader. Auto-save is on by
    // default with a five second delay: open a file, type, have a git
    // checkout or a sync client rewrite it, and a few seconds later the
    // editor used to write over that change without a word.
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: dir.path),
          AppConfig(autoSave: true, autoSaveDelay: 20),
        ),
      ),
    ]);
    addTearDown(container.dispose);

    final opened = await FileService().readFileWithLineEnding(path);
    final notifier = container.read(tabProvider.notifier);
    notifier.addTab(TabInfo(
      id: 'tab',
      filePath: path,
      fileName: 'note.md',
      content: opened.content,
      lineEnding: opened.lineEnding,
      encoding: opened.encoding,
    ));
    await notifier.refreshDiskStamp('tab');

    // Somebody else rewrites the file, then the reader types.
    File(path).writeAsStringSync('changed by somebody else\n');
    notifier.updateContent('tab', 'mine\n');

    // Long enough for the auto-save timer to have fired and finished.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(File(path).readAsStringSync(), 'changed by somebody else\n',
        reason: '自动保存把别人的改动覆盖掉了');
    final tab =
        container.read(tabProvider).tabs.firstWhere((t) => t.id == 'tab');
    expect(tab.diskConflict, isTrue, reason: '没有把冲突记下来');
    expect(tab.isModified, isTrue, reason: '文件没写成，不该标记为已保存');
    expect(tab.content, 'mine\n', reason: '读者的编辑不该丢');
  });

  test('the control: with no conflict, that same auto-save does write',
      () async {
    // Without this the test above proves nothing — a file left unchanged
    // because the timer never fired looks exactly like one left unchanged
    // because the guard worked.
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: dir.path),
          AppConfig(autoSave: true, autoSaveDelay: 20),
        ),
      ),
    ]);
    addTearDown(container.dispose);

    final opened = await FileService().readFileWithLineEnding(path);
    final notifier = container.read(tabProvider.notifier);
    notifier.addTab(TabInfo(
      id: 'tab',
      filePath: path,
      fileName: 'note.md',
      content: opened.content,
      lineEnding: opened.lineEnding,
      encoding: opened.encoding,
    ));
    await notifier.refreshDiskStamp('tab');

    notifier.updateContent('tab', 'mine\n');
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(File(path).readAsStringSync(), 'mine\n',
        reason: '自动保存根本没触发，上一条测试就是空跑的');
    final tab =
        container.read(tabProvider).tabs.firstWhere((t) => t.id == 'tab');
    expect(tab.isModified, isFalse);
    expect(tab.diskConflict, isFalse);
  });
}

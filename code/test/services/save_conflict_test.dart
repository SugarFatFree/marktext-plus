import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/wait_for.dart';
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

  test('no stamp is not a conflict — it is no information', () async {
    // "The file did not exist when it was read" and "it was never read" are
    // both null, and neither is evidence of a change. Answering true made a
    // document with no stamp impossible to save, ever, while telling the
    // reader their file had changed underneath them.
    expect(await FileService.hasChangedSince(path, null), isFalse);
    await FileService.saveDocumentIfUnchanged(path, 'mine\n', expect: null);
    expect(File(path).readAsStringSync(), 'mine\n');
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
            // As every real call site does: the stamp arrives with the
            // content, not in a separate call afterwards.
            diskStamp: opened.stamp,
          ));
      return (container, 'tab');
    }

    TabInfo tabOf(ProviderContainer c) =>
        c.read(tabProvider).tabs.firstWhere((t) => t.id == 'tab');

    test('the stamp arrives with the content, not after it', () async {
      // It used to be taken by an unawaited call made after the tab existed,
      // which left a window in which the tab had a path and no stamp — and a
      // tab with no stamp cannot be saved at all, because "we never looked"
      // and "the file was not there" are the same answer to the check. The
      // window was short enough to pass here and long enough to fail on CI.
      final (container, _) = await openTab();
      expect(tabOf(container).diskStamp, isNotNull,
          reason: '没有记录磁盘戳，之后的检查等于没做');
    });

    test('reading a file hands back a stamp for it', () async {
      final opened = await FileService().readFileWithLineEnding(path);
      expect(opened.stamp, isNotNull);
      expect(await FileService.hasChangedSince(path, opened.stamp), isFalse);
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
      diskStamp: opened.stamp,
    ));

    // Somebody else rewrites the file, then the reader types.
    File(path).writeAsStringSync('changed by somebody else\n');
    notifier.updateContent('tab', 'mine\n');

    // Wait for the conflict to be recorded rather than for a chosen number
    // of milliseconds: the file staying as it is proves nothing until the
    // auto-save has actually run and declined to write it.
    await waitFor(() =>
        container.read(tabProvider).tabs.first.diskConflict);

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
      diskStamp: opened.stamp,
    ));

    notifier.updateContent('tab', 'mine\n');
    await waitFor(() => File(path).readAsStringSync() == 'mine\n');

    expect(File(path).readAsStringSync(), 'mine\n',
        reason: '自动保存根本没触发，上一条测试就是空跑的');
    final tab =
        container.read(tabProvider).tabs.firstWhere((t) => t.id == 'tab');
    expect(tab.isModified, isFalse);
    expect(tab.diskConflict, isFalse);
  });

  test('every tab built straight from a read carries the stamp', () {
    // A tab with no stamp has no baseline, so the check that stops a save
    // from writing over somebody else's change never fires for it — and the
    // tab looks completely ordinary. Six places build a TabInfo; the one
    // that opens files from a second instance was missed when the stamp was
    // introduced, so a document opened from the command line or a file
    // manager was unprotected.
    //
    // Tabs built empty and filled later by `loadTabContent` are exempt: the
    // stamp arrives there with the content. What is checked is a constructor
    // that already has the content in hand.
    final offenders = <String>[];
    for (final path in [
      'lib/providers/tab_provider.dart',
      'lib/ui/widgets/app_menu_bar.dart',
      'lib/ui/widgets/side_bar.dart',
      'lib/ui/screens/home_screen.dart',
      'lib/ui/editor/markdown_renderer.dart',
    ]) {
      final lines = File(path).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('TabInfo(')) continue;
        final end = (i + 16 < lines.length) ? i + 16 : lines.length;
        final body = lines.sublist(i, end).join('\n');
        // Only the ones that hand real content to the constructor.
        if (!body.contains('content: opened.content')) continue;
        if (!body.contains('diskStamp')) {
          offenders.add('$path:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: '这些标签页带着内容却没有磁盘戳，保存冲突检测对它们不生效');
  });

  test('every save of an existing document goes through the check', () {
    // Five places write a document. Two are meant to be unconditional —
    // Save As to a path just chosen, and the overwrite the reader asks for
    // after being told about the conflict — and the rest must compare.
    // Closing a tab was the one that did not, so answering "save" to the
    // close prompt wrote over somebody else's change while Ctrl+S on the
    // same document refused to.
    final unchecked = <String>[];
    for (final path in [
      'lib/providers/tab_provider.dart',
      'lib/ui/widgets/app_menu_bar.dart',
      'lib/ui/widgets/editor_tab_bar.dart',
    ]) {
      final lines = File(path).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('FileService.saveDocument(')) continue;
        // The two deliberate ones say so in the six lines above them.
        final from = i - 8 < 0 ? 0 : i - 8;
        final context = lines.sublist(from, i).join('\n');
        final deliberate = context.contains('Save As') ||
            context.contains('picker') ||
            context.contains('overwrite') ||
            context.contains('unconditionally');
        if (!deliberate) unchecked.add('$path:${i + 1}');
      }
    }
    expect(unchecked, isEmpty,
        reason: '这些地方直接写文件而不比对磁盘，会静默覆盖别人的改动');
  });
}

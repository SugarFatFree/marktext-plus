import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';

/// Closing a tab by mistake should not cost anything.
///
/// Every editor with tabs has this and this one did not: the file had to be
/// found again in the sidebar, or in Recent Files if it was there, or typed
/// into the open dialog.
///
/// What is kept is the **path**, not the text. Holding the content of ten
/// closed documents would undo the claim this editor makes about memory —
/// measured elsewhere at about 63 KB per rendered block — and the copy on
/// disk is what reopening should show anyway. A tab that was never saved has
/// no path, so it is not offered: closing a modified one already asks first,
/// and answering "don't save" is a decision, not a slip.
///
/// The recording hangs off the state setter, beside the undo histories and
/// the disk watches, for the reason written there: six ways of closing a tab
/// and one place they all pass through.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late ProviderContainer container;
  late TextEditingController controller;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('reopen_closed');
    container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: dir.path),
            AppConfig(autoSave: false),
          ),
        ),
      ],
    );
    controller = TextEditingController();
    container.read(editorProvider.notifier).setController(controller);
  });

  tearDown(() {
    controller.dispose();
    container.dispose();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  /// A real file, because reopening reads from disk.
  String write(String name, String body) {
    final file = File('${dir.path}/$name')..writeAsStringSync(body);
    return file.path;
  }

  TabInfo saved(String id, String path) =>
      TabInfo(id: id, filePath: path, fileName: path.split('/').last, content: 'x');

  TabInfo scratch(String id) =>
      TabInfo(id: id, filePath: null, fileName: '$id.md', content: 'x');

  TabNotifier tabs() => container.read(tabProvider.notifier);

  test('a closed document is remembered, newest first', () {
    final one = write('one.md', '# one');
    final two = write('two.md', '# two');
    tabs()
      ..addTab(saved('a', one))
      ..addTab(saved('b', two))
      ..removeTab('a')
      ..removeTab('b');

    expect(
      container.read(tabProvider).recentlyClosed.map((c) => c.filePath),
      [two, one],
    );
  });

  test('a tab that was never saved is not remembered', () {
    // There is nothing on disk to reopen, and keeping its text is the one
    // thing this must not do.
    tabs()
      ..addTab(scratch('a'))
      ..removeTab('a');
    expect(container.read(tabProvider).recentlyClosed, isEmpty);
  });

  test('closing the same document twice leaves one entry', () {
    final path = write('one.md', '# one');
    tabs()
      ..addTab(saved('a', path))
      ..removeTab('a')
      ..addTab(saved('b', path))
      ..removeTab('b');
    expect(container.read(tabProvider).recentlyClosed.length, 1);
  });

  test('the list is bounded', () {
    // Unbounded, this grows for as long as the session lasts. Each entry is
    // small, which is exactly the argument that stops anyone from bounding it.
    for (var i = 0; i < TabNotifier.closedTabsKept + 5; i++) {
      final path = write('f$i.md', '# $i');
      tabs()
        ..addTab(saved('t\$i', path))
        ..removeTab('t\$i');
    }
    expect(
      container.read(tabProvider).recentlyClosed.length,
      TabNotifier.closedTabsKept,
    );
  });

  test('closing several at once remembers every one of them', () {
    // "Close all" and the two "close others" go through the same setter, and
    // those three were the ones that used to skip the per-tab cleanup.
    final paths = [for (var i = 0; i < 3; i++) write('m$i.md', '# $i')];
    for (var i = 0; i < 3; i++) {
      tabs().addTab(saved('m$i', paths[i]));
    }
    tabs().closeAllTabs();
    expect(
      container.read(tabProvider).recentlyClosed.map((c) => c.filePath),
      paths.reversed,
      reason: '一次关掉三个时，最右边那个先回来——这是顺序，不只是集合',
    );
  });

  test('reopening puts the document back where it was, and forgets it', () async {
    final one = write('one.md', '# one');
    final two = write('two.md', '# two');
    final three = write('three.md', '# three');
    tabs()
      ..addTab(saved('a', one))
      ..addTab(saved('b', two))
      ..addTab(saved('c', three))
      ..removeTab('b');

    expect(await tabs().reopenLastClosedTab(), isTrue);

    final state = container.read(tabProvider);
    expect(state.tabs.map((t) => t.filePath), [one, two, three],
        reason: '应当回到它原来的位置，而不是追加到最后');
    expect(state.tabs[1].content, '# two',
        reason: '内容是从磁盘重新读的——关的时候没有留着它');
    expect(state.activeTabId, state.tabs[1].id);
    expect(state.recentlyClosed, isEmpty);
  });

  test('there is nothing to reopen when nothing was closed', () async {
    expect(await tabs().reopenLastClosedTab(), isFalse);
  });

  test('a document deleted since it was closed is dropped, not reopened', () async {
    final path = write('gone.md', '# gone');
    tabs()
      ..addTab(saved('a', path))
      ..removeTab('a');
    File(path).deleteSync();

    expect(await tabs().reopenLastClosedTab(), isFalse);
    expect(container.read(tabProvider).recentlyClosed, isEmpty,
        reason: '否则按第二次还是它，永远退不到上一个');
  });
}

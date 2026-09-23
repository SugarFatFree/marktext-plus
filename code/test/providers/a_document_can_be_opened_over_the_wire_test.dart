import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/mcp_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:marktext_plus/services/mcp_tools.dart';

/// The interface can open a document that is already on disk.
///
/// It could make one, write one, save one under a new name and close one, and
/// it could not **open** one — so it could never check its own work on a file,
/// and a whole class of defect could only be verified by asking the reader to
/// double-click something. The side bar list forgetting its files (BUG-496) was
/// one of those.
///
/// It goes through the same method a second launch uses rather than becoming a
/// fifth way to open a path. That method is also where the reader's preference
/// about new windows lives; this sets it aside, because a document in another
/// window is in another process that the port this request arrived on cannot
/// reach, and says so when it does.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late ProviderContainer container;

  setUp(() => dir = Directory.systemTemp.createTempSync('mcp_open'));
  tearDown(() {
    container.dispose();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  ProviderContainer boot({FileOpenBehavior? behaviour}) {
    container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: dir.path),
            AppConfig(
              autoSave: false,
              fileOpenBehavior: behaviour ?? FileOpenBehavior.existingWindow,
            ),
          ),
        ),
      ],
    );
    return container;
  }

  Future<McpOutcome> open(ProviderContainer c, Map<String, Object?> args) =>
      c.read(mcpProvider.notifier).performAction('open_file', args);

  String write(String name, String body) {
    final file = File('${dir.path}/$name')..writeAsStringSync(body);
    return file.path;
  }

  test('with no path it says what it needs', () async {
    final outcome = await open(boot(), const {});
    expect(outcome.ok, isFalse);
    expect(outcome.said, contains('path'));
  });

  test('a relative path is refused, as it is for saving', () async {
    final outcome = await open(boot(), const {'path': 'notes.md'});
    expect(outcome.ok, isFalse);
    expect(outcome.said, contains('relative'));
  });

  test('a path with nothing at it is told apart from one that will not read',
      () async {
    // Both refusals name the file, so asserting the name alone cannot tell
    // them apart — and the first version of this test could not: taking the
    // existence check out left it green, because an unreadable path falls
    // through to "could not be read" and that also names the file.
    //
    // They are different things to be told. "Nothing is there" is a typo in
    // the path; "there and unreadable" is permissions, or a directory, or a
    // file something else is holding.
    final outcome = await open(boot(), {'path': '${dir.path}/absent.md'});
    expect(outcome.ok, isFalse);
    expect(outcome.said, contains('absent.md'));
    expect(outcome.said, contains('nothing at'));
    expect(outcome.said, isNot(contains('could not be read')));
  });

  test('a document is opened, and the answer says how much of it there is',
      () async {
    final path = write('notes.md', '# notes\n\nbody\n');
    final c = boot();

    final outcome = await open(c, {'path': path});

    expect(outcome.ok, isTrue, reason: outcome.said);
    expect(outcome.said, contains('notes.md'));
    expect(outcome.said, contains('14'), reason: '答复要说出读到了多少——这一篇正好 14 个字符');
    final tab = c.read(tabProvider).tabs.single;
    expect(tab.filePath, path);
    expect(tab.content, '# notes\n\nbody\n');
    expect(tab.isModified, isFalse);
    expect(c.read(tabProvider).activeTabId, tab.id);
  });

  test('one already open is brought forward, not opened twice', () async {
    final path = write('twice.md', 'x\n');
    final c = boot();
    c.read(tabProvider.notifier).addTab(
          TabInfo(id: 'other', fileName: 'other.md', content: 'y'),
        );
    await open(c, {'path': path});
    final firstId = c.read(tabProvider).tabs.last.id;
    c.read(tabProvider.notifier).setActiveTab('other');

    final outcome = await open(c, {'path': path});

    expect(outcome.ok, isTrue, reason: outcome.said);
    expect(outcome.said, contains('already open'));
    expect(c.read(tabProvider).tabs.where((t) => t.filePath == path), hasLength(1));
    expect(c.read(tabProvider).activeTabId, firstId,
        reason: '已经开着的那一个要被带到前面来');
  });

  test('it records the document in Recent Files, like every other way in',
      () async {
    final path = write('recent.md', 'x\n');
    final c = boot();
    await open(c, {'path': path});
    expect(c.read(settingsProvider).recentFiles, contains(path));
  });

  test('the new-window preference is set aside here, and the answer says so',
      () async {
    // Honouring it would put the document in another process, and this port
    // cannot see into that one: "opened" would be true and useless.
    final path = write('elsewhere.md', 'x\n');
    final c = boot(behaviour: FileOpenBehavior.newWindow);

    final outcome = await open(c, {'path': path});

    expect(outcome.ok, isTrue, reason: outcome.said);
    expect(c.read(tabProvider).tabs.single.filePath, path);
    expect(outcome.said.toLowerCase(), contains('new window'));
  });
}

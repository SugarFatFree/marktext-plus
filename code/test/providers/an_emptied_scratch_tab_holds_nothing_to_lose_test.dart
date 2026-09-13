import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/mcp_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';

/// An empty tab that was never saved holds nothing to lose.
///
/// Found from the automation interface, which could open a tab and write to it
/// and then had no way to be rid of one: `close_tab` refuses unsaved work —
/// deliberately, since nothing on that side can press Save — and clearing the
/// text left the tab "modified" all the same. A scratch tab an agent made could
/// only be closed by a person, which is the one thing that interface is for not
/// needing.
///
/// The same applies to the reader: every other editor closes an untitled
/// document you emptied without asking about it.
///
/// Not fixed by comparing against the file on disk. That means keeping a second
/// copy of the document, and this editor is for large ones.
void main() {
  late Directory configDir;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('empty_scratch_test');
  });

  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  ProviderContainer boot() {
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  TabInfo? only(ProviderContainer c, String id) =>
      c.read(tabProvider).tabs.where((t) => t.id == id).firstOrNull;

  group('the tab itself', () {
    test('typing into a new tab marks it modified', () {
      final c = boot();
      c.read(tabProvider.notifier).addTab(TabInfo(id: 'scratch', fileName: 'x.md'));
      c.read(tabProvider.notifier).updateContent('scratch', 'something');

      expect(only(c, 'scratch')!.isModified, isTrue);
    });

    test('clearing it again leaves nothing to lose', () {
      final c = boot();
      c.read(tabProvider.notifier).addTab(TabInfo(id: 'scratch', fileName: 'x.md'));
      c.read(tabProvider.notifier).updateContent('scratch', 'something');
      c.read(tabProvider.notifier).updateContent('scratch', '');

      expect(only(c, 'scratch')!.isModified, isFalse);
    });

    test('emptying a written document is an edit, not an absence of one', () {
      final c = boot();
      final file = File('${configDir.path}/written.md')
        ..writeAsStringSync('a paragraph\n');
      c.read(tabProvider.notifier).addTab(
            TabInfo(id: 'real', fileName: 'written.md', filePath: file.path),
          );
      c.read(tabProvider.notifier).updateContent('real', '');

      expect(only(c, 'real')!.isModified, isTrue,
          reason: '删光一份写过的文档是改动，不是「没有改动」');
      expect(file.readAsStringSync(), 'a paragraph\n',
          reason: '这条断言在的意思是：这个改动没有顺手写盘');
    });
  });

  group('over the automation interface', () {
    test('it can be rid of a scratch tab it made', () async {
      final c = boot();
      final made = await c
          .read(mcpProvider.notifier)
          .performAction('new_tab', {'name': 'scratch.md'});
      expect(made.ok, isTrue, reason: made.said);
      final id = c.read(tabProvider).tabs.last.id;

      await c
          .read(mcpProvider.notifier)
          .performAction('set_content', {'tabId': id, 'content': 'draft'});
      final refused = await c
          .read(mcpProvider.notifier)
          .performAction('close_tab', {'tabId': id});
      expect(refused.ok, isFalse,
          reason: '写过东西的标签页仍然不许悄悄丢掉——那条守卫是故意的');

      await c
          .read(mcpProvider.notifier)
          .performAction('set_content', {'tabId': id, 'content': ''});
      final closed = await c
          .read(mcpProvider.notifier)
          .performAction('close_tab', {'tabId': id});

      expect(closed.ok, isTrue, reason: closed.said);
      expect(only(c, id), isNull);
    });
  });
}

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/mcp_provider.dart';
import 'package:marktext_plus/services/file_service.dart';
import 'package:marktext_plus/services/mcp_tools.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';

/// What `control` reports is what actually happened.
///
/// `mcp_action_test` covers the plumbing — the enum, the wire names, the
/// schema generated from them, and how an outcome becomes a protocol answer.
/// It hands the toolset a stub, so the switch that carries the actions out had
/// never been run by anything.
///
/// Two of its branches were fixed once: activating a tab that does not exist
/// used to be written into the state and reported as a switch that happened,
/// and closing a pane that was not open reported a close. Their siblings in
/// the same switch were left as they were.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('mcp_control'));
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

  TabInfo aTab(String id) => TabInfo(id: id, fileName: '$id.md', content: 'x');

  group('answering a plugin question from the automation interface', () {
    // Measured before it was fixed: an MCP call asking the shipped plugin to
    // translate a document, with `answer: "English"` passed, sat for four
    // minutes and returned nothing. The chip was selected and the word was in
    // the box; the command was waiting for a human to press Confirm, and
    // there is no human on this end of the socket.
    //
    // `open_panel` had taken an answer since it was written. `run_plugin_command`
    // offered the same parameter in the same schema and never read it — the
    // shape this project keeps finding, an argument the interface advertises
    // and one of its actions drops.

    test('run_plugin_command hands the answer to the command', () async {
      final container = boot();
      String? taken;
      var calls = 0;
      container.read(mcpProvider.notifier).runPluginCommand =
          (pluginId, command, answer) async {
        calls++;
        taken = answer;
        return mcpDid('ran $command');
      };

      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('run_plugin_command', {
        'pluginId': 'com.example.demo',
        'command': 'translate.document',
        'answer': 'English',
      });

      expect(outcome.ok, isTrue);
      expect(calls, 1);
      expect(taken, 'English',
          reason: '答案没有交下去，命令就会停在对话框上等一个不存在的人');
    });

    test('and null when none was given, which is a reader being asked',
        () async {
      final container = boot();
      String? taken = 'unset';
      container.read(mcpProvider.notifier).runPluginCommand =
          (pluginId, command, answer) async {
        taken = answer;
        return mcpDid('ran $command');
      };

      await container.read(mcpProvider.notifier).performAction(
        'run_plugin_command',
        {'pluginId': 'com.example.demo', 'command': 'ai.proofread'},
      );

      expect(taken, isNull,
          reason: '没给答案时要照旧问人，而不是替他答一个空字符串');
    });
  });

  group('saving a tab', () {
    // `close_tab` refuses a tab with unsaved work, because nothing on this side
    // can press Save. That left an agent that had written to a tab unable
    // either to keep what it wrote or to tidy the tab away — so the missing
    // piece was saving. Never a "discard anyway" flag: the explicit decision an
    // automated caller can be asked for is "keep this".
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('mcp_save'));
    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    Future<(ProviderContainer, File)> openAFile(String text) async {
      final file = File('${dir.path}/note.md')..writeAsStringSync(text);
      final container = boot();
      container.read(tabProvider.notifier).addTab(TabInfo(
            id: 'one',
            filePath: file.path,
            fileName: 'note.md',
            content: text,
            diskStamp: await FileService.stampOf(file.path),
          ));
      return (container, file);
    }

    test('writes what the tab holds, and says so', () async {
      final (container, file) = await openAFile('first\n');
      await container
          .read(mcpProvider.notifier)
          .performAction('set_content', {'tabId': 'one', 'content': 'second\n'});

      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('save_tab', {'tabId': 'one'});

      expect(outcome.ok, isTrue, reason: outcome.said);
      expect(file.readAsStringSync(), 'second\n');
      expect(container.read(tabProvider).tabs.single.isModified, isFalse);
      expect(outcome.said, contains('note.md'));
    });

    test('and then the tab can be closed, which is the point', () async {
      // The loop this exists for: make a tab, write to it, keep it, tidy up.
      final (container, _) = await openAFile('first\n');
      await container
          .read(mcpProvider.notifier)
          .performAction('set_content', {'tabId': 'one', 'content': 'second\n'});
      expect(
        (await container
                .read(mcpProvider.notifier)
                .performAction('close_tab', {'tabId': 'one'}))
            .ok,
        isFalse,
        reason: '未保存时就该拒绝——这是 BUG-467，不能被这次改动放松',
      );

      await container
          .read(mcpProvider.notifier)
          .performAction('save_tab', {'tabId': 'one'});
      final closed = await container
          .read(mcpProvider.notifier)
          .performAction('close_tab', {'tabId': 'one'});

      expect(closed.ok, isTrue, reason: closed.said);
      expect(container.read(tabProvider).tabs, isEmpty);
    });

    test('a tab made over the socket can be given a file', () async {
      // The corner automation can walk into and not out of: `new_tab` names a
      // tab and gives it no file, so a save had nothing to write to, a close
      // was refused because the tab was modified, and `update_app` was refused
      // because something was unsaved. Three correct refusals adding up to a
      // tab nobody could be rid of — met on a real machine, blocking the very
      // update this interface exists for.
      final container = boot();
      container.read(tabProvider.notifier).addTab(aTab('scratch'));
      container.read(tabProvider.notifier).updateContent('scratch', 'typed\n');
      final to = '${dir.path}/kept.md';

      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('save_tab', {'tabId': 'scratch', 'path': to});

      expect(outcome.ok, isTrue, reason: outcome.said);
      expect(File(to).readAsStringSync(), 'typed\n');
      final tab = container.read(tabProvider).tabs.single;
      expect(tab.filePath, to, reason: '存过之后它应当就是那个文件了');
      expect(tab.isModified, isFalse);

      // And now it can be tidied away, which was the point.
      expect(
        (await container
                .read(mcpProvider.notifier)
                .performAction('close_tab', {'tabId': 'scratch'}))
            .ok,
        isTrue,
      );
    });

    test('will not put it where something already is', () async {
      final container = boot();
      container.read(tabProvider.notifier).addTab(aTab('scratch'));
      container.read(tabProvider.notifier).updateContent('scratch', 'mine\n');
      final taken = File('${dir.path}/taken.md')
        ..writeAsStringSync('somebody else\n');

      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('save_tab', {'tabId': 'scratch', 'path': taken.path});

      expect(outcome.ok, isFalse);
      expect(taken.readAsStringSync(), 'somebody else\n',
          reason: '这一端没有选择框可以问「要替换吗」');
    });

    test('will not take a relative path', () async {
      final container = boot();
      container.read(tabProvider.notifier).addTab(aTab('scratch'));
      container.read(tabProvider.notifier).updateContent('scratch', 'mine\n');

      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('save_tab', {'tabId': 'scratch', 'path': 'kept.md'});

      expect(outcome.ok, isFalse,
          reason: '相对于什么？调用方看不见编辑器的工作目录');
    });

    test('will not move a document the reader opened', () async {
      final (container, file) = await openAFile('first\n');
      final outcome = await container.read(mcpProvider.notifier).performAction(
          'save_tab', {'tabId': 'one', 'path': '${dir.path}/elsewhere.md'});

      expect(outcome.ok, isFalse);
      expect(File('${dir.path}/elsewhere.md').existsSync(), isFalse);
      expect(file.existsSync(), isTrue);
    });

    test('refuses a tab with no file behind it', () async {
      final container = boot();
      container.read(tabProvider.notifier).addTab(aTab('scratch'));
      container.read(tabProvider.notifier).updateContent('scratch', 'typed\n');

      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('save_tab', {'tabId': 'scratch'});

      expect(outcome.ok, isFalse);
      expect(outcome.said, contains('scratch.md'),
          reason: '要说出是哪个标签页，不然调用方无从下手');
      expect(container.read(tabProvider).tabs.single.isModified, isTrue);
    });

    test('refuses when the file changed underneath, rather than deciding',
        () async {
      final (container, file) = await openAFile('first\n');
      await container
          .read(mcpProvider.notifier)
          .performAction('set_content', {'tabId': 'one', 'content': 'mine\n'});
      file.writeAsStringSync('somebody else got here\n');

      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('save_tab', {'tabId': 'one'});

      expect(outcome.ok, isFalse);
      expect(file.readAsStringSync(), 'somebody else got here\n',
          reason: '自动化这一端不该替读者决定哪一份留下');
      expect(container.read(tabProvider).tabs.single.content, 'mine\n');
    });

    test('an unmodified tab is not an error', () async {
      final (container, _) = await openAFile('first\n');
      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('save_tab', {'tabId': 'one'});
      expect(outcome.ok, isTrue);
      expect(outcome.said, contains('nothing unsaved'));
    });
  });

  group('closing a tab', () {
    test('closes it, and says so', () async {
      final container = boot();
      container.read(tabProvider.notifier).addTab(aTab('one'));

      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('close_tab', {'tabId': 'one'});

      expect(outcome.ok, isTrue);
      expect(container.read(tabProvider).tabs, isEmpty);
    });

    test('refuses one with unsaved work, and leaves it open', () async {
      // Every way a person closes a tab asks first — the tab bar's button, the
      // File menu, the side bar, the window's own close button. This was the
      // one way that did not: it threw the work away and reported a close.
      // `update_app` in this same switch already refuses for exactly this
      // reason, and says why: nothing on this side can press Save.
      final container = boot();
      container.read(tabProvider.notifier).addTab(aTab('one'));
      container.read(tabProvider.notifier).updateContent('one', 'edited\n');
      expect(container.read(tabProvider).tabs.single.isModified, isTrue,
          reason: '这个用例靠「已修改」成立，先确认它真的被标上了');

      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('close_tab', {'tabId': 'one'});

      expect(outcome.ok, isFalse, reason: '未保存的内容被不声不响地丢掉了');
      expect(outcome.said, contains('one.md'),
          reason: '要说出是哪个标签页，不然调用方无从下手');
      expect(container.read(tabProvider).tabs, hasLength(1));
      expect(container.read(tabProvider).tabs.single.content, 'edited\n');
    });

    test('a tab with no file behind it is not an exception', () async {
      // Auto-save skips a tab with no path entirely, so its contents exist
      // nowhere but in the tab. The single-tab path says this in its own doc
      // comment; the automation interface has to agree.
      final container = boot();
      container.read(tabProvider.notifier).addTab(
            TabInfo(id: 'scratch', fileName: 'Untitled', content: ''),
          );
      container.read(tabProvider.notifier).updateContent('scratch', 'typed\n');

      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('close_tab', {'tabId': 'scratch'});

      expect(outcome.ok, isFalse);
      expect(container.read(tabProvider).tabs, hasLength(1));
    });

    test('refuses a tab that is not open, rather than reporting a close', () async {
      final container = boot();
      container.read(tabProvider.notifier).addTab(aTab('one'));

      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('close_tab', {'tabId': 'nosuch'});

      expect(
        outcome.ok,
        isFalse,
        reason: '没有这个标签，却回报「closed tab nosuch」',
      );
      expect(outcome.said, contains('nosuch'));
      expect(container.read(tabProvider).tabs, hasLength(1));
    });
  });

  group('writing to a tab', () {
    test('writes it, and says so', () async {
      final container = boot();
      container.read(tabProvider.notifier).addTab(aTab('one'));

      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('set_content', {'tabId': 'one', 'content': 'hello'});

      expect(outcome.ok, isTrue);
      expect(container.read(tabProvider).tabs.single.content, 'hello');
    });

    test('refuses a tab that is not open, rather than reporting a write', () async {
      final container = boot();
      container.read(tabProvider.notifier).addTab(aTab('one'));

      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('set_content', {'tabId': 'nosuch', 'content': 'hello'});

      expect(
        outcome.ok,
        isFalse,
        reason: '没有这个标签，却回报「wrote 5 characters to nosuch」',
      );
      expect(container.read(tabProvider).tabs.single.content, 'x');
    });
  });

  group('the branches that were already honest', () {
    test('activating a tab that is not open is refused', () async {
      final container = boot();
      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('activate_tab', {'tabId': 'nosuch'});
      expect(outcome.ok, isFalse);
    });

    test('activating one that is open is done', () async {
      final container = boot();
      container.read(tabProvider.notifier).addTab(aTab('one'));
      container.read(tabProvider.notifier).addTab(aTab('two'));
      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('activate_tab', {'tabId': 'one'});
      expect(outcome.ok, isTrue);
      expect(container.read(tabProvider).activeTabId, 'one');
    });
  });

  group('the rest of the switch', () {
    test('a new tab is opened and named', () async {
      final container = boot();
      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('new_tab', {'path': 'note.md', 'content': 'hi'});

      expect(outcome.ok, isTrue);
      final tabs = container.read(tabProvider).tabs;
      expect(tabs, hasLength(1));
      expect(tabs.single.content, 'hi');
    });

    test('the view mode is changed, and an unknown one refused', () async {
      final container = boot();
      final good = await container
          .read(mcpProvider.notifier)
          .performAction('set_view_mode', {'mode': 'preview'});
      expect(good.ok, isTrue);
      expect(container.read(settingsProvider).editMode, EditMode.preview);

      final bad = await container
          .read(mcpProvider.notifier)
          .performAction('set_view_mode', {'mode': 'sideways'});
      expect(bad.ok, isFalse);
      expect(
        container.read(settingsProvider).editMode,
        EditMode.preview,
        reason: '被拒绝的请求不该改变任何东西',
      );
    });

    test('closing a pane that was never open is refused', () async {
      final container = boot();
      container.read(tabProvider.notifier).addTab(aTab('one'));
      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('close_pane', {'slot': 'right'});
      expect(outcome.ok, isFalse);
    });

    test('install_plugin with no plugin named is refused before any network',
        () async {
      // The branch, not the decision — `install_plugin_over_mcp_test` covers
      // which entry a name chooses. What matters here is that a call with the
      // field left out comes back without having asked GitHub anything: this
      // test runs where there is no network, and a version that read the
      // catalogue first would hang for the timeout and then blame the network
      // for a mistake the caller made.
      final container = boot();
      final outcome =
          await container.read(mcpProvider.notifier).performAction(
        'install_plugin',
        <String, dynamic>{},
      ).timeout(const Duration(seconds: 5));
      expect(outcome.ok, isFalse);
      expect(outcome.said, 'no pluginId given');
    });

    test('update_app refuses a source it does not have, before any network',
        () async {
      final container = boot();
      final outcome =
          await container.read(mcpProvider.notifier).performAction(
        'update_app',
        {'source': 'somewhere-else'},
      ).timeout(const Duration(seconds: 5));
      expect(outcome.ok, isFalse);
      expect(outcome.said, contains('somewhere-else'));
      // The two it does have, named in the refusal: a caller who guessed
      // wrong should not have to read the schema to find out what to guess
      // next.
      expect(outcome.said, contains('release'));
      expect(outcome.said, contains('ci'));
    });

    test('a CI build with no token is refused rather than tried', () async {
      // Artifacts are not public. Without this the call reaches GitHub, is
      // told 404, and reports that the commit was never built — which sends
      // whoever reads it looking at CI instead of at the missing token.
      final container = boot();
      final outcome =
          await container.read(mcpProvider.notifier).performAction(
        'update_app',
        {'source': 'ci', 'ref': 'abc1234'},
      ).timeout(const Duration(seconds: 20));
      expect(outcome.ok, isFalse);
      expect(outcome.said, contains('token'));
    });

    test('an update is refused while a tab has unsaved work in it', () async {
      // The failure this prevents is silent and total: `/CLOSEAPPLICATIONS`
      // ends the process through the Restart Manager, which asks and then
      // stops waiting, and the editor comes back a version newer with the
      // document gone. Nothing downstream could report it.
      //
      // It answers without a network round trip, which is what makes it
      // testable here — and what stops the refusal from arriving late and
      // looking like GitHub was unreachable.
      final container = boot();
      container.read(tabProvider.notifier).addTab(
            TabInfo(id: 'a', fileName: 'notes.md', content: 'x', isModified: true),
          );
      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('update_app', {'source': 'release'})
          .timeout(const Duration(seconds: 5));
      expect(outcome.ok, isFalse);
      expect(outcome.said, contains('notes.md'));
    });

    test('a dry run still answers with unsaved work open', () async {
      // Asking what would be installed changes nothing. Refusing that too
      // would mean the one call that is safe to make at any time is the one
      // an open document blocks.
      final container = boot();
      container.read(tabProvider.notifier).addTab(
            TabInfo(id: 'a', fileName: 'notes.md', content: 'x', isModified: true),
          );
      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('update_app', {'source': 'ci', 'dryRun': true});
      // No token, so it refuses for that reason — and the point is that the
      // sentence is about the token, not about the open document.
      expect(outcome.said, isNot(contains('notes.md')));
    });

    test('an action nothing implements is refused', () async {
      final container = boot();
      final outcome = await container
          .read(mcpProvider.notifier)
          .performAction('open_file', {'path': '/tmp/x.md'});
      expect(outcome.ok, isFalse);
      expect(outcome.said, contains('open_file'));
    });
  });
}

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/mcp_provider.dart';
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

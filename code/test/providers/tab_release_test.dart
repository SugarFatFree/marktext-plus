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

/// What a closed tab leaves behind.
///
/// Closing one tab dropped its undo history and cancelled its pending
/// auto-save; the three ways of closing several at once — others, to the
/// right, all — did neither, so their histories stayed in memory for the rest
/// of the session. The release now hangs off the state change itself, which
/// is where this file already keeps the watch set, so every way of closing a
/// tab gets it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory configDir;
  late ProviderContainer container;
  late TextEditingController controller;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('tab_release');
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
    controller = TextEditingController();
    container.read(editorProvider.notifier).setController(controller);
  });

  tearDown(() {
    controller.dispose();
    container.dispose();
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  TabInfo tab(String id) =>
      TabInfo(id: id, filePath: null, fileName: '$id.md', content: id);

  /// Opens three tabs, each with something to undo.
  void openThreeWithHistory() {
    final tabs = container.read(tabProvider.notifier);
    final editor = container.read(editorProvider.notifier);
    for (final id in ['a', 'b', 'c']) {
      tabs.addTab(tab(id));
      editor
        ..setHistoryTab(id)
        ..pushHistory('$id one')
        ..pushHistory('$id two');
    }
  }

  /// Whether [id] still has anything to undo.
  bool hasHistory(String id) {
    final editor = container.read(editorProvider.notifier);
    editor.setHistoryTab(id);
    controller.text = '$id two';
    editor.undo();
    return controller.text != '$id two';
  }

  test('closing one tab lets go of its history', () {
    openThreeWithHistory();

    container.read(tabProvider.notifier).removeTab('b');

    expect(hasHistory('b'), isFalse);
    expect(hasHistory('a'), isTrue, reason: '别的标签页的历史被牵连了');
  });

  test('closing the others lets go of theirs', () {
    openThreeWithHistory();

    container.read(tabProvider.notifier).closeOtherTabs('b');

    expect(hasHistory('a'), isFalse);
    expect(hasHistory('c'), isFalse);
    expect(hasHistory('b'), isTrue, reason: '留下的那个不该被清');
  });

  test('closing to the right lets go of those to the right', () {
    openThreeWithHistory();

    container.read(tabProvider.notifier).closeTabsToRight('a');

    expect(hasHistory('b'), isFalse);
    expect(hasHistory('c'), isFalse);
    expect(hasHistory('a'), isTrue);
  });

  test('closing all lets go of every one', () {
    openThreeWithHistory();

    container.read(tabProvider.notifier).closeAllTabs();

    for (final id in ['a', 'b', 'c']) {
      expect(hasHistory(id), isFalse, reason: '$id 的历史还留着');
    }
  });

  test('reordering keeps every history', () {
    // Nothing closed, so nothing may be released.
    openThreeWithHistory();

    container.read(tabProvider.notifier).reorderTabs(0, 2);

    for (final id in ['a', 'b', 'c']) {
      expect(hasHistory(id), isTrue, reason: '$id 的历史在重排时丢了');
    }
  });
}

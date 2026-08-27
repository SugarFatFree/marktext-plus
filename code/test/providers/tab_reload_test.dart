import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';

/// The watcher debounces filesystem notifications, and the notifications
/// themselves are asynchronous, so each check waits rather than asserting
/// immediately.
Future<void> settle() =>
    Future<void>.delayed(const Duration(milliseconds: 900));

void main() {
  // TabNotifier reaches for settings, which reads a config file.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late File document;
  late ProviderContainer container;

  setUp(() {
    root = Directory.systemTemp.createTempSync('tab_reload_');
    document = File('${root.path}/note.md')..writeAsStringSync('one');
    container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: root.path),
            // Auto-save would write the tab back over the change under test.
            AppConfig(autoSave: false),
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  void openDocument() {
    container
        .read(tabProvider.notifier)
        .addTab(
          TabInfo(
            id: 'tab-1',
            filePath: document.path,
            fileName: 'note.md',
            content: 'one',
          ),
        );
  }

  String contentOf() => container.read(tabProvider).tabs.single.content;

  test('a clean document reloads when the file changes on disk', () async {
    openDocument();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    document.writeAsStringSync('two');
    await settle();

    expect(contentOf(), 'two');
  });

  test('the reload bumps the revision so the editors adopt it', () async {
    openDocument();
    final before = container.read(tabProvider).tabs.single.externalRevision;
    await Future<void>.delayed(const Duration(milliseconds: 200));

    document.writeAsStringSync('two');
    await settle();

    expect(
      container.read(tabProvider).tabs.single.externalRevision,
      greaterThan(before),
      reason: 'the source editor ignores a content change without one',
    );
  });

  test('a document with unsaved edits is left alone', () async {
    openDocument();
    container.read(tabProvider.notifier).updateContent('tab-1', 'my own work');
    await Future<void>.delayed(const Duration(milliseconds: 200));

    document.writeAsStringSync('two');
    await settle();

    expect(contentOf(), 'my own work');
    expect(container.read(tabProvider).tabs.single.isModified, isTrue);
  });

  test('a closed document is no longer watched', () async {
    openDocument();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    container.read(tabProvider.notifier).removeTab('tab-1');

    document.writeAsStringSync('two');
    await settle();

    expect(container.read(tabProvider).tabs, isEmpty);
  });

  test('a file rewritten with the same text changes nothing', () async {
    openDocument();
    final before = container.read(tabProvider).tabs.single.externalRevision;
    await Future<void>.delayed(const Duration(milliseconds: 200));

    document.writeAsStringSync('one');
    await settle();

    expect(container.read(tabProvider).tabs.single.externalRevision, before);
  });
}

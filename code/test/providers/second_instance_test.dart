import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';

/// Launching the program while it is already running.
///
/// The window was never brought forward: with a file, the file opened into a
/// tab behind whatever the reader was looking at; without one — clicking the
/// shortcut again — the handler returned before doing anything. Both read as
/// the double click having been ignored. The window call itself belongs to the
/// platform layer, so what is checked here is the answer this method gives it:
/// whether the files were taken by *this* window.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late ProviderContainer container;

  setUp(() {
    root = Directory.systemTemp.createTempSync('second_instance_');
    container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: root.path),
            AppConfig(autoSave: false),
          ),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  File write(String name, String text) =>
      File('${root.path}/$name')..writeAsStringSync(text);

  test('a file opens here, and says so', () async {
    final note = write('note.md', 'hello');
    final notifier = container.read(tabProvider.notifier);

    final openedHere = await notifier.openFilesFromSecondInstance([note.path]);

    expect(openedHere, isTrue,
        reason: '返回 false 会让调用方以为文件去了新窗口，于是不唤起本窗口');
    final tabs = container.read(tabProvider).tabs;
    expect(tabs.where((t) => t.filePath == note.path), hasLength(1));
    expect(tabs.last.content, 'hello');
  });

  test('a file that is already open is activated rather than opened twice',
      () async {
    final note = write('note.md', 'hello');
    final notifier = container.read(tabProvider.notifier);

    await notifier.openFilesFromSecondInstance([note.path]);
    final firstId =
        container.read(tabProvider).tabs.firstWhere((t) => t.filePath == note.path).id;

    final openedHere = await notifier.openFilesFromSecondInstance([note.path]);

    expect(openedHere, isTrue);
    final state = container.read(tabProvider);
    expect(state.tabs.where((t) => t.filePath == note.path), hasLength(1),
        reason: '同一个文件被打开了两次');
    expect(state.activeTabId, firstId,
        reason: '已经打开的文件应该被切到前面，而不是原地不动');
  });

  test('an unreadable path does not stop the others', () async {
    final good = write('good.md', 'text');
    final notifier = container.read(tabProvider.notifier);

    final openedHere = await notifier.openFilesFromSecondInstance(
      ['${root.path}/gone.md', good.path],
    );

    expect(openedHere, isTrue);
    expect(
      container.read(tabProvider).tabs.where((t) => t.filePath == good.path),
      hasLength(1),
    );
  });
}

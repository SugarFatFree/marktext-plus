import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';

/// The side bar's list of files outlives opening another one.
///
/// Reported from a real machine: open a document, close the window, open a
/// different document — and the side bar has forgotten the first. The list was
/// not failing to restore. It was being **overwritten before it was read**.
///
/// On a launch that carries a document — a double-click in the file manager —
/// the screen opened that document first and restored the side bar
/// afterwards. Adding a tab writes the side bar's list to the config, and at
/// that moment the list held only the document just opened, so the saved one
/// went to disk as `[the new file]`. The restore then read exactly what it had
/// just destroyed.
///
/// Two things are held here. The order is one of them, but order is a fragile
/// thing to rely on — so the list also refuses to be written until it has been
/// read, which makes the overwrite impossible rather than merely unlikely.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late ProviderContainer container;

  setUp(() => dir = Directory.systemTemp.createTempSync('sidebar_list'));
  tearDown(() {
    container.dispose();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  /// A container whose config already lists [saved], as it would after a
  /// session that had those files in the side bar.
  ProviderContainer boot(List<String> saved) {
    container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: dir.path),
            AppConfig(sideBarOpenedFiles: saved, autoSave: false),
          ),
        ),
      ],
    );
    return container;
  }

  String write(String name) {
    final file = File('${dir.path}/$name')..writeAsStringSync('# $name');
    return file.path;
  }

  test('opening a document before the list is read does not wipe it', () async {
    // Exactly the reported sequence, at the layer where it goes wrong: the
    // document that came in on the command line is added before anything has
    // restored the side bar.
    final first = write('first.md');
    final second = write('second.md');
    final c = boot([first]);

    c.read(tabProvider.notifier).addTab(
          TabInfo(id: 'b', filePath: second, fileName: 'second.md', content: ''),
        );

    expect(
      c.read(settingsProvider).sideBarOpenedFiles,
      [first],
      reason: '侧栏列表还没被读过，这时写回去就等于把它擦掉',
    );
  });

  test('once it has been read, opening a document adds to it', () async {
    final first = write('first.md');
    final second = write('second.md');
    final c = boot([first]);

    c.read(tabProvider.notifier)
      ..restoreOpenedFiles([first])
      ..addTab(
        TabInfo(id: 'b', filePath: second, fileName: 'second.md', content: ''),
      );

    expect(
      c.read(settingsProvider).sideBarOpenedFiles,
      [first, second],
      reason: '读过之后就该正常追加，不能把守卫做成「永远不写」',
    );
    expect(
      c.read(tabProvider).openedFiles.map((f) => f.filePath),
      [first, second],
    );
  });

  test('a restore that finds nothing still opens the gate', () async {
    // The trap in a guard like this: a first run has nothing saved, so the
    // restore has nothing to put back — and if that left the list unreadable
    // for ever, nothing would be written again for the life of the process.
    final only = write('only.md');
    final c = boot(const []);

    c.read(tabProvider.notifier)
      ..restoreOpenedFiles(const [])
      ..addTab(
        TabInfo(id: 'a', filePath: only, fileName: 'only.md', content: ''),
      );

    expect(c.read(settingsProvider).sideBarOpenedFiles, [only]);
  });

  test('either order gives the same list', () async {
    // The immediate cause was the screen doing these two in the wrong order,
    // and order is exactly the sort of thing that gets changed back without
    // anybody noticing. So neither order is allowed to be wrong.
    final first = write('first.md');
    final second = write('second.md');
    final opened = TabInfo(
      id: 'b',
      filePath: second,
      fileName: 'second.md',
      content: '',
    );

    final restoreFirst = boot([first]).read(tabProvider.notifier)
      ..restoreOpenedFiles([first])
      ..addTab(opened);
    final a = restoreFirst.state.openedFiles.map((f) => f.filePath).toList();
    container.dispose();

    final openFirst = boot([first]).read(tabProvider.notifier)
      ..addTab(opened)
      ..restoreOpenedFiles([first]);
    final b = openFirst.state.openedFiles.map((f) => f.filePath).toSet();

    expect(a.toSet(), {first, second});
    expect(b, a.toSet(), reason: '两种顺序都必须两个文件都在');
  });

  test('a file that has since been deleted is not put back', () async {
    // The existing behaviour, pinned so the change above does not lose it.
    final gone = '${dir.path}/gone.md';
    final c = boot([gone]);

    c.read(tabProvider.notifier).restoreOpenedFiles([gone]);

    expect(c.read(tabProvider).openedFiles, isEmpty);
  });
}

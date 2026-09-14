import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/mcp_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';

/// The question the reader is asked, answerable from the automation interface.
///
/// Closing a tab that holds unsaved work asks a person one of three things:
/// Cancel, Don't save, Save. The interface could give two of those answers —
/// Save through `save_tab`, Cancel by not calling — and not the third, so it
/// refused outright and a scratch tab it had opened itself could only be closed
/// by somebody at the keyboard. An interface whose premise is that nobody is
/// present cannot need a person to tidy up after it.
///
/// `discard: true` is that third answer, spelt the way the dialog spells it.
/// The refusal stays the default, because closing a modified tab takes its undo
/// history with it: there is nothing left afterwards to take the decision back
/// with, which is why every way a *person* closes a tab asks first.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('close_discard'));
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

  /// A tab holding unsaved work, the way one an agent opened does.
  ProviderContainer withDirtyTab(ProviderContainer c, {String text = 'draft'}) {
    c.read(tabProvider.notifier).addTab(TabInfo(id: 'scratch', fileName: 'scratch.md'));
    c.read(tabProvider.notifier).updateContent('scratch', text);
    return c;
  }

  Future<({bool ok, String said})> close(
    ProviderContainer c, {
    bool? discard,
  }) async {
    final outcome = await c.read(mcpProvider.notifier).performAction(
      'close_tab',
      {'tabId': 'scratch', if (discard != null) 'discard': discard},
    );
    return (ok: outcome.ok, said: outcome.said);
  }

  bool stillOpen(ProviderContainer c) =>
      c.read(tabProvider).tabs.any((t) => t.id == 'scratch');

  test('unsaved work is still refused when nothing answers the question',
      () async {
    final c = withDirtyTab(boot());

    final outcome = await close(c);

    expect(outcome.ok, isFalse);
    expect(stillOpen(c), isTrue, reason: '拒绝了却还是关掉了');
    expect(outcome.said, contains('save_tab'),
        reason: '拒绝要说出两条出路，否则调用方只能猜');
    expect(outcome.said, contains('discard'));
  });

  test('discard: false is not an answer either', () async {
    // Passing the flag explicitly false is the caller saying "do not throw it
    // away", which is the same position as not passing it.
    final c = withDirtyTab(boot());

    final outcome = await close(c, discard: false);

    expect(outcome.ok, isFalse);
    expect(stillOpen(c), isTrue);
  });

  test('discard: true closes it and says what went', () async {
    final c = withDirtyTab(boot(), text: 'twelve chars');

    final outcome = await close(c, discard: true);

    expect(outcome.ok, isTrue, reason: outcome.said);
    expect(stillOpen(c), isFalse);
    expect(outcome.said, contains('12'),
        reason: '丢掉了多少要说出来——这是它唯一留下的账');
  });

  test('a tab with nothing to lose needs no answer, and none is mentioned',
      () async {
    final c = boot();
    c.read(tabProvider.notifier).addTab(
          TabInfo(id: 'scratch', fileName: 'scratch.md'),
        );

    final outcome = await close(c);

    expect(outcome.ok, isTrue, reason: outcome.said);
    expect(stillOpen(c), isFalse);
    expect(outcome.said, isNot(contains('discarding')),
        reason: '什么都没丢，就不该说丢了东西');
  });

  test('a saved document closes without the flag', () async {
    final file = File('${configDir.path}/note.md')..writeAsStringSync('on disk\n');
    final c = boot();
    c.read(tabProvider.notifier).addTab(
          TabInfo(
            id: 'scratch',
            fileName: 'note.md',
            filePath: file.path,
            content: 'on disk\n',
          ),
        );

    final outcome = await close(c);

    expect(outcome.ok, isTrue, reason: outcome.said);
    expect(file.existsSync(), isTrue, reason: '关闭不该动磁盘上的文件');
  });
}

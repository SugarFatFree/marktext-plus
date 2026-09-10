import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';

/// Text that arrives from somewhere other than the keyboard has to reach the
/// source editor.
///
/// The editor holds the document in a controller of its own and only reads the
/// tab again when `externalRevision` changes — that is how ticking a checkbox
/// in the preview half of a split reaches the source half. Accepting a
/// plugin's rewrite went through `updateContent`, which did not raise it: the
/// tab held the answer, the editor went on showing what it had, and a reader
/// who had just accepted a paragraph into a blank page watched it stay blank.
/// The next keystroke would then have written the blank back over it.
void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('external_writes_'));
  tearDown(() => dir.existsSync() ? dir.deleteSync(recursive: true) : null);

  TabNotifier open(String content) {
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        // Auto-save off: a timer writing on its own would be a second reason
        // for the tab to change while these are checking what changed it.
        (ref) => SettingsNotifier(
          ConfigService(configDir: dir.path),
          AppConfig(autoSave: false),
        ),
      ),
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(tabProvider.notifier)
      ..addTab(TabInfo(id: 'doc', fileName: 'a.md', content: content));
    return notifier;
  }

  int revisionOf(TabNotifier notifier) =>
      notifier.state.tabs.single.externalRevision;

  test('an accepted rewrite tells the editor to look again', () {
    final tabs = open('');
    final before = revisionOf(tabs);

    tabs.updateContent('doc', 'a written paragraph', external: true);

    expect(tabs.state.tabs.single.content, 'a written paragraph');
    expect(revisionOf(tabs), greaterThan(before),
        reason: '外部写入不推这个数，源码编辑器就一直显示旧内容');
  });

  test('typing does not', () {
    // The editor's own listener calls this on every keystroke. Raising it here
    // would have the editor reading its own text back from the tab as the
    // reader writes.
    final tabs = open('one');
    final before = revisionOf(tabs);

    tabs.updateContent('doc', 'one two');

    expect(tabs.state.tabs.single.content, 'one two');
    expect(revisionOf(tabs), before, reason: '打字不该让编辑器重新同步自己');
  });

  test('writing to a tab that is not there changes nothing', () {
    final tabs = open('one');

    expect(tabs.updateContent('gone', 'x', external: true), isFalse);
    expect(revisionOf(tabs), 0);
  });
}

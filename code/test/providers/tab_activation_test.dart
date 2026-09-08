import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';

/// Which tab is active has to be a tab.
///
/// `setActiveTab` wrote whatever it was handed. The tab bar only ever hands
/// it real ids, so nothing showed — until the MCP server offered the same
/// action to anything that can send JSON. Asked to activate a tab that does
/// not exist, the editor reported success and left `activeTabId` pointing at
/// nothing: tabs along the top, an empty editor below, and no error.
///
/// Verified on a running build before it was fixed:
///
///     control activate_tab "不存在的标签"  →  "tab 不存在的标签 is active"
///     get_state                            →  "activeTabId": "不存在的标签"
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late ProviderContainer container;

  setUp(() {
    root = Directory.systemTemp.createTempSync('tab_activation_');
    container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: root.path),
          AppConfig(autoSave: false),
        ),
      ),
    ]);
  });

  tearDown(() {
    container.dispose();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  void open(String id) => container.read(tabProvider.notifier).addTab(
        TabInfo(id: id, fileName: '$id.md', content: 'text'),
      );

  test('activating a tab that exists works', () {
    open('one');
    open('two');
    container.read(tabProvider.notifier).setActiveTab('one');
    expect(container.read(tabProvider).activeTabId, 'one');
  });

  test('activating a tab that does not exist changes nothing', () {
    open('one');
    container.read(tabProvider.notifier).setActiveTab('one');

    container.read(tabProvider.notifier).setActiveTab('no such tab');

    expect(container.read(tabProvider).activeTabId, 'one',
        reason: '不存在的 id 不能被写进状态——那会让编辑器有标签页却没有活动文档');
  });

  test('the answer says whether it happened', () {
    open('one');
    expect(container.read(tabProvider.notifier).setActiveTab('one'), isTrue);
    expect(container.read(tabProvider.notifier).setActiveTab('nope'), isFalse,
        reason: '调用方要能分辨「切过去了」和「没有这个标签」——'
            'MCP 之前对两者说的是同一句话');
  });
}

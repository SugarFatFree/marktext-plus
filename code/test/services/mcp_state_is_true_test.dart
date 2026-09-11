import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/mcp_provider.dart';
import 'package:marktext_plus/providers/plugin_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// What `get_state` says is what is there.
///
/// This is the picture an agent builds everything else on, and the last part
/// of this layer that had only ever been run as a stub — the same gap that
/// left `close_tab` reporting a close it had not made (BUG-366). The other
/// half of that pairing has its own history: `get_state` once named four
/// plugin commands that `run_plugin_command` refused, because the two read
/// different fields of the manifest.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('mcp_state'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  ProviderContainer boot({
    EditMode mode = EditMode.source,
    List<PluginManifest> plugins = const [],
  }) {
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(editMode: mode),
          ),
        ),
        installedPluginManifestsProvider.overrideWith((ref) async => plugins),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<Map<String, dynamic>> stateOf(ProviderContainer c) =>
      c.read(mcpProvider.notifier).describeState();

  test('an editor with nothing open says so', () async {
    final state = await stateOf(boot());
    expect(state['tabs'], isEmpty);
    expect(state['activeTabId'], isNull);
    expect(state['viewMode'], 'source');
  });

  test('it says how much the process is holding', () async {
    // The editor's first promise is that it stays light, and the only way to
    // read that number was a log line the preview writes on its batched path
    // — so it could be had while a heavy document was open and not once it
    // was closed, which is the wrong way round for the question anyone asks.
    //
    // Measured on a real client before this existed: a 148 KB document took
    // resident from 207 MB to 580 MB, and there was no way to ask whether it
    // came back.
    final state = await stateOf(boot());

    // The platform may decline to say, and then nothing is said rather than
    // zero — "0 MB" reads as a measurement. Both shapes are correct; what is
    // not correct is a figure that could not be true.
    if (state.containsKey('residentMB')) {
      expect(state['residentMB'], isA<int>());
      expect(state['residentMB'], greaterThan(0),
          reason: '报出来的必须是一个测量值，不能是占位的 0');
      expect(state['residentMB'], lessThan(100000),
          reason: '十万兆是读错了单位，不是一台机器');
    }
  });

  test('the view mode reported is the one in force', () async {
    for (final mode in EditMode.values) {
      final state = await stateOf(boot(mode: mode));
      expect(state['viewMode'], mode.name);
    }
  });

  test('each open tab is reported, with what it is and what is in it', () async {
    final container = boot();
    container.read(tabProvider.notifier).addTab(
      TabInfo(
        id: 'one',
        fileName: 'note.md',
        filePath: '/tmp/note.md',
        content: 'hello',
      ),
    );

    final state = await stateOf(container);
    final tab = (state['tabs'] as List).single as Map;
    expect(tab['id'], 'one');
    expect(tab['name'], 'note.md');
    expect(tab['path'], '/tmp/note.md');
    expect(tab['kind'], 'document');
    expect(tab['modified'], isFalse);
    expect(tab['characters'], 5);
  });

  test('characters are the UTF-16 units the tool description promises', () async {
    // A code point outside the basic plane is two units, and the description
    // of `get_state` says units rather than characters on purpose: counting
    // code points would walk every open document on every poll.
    const text = 'a\u{1D11E}中\n'; // 1 + 2 + 1 + 1
    final container = boot();
    container.read(tabProvider.notifier).addTab(
      TabInfo(id: 'one', fileName: 'x.md', content: text),
    );

    final state = await stateOf(container);
    final tab = (state['tabs'] as List).single as Map;
    expect(tab['characters'], 5);
    expect(
      tab['characters'],
      isNot(text.runes.length),
      reason: '这篇文档正好能分出「码元」和「码点」，否则上面那条什么也没证明',
    );
  });

  test('a modified tab is reported as modified', () async {
    final container = boot();
    container.read(tabProvider.notifier).addTab(
      TabInfo(id: 'one', fileName: 'x.md', content: 'a'),
    );
    container.read(tabProvider.notifier).updateContent('one', 'b');

    final tab = ((await stateOf(container))['tabs'] as List).single as Map;
    expect(tab['modified'], isTrue);
    expect(tab['characters'], 1);
  });

  test('a plugin page is not reported as a document', () async {
    final container = boot();
    container.read(tabProvider.notifier).addTab(
      TabInfo(id: 'doc', fileName: 'x.md', content: ''),
    );
    container
        .read(tabProvider.notifier)
        .addTab(TabInfo.pluginSettings(
          const PluginManifest(
            id: 'p',
            name: 'P',
            version: '1',
            entrypoint: 'plugin.lua',
          ),
        ));

    final tabs = (await stateOf(container))['tabs'] as List;
    expect(
      (tabs.firstWhere((t) => (t as Map)['id'] == 'doc') as Map)['kind'],
      'document',
    );
    expect(
      tabs.where((t) => (t as Map)['kind'] == 'plugin'),
      hasLength(1),
      reason: '插件设置页也是插件页，报成 document 会让 set_content 写进它',
    );
  });

  test('which tab is active is the one that is active', () async {
    final container = boot();
    container.read(tabProvider.notifier).addTab(
      TabInfo(id: 'one', fileName: 'a.md', content: ''),
    );
    container.read(tabProvider.notifier).addTab(
      TabInfo(id: 'two', fileName: 'b.md', content: ''),
    );
    container.read(tabProvider.notifier).setActiveTab('one');

    expect((await stateOf(container))['activeTabId'], 'one');
  });

  test('the commands it names are the ones a plugin actually has', () async {
    // The pairing that broke once: this list and the one
    // `run_plugin_command` checks against must come from the same getter.
    const manifest = PluginManifest(
      id: 'com.example.demo',
      name: 'Demo',
      version: '0.1.0',
      entrypoint: 'plugin.lua',
      menus: [
        PluginMenuItem(
          id: 'demo.one',
          title: 'One',
          location: 'editor.contextMenu',
        ),
        PluginMenuItem(
          id: 'demo.two',
          title: 'Two',
          location: 'editor.contextMenu',
        ),
      ],
    );

    final container = boot(plugins: const [manifest]);
    // The override is a future; let it resolve before asking.
    await container.read(installedPluginManifestsProvider.future);

    final plugin = ((await stateOf(container))['plugins'] as List).single as Map;
    expect(plugin['id'], 'com.example.demo');
    expect(plugin['version'], '0.1.0');
    expect(
      plugin['commands'],
      manifest.commandIds,
      reason: 'get_state 报的命令必须和 run_plugin_command 认的是同一份',
    );
    expect(plugin['commands'], ['demo.one', 'demo.two']);
  });

  test('an open pane is reported, and a closed one is not', () async {
    final container = boot();
    container.read(tabProvider.notifier).addTab(
      TabInfo(id: 'one', fileName: 'a.md', content: ''),
    );
    container.read(pluginPanesProvider.notifier).show(
      'one',
      const PluginPaneContent(
        pluginName: 'Demo',
        slot: PluginPaneSlot.right,
        title: '译文',
        text: '一二三',
      ),
    );

    var panes = (await stateOf(container))['panes'] as Map;
    expect(panes['one'], isNotNull);
    expect((panes['one'] as Map)['right'], isNotNull);
    expect(((panes['one'] as Map)['right'] as Map)['title'], '译文');
    expect(((panes['one'] as Map)['right'] as Map)['characters'], 3);

    container.read(pluginPanesProvider.notifier).close('one', PluginPaneSlot.right);
    panes = (await stateOf(container))['panes'] as Map;
    expect(
      panes['one'] == null || (panes['one'] as Map)['right'] == null,
      isTrue,
      reason: '关掉的窗格还报着，agent 会以为它还开着',
    );
  });
}

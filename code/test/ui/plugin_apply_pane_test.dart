import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/plugin_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';
import 'package:marktext_plus/ui/widgets/plugin_panes.dart';

/// Accepting what a plugin put in a pane.
///
/// Shown before it is applied, because what a model returns is worth reading
/// before it lands in what the reader was writing.
void main() {
  late Directory configDir;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('apply_cfg_');
  });

  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  const writer = PluginManifest(
    id: 'com.example.demo',
    name: 'Demo',
    version: '1.0.0',
    entrypoint: 'plugin.lua',
    runtime: PluginRuntime.lua,
    permissions: ['document.read', 'document.write'],
  );

  const reader = PluginManifest(
    id: 'com.example.reader',
    name: 'Reader',
    version: '1.0.0',
    entrypoint: 'plugin.lua',
    runtime: PluginRuntime.lua,
    permissions: ['document.read'],
  );

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required PluginManifest plugin,
    required PluginPaneContent pane,
    String document = 'before the old words after',
  }) async {
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(),
          ),
        ),
        installedPluginManifestsProvider.overrideWith((ref) async => [plugin]),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(tabProvider.notifier)
        .addTab(TabInfo(id: 'tab-a', fileName: 'note.md', content: document));
    container.read(pluginPanesProvider.notifier).show('tab-a', pane);
    // Let the manifests future settle, so the pane knows which plugin it is.
    await container.read(installedPluginManifestsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: PluginPanes(document: SizedBox.expand())),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  PluginPaneContent pane({
    bool canApply = true,
    bool busy = false,
    String replaces = 'the old words',
    String name = 'Demo',
  }) => PluginPaneContent(
    pluginName: name,
    title: 'Rewrite',
    text: 'the new words',
    slot: PluginPaneSlot.right,
    canApply: canApply,
    replaces: replaces,
    busy: busy,
  );

  testWidgets('a pane that offers it has a button', (tester) async {
    await pump(tester, plugin: writer, pane: pane());
    expect(find.byKey(const Key('plugin-pane-apply')), findsOneWidget);
  });

  testWidgets('a pane that does not offer it has none', (tester) async {
    // A translation is something to read, not something to accept.
    await pump(tester, plugin: writer, pane: pane(canApply: false));
    expect(find.byKey(const Key('plugin-pane-apply')), findsNothing);
  });

  testWidgets('nothing to accept while it is still filling', (tester) async {
    // Accepting half a rewrite would write half a rewrite.
    await pump(tester, plugin: writer, pane: pane(busy: true));
    expect(find.byKey(const Key('plugin-pane-apply')), findsNothing);
  });

  testWidgets('accepting replaces the selection and closes the pane', (
    tester,
  ) async {
    final container = await pump(tester, plugin: writer, pane: pane());

    await tester.tap(find.byKey(const Key('plugin-pane-apply')));
    await tester.pump();
    // Writing to a tab schedules auto-save; let its timer run rather than
    // leaving it pending for the next test to trip over.
    await tester.pump(const Duration(seconds: 5));

    final tab = container.read(tabProvider).tabs.single;

    expect(tab.content, 'before the new words after');
    expect(tab.isModified, isTrue);
    expect(
      container.read(pluginPanesProvider)['tab-a'],
      anyOf(isNull, isEmpty),
      reason: '采用之后窗格没有内容可留',
    );
  });

  testWidgets('accepting with no selection replaces the whole document', (
    tester,
  ) async {
    final container = await pump(
      tester,
      plugin: writer,
      pane: pane(replaces: ''),
    );

    await tester.tap(find.byKey(const Key('plugin-pane-apply')));
    await tester.pump();
    // Writing to a tab schedules auto-save; let its timer run rather than
    // leaving it pending for the next test to trip over.
    await tester.pump(const Duration(seconds: 5));

    expect(container.read(tabProvider).tabs.single.content, 'the new words');
  });

  testWidgets('a plugin without the permission cannot, however it asked', (
    tester,
  ) async {
    // The flag says the plugin offered; the permission says whether the
    // editor agreed. The button is checked against the second.
    final container = await pump(
      tester,
      plugin: reader,
      pane: pane(name: 'Reader'),
    );

    await tester.tap(find.byKey(const Key('plugin-pane-apply')));
    await tester.pump();
    // Writing to a tab schedules auto-save; let its timer run rather than
    // leaving it pending for the next test to trip over.
    await tester.pump(const Duration(seconds: 5));

    expect(
      container.read(tabProvider).tabs.single.content,
      'before the old words after',
      reason: '没有 document.write 就不该改得动文档',
    );
  });
}

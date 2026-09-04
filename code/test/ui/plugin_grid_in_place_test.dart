import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/plugin_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';
import 'package:marktext_plus/ui/widgets/plugin_panes.dart';
import 'package:marktext_plus/ui/widgets/plugin_tip.dart';
import 'package:marktext_plus/ui/widgets/right_side_bar.dart';

/// The grid where the editor actually puts it — inside the tab, beside the
/// document, with the side bars for company.
///
/// The grid's own tests build it on its own, which proves it can divide a box
/// in half but not that it is given a box worth halving.
void main() {
  late Directory configDir;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('inplace_cfg_');
  });

  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  /// The editor area as the application builds it: a tab bar above, the grid
  /// beside the document, a side bar for company — and a tab open, because a
  /// pane belongs to one.
  Future<ProviderContainer> pumpArea(
    WidgetTester tester, {
    required Widget document,
  }) async {
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
    container
        .read(tabProvider.notifier)
        .addTab(TabInfo(id: 'tab-a', fileName: 'note.md'));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                const SizedBox(
                  height: 36,
                  child: ColoredBox(color: Colors.grey),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: PluginPanes(
                          document: PluginTipLayer(child: document),
                        ),
                      ),
                      const RightSideBar(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  PluginPaneContent translation(String text) => PluginPaneContent(
    pluginName: 'AI Translate',
    title: '中文',
    text: text,
    slot: PluginPaneSlot.right,
  );

  testWidgets('a translation pane gets half the editor area, in place', (
    tester,
  ) async {
    final container = await pumpArea(
      tester,
      // Stands in for the split view: source and preview side by side.
      document: const Row(
        children: [
          Expanded(child: ColoredBox(color: Colors.white)),
          VerticalDivider(width: 1),
          Expanded(child: ColoredBox(color: Colors.black12)),
        ],
      ),
    );

    container
        .read(pluginPanesProvider.notifier)
        .show('tab-a', translation('the translation'));
    await tester.pump();

    final area = tester.getRect(find.byType(PluginPanes));
    final pane = tester.getRect(find.byType(PluginPaneView));

    expect(
      pane.width,
      closeTo(area.width / 2, 12),
      reason: '窗格该占编辑区的一半，而不是一条侧边栏那么宽',
    );
    expect(pane.height, closeTo(area.height, 2), reason: '一个窗格时没有第二行，它该从上到下');
    expect(pane.top, greaterThanOrEqualTo(area.top - 1));
    expect(pane.right, closeTo(area.right, 2));
  });

  testWidgets('a pane belongs to its tab, and goes when the tab is left', (
    tester,
  ) async {
    // The one that matters: a translation opened in one tab stayed on screen
    // after switching to another, beside a document it had nothing to do
    // with. Whatever width it was drawn at, that is a window in the
    // application rather than a pane in a tab.
    final container = await pumpArea(
      tester,
      document: const ColoredBox(color: Colors.white),
    );
    container
        .read(tabProvider.notifier)
        .addTab(TabInfo(id: 'tab-b', fileName: 'other.md'));
    container.read(tabProvider.notifier).setActiveTab('tab-a');
    await tester.pump();

    container
        .read(pluginPanesProvider.notifier)
        .show('tab-a', translation('translation of A'));
    await tester.pump();
    expect(find.text('translation of A'), findsOneWidget);

    container.read(tabProvider.notifier).setActiveTab('tab-b');
    await tester.pump();
    expect(
      find.text('translation of A'),
      findsNothing,
      reason: '切到另一个标签页，上一个标签页的译文不该还在',
    );

    container.read(tabProvider.notifier).setActiveTab('tab-a');
    await tester.pump();
    expect(
      find.text('translation of A'),
      findsOneWidget,
      reason: '切回来它该还在——它属于这个标签页',
    );
  });

  testWidgets('closing a tab takes its pane with it', (tester) async {
    final container = await pumpArea(
      tester,
      document: const ColoredBox(color: Colors.white),
    );
    container
        .read(tabProvider.notifier)
        .addTab(TabInfo(id: 'tab-b', fileName: 'other.md'));
    container.read(tabProvider.notifier).setActiveTab('tab-a');
    container
        .read(pluginPanesProvider.notifier)
        .show('tab-a', translation('translation of A'));
    await tester.pump();

    container.read(tabProvider.notifier).removeTab('tab-a');
    await tester.pump();

    expect(
      container.read(pluginPanesProvider)['tab-a'],
      anyOf(isNull, isEmpty),
      reason: '标签页关了，它的窗格也该没了',
    );
  });

  testWidgets('a panel result lands in the grid, not a container of its own', (
    tester,
  ) async {
    // There used to be a third place for a result: a 380-pixel strip pinned to
    // the far right, outside the grid and outside the side bar. Three places
    // to put one result is no place at all — the reader could not tell which
    // one a plugin would use, and the strip looked like a side bar that was
    // not one.
    final container = await pumpArea(
      tester,
      document: const ColoredBox(color: Colors.white),
    );
    container
        .read(pluginPanesProvider.notifier)
        .show('tab-a', translation('a panel result'));
    await tester.pump();

    final area = tester.getRect(find.byType(PluginPanes));
    final shown = tester.getRect(
      find.ancestor(
        of: find.text('a panel result'),
        matching: find.byType(PluginPaneView),
      ),
    );
    expect(
      shown.width,
      closeTo(area.width / 2, 12),
      reason: '结果只有一个容器：标签页内的宫格',
    );
  });
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/plugin_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';
import 'package:marktext_plus/ui/widgets/plugin_panes.dart';

/// The editor area is a grid of at most four cells.
///
/// The document holds the first; a plugin may fill the other three. Nothing is
/// drawn for a slot no plugin asked for — an empty pane is a strip of nothing
/// taking space from the document.
void main() {
  late Directory configDir;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('panes_cfg_');
  });

  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<void> pump(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          // Wrapped, so the area's size can be measured whether or not
          // PluginPanes draws anything of its own.
          body: SizedBox.expand(
            key: const Key('area'),
            child: PluginPanes(
              document: const SizedBox.expand(key: Key('document')),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  Size area(WidgetTester tester) => tester.getSize(find.byKey(const Key('area')));

  /// A container with a tab open and the given panes in it.
  ///
  /// The tab matters: a pane belongs to the document it was opened beside, so
  /// with no active tab there is nothing to draw one next to.
  ProviderContainer withPanes(Map<PluginPaneSlot, String> panes) {
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          AppConfig(),
        ),
      ),
    ]);
    addTearDown(container.dispose);
    container
        .read(tabProvider.notifier)
        .addTab(TabInfo(id: 'tab-a', fileName: 'note.md'));
    for (final entry in panes.entries) {
      container.read(pluginPanesProvider.notifier).show(
            'tab-a',
            PluginPaneContent(
              pluginName: 'Demo',
              title: entry.key.name,
              text: entry.value,
              slot: entry.key,
            ),
          );
    }
    return container;
  }

  testWidgets('with no plugin panes the document has the whole area',
      (tester) async {
    await pump(tester, withPanes(const {}));

    expect(find.byType(PluginPaneView), findsNothing);
    final document = tester.getSize(find.byKey(const Key('document')));
    final size = area(tester);
    expect(document.width, size.width, reason: '没有插件面板时不该占文档的宽度');
    expect(document.height, size.height);
  });

  testWidgets('a right pane takes width, not the whole area', (tester) async {
    await pump(tester, withPanes({PluginPaneSlot.right: 'r'}));

    expect(find.byType(PluginPaneView), findsOneWidget);
    final document = tester.getSize(find.byKey(const Key('document')));
    final size = area(tester);
    expect(document.width, lessThan(size.width));
    expect(document.height, size.height, reason: '只放右边时不该切掉文档的高度');
  });

  testWidgets('one pane splits the width, whichever slot it claimed',
      (tester) async {
    // The shape follows the count, not the slot name: with one pane there is
    // no second row to make, so a `bottom` pane sits beside the document like
    // any other. Cutting the height for it would have left an empty cell
    // across from it — space taken from the document for nothing.
    await pump(tester, withPanes({PluginPaneSlot.bottom: 'b'}));

    final document = tester.getSize(find.byKey(const Key('document')));
    final size = area(tester);
    expect(document.width, lessThan(size.width));
    expect(document.height, size.height);
  });

  testWidgets('all three slots make four cells', (tester) async {
    await pump(tester, withPanes({
      PluginPaneSlot.right: 'r',
      PluginPaneSlot.bottom: 'b',
      PluginPaneSlot.corner: 'c',
    }));

    expect(find.byType(PluginPaneView), findsNWidgets(3));
    final document = tester.getSize(find.byKey(const Key('document')));
    final size = area(tester);
    expect(document.width, lessThan(size.width));
    expect(document.height, lessThan(size.height));
  });

  testWidgets('the corner alone does not leave a hole where the others are',
      (tester) async {
    // A plugin may fill the fourth cell without filling the second or third.
    await pump(tester, withPanes({PluginPaneSlot.corner: 'c'}));

    expect(find.byType(PluginPaneView), findsOneWidget);
    final document = tester.getSize(find.byKey(const Key('document')));
    final size = area(tester);
    expect(document.width, lessThan(size.width), reason: '角落面板要真的占到位置');
    expect(document.height, size.height,
        reason: '只有一个面板时是左右对分，不该再切出一整行空白');
  });

  testWidgets('closing a pane gives its space back', (tester) async {
    final container = withPanes({PluginPaneSlot.right: 'r'});
    await pump(tester, container);

    container.read(pluginPanesProvider.notifier).close('tab-a', PluginPaneSlot.right);
    await tester.pump();

    expect(find.byType(PluginPaneView), findsNothing);
    final document = tester.getSize(find.byKey(const Key('document')));
    expect(document.width, area(tester).width);
  });
}

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
///
/// A document being read in split view is two of those cells, not one: source
/// and preview are already a division, and counting them as one cell put
/// source, preview and a translation side by side in three columns. So beside
/// a split document there is room for two panes and not three — which is a
/// promise the SDK has to make to authors, and the reason the marked sentence
/// in its twelve documents exists.
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
  ProviderContainer withPanes(
    Map<PluginPaneSlot, String> panes, {
    EditMode mode = EditMode.source,
  }) {
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          AppConfig(editMode: mode),
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

  testWidgets('one pane goes under the document when it asked for bottom',
      (tester) async {
    // This used to be "one pane splits the width, whichever slot it claimed",
    // on the reasoning that one pane is one pane whatever it calls itself.
    // That reasoning holds for *which* pane and not for *which way*: a
    // rewrite of the paragraph you are reading belongs under it, where the
    // lines are the same width and the eye compares by dropping down rather
    // than across. Manual testing asked for the choice; the plugin makes it
    // with the slot it fills, and the reader can flip it.
    //
    // The rule is also written down in the SDK's README, in twelve
    // languages, where plugin authors read it — and it went on stating the
    // old one after this changed, so an author filling only `bottom` was
    // told they would get a pane beside the document. Whoever changes this
    // again changes those too; `sdk_schema_agrees_test` now counts.
    await pump(tester, withPanes({PluginPaneSlot.bottom: 'b'}));

    final document = tester.getSize(find.byKey(const Key('document')));
    final size = area(tester);
    expect(document.height, lessThan(size.height),
        reason: 'bottom 要的是上下分割');
    expect(document.width, size.width, reason: '上下分割不该同时切掉宽度');
  });

  testWidgets('one pane sits beside the document by default', (tester) async {
    // Anything that is not `bottom` is beside, which keeps the shape a plugin
    // gets without thinking about it.
    await pump(tester, withPanes({PluginPaneSlot.corner: 'c'}));

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

  testWidgets('beside a split document there is room for two panes, not three',
      (tester) async {
    // Not a cap someone put on the plugin: the cells are all used. Pinned
    // because the SDK tells authors so in twelve documents, and the editor is
    // the only side that knows whether it is still true — if this starts
    // drawing three, `the_sdk_says_what_the_editor_does_not_do_test` is where
    // the sentence to change is listed.
    await pump(
      tester,
      withPanes(const {
        PluginPaneSlot.right: 'one',
        PluginPaneSlot.bottom: 'two',
        PluginPaneSlot.corner: 'three',
      }, mode: EditMode.split),
    );

    expect(find.byType(PluginPaneView), findsNWidgets(2),
        reason: '分屏的文档占两格，旁边只剩两格。如果这里改成画三个，'
            'SDK 的 12 份文档里那处 ◆ 的说法要跟着改——'
            '见 the_sdk_says_what_the_editor_does_not_do_test');
  });

  testWidgets('two panes beside a split document are both drawn',
      (tester) async {
    await pump(
      tester,
      withPanes(const {
        PluginPaneSlot.right: 'one',
        PluginPaneSlot.bottom: 'two',
      }, mode: EditMode.split),
    );

    expect(find.byType(PluginPaneView), findsNWidgets(2));
    final document = tester.getSize(find.byKey(const Key('document')));
    final size = area(tester);
    expect(document.width, size.width,
        reason: '分屏的文档自己占满一行，两个窗格分下面那一行');
    expect(document.height, lessThan(size.height));
  });
}

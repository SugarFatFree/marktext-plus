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

/// The shape follows the count, and is symmetrical at every step.
///
/// * one cell  — the document has everything;
/// * two cells — side by side, half each;
/// * three     — the top half split, the bottom half whole;
/// * four      — both halves split, four equal cells.
///
/// It was built as trim instead — a 360-pixel strip down the right and a
/// 240-pixel band along the bottom — so a translation of a document got a
/// sliver next to the document it translated, and no two cells matched.
void main() {
  late Directory configDir;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('grid_cfg_');
  });

  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  /// The grid with a tab open, because a pane belongs to one: with no active
  /// tab there is no document to put a pane beside, and nothing is drawn.
  Future<void> pump(
    WidgetTester tester,
    Map<PluginPaneSlot, PluginPaneContent> panes,
  ) async {
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
    for (final content in panes.values) {
      container.read(pluginPanesProvider.notifier).show('tab-a', content);
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: PluginPanes(document: Text('the document')),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  PluginPaneContent content(PluginPaneSlot slot, String text) =>
      PluginPaneContent(
        pluginName: 'Demo',
        title: text,
        text: text,
        slot: slot,
      );

  Rect cellFor(WidgetTester tester, String title) => tester.getRect(
    find.ancestor(
      of: find.text(title, findRichText: false).first,
      matching: find.byType(PluginPaneView),
    ),
  );

  testWidgets('one cell: with no panes there is no grid at all', (
    tester,
  ) async {
    await pump(tester, (const {}));
    await tester.pump();
    expect(find.text('the document'), findsOneWidget);
    expect(find.byType(PluginPaneView), findsNothing);
  });

  testWidgets('two cells: side by side, half each', (tester) async {
    await pump(tester, ({
      PluginPaneSlot.right: content(PluginPaneSlot.right, 'beside'),
    }));
    await tester.pump();

    final whole = tester.getRect(find.byType(PluginPanes));
    final pane = tester.getRect(find.byType(PluginPaneView));
    expect(
      pane.width,
      closeTo(whole.width / 2, 12),
      reason: 'a translation deserves the same room as what it translates',
    );
    expect(
      pane.height,
      closeTo(whole.height, 2),
      reason: 'with one pane there is no second row to make',
    );
  });

  testWidgets('two cells, whichever slot the plugin chose', (tester) async {
    // The slot says which pane is which, not where it lands. Filling only the
    // corner used to leave two empty cells to get there.
    await pump(tester, ({
      PluginPaneSlot.corner: content(PluginPaneSlot.corner, 'alone'),
    }));
    await tester.pump();

    final whole = tester.getRect(find.byType(PluginPanes));
    final pane = tester.getRect(find.byType(PluginPaneView));
    expect(pane.width, closeTo(whole.width / 2, 12));
    expect(pane.height, closeTo(whole.height, 2));
  });

  testWidgets('three cells: the top half split, the bottom half whole', (
    tester,
  ) async {
    await pump(tester, ({
      PluginPaneSlot.right: content(PluginPaneSlot.right, 'top right'),
      PluginPaneSlot.bottom: content(PluginPaneSlot.bottom, 'all the bottom'),
    }));
    await tester.pump();

    final whole = tester.getRect(find.byType(PluginPanes));
    final topRight = cellFor(tester, 'top right');
    final under = cellFor(tester, 'all the bottom');

    expect(topRight.width, closeTo(whole.width / 2, 12));
    expect(topRight.height, closeTo(whole.height / 2, 12));
    expect(
      under.width,
      closeTo(whole.width, 2),
      reason: 'with nothing beside it, the third cell is the whole row',
    );
    expect(under.height, closeTo(whole.height / 2, 12));
  });

  testWidgets('four cells: both halves split, all four the same', (
    tester,
  ) async {
    await pump(tester, ({
      PluginPaneSlot.right: content(PluginPaneSlot.right, 'top right'),
      PluginPaneSlot.bottom: content(PluginPaneSlot.bottom, 'bottom left'),
      PluginPaneSlot.corner: content(PluginPaneSlot.corner, 'bottom right'),
    }));
    await tester.pump();

    final whole = tester.getRect(find.byType(PluginPanes));
    final cells = [
      for (final title in ['top right', 'bottom left', 'bottom right'])
        cellFor(tester, title),
    ];
    for (final cell in cells) {
      expect(cell.width, closeTo(whole.width / 2, 12));
      expect(cell.height, closeTo(whole.height / 2, 12));
    }
    // Two above, two below, and the columns line up.
    expect(cells[1].top, closeTo(cells[2].top, 2));
    expect(cells[0].left, closeTo(cells[2].left, 2));
  });

  testWidgets('the divider between the columns can be dragged', (tester) async {
    await pump(tester, ({
      PluginPaneSlot.right: content(PluginPaneSlot.right, 'beside'),
    }));
    await tester.pump();

    final before = tester.getRect(find.byType(PluginPaneView)).width;
    await tester.drag(
      find.byKey(const Key('plugin-panes-column-divider')),
      const Offset(-120, 0),
    );
    await tester.pump();
    final after = tester.getRect(find.byType(PluginPaneView)).width;
    expect(
      after,
      greaterThan(before + 80),
      reason: 'the split view can be resized; so should this one',
    );
  });

  testWidgets('the divider between the rows can be dragged', (tester) async {
    await pump(tester, ({
      PluginPaneSlot.right: content(PluginPaneSlot.right, 'top right'),
      PluginPaneSlot.bottom: content(PluginPaneSlot.bottom, 'below'),
    }));
    await tester.pump();

    final before = cellFor(tester, 'below').height;
    await tester.drag(
      find.byKey(const Key('plugin-panes-row-divider')),
      const Offset(0, -100),
    );
    await tester.pump();
    expect(cellFor(tester, 'below').height, greaterThan(before + 60));
  });
}

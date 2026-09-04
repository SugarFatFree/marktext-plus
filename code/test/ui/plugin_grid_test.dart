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
/// * three     — one half split and the other whole, and **the plugin decides
///               which half is which**: filling `right` splits the top,
///               filling `bottom` and `corner` splits the bottom;
/// * four      — top left, top right, bottom left, bottom right.
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
    await pump(tester, const {});
    expect(find.text('the document'), findsOneWidget);
    expect(find.byType(PluginPaneView), findsNothing);
  });

  testWidgets('two cells: side by side, half each', (tester) async {
    await pump(tester, {
      PluginPaneSlot.right: content(PluginPaneSlot.right, 'beside'),
    });

    final whole = tester.getRect(find.byType(PluginPanes));
    final pane = tester.getRect(find.byType(PluginPaneView));
    expect(
      pane.width,
      closeTo(whole.width / 2, 12),
      reason: '译文该和它翻译的东西一样宽',
    );
    expect(
      pane.height,
      closeTo(whole.height, 2),
      reason: '只有一个窗格时没有第二行',
    );
  });

  testWidgets('two cells, whichever slot the plugin chose', (tester) async {
    // One pane is one pane: left and right, whatever it called itself.
    await pump(tester, {
      PluginPaneSlot.corner: content(PluginPaneSlot.corner, 'alone'),
    });

    final whole = tester.getRect(find.byType(PluginPanes));
    final pane = tester.getRect(find.byType(PluginPaneView));
    expect(pane.width, closeTo(whole.width / 2, 12));
    expect(pane.height, closeTo(whole.height, 2));
  });

  testWidgets('three cells, top split: right and bottom', (tester) async {
    // `right` sits beside the document, so the top half is the split one and
    // the remaining pane takes the bottom row whole.
    await pump(tester, {
      PluginPaneSlot.right: content(PluginPaneSlot.right, 'top right'),
      PluginPaneSlot.bottom: content(PluginPaneSlot.bottom, 'all the bottom'),
    });

    final whole = tester.getRect(find.byType(PluginPanes));
    final topRight = cellFor(tester, 'top right');
    final under = cellFor(tester, 'all the bottom');

    expect(topRight.width, closeTo(whole.width / 2, 12));
    expect(topRight.height, closeTo(whole.height / 2, 12));
    expect(topRight.top, closeTo(whole.top, 2), reason: '它在上半');
    expect(
      under.width,
      closeTo(whole.width, 2),
      reason: '下半没有第二格，它就是整行',
    );
    expect(under.height, closeTo(whole.height / 2, 12));
  });

  testWidgets('three cells, bottom split: bottom and corner', (tester) async {
    // The other shape, and the plugin chose it by not filling `right`: the
    // document keeps the top row whole and the two panes divide the bottom.
    await pump(tester, {
      PluginPaneSlot.bottom: content(PluginPaneSlot.bottom, 'bottom left'),
      PluginPaneSlot.corner: content(PluginPaneSlot.corner, 'bottom right'),
    });

    final whole = tester.getRect(find.byType(PluginPanes));
    final left = cellFor(tester, 'bottom left');
    final right = cellFor(tester, 'bottom right');
    final document = tester.getRect(find.text('the document'));

    expect(left.width, closeTo(whole.width / 2, 12));
    expect(right.width, closeTo(whole.width / 2, 12));
    expect(left.height, closeTo(whole.height / 2, 12));
    expect(left.top, closeTo(right.top, 2), reason: '两格在同一行');
    expect(left.left, closeTo(whole.left, 2), reason: '左下在左边');
    expect(right.right, closeTo(whole.right, 2), reason: '右下在右边');
    expect(
      document.top,
      lessThan(left.top),
      reason: '文档独占上半整行',
    );
  });

  testWidgets('three cells: the reader can move the split to the other half', (
    tester,
  ) async {
    // The plugin picks the shape it wants; the reader is the one looking at
    // it. Which half is divided is a view, not a decision the plugin gets to
    // hold on to.
    await pump(tester, {
      PluginPaneSlot.right: content(PluginPaneSlot.right, 'first'),
      PluginPaneSlot.bottom: content(PluginPaneSlot.bottom, 'second'),
    });

    final whole = tester.getRect(find.byType(PluginPanes));
    expect(
      cellFor(tester, 'first').top,
      closeTo(whole.top, 2),
      reason: '默认上半分割：第一个窗格在上半',
    );
    expect(
      cellFor(tester, 'second').width,
      closeTo(whole.width, 2),
      reason: '默认下半整行',
    );

    await tester.tap(find.byKey(const Key('plugin-panes-flip')).first);
    await tester.pump();

    final document = tester.getRect(find.text('the document'));
    final first = cellFor(tester, 'first');
    final second = cellFor(tester, 'second');
    expect(
      document.top,
      lessThan(first.top),
      reason: '切换之后文档独占上半整行',
    );
    expect(first.top, closeTo(second.top, 2), reason: '两个窗格并排在下半');
    expect(first.width, closeTo(whole.width / 2, 12));
    expect(second.width, closeTo(whole.width / 2, 12));
  });

  testWidgets('the flip goes both ways', (tester) async {
    await pump(tester, {
      PluginPaneSlot.bottom: content(PluginPaneSlot.bottom, 'first'),
      PluginPaneSlot.corner: content(PluginPaneSlot.corner, 'second'),
    });

    final whole = tester.getRect(find.byType(PluginPanes));
    // This plugin asked for the bottom half to be the split one.
    expect(cellFor(tester, 'first').width, closeTo(whole.width / 2, 12));

    await tester.tap(find.byKey(const Key('plugin-panes-flip')).first);
    await tester.pump();

    expect(
      cellFor(tester, 'first').top,
      closeTo(whole.top, 2),
      reason: '切过去之后第一个窗格在上半，与文档并排',
    );
    expect(
      cellFor(tester, 'second').width,
      closeTo(whole.width, 2),
      reason: '另一个成了下半整行',
    );
  });

  testWidgets('there is nothing to flip with one pane, or with four cells', (
    tester,
  ) async {
    // Two cells have no second row, and four have both halves split already.
    // A button that does nothing is worse than no button.
    await pump(tester, {
      PluginPaneSlot.right: content(PluginPaneSlot.right, 'beside'),
    });
    expect(find.byKey(const Key('plugin-panes-flip')), findsNothing);

    await pump(tester, {
      PluginPaneSlot.right: content(PluginPaneSlot.right, 'top right'),
      PluginPaneSlot.bottom: content(PluginPaneSlot.bottom, 'bottom left'),
      PluginPaneSlot.corner: content(PluginPaneSlot.corner, 'bottom right'),
    });
    expect(find.byKey(const Key('plugin-panes-flip')), findsNothing);
  });

  testWidgets('four cells: top left, top right, bottom left, bottom right', (
    tester,
  ) async {
    await pump(tester, {
      PluginPaneSlot.right: content(PluginPaneSlot.right, 'top right'),
      PluginPaneSlot.bottom: content(PluginPaneSlot.bottom, 'bottom left'),
      PluginPaneSlot.corner: content(PluginPaneSlot.corner, 'bottom right'),
    });

    final whole = tester.getRect(find.byType(PluginPanes));
    final topRight = cellFor(tester, 'top right');
    final bottomLeft = cellFor(tester, 'bottom left');
    final bottomRight = cellFor(tester, 'bottom right');

    for (final cell in [topRight, bottomLeft, bottomRight]) {
      expect(cell.width, closeTo(whole.width / 2, 12));
      expect(cell.height, closeTo(whole.height / 2, 12));
    }
    // Two above, two below; the columns line up.
    expect(bottomLeft.top, closeTo(bottomRight.top, 2));
    expect(topRight.left, closeTo(bottomRight.left, 2));
    expect(topRight.top, closeTo(whole.top, 2));
    expect(bottomLeft.left, closeTo(whole.left, 2));
  });

  testWidgets('the divider between the columns can be dragged', (tester) async {
    await pump(tester, {
      PluginPaneSlot.right: content(PluginPaneSlot.right, 'beside'),
    });

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
      reason: '分屏能拖，这个也该能拖',
    );
  });

  testWidgets('the divider between the rows can be dragged', (tester) async {
    await pump(tester, {
      PluginPaneSlot.right: content(PluginPaneSlot.right, 'top right'),
      PluginPaneSlot.bottom: content(PluginPaneSlot.bottom, 'below'),
    });

    final before = cellFor(tester, 'below').height;
    await tester.drag(
      find.byKey(const Key('plugin-panes-row-divider')),
      const Offset(0, -100),
    );
    await tester.pump();
    expect(cellFor(tester, 'below').height, greaterThan(before + 60));
  });
}

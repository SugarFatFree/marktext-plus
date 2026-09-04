import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/plugin_provider.dart';
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
  Widget editorArea({required Widget document}) => ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Column(
          children: [
            // Stands in for the tab bar.
            const SizedBox(height: 36, child: ColoredBox(color: Colors.grey)),
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
  );

  testWidgets('a translation pane gets half the editor area, in place', (
    tester,
  ) async {
    late WidgetRef captured;
    await tester.pumpWidget(
      editorArea(
        document: Consumer(
          builder: (context, ref, _) {
            captured = ref;
            // Stands in for the split view: source and preview side by side.
            return const Row(
              children: [
                Expanded(child: ColoredBox(color: Colors.white)),
                VerticalDivider(width: 1),
                Expanded(child: ColoredBox(color: Colors.black12)),
              ],
            );
          },
        ),
      ),
    );

    captured
        .read(pluginPanesProvider.notifier)
        .show(
          const PluginPaneContent(
            pluginName: 'AI Translate',
            title: '中文',
            text: 'the translation',
            slot: PluginPaneSlot.right,
          ),
        );
    await tester.pump();

    final area = tester.getRect(find.byType(PluginPanes));
    final pane = tester.getRect(find.byType(PluginPaneView));

    expect(
      pane.width,
      closeTo(area.width / 2, 12),
      reason: '窗格该占编辑区的一半，而不是一条侧边栏那么宽',
    );
    expect(pane.height, closeTo(area.height, 2), reason: '一个窗格时没有第二行，它该从上到下');
    // And it is inside the tab's content area, not floating beside it.
    expect(pane.top, greaterThanOrEqualTo(area.top - 1));
    expect(pane.right, closeTo(area.right, 2));
  });

  testWidgets('the side bar is not what a translation lands in', (
    tester,
  ) async {
    // With no plugin contributing a panel there is no rail at all, so the
    // grid has the whole width to divide.
    late WidgetRef captured;
    await tester.pumpWidget(
      editorArea(
        document: Consumer(
          builder: (context, ref, _) {
            captured = ref;
            return const ColoredBox(color: Colors.white);
          },
        ),
      ),
    );
    captured
        .read(pluginPanesProvider.notifier)
        .show(
          const PluginPaneContent(
            pluginName: 'AI Translate',
            title: '中文',
            text: 'the translation',
            slot: PluginPaneSlot.right,
          ),
        );
    await tester.pump();

    final screen = tester.getRect(find.byType(Scaffold));
    final pane = tester.getRect(find.byType(PluginPaneView));
    expect(pane.width, greaterThan(screen.width * 0.4));
  });

  testWidgets('a panel result lands in the grid, not a container of its own', (
    tester,
  ) async {
    // There used to be a third place for a result: a 380-pixel strip pinned to
    // the far right, outside the grid and outside the side bar. Three places
    // to put one result is no place at all — the reader could not tell which
    // one a plugin would use, and the strip looked like a side bar that was
    // not one.
    late WidgetRef captured;
    await tester.pumpWidget(
      editorArea(
        document: Consumer(
          builder: (context, ref, _) {
            captured = ref;
            return const ColoredBox(color: Colors.white);
          },
        ),
      ),
    );

    captured
        .read(pluginPanesProvider.notifier)
        .show(
          const PluginPaneContent(
            pluginName: 'AI Translate',
            title: '中文',
            text: 'a panel result',
            slot: PluginPaneSlot.right,
          ),
        );
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

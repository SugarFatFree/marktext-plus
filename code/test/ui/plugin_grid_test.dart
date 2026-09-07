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

/// The shape follows how many cells there are, and **the split view's two
/// halves are two of them**.
///
/// That is what the grid was for: the editor could already divide a tab
/// between source and preview, and the point was to offer that same division
/// out to plugins. So a split document is two cells before a plugin fills
/// anything, and one pane beside it makes three — which is a top half divided
/// and a whole row underneath, not three columns.
///
/// * one cell  — the document has everything;
/// * two cells — side by side, half each;
/// * three     — one half divided, the other whole;
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
    Map<PluginPaneSlot, PluginPaneContent> panes, {
    EditMode editMode = EditMode.preview,
  }) async {
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(editMode: editMode),
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
            body: PluginPanes(
              // Expanded, so the cell it is given can be measured: a bare
              // Text is only as wide as its letters.
              document: SizedBox.expand(
                key: Key('document'),
                child: Text('the document'),
              ),
            ),
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

  group('a document that is not split counts as one cell', () {
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
      expect(pane.width, closeTo(whole.width / 2, 12));
      expect(pane.height, closeTo(whole.height, 2));
    });

    testWidgets('three cells: the top half divided, the bottom whole', (
      tester,
    ) async {
      await pump(tester, {
        PluginPaneSlot.right: content(PluginPaneSlot.right, 'top right'),
        PluginPaneSlot.bottom: content(PluginPaneSlot.bottom, 'all the bottom'),
      });

      final whole = tester.getRect(find.byType(PluginPanes));
      final topRight = cellFor(tester, 'top right');
      final under = cellFor(tester, 'all the bottom');

      expect(topRight.width, closeTo(whole.width / 2, 12));
      expect(topRight.top, closeTo(whole.top, 2));
      expect(under.width, closeTo(whole.width, 2));
      expect(under.height, closeTo(whole.height / 2, 12));
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
      for (final title in ['top right', 'bottom left', 'bottom right']) {
        final cell = cellFor(tester, title);
        expect(cell.width, closeTo(whole.width / 2, 12), reason: title);
        expect(cell.height, closeTo(whole.height / 2, 12), reason: title);
      }
      expect(
        cellFor(tester, 'bottom left').top,
        closeTo(cellFor(tester, 'bottom right').top, 2),
      );
      expect(
        cellFor(tester, 'top right').left,
        closeTo(cellFor(tester, 'bottom right').left, 2),
      );
    });
  });

  group('a split document is already two cells', () {
    testWidgets('split alone is the whole area, as it always was', (
      tester,
    ) async {
      await pump(tester, const {}, editMode: EditMode.split);
      expect(find.byType(PluginPaneView), findsNothing);
      final area = tester.getRect(find.byType(PluginPanes));
      final document = tester.getRect(find.byKey(const Key('document')));
      expect(document.width, closeTo(area.width, 2));
      expect(document.height, closeTo(area.height, 2));
    });

    testWidgets('split plus one pane is three cells, not three columns', (
      tester,
    ) async {
      // The bug in the screenshot: source, preview and the translation side by
      // side across the window. Source and preview are two cells already, so
      // one pane makes three — and three means a divided half and a whole row.
      await pump(tester, {
        PluginPaneSlot.right: content(PluginPaneSlot.right, 'the translation'),
      }, editMode: EditMode.split);

      final area = tester.getRect(find.byType(PluginPanes));
      final pane = cellFor(tester, 'the translation');
      final document = tester.getRect(find.byKey(const Key('document')));

      expect(
        pane.width,
        closeTo(area.width, 2),
        reason: '第三格是下半整行，不是右边第三栏',
      );
      expect(
        pane.height,
        closeTo(area.height / 2, 12),
        reason: '它占下半',
      );
      expect(
        document.width,
        closeTo(area.width, 2),
        reason: '源码和预览一起占满上半整行',
      );
      expect(document.top, lessThan(pane.top));
    });

    testWidgets('split plus two panes is four cells', (tester) async {
      await pump(tester, {
        PluginPaneSlot.right: content(PluginPaneSlot.right, 'left below'),
        PluginPaneSlot.bottom: content(PluginPaneSlot.bottom, 'right below'),
      }, editMode: EditMode.split);

      final area = tester.getRect(find.byType(PluginPanes));
      final left = cellFor(tester, 'left below');
      final right = cellFor(tester, 'right below');
      final document = tester.getRect(find.byKey(const Key('document')));

      expect(left.width, closeTo(area.width / 2, 12));
      expect(right.width, closeTo(area.width / 2, 12));
      expect(left.top, closeTo(right.top, 2), reason: '两格在同一行');
      expect(document.width, closeTo(area.width, 2), reason: '上半仍是整行');
      expect(document.top, lessThan(left.top));
    });

    testWidgets('a third pane has nowhere to go and is not drawn', (
      tester,
    ) async {
      // Two from the document and three panes is five, and there is no fifth
      // cell. Drawing four of them and silently dropping one would be worse
      // than what the reader gets: the two that fit, and the rest ignored.
      await pump(tester, {
        PluginPaneSlot.right: content(PluginPaneSlot.right, 'one'),
        PluginPaneSlot.bottom: content(PluginPaneSlot.bottom, 'two'),
        PluginPaneSlot.corner: content(PluginPaneSlot.corner, 'three'),
      }, editMode: EditMode.split);

      expect(find.byType(PluginPaneView), findsNWidgets(2));
      expect(find.text('three'), findsNothing);
    });
  });

  group('moving the split to the other half', () {
    testWidgets('three cells: the reader can move it', (tester) async {
      await pump(tester, {
        PluginPaneSlot.right: content(PluginPaneSlot.right, 'first'),
        PluginPaneSlot.bottom: content(PluginPaneSlot.bottom, 'second'),
      });

      final whole = tester.getRect(find.byType(PluginPanes));
      expect(cellFor(tester, 'first').top, closeTo(whole.top, 2));

      await tester.tap(find.byKey(const Key('plugin-panes-flip')).first);
      await tester.pump();

      final document = tester.getRect(find.byKey(const Key('document')));
      final first = cellFor(tester, 'first');
      final second = cellFor(tester, 'second');
      expect(document.top, lessThan(first.top));
      expect(first.top, closeTo(second.top, 2));
      expect(first.width, closeTo(whole.width / 2, 12));
    });

    testWidgets('a split document cannot be moved below its panes', (
      tester,
    ) async {
      // The divided half is the document's own, and the editor is not going to
      // put source above preview to satisfy a button.
      await pump(tester, {
        PluginPaneSlot.right: content(PluginPaneSlot.right, 'the translation'),
      }, editMode: EditMode.split);
      expect(find.byKey(const Key('plugin-panes-flip')), findsNothing);
    });

    testWidgets('two cells flip between beside and under', (tester) async {
      // This test used to be called "there is nothing to flip with two cells,
      // or with four", from when one pane was always beside the document.
      // Manual testing asked for the other direction — a rewrite belongs
      // under the paragraph it rewrites — so there is something to flip now.
      await pump(tester, {
        PluginPaneSlot.right: content(PluginPaneSlot.right, 'beside'),
      });
      final flip = find.byKey(const Key('plugin-panes-flip'));
      expect(flip, findsOneWidget);

      final wide = tester.getSize(find.byKey(const Key('document')));
      await tester.tap(flip);
      await tester.pumpAndSettle();
      final tall = tester.getSize(find.byKey(const Key('document')));

      expect(tall.width, greaterThan(wide.width), reason: '翻转后文档占满宽度');
      expect(tall.height, lessThan(wide.height), reason: '翻转后高度让出一半');
    });

    testWidgets('there is nothing to flip with four cells', (tester) async {
      // Both halves are already divided, so the button would do nothing.
      await pump(tester, {
        PluginPaneSlot.right: content(PluginPaneSlot.right, 'top right'),
        PluginPaneSlot.bottom: content(PluginPaneSlot.bottom, 'bottom left'),
        PluginPaneSlot.corner: content(PluginPaneSlot.corner, 'bottom right'),
      });
      expect(find.byKey(const Key('plugin-panes-flip')), findsNothing);
    });
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
    expect(
      tester.getRect(find.byType(PluginPaneView)).width,
      greaterThan(before + 80),
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

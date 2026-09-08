import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// Coming back to a tab should come back to where you were reading.
///
/// Each pane is keyed by the tab it shows, so switching tabs destroys the
/// editor and builds a new one with a fresh scroll controller at zero. Read
/// halfway down a long document, glance at another tab, come back — and you
/// are at the top again, with no way to find your place except scrolling for
/// it.
///
/// The model had carried a `scrollOffset` for this since the beginning. It was
/// never written and never read: the field, the constructor argument, the
/// `copyWith` plumbing and an `updateScroll` on the editor provider all
/// existed, and the whole chain was dead.
///
/// Kept off the provider's state on purpose. Recording this in `TabInfo` would
/// rebuild everything watching the tab list, and doing it while a pane is
/// being taken down is modifying a provider mid-teardown — the shape of
/// BUG-337. It lives beside the undo stacks instead, which are per-tab, cause
/// no rebuild, and are already released for every way a tab can close.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('scroll_memory'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  final document = List.generate(300, (i) => 'line ${i + 1}').join('\n');

  Future<void> show(WidgetTester tester, String tabId) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(
              ConfigService(configDir: configDir.path),
              AppConfig(editMode: EditMode.source),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SourceEditor(
              // The key the application gives it: a different tab is a
              // different widget, so the state and its controller go away.
              key: ValueKey('source_inner_$tabId'),
              tabId: tabId,
              initialContent: document,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ScrollableState pane(WidgetTester tester) => tester.state<ScrollableState>(
    find
        .descendant(
          of: find.byType(SourceEditor),
          matching: find.byType(Scrollable),
        )
        .first,
  );

  testWidgets('a tab comes back to where it was left', (tester) async {
    await show(tester, 'a');
    pane(tester).position.jumpTo(1200);
    await tester.pumpAndSettle();

    await show(tester, 'b');
    expect(
      pane(tester).position.pixels,
      0,
      reason: '另一个标签是另一篇文档，不该继承上一个的位置',
    );

    await show(tester, 'a');
    expect(
      pane(tester).position.pixels,
      1200,
      reason: '回到读过的标签，该回到读到的地方',
    );
  });

  testWidgets('a tab never scrolled comes back at the top', (tester) async {
    // The other half: remembering zero and remembering nothing must look the
    // same, or the first visit to a tab would land somewhere arbitrary.
    await show(tester, 'a');
    await show(tester, 'b');
    await show(tester, 'a');

    expect(pane(tester).position.pixels, 0);
  });

  // Not guarded, and measured rather than assumed: replacing the clamp in
  // `_restoreScroll` with a bare `jumpTo(saved)` leaves this whole file green.
  // Flutter's `jumpTo` forces the position to the value it was given and then
  // lets a ballistic simulation carry it back into range, so once anything
  // settles the two spellings end in the same place. What differs is the
  // frame in between — a visible snap back from past the end of the document.
  // The clamp stays for that, and for matching `_scrollToTargetLine`, which
  // clamps for the same reason.

  testWidgets('what is remembered is clamped to the document', (tester) async {
    // A remembered position outside the document is not a position. It can
    // happen: the window is resized, the font is made larger, or the document
    // is rewritten from a plugin while the tab is off screen.
    await show(tester, 'a');
    pane(tester).position.jumpTo(pane(tester).position.maxScrollExtent);
    final wasAtBottom = pane(tester).position.pixels;
    await tester.pumpAndSettle();

    await show(tester, 'b');
    tester.view.physicalSize = const Size(1000, 2400);
    await show(tester, 'a');

    final position = pane(tester).position;
    expect(position.pixels, lessThanOrEqualTo(position.maxScrollExtent));
    expect(position.pixels, greaterThan(0), reason: '仍应回到文档下方，而不是跳回顶部');
    expect(wasAtBottom, greaterThan(0), reason: '这篇文档得真的能滚动，否则上面什么也没证明');
  });

  group('the preview pane too', () {
    // The same gap in the other mode. Reading in preview and glancing at
    // another tab lost the place just as thoroughly, and "remembers where you
    // were in source mode but not in preview" is a worse answer than either.
    final blocks = List.generate(400, (i) => 'Paragraph $i.').join('\n\n');

    Future<void> showPreview(WidgetTester tester, String tabId) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(
              (ref) => SettingsNotifier(
                ConfigService(configDir: configDir.path),
                AppConfig(editMode: EditMode.preview),
              ),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: MarkdownRenderer(
                key: ValueKey('preview_inner_$tabId'),
                tabId: tabId,
                markdown: blocks,
              ),
            ),
          ),
        ),
      );
      // The fill runs from post-frame callbacks, so this never settles on its
      // own until every block is built.
      for (var i = 0; i < 24; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    ScrollableState previewPane(WidgetTester tester) =>
        tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(MarkdownRenderer),
                matching: find.byType(Scrollable),
              )
              .first,
        );

    testWidgets('a tab comes back to where it was left', (tester) async {
      await showPreview(tester, 'a');
      previewPane(tester).position.jumpTo(900);
      await tester.pump();

      await showPreview(tester, 'b');
      expect(previewPane(tester).position.pixels, 0);

      await showPreview(tester, 'a');
      expect(
        previewPane(tester).position.pixels,
        900,
        reason: '预览也该回到读到的地方',
      );
    });

    testWidgets('the restore waits for the document to be drawn', (
      tester,
    ) async {
      // The trap this has to avoid: the preview fills in across frames, so
      // just after it is built the scrollable only extends over the first
      // batch of blocks. Restoring then clamps to that, and the reader lands
      // near the top of a document they were reading the middle of.
      await showPreview(tester, 'a');
      final deep = previewPane(tester).position.maxScrollExtent;
      previewPane(tester).position.jumpTo(deep);
      await tester.pump();

      await showPreview(tester, 'b');
      await showPreview(tester, 'a');

      expect(deep, greaterThan(2000), reason: '文档得够长，否则夹取问题根本演不出来');
      expect(
        previewPane(tester).position.pixels,
        deep,
        reason: '夹到了首批区块的高度，就是把读者丢回了文档上方',
      );
    });
  });

  test('the application actually hands the panes their tab', () {
    // The tests above build the panes themselves, so they would all stay
    // green with the argument dropped from the screen that really builds
    // them — and the feature would be gone with nothing to say so. This
    // repository has had a run of exactly that.
    final source = File('lib/ui/screens/home_screen.dart').readAsStringSync();

    for (final pane in ['source_inner_', 'preview_inner_']) {
      final at = source.indexOf(pane);
      expect(at, isNot(-1), reason: '$pane 这个 key 不见了，接线守卫失去了锚点');
      final call = source.substring(at, at + 500);
      expect(
        call,
        contains('tabId:'),
        reason: '$pane 那个窗格没拿到 tabId，它就记不住这个标签读到哪了',
      );
    }
  });
}

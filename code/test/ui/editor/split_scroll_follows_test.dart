import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';
import 'package:marktext_plus/ui/editor/split_editor.dart';

/// The two halves of a split follow each other.
///
/// Nothing covered this. The panes report the line at the top of each to the
/// other through the editor state, and each ignores a report for 200 ms after
/// being moved by its neighbour so the two cannot chase each other — four
/// moving parts with no test between them.
void main() {
  late Directory configDir;
  ProviderContainer? container;

  setUp(() => configDir = Directory.systemTemp.createTempSync('split_scroll'));
  tearDown(() {
    container?.dispose();
    container = null;
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  /// Long enough that both halves scroll, with headings so the preview can
  /// work out which line it is showing.
  final document = [
    for (var i = 1; i <= 60; i++) '## Section $i\n\nParagraph $i of the text.',
  ].join('\n\n');

  /// Shows the split, or nothing, without tearing down the container: where a
  /// tab was read is remembered on the notifier, and throwing that away
  /// between visits is a forgetting no reader experiences.
  Future<void> show(WidgetTester tester, {bool empty = false}) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    container ??= ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(editMode: EditMode.split),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container!,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: empty
                ? const SizedBox()
                : SplitEditor(tabId: 'tab', initialContent: document),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ScrollableState scrollableIn(WidgetTester tester, Type pane) =>
      tester.state<ScrollableState>(
        find
            .descendant(of: find.byType(pane), matching: find.byType(Scrollable))
            .first,
      );

  testWidgets('both halves have somewhere to scroll to', (tester) async {
    // Otherwise the tests below compare zero with zero.
    await show(tester);
    expect(
      scrollableIn(tester, SourceEditor).position.maxScrollExtent,
      greaterThan(200),
    );
    expect(
      scrollableIn(tester, MarkdownRenderer).position.maxScrollExtent,
      greaterThan(200),
    );
  });

  testWidgets('scrolling the source moves the preview with it', (tester) async {
    await show(tester);
    final source = scrollableIn(tester, SourceEditor);
    final preview = scrollableIn(tester, MarkdownRenderer);
    expect(preview.position.pixels, 0);

    source.position.jumpTo(source.position.maxScrollExtent / 2);
    await tester.pumpAndSettle();

    expect(preview.position.pixels, greaterThan(0),
        reason: '源码滚到中间，预览没有跟过去');
  });

  testWidgets('scrolling the preview moves the source with it', (tester) async {
    await show(tester);
    final source = scrollableIn(tester, SourceEditor);
    final preview = scrollableIn(tester, MarkdownRenderer);

    preview.position.jumpTo(preview.position.maxScrollExtent / 2);
    await tester.pumpAndSettle();

    expect(source.position.pixels, greaterThan(0),
        reason: '预览滚到中间，源码没有跟过去');
  });

  testWidgets('the two do not chase each other', (tester) async {
    // Each half reports where it is when it moves, and moving the other makes
    // it report in turn. Without the guard that ignores a report just after
    // being moved, one scroll would bounce between them for ever.
    await show(tester);
    final source = scrollableIn(tester, SourceEditor);
    final preview = scrollableIn(tester, MarkdownRenderer);

    source.position.jumpTo(source.position.maxScrollExtent / 2);
    await tester.pumpAndSettle();
    final sourceSettled = source.position.pixels;
    final previewSettled = preview.position.pixels;

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(source.position.pixels, sourceSettled, reason: '源码自己动了起来');
    expect(preview.position.pixels, previewSettled, reason: '预览自己动了起来');
  });

  testWidgets('coming back to a split tab leaves the two halves in step',
      (tester) async {
    // The source pane remembers where this tab was read and goes back there
    // when it is rebuilt; the preview beside it deliberately does not, because
    // in a split the source owns the position and the preview follows. So the
    // restore has to reach the preview — otherwise coming back to a tab shows
    // the middle of the document beside the top of it.
    await show(tester);
    final first = scrollableIn(tester, SourceEditor);
    first.position.jumpTo(first.position.maxScrollExtent / 2);
    await tester.pumpAndSettle();
    final wasAt = first.position.pixels;
    expect(wasAt, greaterThan(100), reason: '得真的滚下去，否则下面什么也没证明');

    await show(tester, empty: true);
    await show(tester);

    final source = scrollableIn(tester, SourceEditor);
    final preview = scrollableIn(tester, MarkdownRenderer);
    expect(source.position.pixels, closeTo(wasAt, 1),
        reason: '源码没有回到读到的地方');
    expect(preview.position.pixels, greaterThan(0),
        reason: '源码回到了中间，预览还停在顶部——两半错开了');
  });

  testWidgets('scrolling the preview back up brings the source back up',
      (tester) async {
    // Reported from a running build: scrolling or dragging in the source half
    // is fine, but scrolling *up* in the preview often threw the source to the
    // very bottom. Down then up, watching where the source lands.
    await show(tester);
    final source = scrollableIn(tester, SourceEditor);
    final preview = scrollableIn(tester, MarkdownRenderer);

    preview.position.jumpTo(preview.position.maxScrollExtent * 0.8);
    await tester.pumpAndSettle();
    final deep = source.position.pixels;
    expect(deep, greaterThan(100), reason: '先得真的滚下去，否则下面没有意义');

    // Back up, a few steps, the way a wheel arrives.
    for (final fraction in [0.6, 0.4, 0.2, 0.0]) {
      preview.position.jumpTo(preview.position.maxScrollExtent * fraction);
      await tester.pumpAndSettle();
      expect(
        source.position.pixels,
        lessThanOrEqualTo(deep + 1),
        reason: '预览往回滚，源码却没有跟着往回——'
            '停在 ${source.position.pixels}，之前是 $deep',
      );
    }

    expect(
      source.position.pixels,
      lessThan(deep),
      reason: '预览回到顶部，源码该跟着回来，而不是留在下面',
    );
  });
}

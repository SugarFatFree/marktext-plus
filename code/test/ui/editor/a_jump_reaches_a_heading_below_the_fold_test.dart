import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// Jumping to a heading far below the screen.
///
/// The outline, the sidebar's two search lists and the split panes' scroll sync
/// all aim at a line that is, by definition, off screen. The preview finds it by
/// asking a heading's `GlobalKey` where it was drawn — which answers only for a
/// heading that has an element. So the whole document has to be in the tree, and
/// it is: the blocks sit in a Column, not a lazy list.
///
/// The test that existed asserted only that the request had been consumed, on a
/// seven-line document. A lazy list would keep that green — the target is
/// cleared whether or not the key answered — while every jump past the first
/// screen silently did nothing. This asks where the preview actually went.
///
/// What these do *not* cover, said out loud: `_renderUpTo`, which draws down to
/// the target instead of waiting for the fill to arrive there. At 120 sections
/// the fill finishes in four passes, so waiting is just as good and removing
/// the growth leaves these green — an equivalent mutant. Its worth is latency
/// on a document whose fill takes seconds, and that document is too big to pump
/// in a widget test. The correctness net is the `_drawnNodeCount` check, and
/// removing *that* turns these red.
void main() {
  late Directory configDir;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('preview_jump_test');
  });

  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() {
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
    return container;
  }

  /// 120 sections of two blocks each, so the target is far past the first batch
  /// of 50 and far below a 600 pixel viewport.
  final document = [
    for (var i = 1; i <= 120; i++) '## Section $i\n\nBody of section $i.\n',
  ].join('\n');

  /// Section [n]'s heading, one-based, in the document above.
  int lineOfSection(int n) => 1 + (n - 1) * 4;

  Future<void> pump(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: MarkdownRenderer(markdown: document)),
        ),
      ),
    );
    // Not pumpAndSettle: the fill schedules further frames, so the tree never
    // goes quiet on its own.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  double offsetOf(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;

  testWidgets('it goes to a heading that was below the fold', (tester) async {
    final container = makeContainer();
    await pump(tester, container);

    expect(offsetOf(tester), 0, reason: 'nothing has asked it to move yet');
    // The condition this test needs staged: the target has an element — that
    // is what the Column buys — and is nowhere near the screen. A lazy list
    // would have the second half of this and not the first.
    expect(find.text('Section 100'), findsOneWidget,
        reason: '目标不在树里的话，这条测的就不是跳转而是填充');
    expect(tester.getRect(find.text('Section 100')).top, greaterThan(600),
        reason: '目标本来就在屏幕上，那就没什么可跳的');

    container.read(editorProvider.notifier).scrollToLine(lineOfSection(100));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(offsetOf(tester), greaterThan(600),
        reason: '第 100 节在 600 像素的视口之外，预览没有动');
    final where = tester.getRect(find.text('Section 100'));
    expect(where.top, lessThan(600), reason: '滚过去了但目标不在屏幕上');
    expect(where.bottom, greaterThan(0), reason: '滚过头了，目标在视口上方');
  });

  testWidgets('it goes to the far end of the document', (tester) async {
    final container = makeContainer();
    await pump(tester, container);

    container.read(editorProvider.notifier).scrollToLine(lineOfSection(120));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final where = tester.getRect(find.text('Section 120'));
    expect(where.top, lessThan(600));
    expect(where.bottom, greaterThan(0));
  });

  testWidgets('it goes there when asked before the fill has got that far', (
    tester,
  ) async {
    // The case the fix in `_scrollToTargetLine` is about, and the one the three
    // tests above miss: they pump until the fill is finished, so every heading
    // already has a key and `_renderUpTo` never has to grow. Ask on the first
    // frame instead, while only the opening batch of 50 blocks is drawn.
    //
    // Without the growth, `_keyForLine` answers with the last heading that
    // *had* been drawn — a quarter of the way in — and the target is cleared
    // either way, so nothing ever corrects it.
    final container = makeContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: MarkdownRenderer(markdown: document)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Section 100'), findsNothing,
        reason: '第一帧就已经画到第 100 节的话，这条测的不是补画中的跳转');

    container.read(editorProvider.notifier).scrollToLine(lineOfSection(100));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final where = tester.getRect(find.text('Section 100'));
    expect(where.top, lessThan(600),
        reason: '停在了补画当时画到的最后一个标题上，而不是要去的那个');
    expect(where.bottom, greaterThan(0));
  });

  testWidgets('the request is cleared once it has been acted on', (
    tester,
  ) async {
    final container = makeContainer();
    await pump(tester, container);

    container.read(editorProvider.notifier).scrollToLine(lineOfSection(100));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(container.read(editorProvider).targetScrollLine, isNull,
        reason: '留着的话下一帧会再滚一次');
  });
}

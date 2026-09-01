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

/// Scrolling one half of the split view moves the other.
///
/// There was no synchronisation at all: the preview stayed wherever it was
/// while the editing pane moved, which is most of what a split view is for.
///
/// Anchored on the headings rather than on a fraction of the way down — the
/// two panes have nothing like the same height, so a fraction lands
/// arbitrarily far from the text being written.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('split_sync'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  final source = () {
    final b = StringBuffer();
    for (var i = 0; i < 60; i++) {
      b.writeln('## 第 $i 节\n');
      b.writeln('第 $i 段正文，写得长一些好让它占掉几行的高度，'
          '这样两边的滚动位置才有意义。\n');
    }
    return b.toString();
  }();

  Future<void> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(
              ConfigService(configDir: configDir.path),
              AppConfig(),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SplitEditor(tabId: 't', initialContent: source),
          ),
        ),
      ),
    );
    for (var round = 0; round < 3; round++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }
  }

  /// Where the preview has scrolled to.
  double previewOffset(WidgetTester tester) {
    final scrollable = find.descendant(
      of: find.byType(MarkdownRenderer),
      matching: find.byType(Scrollable),
    );
    return tester.state<ScrollableState>(scrollable.first).position.pixels;
  }

  testWidgets('the preview follows the editing pane', (tester) async {
    await show(tester);
    expect(previewOffset(tester), 0, reason: '前提：两边都在顶部');

    await tester.drag(find.byType(EditableText), const Offset(0, -1500));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(previewOffset(tester), greaterThan(100),
        reason: '滚动了源码区，预览却没有跟着动');
  });

  testWidgets('it lands on the section the reader is looking at',
      (tester) async {
    await show(tester);
    await tester.drag(find.byType(EditableText), const Offset(0, -1500));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Whichever heading is at the top of the source, the same heading has to
    // be near the top of the preview — not merely "somewhere scrolled".
    final editable =
        tester.state<EditableTextState>(find.byType(EditableText));
    final field = tester.renderObject<RenderBox>(find.byType(EditableText));
    final topOfSource = editable.renderEditable
        .getPositionForPoint(field.localToGlobal(Offset.zero))
        .offset;
    final line = '\n'.allMatches(source.substring(0, topOfSource)).length;
    // Walk back to the section heading that line belongs to.
    final lines = source.split('\n');
    var section = -1;
    for (var i = line; i >= 0; i--) {
      final m = RegExp(r'^## 第 (\d+) 节').firstMatch(lines[i]);
      if (m != null) {
        section = int.parse(m.group(1)!);
        break;
      }
    }
    expect(section, greaterThanOrEqualTo(0), reason: '源码顶部找不到小节');

    final heading =
        find.textContaining('第 $section 节', findRichText: true).last;
    final box = tester.renderObject<RenderBox>(heading);
    final dy = box.localToGlobal(Offset.zero).dy;
    expect(dy, greaterThan(-120),
        reason: '第 $section 节被滚过头了（y=$dy）');
    expect(dy, lessThan(400),
        reason: '第 $section 节还远在预览下方（y=$dy）');
  });

  testWidgets('and lands there even where the two panes are nothing alike',
      (tester) async {
    // The case that separates anchoring from a fraction of the way down. A
    // long HTML comment occupies forty lines of source and no height at all
    // in the preview, so a fraction computed from the line number overshoots
    // by the whole of it.
    final lopsided = StringBuffer();
    lopsided.writeln('## 第 0 节\n');
    lopsided.writeln('<!--');
    for (var i = 0; i < 40; i++) {
      lopsided.writeln('这一行只在源码里占位置，预览里什么也不画。');
    }
    lopsided.writeln('-->\n');
    for (var i = 1; i < 40; i++) {
      lopsided.writeln('## 第 $i 节\n');
      lopsided.writeln('第 $i 段正文，写得长一些好让它占掉几行的高度。\n');
    }

    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(
              ConfigService(configDir: configDir.path),
              AppConfig(),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SplitEditor(tabId: 't2', initialContent: lopsided.toString()),
          ),
        ),
      ),
    );
    for (var round = 0; round < 3; round++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    // Just past the comment: the reader is looking at the first sections,
    // which a fraction of the way down would put far below.
    await tester.drag(find.byType(EditableText), const Offset(0, -900));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final heading = find.textContaining('第 1 节', findRichText: true).last;
    final dy = tester.renderObject<RenderBox>(heading).localToGlobal(Offset.zero).dy;
    expect(dy, greaterThan(-200), reason: '按比例同步会把预览滚过头（y=$dy）');
    expect(dy, lessThan(600), reason: '预览没有跟到该到的地方（y=$dy）');
  });

  /// Where the editing pane has scrolled to.
  double sourceOffset(WidgetTester tester) {
    final scrollable = find.descendant(
      of: find.byType(SourceEditor),
      matching: find.byType(Scrollable),
    );
    // The gutter is no longer a scroll view, so the text field's is the only
    // one here; `.last` would find the same thing.
    return tester.state<ScrollableState>(scrollable.first).position.pixels;
  }

  testWidgets('and the editing pane follows the preview', (tester) async {
    // The reading half is the one people scroll, so this direction matters as
    // much as the other.
    await show(tester);
    expect(sourceOffset(tester), 0, reason: '前提：两边都在顶部');

    final preview = find.descendant(
      of: find.byType(MarkdownRenderer),
      matching: find.byType(Scrollable),
    );
    tester.state<ScrollableState>(preview.first).position.jumpTo(1500);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(sourceOffset(tester), greaterThan(100),
        reason: '滚动了预览，源码区却没有跟着动');
  });

  testWidgets('the two do not chase each other', (tester) async {
    // Each follows the other, so without a guard a move is answered by a
    // move. Where the round trip happens to be a fixed point that settles at
    // once and nothing is visibly wrong — which is why driving the preview
    // proves nothing here. Driving the *editing* pane to where the preview
    // has run out of document does not settle: the two push each other
    // forever, and this test hangs rather than failing an expectation.
    await show(tester);
    final source = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(SourceEditor),
            matching: find.byType(Scrollable),
          )
          .first,
    );

    for (final through in [0.4, 0.8, 0.98, 1.0]) {
      source.position.jumpTo(source.position.maxScrollExtent * through);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final settledSource = sourceOffset(tester);
      final settledPreview = previewOffset(tester);

      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(sourceOffset(tester), closeTo(settledSource, 2),
          reason: '滚到 ${(through * 100).round()}% 之后源码区自己动了起来');
      expect(previewOffset(tester), closeTo(settledPreview, 2),
          reason: '滚到 ${(through * 100).round()}% 之后预览自己动了起来');
    }
  });

  testWidgets('a preview on its own is left alone', (tester) async {
    // The flag exists so that preview-only mode does not chase a pane that
    // is not on screen.
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(
              ConfigService(configDir: configDir.path),
              AppConfig(),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: MarkdownRenderer(markdown: source)),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(MarkdownRenderer), findsOneWidget);
  });
}

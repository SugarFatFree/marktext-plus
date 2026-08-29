import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// Two things reported against this editor and never answered:
///
/// * #4 — the preview cannot be zoomed. The zoom commands change the font
///   size setting, and the preview did not read it: its body text and all
///   four heading sizes were compile-time constants.
/// * #2 — there is no room under the last block, so it cannot be scrolled up
///   to where the eye is.
///
/// The size is changed through the notifier here, which is the same call the
/// zoom commands make.
void main() {
  late Directory configDir;
  late ProviderContainer container;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('zoom_test');
    container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          AppConfig(),
        ),
      ),
    ]);
  });
  tearDown(() {
    container.dispose();
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<void> pumpPreview(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: MarkdownRenderer(markdown: '# Heading\n\nSome body text.\n'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Not awaited on purpose: the notifier persists to disk, and a `dart:io`
  /// future never completes inside the fake-async zone a widget test runs in.
  /// The state changes synchronously, which is all this needs.
  Future<void> setFontSize(WidgetTester tester, double size) async {
    unawaited(container.read(settingsProvider.notifier).setFontSize(size));
    await tester.pump();
  }

  /// The style the text containing [needle] is actually painted with.
  ///
  /// Read off the render object, and off the span that carries the character
  /// rather than the root: a paragraph's root span holds no style of its own
  /// — the size is on the runs inside it — so reading the root gives back
  /// whatever Material's DefaultTextStyle happened to be.
  TextStyle styleOf(WidgetTester tester, String needle) {
    final paragraph = tester
        .renderObjectList<RenderParagraph>(
          find.textContaining(needle, findRichText: true),
        )
        .first;
    final span = paragraph.text.getSpanForPosition(const TextPosition(offset: 1));
    return span?.style ?? paragraph.text.style!;
  }

  testWidgets('the preview draws body text at the size that was chosen',
      (tester) async {
    await pumpPreview(tester);
    expect(styleOf(tester, 'Some body text').fontSize, 16);

    await setFontSize(tester, 24);
    expect(styleOf(tester, 'Some body text').fontSize, 24,
        reason: '字号对预览无效——这正是 #4 报告的"预览不能放大缩小"');
  });

  testWidgets('headings grow with it, keeping their proportions',
      (tester) async {
    await pumpPreview(tester);
    final small = styleOf(tester, 'Heading').fontSize!;

    await setFontSize(tester, 32);
    final large = styleOf(tester, 'Heading').fontSize!;

    expect(large / small, closeTo(2.0, 0.01),
        reason: '标题没有按同一比例放大，版面会走形');
  });

  testWidgets('the line height setting is honoured too', (tester) async {
    await pumpPreview(tester);
    expect(styleOf(tester, 'Some body text').height, 1.6);

    unawaited(container
        .read(settingsProvider.notifier)
        .updateConfig((c) => c.copyWith(lineHeight: 2.2)));
    await tester.pump();
    expect(styleOf(tester, 'Some body text').height, 2.2);
  });

  testWidgets('there is room under the last block to scroll it up',
      (tester) async {
    await pumpPreview(tester);
    final padding = tester
        .widgetList<Padding>(find.byType(Padding))
        .map((p) => p.padding.resolve(TextDirection.ltr))
        .where((p) => p.left == 24 && p.top == 24)
        .toList();
    expect(padding, isNotEmpty, reason: '找不到预览的外层内边距');
    expect(padding.first.bottom, greaterThan(200),
        reason: '最后一段仍然贴在底边上，滚不到视线高度');
  });
}

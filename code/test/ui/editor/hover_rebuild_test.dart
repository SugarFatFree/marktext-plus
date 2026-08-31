import 'dart:io';

import 'package:flutter/gestures.dart';
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

/// Moving the pointer over a link must not rebuild the document.
///
/// The bar naming the hovered link lived in the renderer's own state, so
/// showing it went through setState and rebuilt every block of the document —
/// on a large one, a fifth of a second of the window standing still each time
/// the pointer crossed a link, and again when it left. The bar is one small
/// widget in a corner; nothing else has to be touched to draw it.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('hover_rebuild'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  testWidgets('hovering a link in a long document is cheap', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final source = StringBuffer('见 [使用手册](https://example.com/guide)\n\n');
    for (var i = 0; i < 2500; i++) {
      source.writeln('第 $i 段正文，带 [链接$i](/u$i) 一处。\n');
    }

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
          home: Scaffold(body: MarkdownRenderer(markdown: source.toString())),
        ),
      ),
    );

    // A document this size is parsed on another isolate, which a test's fake
    // clock never lets finish; runAsync does. Then the blocks arrive in
    // doubling batches, so it takes a few frames to draw them all.
    for (var round = 0; round < 4; round++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    final paragraph = tester
        .renderObjectList<RenderParagraph>(
          find.textContaining('使用手册', findRichText: true),
        )
        .first;
    late TextSpan link;
    paragraph.text.visitChildren((span) {
      if (span is TextSpan && (span.text ?? '').contains('使用手册')) {
        link = span;
        return false;
      }
      return true;
    });

    final watch = Stopwatch();
    for (var i = 0; i < 6; i++) {
      link.onEnter!(const PointerEnterEvent());
      watch.start();
      await tester.pump();
      watch.stop();
      link.onExit!(const PointerExitEvent());
      await tester.pump();
    }

    // The hint still appears — the point is what it costs, not whether it
    // works, which the tests beside this one cover.
    link.onEnter!(const PointerEnterEvent());
    await tester.pump();
    expect(find.textContaining('example.com/guide'), findsOneWidget);

    // 31 ms when only the bar is rebuilt, 279 ms when the document is. The
    // budget is four times the one and a quarter of the other.
    final each = watch.elapsedMicroseconds / 6 / 1000;
    expect(each, lessThan(120),
        reason: '悬停一个链接看起来又在重建整篇文档了（${each.toStringAsFixed(1)} ms）');
  });
}

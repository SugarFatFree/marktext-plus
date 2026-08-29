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

/// What a link in the preview tells the reader before they follow it.
///
/// It opens only with Ctrl or Cmd held — which is right, since a bare click
/// belongs to the text selection — but it showed neither its target nor that
/// requirement. A link that does nothing when clicked, and says nothing about
/// where it goes, is one most readers try once and give up on.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('link_hint'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<void> pump(WidgetTester tester, String markdown) async {
    tester.view.physicalSize = const Size(1000, 800);
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
          home: Scaffold(body: MarkdownRenderer(markdown: markdown)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The span carrying [needle], as the paragraph actually painted it.
  TextSpan spanFor(WidgetTester tester, String needle) {
    final paragraph = tester
        .renderObjectList<RenderParagraph>(
          find.textContaining(needle, findRichText: true),
        )
        .first;
    late TextSpan found;
    paragraph.text.visitChildren((span) {
      if (span is TextSpan && (span.text ?? '').contains(needle)) {
        found = span;
        return false;
      }
      return true;
    });
    return found;
  }

  testWidgets('a link shows a hand cursor, so it reads as clickable',
      (tester) async {
    await pump(tester, '见 [使用手册](https://example.com/guide) 的说明\n');
    expect(spanFor(tester, '使用手册').mouseCursor, SystemMouseCursors.click);
  });

  testWidgets('hovering names the target and how to open it', (tester) async {
    await pump(tester, '见 [使用手册](https://example.com/guide) 的说明\n');
    expect(find.textContaining('https://example.com/guide'), findsNothing);

    final span = spanFor(tester, '使用手册');
    span.onEnter!(const PointerEnterEvent());
    await tester.pumpAndSettle();

    expect(find.textContaining('https://example.com/guide'), findsOneWidget);
    expect(find.textContaining('Ctrl/Cmd'), findsOneWidget,
        reason: '只显示地址，读者仍然不知道要按住修饰键');
  });

  testWidgets('the hint goes away when the pointer leaves', (tester) async {
    await pump(tester, '见 [使用手册](https://example.com/guide) 的说明\n');
    final span = spanFor(tester, '使用手册');

    span.onEnter!(const PointerEnterEvent());
    await tester.pumpAndSettle();
    expect(find.textContaining('example.com'), findsOneWidget);

    span.onExit!(const PointerExitEvent());
    await tester.pumpAndSettle();
    expect(find.textContaining('example.com'), findsNothing);
  });

  testWidgets('ordinary text carries no hint and no hand cursor',
      (tester) async {
    await pump(tester, '一段普通文字\n');
    final span = spanFor(tester, '一段普通文字');
    expect(span.onEnter, isNull);
    expect(span.mouseCursor, isNot(SystemMouseCursors.click));
  });

  testWidgets('the hint does not push the text around', (tester) async {
    // It is drawn over the document, not inserted into it: a paragraph that
    // moved as the pointer crossed a link would take the link out from under
    // the pointer.
    await pump(tester, '见 [手册](https://example.com) 的说明\n\n第二段\n');
    final before = tester.getTopLeft(find.textContaining('第二段'));

    spanFor(tester, '手册').onEnter!(const PointerEnterEvent());
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.textContaining('第二段')), before);
  });
}

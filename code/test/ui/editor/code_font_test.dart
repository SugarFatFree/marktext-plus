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

/// The chosen code font, everywhere code is drawn.
///
/// It was read by the fenced code block and by nothing else, so picking a
/// face changed the blocks and left inline `code`, front matter and html
/// blocks in the platform's generic monospace — one setting producing two
/// fonts on the same screen.
void main() {
  const chosen = 'Fira Code';
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('code_font'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<void> pump(WidgetTester tester, String markdown,
      {double? codeFontSize}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(
              ConfigService(configDir: configDir.path),
              AppConfig(
                codeFontFamily: chosen,
                codeFontSize: codeFontSize ?? 14.0,
              ),
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
    await tester.pump();
  }

  /// Every font family named by any Text or Text.rich in the tree.
  Set<String?> familiesOf(WidgetTester tester) {
    final families = <String?>{};
    void walk(InlineSpan span) {
      families.add(span.style?.fontFamily);
      span.visitChildren((child) {
        if (child != span) walk(child);
        return true;
      });
    }

    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      if (text.style != null) families.add(text.style!.fontFamily);
      final span = text.textSpan;
      if (span != null) walk(span);
    }
    return families;
  }

  /// Every font size named by any Text or Text.rich in the tree.
  Set<double?> sizesOf(WidgetTester tester) {
    final sizes = <double?>{};
    void walk(InlineSpan span) {
      sizes.add(span.style?.fontSize);
      span.visitChildren((child) {
        if (child != span) walk(child);
        return true;
      });
    }

    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      if (text.style != null) sizes.add(text.style!.fontSize);
      final span = text.textSpan;
      if (span != null) walk(span);
    }
    return sizes;
  }

  testWidgets('a fenced block is drawn at the chosen size', (tester) async {
    // The size was fixed at 14 whatever anyone set, so enlarging the text
    // gave large prose and small code.
    await pump(tester, '```\nplain\n```\n', codeFontSize: 22);
    expect(sizesOf(tester), contains(22.0));
    expect(sizesOf(tester), isNot(contains(14.0)));
  });

  testWidgets('front matter and html blocks follow the same size',
      (tester) async {
    // They were drawn a point smaller than fenced blocks for no stated
    // reason, so one setting produced two sizes.
    await pump(tester, '---\ntitle: x\n---\n\n<div>\n  raw\n</div>\n',
        codeFontSize: 22);
    expect(sizesOf(tester), contains(22.0));
    expect(sizesOf(tester), isNot(contains(13.0)));
  });

  testWidgets('a fenced block uses the chosen face', (tester) async {
    await pump(tester, '```\nplain\n```\n');
    expect(familiesOf(tester), contains(chosen));
  });

  testWidgets('inline code uses it too', (tester) async {
    await pump(tester, 'a `snippet` here\n');
    expect(familiesOf(tester), contains(chosen),
        reason: '行内代码留在了平台默认等宽字体');
    expect(familiesOf(tester), isNot(contains('monospace')));
  });

  testWidgets('front matter uses it too', (tester) async {
    await pump(tester, '---\ntitle: x\n---\n\nbody\n');
    expect(familiesOf(tester), contains(chosen));
    expect(familiesOf(tester), isNot(contains('monospace')));
  });

  testWidgets('an html block uses it too', (tester) async {
    await pump(tester, '<div>\n  raw\n</div>\n');
    expect(familiesOf(tester), contains(chosen));
    expect(familiesOf(tester), isNot(contains('monospace')));
  });
}

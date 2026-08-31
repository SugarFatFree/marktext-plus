import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// The preview keeps each block's widget and hands the same one back while
/// nothing about how the document is drawn has changed.
///
/// That is what makes a long document affordable — every block is rebuilt on
/// every frame otherwise, because they live in a Column rather than a lazy
/// list. It is also the one change that can leave something stale on screen,
/// so each thing a block's appearance depends on is changed here and the
/// preview is asked whether it noticed.
void main() {
  late Directory configDir;
  late SettingsNotifier settings;
  late ProviderContainer container;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('block_cache');
    settings = SettingsNotifier(
      ConfigService(configDir: configDir.path),
      AppConfig(),
    );
    container = ProviderContainer(
      overrides: [settingsProvider.overrideWith((ref) => settings)],
    );
  });
  tearDown(() {
    container.dispose();
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<void> show(WidgetTester tester, String markdown) async {
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
          home: Scaffold(body: MarkdownRenderer(markdown: markdown)),
        ),
      ),
    );
    await tester.pump();
  }

  /// The style the word 甲 is drawn in.
  TextStyle styleOfFirst(WidgetTester tester) {
    final rich = tester.widgetList<Text>(find.byType(Text)).firstWhere(
          (t) => (t.textSpan?.toPlainText() ?? t.data ?? '').contains('甲'),
        );
    final span = rich.textSpan as TextSpan;
    late TextStyle found;
    span.visitChildren((s) {
      if (s is TextSpan && (s.text ?? '').contains('甲')) {
        found = s.style ?? const TextStyle();
        return false;
      }
      return true;
    });
    return found;
  }

  testWidgets('changing the text redraws it', (tester) async {
    await show(tester, '甲一段\n');
    expect(find.textContaining('甲一段', findRichText: true), findsOneWidget);

    await show(tester, '甲二段\n');
    expect(find.textContaining('甲二段', findRichText: true), findsOneWidget);
    expect(find.textContaining('甲一段', findRichText: true), findsNothing,
        reason: '旧内容留在屏幕上了');
  });

  testWidgets('adding a block at the end shows it', (tester) async {
    await show(tester, '甲一段\n');
    await show(tester, '甲一段\n\n乙二段\n');
    expect(find.textContaining('乙二段', findRichText: true), findsOneWidget);
  });

  testWidgets('changing the font size redraws every block', (tester) async {
    await show(tester, '甲一段\n');
    final before = styleOfFirst(tester).fontSize;

    // Not awaited: the write to disk behind this never completes inside a
    // test's fake clock. The state is updated before it, which is what the
    // preview watches.
    unawaited(settings.updateConfig((c) => c.copyWith(fontSize: 28)));
    await tester.pump();

    expect(styleOfFirst(tester).fontSize, isNot(before),
        reason: '字号变了，块却是从缓存里拿的旧的');
  });

  testWidgets('changing the theme redraws every block', (tester) async {
    // A rule takes its colour straight from the theme's tokens, which is what
    // the theme setting changes. A heading's colour comes from the Material
    // text theme, which this harness does not drive.
    await show(tester, '甲一段\n\n---\n');
    Color? ruleColour() =>
        tester.widget<Divider>(find.byType(Divider).first).color;
    final before = ruleColour();

    unawaited(settings.updateConfig((c) => c.copyWith(themeName: 'midnight')));
    await tester.pump();

    expect(ruleColour(), isNot(before),
        reason: '主题变了，块却是从缓存里拿的旧的');
  });

  testWidgets('a search highlights, and numbers its matches from the top',
      (tester) async {
    await show(tester, '甲一\n\n甲二\n\n甲三\n');
    // Nothing cached while a search runs: the matches are numbered by
    // counting them as the blocks are drawn.
    container.read(editorProvider.notifier).updatePreviewSearch(
          query: '甲',
          caseSensitive: false,
          wholeWord: false,
          useRegex: false,
          currentMatchIndex: 0,
        );
    await tester.pump();

    final highlighted = <TextSpan>[];
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      text.textSpan?.visitChildren((s) {
        if (s is TextSpan && s.style?.backgroundColor != null) {
          highlighted.add(s);
        }
        return true;
      });
    }
    expect(highlighted.length, 3, reason: '三段各有一处「甲」');
  });
}

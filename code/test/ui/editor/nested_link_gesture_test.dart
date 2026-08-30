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

/// A link whose text is marked up — `[**Download**](/url)`, the shape of every
/// README's download button.
///
/// The preview builds it as a span holding the spans its text became, and a
/// gesture recognizer on a span does not reach that span's children: a link
/// built as a wrapper would have looked exactly right and done nothing when
/// clicked.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('nestedlink'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Widget wrap(ProviderContainer container, Widget child) =>
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
          home: Scaffold(body: child),
        ),
      );

  /// Every span in the preview whose own text is [text].
  List<TextSpan> spansWithText(WidgetTester tester, String text) {
    final found = <TextSpan>[];
    void walk(InlineSpan span) {
      if (span is TextSpan) {
        if (span.text == text) found.add(span);
        for (final child in span.children ?? const <InlineSpan>[]) {
          walk(child);
        }
      }
    }

    for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
      walk(rich.text);
    }
    return found;
  }

  Future<ProviderContainer> pumpPreview(
    WidgetTester tester,
    String markdown, {
    bool enableHtml = false,
  }) async {
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          AppConfig(enableHtml: enableHtml),
        ),
      ),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(wrap(
      container,
      MarkdownRenderer(markdown: markdown, onSourceChanged: (_) {}),
    ));
    await tester.pump();
    return container;
  }

  testWidgets('bold link text is bold and still clickable', (tester) async {
    await pumpPreview(tester, '[**下载**](https://example.com)\n');

    final spans = spansWithText(tester, '下载');
    expect(spans, isNotEmpty, reason: '加粗的链接文字没有被渲染出来');
    final span = spans.first;
    expect(span.style?.fontWeight, FontWeight.bold, reason: '链接文字没有加粗');
    expect(span.recognizer, isNotNull,
        reason: '识别器没有铺到叶子，这个链接点了没反应');
    expect(span.mouseCursor, SystemMouseCursors.click);
  });

  testWidgets('a plain link is untouched', (tester) async {
    // The guard: the ordinary link takes the path it always took.
    await pumpPreview(tester, '[普通链接](https://example.com)\n');

    final spans = spansWithText(tester, '普通链接');
    expect(spans, isNotEmpty);
    expect(spans.first.recognizer, isNotNull);
  });

  testWidgets('bold text that is not a link gets no recognizer',
      (tester) async {
    await pumpPreview(tester, '**只是加粗**\n');

    final spans = spansWithText(tester, '只是加粗');
    expect(spans, isNotEmpty);
    expect(spans.first.style?.fontWeight, FontWeight.bold);
    expect(spans.first.recognizer, isNull, reason: '不是链接却成了点击目标');
  });

  testWidgets('italic inside bold is drawn as both', (tester) async {
    // The nested branch uses the outer emphasis as the base style, so the two
    // compose. Replacing the base rather than building on it would have drawn
    // the inner run italic and not bold.
    await pumpPreview(tester, '**加粗里的 *斜体* 收尾**\n');

    final spans = spansWithText(tester, '斜体');
    expect(spans, isNotEmpty, reason: '嵌套的斜体没有单独成片');
    expect(spans.first.style?.fontWeight, FontWeight.bold, reason: '外层加粗丢了');
    expect(spans.first.style?.fontStyle, FontStyle.italic);
  });

  testWidgets('a ruby reading is drawn above its text', (tester) async {
    // Ruby is the one inline construct a run of styled text cannot express:
    // the reading has to sit above, so it is drawn as a widget. Asserting the
    // geometry rather than the presence of two Texts — two labels side by side
    // would satisfy a weaker test and be wrong.
    await pumpPreview(
      tester,
      '汉字<ruby>漢<rt>hàn</rt></ruby>注音\n',
      enableHtml: true,
    );

    final reading = find.text('hàn');
    final base = find.text('漢');
    expect(reading, findsOneWidget, reason: '注音没有画出来');
    expect(base, findsOneWidget);

    final readingBox = tester.getRect(reading);
    final baseBox = tester.getRect(base);
    expect(readingBox.bottom, lessThanOrEqualTo(baseBox.top + 1),
        reason: '注音没有落在文字上方');
    expect(readingBox.height, lessThan(baseBox.height),
        reason: '注音应当比正文小');
  });
}

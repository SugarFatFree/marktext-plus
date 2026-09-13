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

/// The face the preview reads in.
///
/// There was one font setting and it belonged to the editing pane — which shows
/// markup, and defaults to a monospace face so that a table's pipes line up.
/// The preview, which is where a document is actually read, drew prose in
/// whatever the platform's fallback list began with, and nothing could change
/// it. Three of the twelve translations called that one setting "body text
/// font", which is the half it did not do.
///
/// Asked of the render objects rather than of the widgets: the face is applied
/// once above every block, so a widget's own [TextStyle] does not name it and
/// only what is being drawn can answer.
void main() {
  const reading = 'Georgia';
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('reading_font'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  /// The notifier, so a test can change a setting the way the settings page
  /// does and see whether the preview follows.
  late SettingsNotifier settings;

  Future<void> pump(
    WidgetTester tester,
    String markdown, {
    String previewFontFamily = '',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) {
            settings = SettingsNotifier(
              ConfigService(configDir: configDir.path),
              AppConfig(
                previewFontFamily: previewFontFamily,
                codeFontFamily: 'Fira Code',
              ),
            );
            return settings;
          }),
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

  /// The family the first characters under [finder] are actually drawn with.
  ///
  /// Two levels of care, both learnt from getting it wrong:
  ///
  /// The render object of the finder itself is not the one drawing — a
  /// paragraph in the preview is wrapped for hovering and for in-place editing
  /// — so this descends to the first [RenderParagraph].
  ///
  /// And the root span of that paragraph is not what the glyphs use.
  /// `Text.rich` puts the span it was given *inside* a root whose style is the
  /// inherited one, so a code block reads as the reading font at the root and
  /// as the code font one level down. This walks to the first span that
  /// actually carries text, keeping the last family named on the way — which is
  /// how the painter resolves it.
  String? drawnFamily(WidgetTester tester, Finder finder) {
    RenderParagraph? paragraph;
    void findParagraph(RenderObject node) {
      if (paragraph != null) return;
      if (node is RenderParagraph) {
        paragraph = node;
        return;
      }
      node.visitChildren(findParagraph);
    }

    findParagraph(tester.renderObject(finder));
    expect(paragraph, isNotNull, reason: '这个 finder 下面没有正在画字的东西');

    String? answer;
    var found = false;
    void walk(InlineSpan span, String? inherited) {
      if (found) return;
      final family = span.style?.fontFamily ?? inherited;
      if (span is TextSpan) {
        if ((span.text ?? '').isNotEmpty) {
          answer = family;
          found = true;
          return;
        }
        for (final child in span.children ?? const <InlineSpan>[]) {
          walk(child, family);
          if (found) return;
        }
      }
    }

    walk(paragraph!.text, null);
    expect(found, isTrue, reason: '找到了段落但它没有可读的文字');
    return answer;
  }

  const document = '# A heading\n\nA paragraph of prose.\n\n```dart\nvar x = 1;\n```\n';

  testWidgets('prose is drawn in the face the reader chose', (tester) async {
    await pump(tester, document, previewFontFamily: reading);

    expect(drawnFamily(tester, find.text('A paragraph of prose.')), reading);
    expect(drawnFamily(tester, find.text('A heading')), reading,
        reason: '标题也是正文的一部分，它自己那份样式并不写字体族');
  });

  testWidgets('a code block keeps the code face', (tester) async {
    await pump(tester, document, previewFontFamily: reading);

    final code = find.textContaining('var x = 1;');
    expect(code, findsWidgets);
    expect(drawnFamily(tester, code.first), 'Fira Code',
        reason: '两个设置分开的意义就在这里——代码不跟阅读字体走');
  });

  testWidgets('nothing is forced when the setting is empty', (tester) async {
    // Not just "is not Georgia": merging `TextStyle(fontFamily: '')` would
    // *set* the family to the empty string, which is not Georgia either and is
    // not what the preview drew before there was a setting. The property that
    // tells those apart is that the family is still an inherited, real one —
    // which is asserted rather than named, because the name is Flutter's
    // default typography and not this editor's to pin.
    await pump(tester, document);

    final family = drawnFamily(tester, find.text('A paragraph of prose.'));
    expect(family, isNot(reading));
    expect(family, isNotNull, reason: '继承链上应当有一个字体族');
    expect(family, isNotEmpty, reason: '空字符串是「被顶掉了」，不是平台默认');
  });

  testWidgets('changing it takes effect on its own', (tester) async {
    // The failure this is for: the preview keeps one built widget per block and
    // reuses it while a signature holds, so a face written into each block's
    // own style would stay the old one until something else invalidated the
    // cache — which is precisely how picking a code font used to behave. It is
    // applied through an inherited widget instead, and this is the difference
    // between the two.
    await pump(tester, document);
    final before = drawnFamily(tester, find.text('A paragraph of prose.'));
    expect(before, isNot(reading), reason: '起点必须不是目标值，否则这条什么也没测');

    // Not awaited: the notifier writes the config file, and a dart:io future
    // never completes inside the FakeAsync zone `testWidgets` runs in. The
    // state is set before the write, which is the half this test is about.
    unawaited(
      settings.updateConfig((c) => c.copyWith(previewFontFamily: reading)),
    );
    await tester.pump();

    expect(drawnFamily(tester, find.text('A paragraph of prose.')), reading,
        reason: '设置改了，画面没跟上——这个面大概是写进各块自己的样式里了，'
            '而缓存里那一份不会重建');
  });
}

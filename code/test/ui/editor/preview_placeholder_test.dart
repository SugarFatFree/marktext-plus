import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
// `InlineSpan` is Flutter's name too, and this file needs both libraries.
import 'package:marktext_plus/services/markdown_parser.dart' as md;
import 'package:marktext_plus/services/rich_copy_service.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// The text a selection returns, and the text rich copy looks for in it.
///
/// The preview draws a formula, a picture, a footnote marker, a ruby
/// annotation and a raised or lowered run as widgets. Each occupies exactly
/// one position in the surrounding text — U+FFFC — and the letters that went
/// into it cannot be selected.
///
/// `RichCopyService.plainTextOf` returned those letters instead: the LaTeX,
/// the alt text, the digits of an exponent. So `indexOf` never found the
/// selection, rich copy fell through to plain, and a paragraph lost every
/// heading, bold run and link in it because it happened to contain a formula.
///
/// Which spans are widgets is written down in two places — the renderer's own
/// switch and rich copy's list — and nothing joined them. This does: whatever
/// the renderer actually draws is compared, character for character, with
/// what rich copy expects to find.
void main() {
  late Directory configDir;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('placeholder_test');
  });
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  /// The text the preview actually puts on screen for [markdown].
  Future<String> drawn(
    WidgetTester tester,
    String markdown, {
    bool enableHtml = false,
  }) async {
    final configService = ConfigService(configDir: configDir.path);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(
              configService,
              AppConfig(enableHtml: enableHtml),
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
    // Not pumpAndSettle: progressive rendering keeps scheduling frames.
    await tester.pump();

    final rich = tester.widgetList<RichText>(find.byType(RichText));
    // The paragraph is the widest run of text on the page; a diagram toolbar
    // or an error label would be a second, shorter one.
    var longest = '';
    for (final widget in rich) {
      final text = widget.text.toPlainText();
      if (text.length > longest.length) longest = text;
    }
    return longest;
  }

  // The setting has to be given to both sides. It was left at the default on
  // each, which made them agree by coincidence rather than by construction —
  // and inline HTML is exactly where the two could have diverged.
  String expected(String markdown, {bool enableHtml = false}) =>
      RichCopyService.plainTextOf(
        MarkdownParser(enableHtml: enableHtml).parse(markdown).single,
      );

  /// Every sample below, so the list can be checked against the enum.
  final samples = <(String, bool)>[];

  void agree(String name, String markdown, {bool enableHtml = false}) {
    samples.add((markdown, enableHtml));
    testWidgets(name, (tester) async {
      expect(
        await drawn(tester, markdown, enableHtml: enableHtml),
        expected(markdown, enableHtml: enableHtml),
        reason: markdown,
      );
    });
  }

  agree('plain text', 'Just a sentence about nothing.\n');
  agree('bold and a link', 'a **bold** word and [a link](/url) after it\n');
  agree(
    'inline maths',
    r'Energy is $E = mc^2$ in a sentence.'
        '\n',
  );
  agree('a raised run', 'The area is 5 cm^2^ in total.\n');
  agree('a lowered run', 'Water is H~2~O, mostly.\n');
  agree('marked and struck text', 'Some ==marked== and ~~struck~~ words.\n');
  agree('inline code', 'Call `doThing()` when ready to proceed.\n');
  agree('a link', 'Read [the manual](https://example.com) before starting.\n');
  // `![alt]()` is not a picture at all: with nothing to load, the parser
  // reads it as a link and leaves the `!` as a literal character in front.
  agree('an image with no address', 'See ![a missing cat]() in the text.\n');
  agree('a footnote marker', 'A claim[^1] worth checking in the text.\n');

  // The three the hand-written list above had never reached. Counted rather
  // than eyeballed: parsing all of these and collecting the `InlineType` of
  // every span produced eleven of the fourteen, and a picture with an actual
  // address was among the missing — which is the widget branch of
  // `_isWidget`, the one this whole file exists to hold in place. The other
  // two are ordinary spans and cost nothing to keep.
  agree('an italic run', 'A word in *italics* inside a sentence.\n');
  agree('an underlined run', 'A word ++underlined++ inside a sentence.\n');
  agree('an image with an address',
      'See ![a cat](https://example.com/cat.png) in the text.\n');

  // Ruby is a tag, so it only exists when inline HTML is on. Off, the tag is
  // literal text; on, the preview draws it as a widget. Both, because the
  // switch must not be able to break the copy.
  const ruby = 'The word <ruby>漢字<rt>かんじ</rt></ruby> sits in a sentence.\n';
  agree('a ruby annotation, inline HTML on', ruby, enableHtml: true);
  agree('the same tag, inline HTML off', ruby);
  agree('a bold tag, inline HTML on', 'a <b>tagged</b> word here\n',
      enableHtml: true);

  /// The samples are a hand-written list, and this is what keeps it honest.
  ///
  /// Which spans the preview draws as widgets is written down twice — the
  /// renderer's switch and `RichCopyService._isWidget` — and the agreements
  /// above are how the two are held together. But an agreement only holds
  /// for a span somebody wrote a sample for, and `_isWidget` ends in a
  /// wildcard: a new [InlineType] that the renderer draws as a widget would
  /// be read as an ordinary span by rich copy, `indexOf` would miss, and the
  /// selection would fall back to plain text — losing every heading, bold
  /// run and link in the paragraph. That is the bug this file was written
  /// for, and nothing stopped it happening again for the next kind of span.
  ///
  /// Counting rather than reading found three the list had never reached:
  /// italics, an underlined run, and a picture with an actual address —
  /// which is the widget branch of `_isWidget` itself.
  test('every kind of inline span has a sample above', () {
    final reached = <InlineType>{};

    void walk(List<md.InlineSpan> spans) {
      for (final span in spans) {
        reached.add(span.type);
        walk(span.children);
      }
    }

    for (final (markdown, enableHtml) in samples) {
      for (final node in MarkdownParser(enableHtml: enableHtml).parse(markdown)) {
        if (node is ParagraphNode) walk(node.inlineSpans);
      }
    }

    expect(
      InlineType.values.toSet().difference(reached),
      isEmpty,
      reason: '新增的内联类型没有样例，渲染器与富文本复制就无人对账',
    );
  });
}

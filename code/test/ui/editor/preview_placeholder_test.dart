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
  Future<String> drawn(WidgetTester tester, String markdown) async {
    final configService = ConfigService(configDir: configDir.path);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(configService, AppConfig()),
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

  String expected(String markdown) =>
      RichCopyService.plainTextOf(MarkdownParser().parse(markdown).single);

  void agree(String name, String markdown) {
    testWidgets(name, (tester) async {
      expect(
        await drawn(tester, markdown),
        expected(markdown),
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
}

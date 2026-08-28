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

/// A formula that will not parse.
///
/// `flutter_math_fork` prints its own exception when it cannot read one —
/// `ParseException: Undefined control sequence: \foo`, in English, as body
/// text, indistinguishable from something the reader wrote. Inline it is
/// worse: the message is several lines long and it sits in the middle of a
/// sentence. What belongs there is the formula they typed, marked as not
/// having come out.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('math_err'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<void> pump(WidgetTester tester, String markdown) async {
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
    await tester.pump();
  }

  testWidgets('a broken block formula shows what was written, not an exception',
      (tester) async {
    await pump(tester, r'$$' '\n' r'\undefinedcommand{x}' '\n' r'$$' '\n');

    expect(find.textContaining(r'\undefinedcommand'), findsWidgets,
        reason: '读者看不到自己写的是什么');
    expect(find.textContaining('ParseException'), findsNothing,
        reason: '把库的异常信息当正文显示了');
    expect(find.textContaining('Undefined control sequence'), findsNothing);
  });

  testWidgets('a broken inline formula stays on one line', (tester) async {
    await pump(tester, r'Einstein wrote $\undefinedcommand{x}$ once.' '\n');

    expect(find.textContaining('ParseException'), findsNothing);
    final broken = tester.widgetList<Text>(
      find.textContaining(r'\undefinedcommand'),
    );
    expect(broken, isNotEmpty);
    expect(broken.first.maxLines, 1,
        reason: '句子中间的报错换了行，会把整行撑开');
  });

  testWidgets('a formula that does parse is still rendered as maths',
      (tester) async {
    await pump(tester, r'$$' '\n' 'E = mc^2' '\n' r'$$' '\n');

    // Not shown as its own source: that would mean the fallback fired for a
    // formula that is perfectly good.
    expect(find.text('E = mc^2'), findsNothing);
  });
}

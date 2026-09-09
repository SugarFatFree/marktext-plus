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

/// Arabic turns the window around; a fenced code block has to stay put.
///
/// `app.dart` wraps everything in a right-to-left [Directionality] for Arabic,
/// and for anyone who picks that direction in Settings whatever their
/// language. Every [Row] then lays its children out the other way — including
/// the one holding a code block's line numbers beside its code, which is not
/// prose and does not read right to left in any language.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('rtl_test'));
  tearDown(() => configDir.existsSync() ? configDir.deleteSync(recursive: true) : null);

  Future<void> draw(WidgetTester tester, String markdown, TextDirection direction) async {
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
          locale: direction == TextDirection.rtl ? const Locale('ar') : const Locale('en'),
          home: Directionality(
            textDirection: direction,
            child: Scaffold(body: MarkdownRenderer(markdown: markdown)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Where the run of text [needle] sits horizontally.
  double leftOf(WidgetTester tester, String needle) {
    for (final element in tester.elementList(find.byType(RichText))) {
      final widget = element.widget as RichText;
      if (!widget.text.toPlainText().contains(needle)) continue;
      return tester.getTopLeft(find.byElementPredicate((e) => e == element)).dx;
    }
    fail('画面上找不到 "$needle"');
  }

  const code = '```dart\nvar answer = 42;\n```\n';

  testWidgets('the line numbers stay beside the code, not across from it',
      (tester) async {
    await draw(tester, code, TextDirection.ltr);
    final numberLtr = leftOf(tester, '1');
    final codeLtr = leftOf(tester, 'answer');
    expect(numberLtr, lessThan(codeLtr), reason: '左起时行号在代码左边');

    await draw(tester, code, TextDirection.rtl);
    expect(
      leftOf(tester, '1'),
      lessThan(leftOf(tester, 'answer')),
      reason: '右起时行号跑到了代码右边——代码不是散文，不随语言掉头',
    );
  });
}

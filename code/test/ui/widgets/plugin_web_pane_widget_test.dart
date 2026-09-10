import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/ui/widgets/plugin_web_pane.dart';

/// What a reader sees where there is no web engine.
///
/// The editor uses the operating system's engine rather than packaging one, so
/// there are machines without: a Linux box with no WPE WebKit, and every
/// machine running the tests. A pane that simply drew nothing would look like a
/// plugin that had failed, and the reader would go looking for the fault in it.
void main() {
  Future<void> draw(WidgetTester tester, {Locale? locale}) => tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: PluginWebPane(html: '<h1>hi</h1>', pluginName: 'Demo'),
          ),
        ),
      );

  testWidgets('with no engine it says so, and says whose page it was',
      (tester) async {
    // Nothing registers a platform under `flutter test`, which is exactly the
    // case being checked.
    expect(PluginWebPane.supported, isFalse);

    await draw(tester);

    expect(find.textContaining('Demo'), findsOneWidget,
        reason: '要说清是哪个插件的页面画不出来，否则读者不知道该找谁');
    expect(find.byType(SelectableText), findsNothing);
  });

  testWidgets('and says it in the reader language', (tester) async {
    await draw(tester, locale: const Locale('zh'));

    expect(find.textContaining('网页引擎'), findsOneWidget,
        reason: '这句话和插件页面上的其他文字一样，要跟着读者的语言走');
  });
}

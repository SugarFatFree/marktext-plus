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

  /// The blockquote's border, as the widget tree actually holds it.
  ///
  /// Read from a real build rather than grepped: the file guard next door can
  /// only say that `Border(left:` is not written, and a decoration assembled
  /// some other way would pass it. What matters is the type that reaches the
  /// tree, because that is what decides which side the bar lands on.
  ///
  /// Flutter's own flipping of a `BorderDirectional` is not re-verified here —
  /// that is Flutter's test to have. What this catches is the bar being
  /// declared against the left instead of against the beginning.
  BoxBorder quoteBorder(WidgetTester tester) {
    for (final element in tester.elementList(find.byType(Container))) {
      final decoration = (element.widget as Container).decoration;
      if (decoration is! BoxDecoration) continue;
      final border = decoration.border;
      if (border == null) continue;
      if (border.top == BorderSide.none &&
          border.bottom == BorderSide.none &&
          border.dimensions.horizontal == 3) {
        return border;
      }
    }
    fail('画面上找不到引用块的竖线');
  }

  testWidgets('the quote bar is declared against the beginning, not the left',
      (tester) async {
    // What this replaces: `Border(left: BorderSide(width: 3))`, which does not
    // turn around, so an Arabic reader saw the bar across the quote from where
    // the words start — the most recognisable way to get a right-to-left
    // layout wrong.
    await draw(tester, '> quoted text\n', TextDirection.rtl);
    final border = quoteBorder(tester);
    expect(border, isA<BorderDirectional>(),
        reason: '引用块的竖线还是固定在某一侧，不会跟着阅读方向翻');
    expect((border as BorderDirectional).start.width, 3);
    expect(border.end, BorderSide.none);
  });

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

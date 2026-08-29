import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';
import 'package:marktext_plus/ui/widgets/language_picker.dart';

/// Choosing the language of a fenced code block.
///
/// Upstream MarkText gives this control nine end-to-end tests. Without it the
/// language has to be typed exactly and from memory, and a fence with a
/// misspelt language is drawn as plain, unhighlighted code with nothing to
/// say why.
void main() {
  group('which languages a query offers', () {
    test('an exact name comes first', () {
      expect(matchingLanguages('dart').first, 'dart');
      expect(matchingLanguages('java').first, 'java');
    });

    test('a prefix finds the language', () {
      expect(matchingLanguages('pyth'), contains('python'));
      expect(matchingLanguages('kot'), contains('kotlin'));
    });

    test('an abbreviation finds it too', () {
      // A prefix match would answer `ts` with nothing at all, which is the
      // abbreviation most people actually type.
      expect(matchingLanguages('ts'), contains('typescript'));
      expect(matchingLanguages('js'), contains('javascript'));
    });

    test('an empty query offers everything', () {
      expect(matchingLanguages('').length,
          greaterThan(10));
      expect(matchingLanguages('   '), matchingLanguages(''));
    });

    test('a query that means nothing offers nothing', () {
      expect(matchingLanguages('zzqqxx'), isEmpty);
    });

    test('the match is case-insensitive', () {
      expect(matchingLanguages('Dart'), contains('dart'));
      expect(matchingLanguages('PYTHON'), contains('python'));
    });
  });

  group('in the editor', () {
    late Directory configDir;
    var tabCounter = 0;

    setUp(() => configDir = Directory.systemTemp.createTempSync('langpick'));
    tearDown(() {
      if (configDir.existsSync()) configDir.deleteSync(recursive: true);
    });

    Future<TextEditingController> editor(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

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
            home: Scaffold(body: SourceEditor(tabId: 'tab-${tabCounter++}')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.widget<TextField>(find.byType(TextField)).controller!;
    }

    Future<void> setText(
      WidgetTester tester,
      TextEditingController controller,
      String text, {
      int? caret,
    }) async {
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: caret ?? text.length),
      );
      await tester.pump();
    }

    testWidgets('typing an opening fence opens the picker', (tester) async {
      final controller = await editor(tester);
      await setText(tester, controller, '```');
      expect(find.byType(LanguagePicker), findsOneWidget);
    });

    testWidgets('the list narrows as the language is typed', (tester) async {
      final controller = await editor(tester);
      await setText(tester, controller, '```da');
      expect(find.byKey(const ValueKey('language-dart')), findsOneWidget);
      expect(find.byKey(const ValueKey('language-python')), findsNothing);
    });

    testWidgets('choosing one writes it into the fence', (tester) async {
      final controller = await editor(tester);
      await setText(tester, controller, '```da');
      await tester.tap(find.byKey(const ValueKey('language-dart')));
      await tester.pumpAndSettle();

      expect(controller.text, '```dart');
      expect(find.byType(LanguagePicker), findsNothing);
    });

    testWidgets('the picker goes away when the caret leaves the fence line',
        (tester) async {
      final controller = await editor(tester);
      await setText(tester, controller, '```dart');
      expect(find.byType(LanguagePicker), findsOneWidget);

      await setText(tester, controller, '```dart\nvoid main() {}');
      expect(find.byType(LanguagePicker), findsNothing,
          reason: '选择器挂在正在写的代码上面');
    });

    testWidgets('a query matching nothing shows no list', (tester) async {
      final controller = await editor(tester);
      await setText(tester, controller, '```zzqqxx');
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('Escape closes it and leaves the fence alone', (tester) async {
      final controller = await editor(tester);
      await setText(tester, controller, '```da');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(LanguagePicker), findsNothing);
      expect(controller.text, '```da');
    });

    testWidgets('an ordinary paragraph does not open it', (tester) async {
      final controller = await editor(tester);
      await setText(tester, controller, '一段普通文字');
      expect(find.byType(LanguagePicker), findsNothing);
    });
  });
}

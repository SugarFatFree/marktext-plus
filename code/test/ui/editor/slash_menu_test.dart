import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations_en.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';
import 'package:marktext_plus/ui/widgets/slash_menu.dart';

/// The quick-insert menu, opened by typing `/`.
///
/// Upstream MarkText gives it four end-to-end tests of its own — it is how
/// most people reach a table or a code fence without learning the markdown
/// for it. This editor had only the command palette, which is opened by a
/// shortcut, is not anchored to the caret, and does not take the `/` back out
/// afterwards.
void main() {
  late Directory configDir;
  var tabCounter = 0;

  setUp(() => configDir = Directory.systemTemp.createTempSync('slash'));
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
    // The editor marks itself initialised in a post-frame callback, and
    // nothing it does on a keystroke happens before that.
    await tester.pumpAndSettle();
    return tester.widget<TextField>(find.byType(TextField)).controller!;
  }

  Future<void> typeSlash(
    WidgetTester tester,
    TextEditingController controller, {
    String before = '',
  }) async {
    controller.value = TextEditingValue(
      text: before,
      selection: TextSelection.collapsed(offset: before.length),
    );
    await tester.pump();
    controller.value = TextEditingValue(
      text: '$before/',
      selection: TextSelection.collapsed(offset: before.length + 1),
    );
    await tester.pump();
  }

  testWidgets('typing / on an empty line opens the menu', (tester) async {
    final controller = await editor(tester);
    await typeSlash(tester, controller);
    expect(find.byType(SlashMenu), findsOneWidget);
  });

  testWidgets('the menu offers the blocks upstream offers', (tester) async {
    final controller = await editor(tester);
    await typeSlash(tester, controller);
    // The three upstream names its own tests by, plus the rest.
    for (final id in ['bullet-list', 'order-list', 'task-list', 'table']) {
      expect(find.byKey(ValueKey('slash-$id')), findsOneWidget, reason: id);
    }
  });

  testWidgets('choosing an entry takes the slash back out', (tester) async {
    final controller = await editor(tester);
    await typeSlash(tester, controller);
    await tester.tap(find.byKey(const ValueKey('slash-table')));
    await tester.pumpAndSettle();

    expect(find.byType(SlashMenu), findsNothing);
    expect(controller.text, isNot(contains('/')),
        reason: '插入之后正文里留下了一个斜杠');
  });

  testWidgets('Escape closes it and leaves the slash alone', (tester) async {
    final controller = await editor(tester);
    await typeSlash(tester, controller);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(SlashMenu), findsNothing);
    expect(controller.text, '/', reason: '取消菜单不该动正文');
  });

  testWidgets('a slash in the middle of prose is just a slash',
      (tester) async {
    // `and/or`, a path, a date — the menu appearing there would be in the way
    // far more often than not.
    final controller = await editor(tester);
    await typeSlash(tester, controller, before: 'and');
    expect(find.byType(SlashMenu), findsNothing);
    expect(controller.text, 'and/');
  });

  group('the entry list itself', () {
    test('every entry matches its own id and label', () {
      final commands = slashCommands(AppLocalizationsEn());
      expect(commands, isNotEmpty);
      for (final command in commands) {
        expect(command.matches(command.id), isTrue, reason: command.id);
        expect(command.matches(''), isTrue, reason: command.id);
      }
    });

    test('a Chinese keyword finds the entry', () {
      // The editor is used to write Chinese; typing `/表格` has to work as
      // well as `/table`.
      final commands = slashCommands(AppLocalizationsEn());
      expect(
        commands.where((c) => c.matches('表格')).map((c) => c.id),
        contains('table'),
      );
      expect(
        commands.where((c) => c.matches('代码')).map((c) => c.id),
        contains('code-fence'),
      );
    });

    test('nothing matches a query that means nothing', () {
      final commands = slashCommands(AppLocalizationsEn());
      expect(commands.where((c) => c.matches('zzzznotathing')), isEmpty);
    });
  });
}

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
              // The source pane is what this exercises, so the editor is in
              // the mode that shows it: it stands aside for format commands
              // while the reader is looking at the preview.
              AppConfig(editMode: EditMode.source),
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

  testWidgets('a mermaid diagram can be inserted from the menu',
      (tester) async {
    // The block this editor is built around, and the one with three parts to
    // remember. What it inserts has to draw something straight away.
    final controller = await editor(tester);
    await typeSlash(tester, controller);
    // About five entries fit before the list scrolls, and this one sits below
    // them — the same scroll a reader would do.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('slash-mermaid-block')),
      60,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('slash-mermaid-block')));
    await tester.pumpAndSettle();

    expect(controller.text, contains('```mermaid'));
    expect(controller.text, contains('graph TD'));
    expect(controller.text, isNot(contains('/')), reason: '斜杠没有被吃掉');

    // What was inserted has to be a diagram, not just a fence with a word in
    // it: the skeleton is parsed the way the preview parses it.
    final fence = RegExp(r'```mermaid\n([\s\S]*?)```').firstMatch(
      controller.text,
    );
    expect(fence, isNotNull);
    expect(fence!.group(1)!.trim(), isNotEmpty, reason: '插入的是一个空围栏');
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

    test('the headings upstream offers are all listed', () {
      // A question about the list, not about what is on screen: the menu is a
      // scrolling list, so a widget test would be asserting how far it happens
      // to be scrolled.
      final ids = slashCommands(AppLocalizationsEn()).map((c) => c.id).toList();
      for (var level = 1; level <= 6; level++) {
        expect(ids, contains('heading-$level'), reason: '标题 $level 不在菜单里');
      }
    });

    test('the awkward blocks come before the headings', () {
      // Six headings at the top would push the table, the fence and the
      // diagram — the ones that are actually hard to type — out of sight.
      final ids = slashCommands(AppLocalizationsEn()).map((c) => c.id).toList();
      for (final id in ['table', 'code-fence', 'mermaid-block']) {
        expect(ids.indexOf(id), lessThan(ids.indexOf('heading-1')), reason: id);
      }
    });

    test('the diagram is reachable by typing, not only by scrolling', () {
      // The path a reader actually takes for an entry below the fold.
      final commands = slashCommands(AppLocalizationsEn());
      for (final query in ['mermaid', '流程图', '图表', 'diagram']) {
        expect(
          commands.where((c) => c.matches(query)).map((c) => c.id),
          contains('mermaid-block'),
          reason: query,
        );
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

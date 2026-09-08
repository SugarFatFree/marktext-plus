import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// Each format action writes what its name promises.
///
/// The switch that carries these out has no `default`, so the compiler already
/// insists every one of the fifty-two is handled — that half of BUG-330 cannot
/// come back here. What the compiler cannot see is *which* handler a case was
/// given: `quoteBlock` calling `_applyLinePrefixAtCursor('* ')` compiles, is
/// bindable, is drawn in the menus, and writes a bullet.
///
/// Measured before this file existed: twenty-five of the fifty-two actions
/// were not named anywhere in the tests, and mutating two of them — the quote
/// prefix to a bullet, and promote-heading into demote — left all 2870 tests
/// green.
///
/// Sibling of `window_actions_do_something_test`, which asks the same question
/// of the other half of the keybinding table.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('fmt_actions'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  var built = 0;

  /// Runs [action] over [text] with [selection] and returns the document, plus
  /// where the selection ended up.
  Future<({String text, TextSelection selection})> apply(
    WidgetTester tester,
    FormatAction action, {
    required String text,
    required TextSelection selection,
  }) async {
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(editMode: EditMode.source),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SourceEditor(
              // Distinct per call: without it the element is reused, the new
              // editor never runs `initState`, and the controller is never
              // registered with this container.
              key: ValueKey('editor${built++}'),
              tabId: 't',
              initialContent: text,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final controller = container.read(editorProvider.notifier).controller!;
    controller.selection = selection;
    await tester.pump();
    container.read(editorProvider.notifier).applyFormat(action);
    await tester.pumpAndSettle();
    return (text: controller.text, selection: controller.selection);
  }

  TextSelection at(int offset) => TextSelection.collapsed(offset: offset);
  TextSelection over(int from, int to) =>
      TextSelection(baseOffset: from, extentOffset: to);

  /// A table with three data rows, so "insert above" and "insert below" put
  /// their blank row in different places. With one data row they agree, and a
  /// pair of actions wired to each other's handler would pass.
  const table3 = '| h |\n|---|\n| 1 |\n| 2 |\n| 3 |\n';

  /// Offset 15 is inside the first data row of [table3].
  const inFirstRow = 15;

  /// Three paragraphs with the caret in the middle one, for the same reason.
  const threeBlocks = 'a\n\nb\n\nc';

  final cases = <(FormatAction, String, TextSelection, String)>[
    // The wrappers.
    (FormatAction.bold, 'x', over(0, 1), '**x**'),
    (FormatAction.italic, 'x', over(0, 1), '*x*'),
    (FormatAction.strikethrough, 'x', over(0, 1), '~~x~~'),
    (FormatAction.underline, 'x', over(0, 1), '++x++'),
    (FormatAction.superscript, 'x', over(0, 1), '^x^'),
    (FormatAction.subscript, 'x', over(0, 1), '~x~'),
    (FormatAction.highlight, 'x', over(0, 1), '==x=='),
    (FormatAction.inlineCode, 'x', over(0, 1), '`x`'),
    (FormatAction.inlineMath, 'x', over(0, 1), r'$x$'),
    (FormatAction.link, 'x', over(0, 1), '[x](url)'),
    (FormatAction.image, 'x', over(0, 1), '![x](url)'),

    // Headings: the level is the thing that can be wired wrong.
    (FormatAction.heading1, 'title', at(2), '# title'),
    (FormatAction.heading2, 'title', at(2), '## title'),
    (FormatAction.heading3, 'title', at(2), '### title'),
    (FormatAction.heading4, 'title', at(2), '#### title'),
    (FormatAction.heading5, 'title', at(2), '##### title'),
    (FormatAction.heading6, 'title', at(2), '###### title'),
    (FormatAction.promoteHeading, '## title', at(4), '# title'),
    (FormatAction.demoteHeading, '## title', at(4), '### title'),
    (FormatAction.toParagraph, '## title', at(4), 'title'),

    // Lists.
    (FormatAction.unorderedList, 'a\nb', at(0), '- a\nb'),
    (FormatAction.orderedList, 'a\nb', at(0), '1. a\nb'),
    (FormatAction.taskList, 'a', at(0), '- [ ] a'),
    (FormatAction.looseList, '- a\n- b\n', at(0), '- a\n\n- b\n'),

    // Blocks.
    (FormatAction.quoteBlock, 'hello', at(2), '> hello'),
    (FormatAction.quoteBlock, 'a\nb', over(0, 3), '> a\n> b'),
    (FormatAction.codeBlock, '', at(0), '```\n\n```'),
    (FormatAction.mathBlock, '', at(0), '\$\$\n\n\$\$'),
    (FormatAction.htmlBlock, '', at(0), '<div>\n\n</div>'),
    (FormatAction.frontMatter, 'a', at(0), '---\ntitle: \n---\n\na'),
    (
      FormatAction.mermaidBlock,
      '',
      at(0),
      '```mermaid\ngraph TD\n    A --> B\n```\n',
    ),
    (
      FormatAction.table,
      '',
      at(0),
      '| Column 1 | Column 2 | Column 3 |\n'
          '| -------- | -------- | -------- |\n'
          '|          |          |          |\n',
    ),
    (FormatAction.horizontalRule, 'a', at(1), 'a\n---\n'),

    // Lines and paragraphs.
    (FormatAction.duplicateLine, 'abc', at(1), 'abc\nabc'),
    (FormatAction.createParagraph, 'a', at(1), 'a\n\n'),
    (FormatAction.deleteParagraph, 'a\n\nb', at(0), 'b'),
    (FormatAction.clearFormatting, '**bold**', over(0, 8), 'bold'),
    (FormatAction.moveBlockUp, threeBlocks, at(3), 'b\n\na\n\nc'),
    (FormatAction.moveBlockDown, threeBlocks, at(3), 'a\n\nc\n\nb'),

    // Tables. The row pair and the column pair are the ones that could be
    // swapped without any other test noticing.
    (
      FormatAction.tableInsertRowBelow,
      table3,
      at(inFirstRow),
      '| h   |\n| --- |\n| 1   |\n|     |\n| 2   |\n| 3   |\n',
    ),
    (
      FormatAction.tableInsertRowAbove,
      table3,
      at(inFirstRow),
      '| h   |\n| --- |\n|     |\n| 1   |\n| 2   |\n| 3   |\n',
    ),
    (
      FormatAction.tableDeleteRow,
      table3,
      at(inFirstRow),
      '| h   |\n| --- |\n| 2   |\n| 3   |\n',
    ),
    (
      FormatAction.tableInsertColumnLeft,
      '| a | b |\n|---|---|\n| 1 | 2 |\n',
      at(2),
      '|     | a   | b   |\n| --- | --- | --- |\n|     | 1   | 2   |\n',
    ),
    (
      FormatAction.tableInsertColumnRight,
      '| a | b |\n|---|---|\n| 1 | 2 |\n',
      at(2),
      '| a   |     | b   |\n| --- | --- | --- |\n| 1   |     | 2   |\n',
    ),
    (
      FormatAction.tableDeleteColumn,
      '| a | b |\n|---|---|\n| 1 | 2 |\n',
      at(2),
      '| b   |\n| --- |\n| 2   |\n',
    ),
    (
      FormatAction.tableAlignLeft,
      '| a | b |\n|---|---|\n| 1 | 2 |\n',
      at(2),
      '| a   | b   |\n| :-- | --- |\n| 1   | 2   |\n',
    ),
    (
      FormatAction.tableAlignCenter,
      '| a | b |\n|---|---|\n| 1 | 2 |\n',
      at(2),
      '| a   | b   |\n| :-: | --- |\n| 1   | 2   |\n',
    ),
    (
      FormatAction.tableAlignRight,
      '| a | b |\n|---|---|\n| 1 | 2 |\n',
      at(2),
      '| a   | b   |\n| --: | --- |\n| 1   | 2   |\n',
    ),
    (
      FormatAction.tableAlignNone,
      '| a | b |\n|:-:|---|\n| 1 | 2 |\n',
      at(2),
      '| a   | b   |\n| --- | --- |\n| 1   | 2   |\n',
    ),
    (
      FormatAction.tableTidy,
      '|a|b|\n|-|-|\n|1|2|\n',
      at(2),
      '| a   | b   |\n| --- | --- |\n| 1   | 2   |\n',
    ),
  ];

  /// The ones that put nothing in the document, and why.
  const cannotBeStaged = <FormatAction, String>{
    FormatAction.copyAsMarkdown: '写系统剪贴板，不改文档',
    FormatAction.copyAsHtml: '同上',
  };

  for (final (action, input, selection, want) in cases) {
    testWidgets('${action.name} 写出它承诺的东西', (tester) async {
      final got = await apply(
        tester,
        action,
        text: input,
        selection: selection,
      );
      expect(
        got.text,
        want,
        reason: '${action.name} 接到的处理不是它名字说的那个',
      );
    });
  }

  testWidgets('selectAll 选中整篇而不改动它', (tester) async {
    final got = await apply(
      tester,
      FormatAction.selectAll,
      text: 'abc',
      selection: at(0),
    );
    expect(got.text, 'abc', reason: '全选不该改文档');
    expect(got.selection.start, 0);
    expect(got.selection.end, 3, reason: '没有选到末尾');
  });

  test('every format action is either exercised above or named as unstageable', () {
    final exercised = cases.map((c) => c.$1).toSet()
      ..add(FormatAction.selectAll);
    final accounted = exercised.union(cannotBeStaged.keys.toSet());

    expect(
      FormatAction.values.toSet().difference(accounted),
      isEmpty,
      reason: '这些动作既没被跑过，也没说明为什么跑不了——接错了不会有人发现',
    );
  });
}

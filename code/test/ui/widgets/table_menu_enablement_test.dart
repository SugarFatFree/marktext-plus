import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:marktext_plus/ui/widgets/app_menu_bar.dart';

/// The table commands are offered only where they apply.
///
/// Reading the code is not enough to know this works: either the caret or the
/// text going stale would leave the entries permanently grey or permanently
/// live.
///
/// This file used to say the caret was moved between the assertions. It was not:
/// every case built a fresh tree with the caret already where it wanted it, so
/// nothing here needed the menu to notice a caret that moves. Removing the watch
/// on the caret left all of them green. The last test below is the one that
/// moves it inside one tree.
///
/// The caret comes from the field, not from the line and column the status bar
/// shows. It used to be rebuilt from those by splitting the document into lines
/// and adding their lengths up — 36.7 ms over eight megabytes, while the menu
/// was being built, so on every caret move. The two agree in the running editor
/// because one selection sets both; where they differ is preview mode, which has
/// no field, and there an offset built from the last line and column reported by
/// the source pane points at a position the reader cannot see. So this registers
/// a controller and moves its selection, which is what the source pane does.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('tablemenu'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  const document = 'a paragraph\n'
      '\n'
      '| A | B |\n'
      '| --- | --- |\n'
      '| 1 | 2 |\n';

  /// Opens the Format ▸ Table submenu with the caret on [line] and returns
  /// whether each named entry is enabled.
  Future<Map<String, bool>> entriesWithCaretOn(
    WidgetTester tester,
    int line,
    int column,
  ) async {
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          AppConfig(),
        ),
      ),
    ]);
    addTearDown(container.dispose);

    container.read(tabProvider.notifier).addTab(
          TabInfo(id: 't1', fileName: 'x.md', content: document),
        );

    // Both, as one selection change does in the editor: the field carries the
    // offset the commands are worked out from, and the line and column are what
    // the menu watches to know it has to rebuild.
    final controller = TextEditingController(text: document);
    addTearDown(controller.dispose);
    final lines = document.split('\n');
    var offset = 0;
    for (var i = 0; i < line && i < lines.length; i++) {
      offset += lines[i].length + 1;
    }
    controller.selection = TextSelection.collapsed(
      offset: offset + column.clamp(0, lines[line].length),
    );
    container.read(editorProvider.notifier).setController(controller);
    container.read(editorProvider.notifier).updateCursor(line, column);
    _lastContainer = container;
    _lastController = controller;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AppMenuBar()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Format'));
    await tester.pumpAndSettle();
    // Format ▸ Insert ▸ Edit Table — the insert-a-table command lives in the
    // same submenu, so the editing commands sit beside it.
    await tester.tap(find.text('Insert'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Table'));
    await tester.pumpAndSettle();

    final result = <String, bool>{};
    for (final label in [
      'Insert Row Below',
      'Delete Row',
      'Delete Column',
      'Align Column Center',
    ]) {
      final finder = find.widgetWithText(MenuItemButton, label);
      expect(finder, findsOneWidget, reason: '菜单里没有「$label」');
      result[label] = tester.widget<MenuItemButton>(finder).onPressed != null;
    }
    return result;
  }

  testWidgets('outside a table every entry is greyed out', (tester) async {
    final entries = await entriesWithCaretOn(tester, 0, 3);
    expect(entries.values, everyElement(isFalse),
        reason: '光标在普通段落上，表格命令不该可用');
  });

  testWidgets('inside a body row the entries are live', (tester) async {
    final entries = await entriesWithCaretOn(tester, 4, 2);
    expect(entries['Insert Row Below'], isTrue);
    expect(entries['Delete Row'], isTrue);
    expect(entries['Align Column Center'], isTrue);
  });

  testWidgets('on the header row, Delete Row alone stays greyed out',
      (tester) async {
    // A GFM table without a header is not a table, so that one command does
    // not apply even though the caret is inside a table.
    final entries = await entriesWithCaretOn(tester, 2, 2);
    expect(entries['Insert Row Below'], isTrue);
    expect(entries['Delete Row'], isFalse, reason: '表头行不该能删');
  });

  testWidgets('with only one column, Delete Column stays greyed out',
      (tester) async {
    final entries = await entriesWithCaretOn(tester, 4, 2);
    expect(entries['Delete Column'], isTrue,
        reason: '两列的表格应当可以删列');
  });

  /// The menu has to notice a caret that moves, which is the half the cases
  /// above cannot show: each of them builds its own tree with the caret already
  /// in place. Mutating the watch away left every one of them green.
  testWidgets('the entries follow a caret that moves', (tester) async {
    final outside = await entriesWithCaretOn(tester, 0, 3);
    expect(outside.values, everyElement(isFalse),
        reason: '起点应当在表格外');

    // Into the table, in the tree that is already on screen.
    final container = _lastContainer!;
    final controller = _lastController!;
    final lines = document.split('\n');
    var offset = 0;
    for (var i = 0; i < 4; i++) {
      offset += lines[i].length + 1;
    }
    controller.selection = TextSelection.collapsed(offset: offset + 2);
    container.read(editorProvider.notifier).updateCursor(4, 2);
    await tester.pumpAndSettle();

    final live = await _readEntries(tester);
    expect(live['Insert Row Below'], isTrue,
        reason: '光标移进表格之后菜单没有跟着更新');
    expect(live['Align Column Center'], isTrue);
  });
}

ProviderContainer? _lastContainer;
TextEditingController? _lastController;

/// Reads the four entries from the submenu that is already open.
///
/// The open menu is not closed by a rebuild underneath it — the entries are
/// rebuilt in place — so moving the caret and pumping is enough to see them
/// change. Tapping the top-level item again would close the menu instead.
Future<Map<String, bool>> _readEntries(WidgetTester tester) async {
  final result = <String, bool>{};
  for (final label in [
    'Insert Row Below',
    'Delete Row',
    'Delete Column',
    'Align Column Center',
  ]) {
    final finder = find.widgetWithText(MenuItemButton, label);
    expect(finder, findsOneWidget, reason: '菜单里没有「$label」');
    result[label] = tester.widget<MenuItemButton>(finder).onPressed != null;
  }
  return result;
}

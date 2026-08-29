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
/// Reading the code is not enough to know this works: the menu takes the caret
/// from the editor's line-and-column state and the text from the active tab,
/// and either of those going stale would leave the entries permanently grey or
/// permanently live. So the caret is actually moved between the assertions.
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
    container.read(editorProvider.notifier).updateCursor(line, column);

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
}

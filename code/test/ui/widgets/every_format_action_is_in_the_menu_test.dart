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

/// Every command the Format menu can carry out is offered by it.
///
/// The menu had fifty-one of the fifty-two. The missing one was
/// `mermaidBlock` — a fenced block with a diagram already in it, the feature
/// this editor is built around, and the only block of its family a reader
/// cannot reach by typing two or three characters. It was added to the `/`
/// menu, which is where its absence had been noticed, and stopped there.
///
/// The other places that dispatch a format action are deliberately narrower:
/// the toolbar carries six, the `/` menu sixteen, and choosing which is the
/// point of both. The menu bar is the one that holds all of them, which is
/// what makes it checkable — and it was already holding all but one, so this
/// writes down a rule the file was following anyway.
///
/// Read from the source because a menu bar has to be built, laid out and
/// opened submenu by submenu before a widget test can see an item, and what
/// went wrong was not how an item behaves but that nobody had written one.
void main() {
  test('the menu bar offers every format action', () {
    final source = File('lib/ui/widgets/app_menu_bar.dart')
        .readAsLinesSync()
        .where((line) => !line.trimLeft().startsWith('//'))
        .join('\n');
    expect(source, contains('FormatAction.'), reason: '读法要跟着改');

    final missing = [
      for (final action in FormatAction.values)
        if (!source.contains('FormatAction.${action.name}')) action.name,
    ];

    expect(
      missing,
      isEmpty,
      reason: '这些格式命令没有任何菜单项能触发：$missing\n'
          '要么给它加一项，要么说明它为什么只该从别处触发',
    );
  });

  test('the enum is the list, not a copy of it', () {
    // Fifty-two of them, and the number is not written here: the test reads
    // the enum, so adding a command adds a row to check rather than a row to
    // remember to add.
    expect(FormatAction.values.length, greaterThan(40),
        reason: '枚举读得太少，取法要跟着改');
  });

  testWidgets('and the new one can actually be reached and pressed',
      (tester) async {
    // The check above reads the source, so it would pass on an item written
    // into a submenu nobody can open, or one whose onPressed is null. What
    // the action then does is `format_actions_do_something_test`'s business;
    // this is the half between them.
    final configDir = Directory.systemTemp.createTempSync('formatmenu');
    addTearDown(() {
      if (configDir.existsSync()) configDir.deleteSync(recursive: true);
    });

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
          TabInfo(id: 't1', fileName: 'x.md', content: 'a paragraph\n'),
        );

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
    await tester.tap(find.text('Code'));
    await tester.pumpAndSettle();

    final item = find.widgetWithText(MenuItemButton, 'Mermaid diagram');
    expect(item, findsOneWidget, reason: '格式 ▸ 代码 里应当有这一项');
    expect(tester.widget<MenuItemButton>(item).onPressed, isNotNull,
        reason: '摆在那里却按不动，比没有更糟');
  });
}

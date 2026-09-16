import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:marktext_plus/ui/widgets/app_menu_bar.dart';

/// File ▸ Reopen Closed Tab is live only when there is one.
///
/// The behaviour behind it has its own tests and has been driven over the
/// automation interface on a real machine; what those cannot see is the menu
/// entry, and an entry that is always live does nothing when pressed while an
/// entry that is always grey hides a feature that works. Neither shows up
/// anywhere else.
///
/// This is the check that would otherwise have to be done by hand, and by hand
/// it is worse: it needs somebody to notice a grey word.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('reopen_menu'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  /// Opens the File menu and answers whether the entry can be pressed.
  Future<bool> reopenIsLive(
    WidgetTester tester, {
    required void Function(ProviderContainer) before,
  }) async {
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          AppConfig(autoSave: false),
        ),
      ),
    ]);
    addTearDown(container.dispose);
    before(container);

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

    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();

    final finder = find.widgetWithText(MenuItemButton, 'Reopen Closed Tab');
    expect(finder, findsOneWidget, reason: '文件菜单里没有这一项');
    return tester.widget<MenuItemButton>(finder).onPressed != null;
  }

  testWidgets('with nothing closed it is greyed out', (tester) async {
    expect(
      await reopenIsLive(tester, before: (_) {}),
      isFalse,
      reason: '没有可拿回的东西时，它应当是灰的，而不是按了没反应',
    );
  });

  testWidgets('after a document is closed it is live', (tester) async {
    final file = File('${configDir.path}/closed.md')
      ..writeAsStringSync('# closed');
    expect(
      await reopenIsLive(tester, before: (container) {
        container.read(tabProvider.notifier)
          ..addTab(TabInfo(
            id: 'a',
            filePath: file.path,
            fileName: 'closed.md',
            content: '# closed',
          ))
          ..removeTab('a');
      }),
      isTrue,
    );
  });

  testWidgets('a tab that was never saved does not light it up', (tester) async {
    // The same rule the list itself keeps, seen from the menu: a tab with no
    // file behind it is not offered, so the entry must not promise it.
    expect(
      await reopenIsLive(tester, before: (container) {
        container.read(tabProvider.notifier)
          ..addTab(TabInfo(id: 'scratch', fileName: 'Untitled', content: 'x'))
          ..removeTab('scratch');
      }),
      isFalse,
    );
  });
}

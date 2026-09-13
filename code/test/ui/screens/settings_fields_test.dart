import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/locale_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/screens/settings_screen.dart';

/// The settings text fields keep what is typed into them.
///
/// Their controllers were built inside `build`, so every rebuild made new
/// ones: the old were never disposed, and the text was reset to whatever the
/// config said. These fields commit on Enter, so flipping any switch on the
/// screen threw away whatever had been typed and not yet submitted.
void main() {
  late Directory configDir;
  late ProviderContainer container;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('settings_fields');
    container = ProviderContainer(
      overrides: [
        localeProvider.overrideWith(
          (ref) => LocaleNotifier(const Locale('en', 'US')),
        ),
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(),
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  /// Mounts the screen at whatever surface size is already set.
  Future<void> pumpAt(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Mounts it at a size comfortably wider than the rows it draws.
  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAt(tester);
  }

  /// The field showing [current], whatever row it sits in.
  Finder fieldShowing(String current) => find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text == current,
      );

  testWidgets('a rebuild does not throw away what is being typed',
      (tester) async {
    await pump(tester);

    // The auto-save delay, which is on the General page the screen opens on.
    final field = fieldShowing('5000');
    expect(field, findsOneWidget, reason: '找不到自动保存延迟那一行');

    await tester.enterText(field, '900');
    await tester.pump();

    // Something else on the screen changes, which rebuilds it. Not awaited:
    // the rebuild is what this is for, and the settings write behind it goes
    // to disk on its own time.
    unawaited(container.read(settingsProvider.notifier).toggleSideBar());
    await tester.pump();

    expect(fieldShowing('900'), findsOneWidget,
        reason: '重建把没提交的输入抹掉了');
  });

  testWidgets('a value changed elsewhere still reaches the field',
      (tester) async {
    await pump(tester);
    expect(fieldShowing('5000'), findsOneWidget);

    // Not awaited, for the same reason: the rebuild is the subject and the
    // write behind it is not.
    unawaited(container.read(settingsProvider.notifier).updateConfig(
      (c) => c.copyWith(autoSaveDelay: 1234),
    ));
    await tester.pump();

    expect(fieldShowing('1234'), findsOneWidget,
        reason: '别处改了配置，字段应当跟上');
  });

  testWidgets('AI text settings save while typing without pressing Enter',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('AI models'));
    await tester.pump();

    final fields = find.byType(TextField);
    expect(fields, findsWidgets);
    await tester.enterText(fields.at(0), 'https://api.example.test');
    await tester.pump(const Duration(milliseconds: 400));

    expect(container.read(settingsProvider).aiEndpoint,
        'https://api.example.test');
  });

  group('the page fits the window it is given', () {
    // Every row was laid out with neither side able to give way, so the whole
    // page overflowed to the right below about a thousand pixels — striped,
    // not scrollable. The keybindings page did it fifty-nine times at once.
    for (final width in [1200.0, 1000.0, 800.0, 600.0]) {
      testWidgets('at ${width.toInt()} px, on every page', (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // Every category, not the four that were named here by hand. General
        // happens to be the one that opens, so it was covered; **AI was never
        // opened at any width**, and a page the overflow check never visits is a
        // page with no overflow check.
        //
        // English labels, the way the rest of this file names things: asking the
        // delegate for them means awaiting a real future inside the fake clock
        // `testWidgets` runs under, and that never returns.
        const pages = [
          'General',
          'Editor',
          'Markdown',
          'Theme',
          'Keybindings',
          'AI models',
          'MCP',
        ];

        // Counted before the override goes on: everything below has to run
        // without an `expect`, because the binding treats a failed expectation
        // while `FlutterError.onError` is replaced as "a test broke the error
        // machinery" and reports that instead of what happened. This test hid a
        // real overflow behind that message for as long as it took to work out.
        final declared = RegExp(r'_catTile\(_Category\.')
            .allMatches(
              File('lib/ui/screens/settings_screen.dart').readAsStringSync(),
            )
            .length;

        final caught = <String>[];
        final missing = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) =>
            caught.add(details.exceptionAsString().split('\n').first);

        await pumpAt(tester);

        for (final page in pages) {
          final tile = find.text(page);
          if (tile.evaluate().isEmpty) {
            missing.add(page);
            continue;
          }
          await tester.tap(tile.first);
          await tester.pump();
        }

        FlutterError.onError = previous;
        tester.takeException();

        expect(missing, isEmpty, reason: '找不到这些分类入口：$missing');
        expect(declared, pages.length,
            reason: '设置页画了 $declared 个分类入口，这里只走了 ${pages.length} 个——'
                '新增了一类就把它加进来，不然它一个宽度都没测过');
        expect(caught, isEmpty, reason: caught.join(' | '));
      });
    }
  });

  testWidgets('the screen tears down without complaint', (tester) async {
    await pump(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}

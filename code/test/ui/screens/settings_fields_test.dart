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

    // Something else on the screen changes, which rebuilds it.
    container.read(settingsProvider.notifier).toggleSideBar();
    await tester.pump();

    expect(fieldShowing('900'), findsOneWidget,
        reason: '重建把没提交的输入抹掉了');
  });

  testWidgets('a value changed elsewhere still reaches the field',
      (tester) async {
    await pump(tester);
    expect(fieldShowing('5000'), findsOneWidget);

    container.read(settingsProvider.notifier).updateConfig(
          (c) => c.copyWith(autoSaveDelay: 1234),
        );
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

        final caught = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) =>
            caught.add(details.exceptionAsString().split('\n').first);
        addTearDown(() => FlutterError.onError = previous);

        await pumpAt(tester);

        for (final page in ['Editor', 'Markdown', 'Theme', 'Keybindings']) {
          final tile = find.text(page);
          expect(tile, findsWidgets, reason: '找不到 $page 分类入口');
          await tester.tap(tile.first);
          await tester.pump();
        }

        expect(caught, isEmpty, reason: caught.join(' | '));
        tester.takeException();
      });
    }
  });

  testWidgets('the screen tears down without complaint', (tester) async {
    await pump(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/ui/widgets/plugin_panel.dart';

/// An installed plugin can be opened in the reader's file manager.
///
/// A plugin keeps its settings in its own directory, and that directory is
/// nowhere near the editor's install path — it is under the system's
/// application-support directory, which nobody can be expected to guess.
void main() {
  late Directory support;

  setUp(() {
    support = Directory.systemTemp.createTempSync('plugin_folder_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => support.path,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    if (support.existsSync()) support.deleteSync(recursive: true);
  });

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PluginPanel()),
      ),
    ));
    // The panel reads the plugin directory off the real filesystem, and real
    // I/O never completes under the fake clock a widget test runs on.
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
      if (find.text('Demo').evaluate().isNotEmpty) break;
    }
    expect(find.text('Demo'), findsOneWidget);
  }

  void install(String id) {
    final dir = Directory('${support.path}/plugins/$id')
      ..createSync(recursive: true);
    File('${dir.path}/manifest.json').writeAsStringSync(jsonEncode({
      'id': id,
      'name': 'Demo',
      'version': '1.0.0',
      'runtime': 'lua',
      'entrypoint': 'plugin.lua',
    }));
  }

  testWidgets('right-clicking an installed plugin offers its folder',
      (tester) async {
    install('com.example.demo');

    await show(tester);

    await tester.tapAt(
      tester.getCenter(find.text('Demo')),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle();

    expect(find.text('Open plugin folder'), findsOneWidget);
  });

  testWidgets('the whole row answers the right-click, not just the name',
      (tester) async {
    install('com.example.demo');
    await show(tester);

    // The version line, which is what someone right-clicking a list entry is
    // as likely to hit as the name itself.
    await tester.tapAt(
      tester.getCenter(find.textContaining('1.0.0')),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle();

    expect(find.text('Open plugin folder'), findsOneWidget);
  });
}

import 'dart:convert';

import '../../support/wait_for.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/ui/screens/plugin_settings_screen.dart';

/// A plugin's settings page is drawn by the editor from what the plugin
/// declared, not by the plugin itself.
///
/// The first version of this page started the plugin as a separate process and
/// asked it for its settings over JSON-RPC, then showed the reply as raw JSON
/// in a text box. Plugins do not run as separate processes any more — a script
/// plugin has no process to ask — so that page could only ever show an error,
/// and even when it worked it asked the reader to hand-edit JSON.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('plugin_settings_'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  PluginManifest install(List<Map<String, dynamic>> fields,
      {Map<String, dynamic> extra = const {}}) {
    Directory('${root.path}/com.example.demo').createSync(recursive: true);
    File('${root.path}/com.example.demo/plugin.lua').writeAsStringSync('');
    return PluginManifest.fromJson({
      'id': 'com.example.demo',
      'name': 'Demo',
      'version': '1.0.0',
      'runtime': 'lua',
      'entrypoint': 'plugin.lua',
      'settings': fields,
      ...extra,
    });
  }

  Future<void> show(WidgetTester tester, PluginManifest manifest) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        // The page is a tab now, so it draws no Scaffold of its own — the
        // editor area it sits in has one.
        home: Scaffold(
          body: PluginSettingsScreen(
            plugin: manifest,
            installDirectory: root.path,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Map<String, dynamic> saved() => jsonDecode(
        File('${root.path}/com.example.demo/settings.json').readAsStringSync(),
      ) as Map<String, dynamic>;

  /// Presses Save and waits for the file to actually be on disk.
  ///
  /// The tap has to happen inside `runAsync`: writing the file is real I/O,
  /// and everything a widget test does otherwise runs on a fake clock that
  /// never lets real I/O finish.
  Future<void> save(WidgetTester tester) async {
    final file = File('${root.path}/com.example.demo/settings.json');
    await tester.runAsync(() async {
      await tester.tap(find.byType(FilledButton));
      // The shared poll, not a loop written here: that one gave up after a
      // second, which is not long for a write on a busy machine.
      await waitFor(
          () => file.existsSync() && file.readAsStringSync().isNotEmpty);
    });
    expect(file.existsSync() && file.readAsStringSync().isNotEmpty, isTrue,
        reason: '设置没有写到磁盘');
    await tester.pump();
  }

  testWidgets('each declared field gets a control, filled with its default',
      (tester) async {
    await show(
        tester,
        install([
          {'key': 'target', 'title': 'Target language', 'default': 'Japanese'},
          {'key': 'formal', 'title': 'Formal tone', 'type': 'boolean'},
        ]));

    expect(find.text('Target language'), findsOneWidget);
    expect(find.text('Japanese'), findsOneWidget);
    expect(find.text('Formal tone'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget,
        reason: 'boolean 字段该给开关，而不是让人手打 true');
  });

  testWidgets('what the reader types is saved under the declared key',
      (tester) async {
    await show(
        tester,
        install([
          {'key': 'target', 'title': 'Target language', 'default': 'Japanese'},
        ]));

    await tester.enterText(find.byType(TextField), 'Korean');
    await save(tester);

    expect(saved(), {'target': 'Korean'});
  });

  testWidgets('a switch saves the words the script compares against',
      (tester) async {
    await show(
        tester,
        install([
          {'key': 'formal', 'title': 'Formal tone', 'type': 'boolean'},
        ]));

    await tester.tap(find.byType(Switch));
    await save(tester);

    expect(saved(), {'formal': 'true'});
  });

  testWidgets('a password field does not show the key on screen',
      (tester) async {
    await show(
        tester,
        install([
          {'key': 'token', 'title': 'Token', 'type': 'password',
            'default': 'sk-secret'},
        ]));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isTrue);
  });

  testWidgets('the field titles come from the plugin in the reader language',
      (tester) async {
    await show(
        tester,
        install([
          {'key': 'target', 'title': 'settings.target'},
        ], extra: {
          'locales': {
            'en': {'settings.target': 'Target language'},
            'zh': {'settings.target': '目标语言'},
          },
        }));

    expect(find.text('Target language'), findsOneWidget);
    expect(find.text('settings.target'), findsNothing);
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/widgets/plugin_tip.dart';
import 'package:marktext_plus/ui/widgets/right_side_bar.dart';

/// The right side bar exists only when a plugin has put something in it.
///
/// `ui.sidebar` was in the permission list with nothing behind it. A rail of
/// icons with no icons in it is a strip of nothing taking width from the
/// document, so with no panels contributed there is no rail at all.
void main() {
  late Directory support;

  setUp(() {
    support = Directory.systemTemp.createTempSync('right_bar_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => support.path,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'), null);
    if (support.existsSync()) support.deleteSync(recursive: true);
  });

  void install(String id, {required List<Map<String, String>> panels,
      List<String> permissions = const ['ui.sidebar'],
      String script = ''}) {
    final dir = Directory('${support.path}/plugins/$id')
      ..createSync(recursive: true);
    File('${dir.path}/manifest.json').writeAsStringSync(jsonEncode({
      'id': id,
      'name': 'Demo',
      'version': '1.0.0',
      'runtime': 'lua',
      'entrypoint': 'plugin.lua',
      'permissions': permissions,
      'panels': panels,
    }));
    File('${dir.path}/plugin.lua').writeAsStringSync(script);
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      // The drawer runs the whole command now rather than one step of it, so
      // it reads the settings the way every other command path does — which
      // needs a config service, which a widget test has to hand it.
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: support.path),
            AppConfig(),
          ),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        // The card layer is where a question is asked, and in the running
        // application it wraps the whole window. A drawer that asks needs it
        // present or the question has nowhere to appear.
        home: Scaffold(
          body: PluginTipLayer(
            child: Row(
              children: [Expanded(child: SizedBox()), RightSideBar()],
            ),
          ),
        ),
      ),
    ));
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
  }

  testWidgets('with nothing contributed the bar is not there', (tester) async {
    await pump(tester);
    expect(tester.getSize(find.byType(RightSideBar)).width, 0,
        reason: '没有图标的图标栏就是白占宽度');
  });

  testWidgets('a contributed panel puts an icon in the rail', (tester) async {
    install('com.example.demo',
        panels: [{'id': 'outline', 'title': 'Outline', 'icon': 'list'}]);
    await pump(tester);

    expect(tester.getSize(find.byType(RightSideBar)).width, greaterThan(0));
    expect(find.byIcon(Icons.list), findsOneWidget);
  });

  testWidgets('a panel from a plugin without the permission is not shown',
      (tester) async {
    install('com.example.demo',
        panels: [{'id': 'outline', 'title': 'Outline', 'icon': 'list'}],
        permissions: const []);
    await pump(tester);

    expect(tester.getSize(find.byType(RightSideBar)).width, 0,
        reason: '没申请 ui.sidebar 就不该出现在侧栏');
  });

  testWidgets('pressing the icon opens the drawer, pressing again closes it',
      (tester) async {
    install('com.example.demo',
        panels: [{'id': 'outline', 'title': 'Outline', 'icon': 'list'}]);
    await pump(tester);

    final railOnly = tester.getSize(find.byType(RightSideBar)).width;

    await tester.tap(find.byIcon(Icons.list));
    await tester.pump();
    expect(tester.getSize(find.byType(RightSideBar)).width,
        greaterThan(railOnly));
    expect(find.text('Outline'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.list));
    await tester.pump();
    expect(tester.getSize(find.byType(RightSideBar)).width, railOnly,
        reason: '再点一次该收起抽屉，只留图标栏');
  });

  testWidgets('a panel that asks a question gets to ask it', (tester) async {
    // The drawer used to run one step of the command and render whatever came
    // back as text, so a plugin that opens with a question — which the one
    // official plugin does, since writing needs a brief — filled the drawer
    // with the sentence "a panel cannot ask a question" and offered nowhere
    // to type. Manual testing put it plainly: no input box, so no way to say
    // what to write.
    install('com.example.asker', panels: [
      {'id': 'ask.something', 'title': 'Ask', 'icon': 'edit_note'},
    ], script: '''
function on_command(ctx)
  if ctx.answer == nil then
    return { ask = "What should it say?" }
  end
  return { show = "you said " .. ctx.answer }
end
''');
    await pump(tester);
    await tester.tap(find.byIcon(Icons.edit_note));
    for (var attempt = 0; attempt < 10; attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }

    expect(find.textContaining('cannot ask'), findsNothing,
        reason: '面板不该再用一句话打发掉提问');
    expect(find.textContaining('What should it say?'), findsOneWidget,
        reason: '问题该真的问出来');
  });
}

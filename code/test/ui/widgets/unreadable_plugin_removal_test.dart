import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/ui/widgets/plugin_panel.dart';

/// A plugin the editor cannot read can still be got rid of.
///
/// The panel names them — "installed but unreadable", with the reason — and
/// offered nothing else. The uninstall button belongs to the list above,
/// which is built from manifests that parsed, so the one plugin a reader
/// actually wants gone is the only one with no way to go.
///
/// Reported from a real machine: an old build of the AI plugin, shipping Dart
/// source, sat there through "I deleted all the installed plugins" — because
/// deleting them all is done with buttons this one never had.
void main() {
  late Directory support;

  setUp(() {
    support = Directory.systemTemp.createTempSync('unreadable_plugin_');
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

  /// A plugin directory the manifest reader will refuse: Dart source, which
  /// is what the machine that reported this had installed.
  Directory installUnreadable(String id) {
    final dir = Directory('${support.path}/plugins/$id')
      ..createSync(recursive: true);
    File('${dir.path}/manifest.json').writeAsStringSync(jsonEncode({
      'id': id,
      'name': 'Old AI plugin',
      'version': '0.0.9',
      'entrypoint': 'plugin.dart',
    }));
    File('${dir.path}/plugin.dart').writeAsStringSync('void main() {}');
    return dir;
  }

  Future<void> show(WidgetTester tester, String reason) async {
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
    // Real I/O never completes under the fake clock a widget test runs on.
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
      if (find.textContaining(reason).evaluate().isNotEmpty) break;
    }
  }

  testWidgets('an unreadable plugin can be removed from the panel',
      (tester) async {
    final dir = installUnreadable('com.example.old-ai');
    await show(tester, 'com.example.old-ai');

    expect(find.textContaining('com.example.old-ai'), findsOneWidget,
        reason: '前提是这条确实被列出来了');

    final remove = find.descendant(
      of: find.ancestor(
        of: find.textContaining('com.example.old-ai'),
        matching: find.byType(Row),
      ),
      matching: find.byIcon(Icons.delete_outline),
    );
    expect(remove, findsOneWidget,
        reason: '读不出来的插件也要能删掉——它正是读者唯一想删的那个');

    await tester.tap(remove.first);
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
      if (!dir.existsSync()) break;
    }

    expect(dir.existsSync(), isFalse, reason: '目录要真的从磁盘上消失');
  });
}

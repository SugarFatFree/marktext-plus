import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// Clicking an entry in a long document's outline.
///
/// The preview draws a long document a batch at a time, and only a prefix of
/// it is parsed at first. A heading that has not been drawn has no key, and
/// the lookup answers with the nearest heading above rather than nothing — so
/// a request for a heading near the end was treated as satisfied by the last
/// heading drawn, thousands of lines short, and then thrown away. Nothing
/// corrected it: the reader clicked an entry and landed somewhere else.
void main() {
  late Directory configDir;
  late ProviderContainer container;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('scroll_heading');
    container = ProviderContainer(overrides: [
      settingsProvider.overrideWith((ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(),
          )),
    ]);
  });
  tearDown(() {
    container.dispose();
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  testWidgets('a heading near the end of a long document is scrolled to',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final source = StringBuffer();
    for (var i = 0; i < 400; i++) {
      source.writeln('## 第 $i 节\n');
      source.writeln('第 $i 段正文。\n');
    }
    final text = source.toString();
    final target = text.split('\n').indexWhere((l) => l.trim() == '## 第 390 节') + 1;
    expect(target, greaterThan(0));

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
          home: Scaffold(body: MarkdownRenderer(markdown: text)),
        ),
      ),
    );
    // One frame only: fifty blocks are on screen and the rest of the document
    // has not even been parsed. This is the moment the outline is clickable
    // and the bug was reachable.
    await tester.pump();
    final heading = find.textContaining('第 390 节', findRichText: true);
    expect(heading, findsNothing, reason: '前提：目标标题此时还没画出来');

    container.read(editorProvider.notifier).scrollToLine(target);
    for (var round = 0; round < 4; round++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    expect(heading, findsOneWidget, reason: '目标标题始终没有被画出来');

    // In the tree is not enough — by now every block is. It has to be on
    // screen.
    final box = tester.renderObject<RenderBox>(heading);
    final top = box.localToGlobal(Offset.zero).dy;
    expect(top, greaterThanOrEqualTo(-box.size.height),
        reason: '目标标题在视口上方，没滚到');
    expect(top, lessThanOrEqualTo(800),
        reason: '目标标题在视口下方，没滚到');
  });

  testWidgets('a heading in a short document still works', (tester) async {
    // The whole document is parsed and drawn on the first frame, which is the
    // path that always worked and must keep working.
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final source = StringBuffer();
    for (var i = 0; i < 30; i++) {
      source.writeln('## 第 $i 节\n');
      source.writeln('第 $i 段正文。\n');
    }
    final text = source.toString();
    final target = text.split('\n').indexWhere((l) => l.trim() == '## 第 28 节') + 1;

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
          home: Scaffold(body: MarkdownRenderer(markdown: text)),
        ),
      ),
    );
    await tester.pump();

    container.read(editorProvider.notifier).scrollToLine(target);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final heading = find.textContaining('第 28 节', findRichText: true);
    final box = tester.renderObject<RenderBox>(heading);
    final top = box.localToGlobal(Offset.zero).dy;
    expect(top, greaterThanOrEqualTo(-box.size.height));
    expect(top, lessThanOrEqualTo(800));
  });
}

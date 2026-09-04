import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// Where typing starts in an empty preview.
///
/// On the first line, as it does in the source pane. An editor that opens
/// halfway down the page is one the reader has to go looking for.
void main() {
  late Directory configDir;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('caret_cfg_');
  });

  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<void> pump(
    WidgetTester tester, {
    required bool split,
    Size size = const Size(800, 600),
    String markdown = '',
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(
              ConfigService(configDir: configDir.path),
              AppConfig(),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MarkdownRenderer(
              markdown: markdown,
              followsSource: split,
              onSourceChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the place to click is at the top, not down the page', (
    tester,
  ) async {
    await pump(tester, split: true);
    final area = tester.getRect(find.byType(MarkdownRenderer));
    final target = tester.getRect(find.byType(GestureDetector).last);
    expect(target.top - area.top, lessThan(60), reason: '空文档时该点的地方要在第一行，不该往下推');
  });

  testWidgets('the editor opens on the first line', (tester) async {
    await pump(tester, split: true);
    final area = tester.getRect(find.byType(MarkdownRenderer));

    await tester.tap(find.byType(GestureDetector).last);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    final editor = tester.getRect(find.byType(TextField));
    expect(
      editor.top - area.top,
      lessThan(60),
      reason:
          '编辑框在第 ${(editor.top - area.top).toStringAsFixed(0)} 像素处，'
          '不是第一行——读者得去找它',
    );
  });

  testWidgets('it opens on the first line outside split view too', (
    tester,
  ) async {
    await pump(tester, split: false);
    final area = tester.getRect(find.byType(MarkdownRenderer));

    await tester.tap(find.byType(GestureDetector).last);
    await tester.pumpAndSettle();

    final editor = tester.getRect(find.byType(TextField));
    expect(editor.top - area.top, lessThan(60));
  });

  testWidgets('and it starts at the left, where the source pane starts', (
    tester,
  ) async {
    // The preview centres its content inside a maximum width, which is right
    // for a page of prose and wrong for a caret waiting on an empty document:
    // beside a source pane that starts hard against the left, an editor
    // floating in the middle reads as something else entirely.
    await pump(tester, split: true, size: const Size(1600, 900));
    final area = tester.getRect(find.byType(MarkdownRenderer));

    await tester.tap(find.byType(GestureDetector).last);
    await tester.pumpAndSettle();

    final editor = tester.getRect(find.byType(TextField));
    expect(
      editor.left - area.left,
      lessThan(60),
      reason:
          '编辑框离左边 ${(editor.left - area.left).toStringAsFixed(0)} 像素，'
          '源码那半边是贴着左边开始的',
    );
  });

  testWidgets('a document with something in it is still centred', (
    tester,
  ) async {
    // The centring is right for a page of prose; only the empty case is not.
    await pump(
      tester,
      split: false,
      size: const Size(1600, 900),
      markdown: '# Title\n\nA paragraph of prose.',
    );
    final area = tester.getRect(find.byType(MarkdownRenderer));
    final title = tester.getRect(find.text('Title'));
    expect(
      title.left - area.left,
      greaterThan(100),
      reason: '有内容的文档该保持居中，不能被这次改动一起改掉',
    );
  });
}

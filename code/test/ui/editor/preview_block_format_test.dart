import 'dart:io';

import 'package:flutter/gestures.dart';
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
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// Formatting commands while a block is open in the preview.
///
/// The block editor holds the block's markdown and is an ordinary text field,
/// so Ctrl+B there means what it means anywhere. It used to mean nothing: the
/// command was recorded as pending for a source pane to carry out, and in
/// preview mode there is no source pane — so nothing happened, and the command
/// stayed pending to go off later at whatever caret a source pane next had.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('previewfmt'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          AppConfig(),
        ),
      ),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  Widget wrap(ProviderContainer container, Widget child) =>
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
          home: Scaffold(body: child),
        ),
      );

  Future<TextEditingController> openBlock(WidgetTester tester) async {
    final block = find.byType(PreviewEditableBlock).first;
    await tester.tap(block);
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(block);
    await tester.pump(kDoubleTapTimeout);
    await tester.pump();
    return tester.widget<TextField>(find.byType(TextField)).controller!;
  }

  testWidgets('bold wraps the selection inside the block', (tester) async {
    final container = makeContainer();
    await tester.pumpWidget(wrap(
      container,
      MarkdownRenderer(markdown: 'hello world\n', onSourceChanged: (_) {}),
    ));
    await tester.pump();

    final controller = await openBlock(tester);
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();

    container.read(editorProvider.notifier).applyFormat(FormatAction.bold);
    await tester.pump();
    await tester.pump();

    expect(controller.text, '**hello** world', reason: '块编辑器里加粗没生效');
    expect(container.read(editorProvider).pendingFormat, isNull,
        reason: '命令没有被清掉，之后会在别处突然生效');
  });

  // One test per command, not a loop inside one: pumping a second widget of
  // the same type at the same position reuses the State, so the previous
  // iteration's open block editor is still there and the finder for a
  // closed block finds nothing.
  for (final (action, expected) in [
    (FormatAction.italic, '*hello* world'),
    (FormatAction.inlineCode, '`hello` world'),
    (FormatAction.strikethrough, '~~hello~~ world'),
    (FormatAction.highlight, '==hello== world'),
  ]) {
    testWidgets('${action.name} wraps the selection too', (tester) async {
      final container = makeContainer();
      await tester.pumpWidget(wrap(
        container,
        MarkdownRenderer(markdown: 'hello world\n', onSourceChanged: (_) {}),
      ));
      await tester.pump();
      final controller = await openBlock(tester);
      controller.selection =
          const TextSelection(baseOffset: 0, extentOffset: 5);
      await tester.pump();
      container.read(editorProvider.notifier).applyFormat(action);
      await tester.pump();
      await tester.pump();
      expect(controller.text, expected);
    });
  }

  testWidgets('a command the block cannot carry out is still cleared',
      (tester) async {
    // Inserting a table is about the document, not about this block's text.
    // It does nothing here — but it must not stay pending, or it goes off in
    // the source pane later, at a caret the reader never put it at.
    final container = makeContainer();
    await tester.pumpWidget(wrap(
      container,
      MarkdownRenderer(markdown: 'hello world\n', onSourceChanged: (_) {}),
    ));
    await tester.pump();
    final controller = await openBlock(tester);
    await tester.pump();

    container.read(editorProvider.notifier).applyFormat(FormatAction.table);
    await tester.pump();
    await tester.pump();

    expect(controller.text, 'hello world');
    expect(container.read(editorProvider).pendingFormat, isNull);
  });

  testWidgets('with both panes on screen, only the preview acts',
      (tester) async {
    // Split view. Both a source pane and an editable preview are mounted; a
    // command applied twice would bold in two places at once.
    final container = makeContainer();
    await tester.pumpWidget(wrap(
      container,
      Column(children: [
        const SizedBox(
          height: 200,
          child: SourceEditor(tabId: 'split', initialContent: 'hello world\n'),
        ),
        Expanded(
          child: MarkdownRenderer(
            markdown: 'hello world\n',
            onSourceChanged: (_) {},
          ),
        ),
      ]),
    ));
    await tester.pumpAndSettle();

    final source = tester
        .widget<TextField>(find.byType(TextField).first)
        .controller!;

    final block = find.byType(PreviewEditableBlock).first;
    await tester.tap(block);
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(block);
    await tester.pump(kDoubleTapTimeout);
    await tester.pump();

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2), reason: '两个面板都该在场');
    final blockEditor = tester.widget<TextField>(fields.last).controller!;
    blockEditor.selection =
        const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();

    container.read(editorProvider.notifier).applyFormat(FormatAction.bold);
    await tester.pump();
    await tester.pump();

    expect(blockEditor.text, '**hello** world');
    expect(source.text, 'hello world\n', reason: '源码面板不该也被加粗');
  });
}

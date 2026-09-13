import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// Two commands in a row come back one at a time.
///
/// The editor's history closes a step 300 ms after a pause in typing. A command
/// — bold, a heading, an indent, a block move — used to write the controller and
/// leave the boundary to that, so two commands quicker than the pause reached
/// the stack as one entry holding only the last state: one press of Ctrl+Z took
/// back both, and anything typed in the same window went with them.
///
/// Two of each, never one: a single command comes back either way, because the
/// editor puts the document's first state on the stack when it is built and undo
/// adds what is on screen before stepping. The second is the one that needs the
/// step to have been closed.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('one_step'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<(ProviderContainer, TextEditingController)> pump(
    WidgetTester tester,
    String content,
  ) async {
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            // A source pane on screen: format actions are only acted on where
            // there is one, and the default mode is preview.
            AppConfig(editMode: EditMode.source),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SourceEditor(tabId: 'tab', initialContent: content),
          ),
        ),
      ),
    );
    await tester.pump();
    return (container, container.read(editorProvider.notifier).controller!);
  }

  Future<void> command(
    WidgetTester tester,
    ProviderContainer container,
    FormatAction action, {
    int? at,
    (int, int)? over,
  }) async {
    final controller = container.read(editorProvider.notifier).controller!;
    controller.selection = over == null
        ? TextSelection.collapsed(offset: at ?? 0)
        : TextSelection(baseOffset: over.$1, extentOffset: over.$2);
    container.read(editorProvider.notifier).applyFormat(action);
    await tester.pump();
  }

  void undo(ProviderContainer container) =>
      container.read(editorProvider.notifier).undo();

  /// Each case: what to run twice, and the three texts it should pass through
  /// coming back.
  testWidgets('two words made bold come back one at a time', (tester) async {
    final (c, controller) = await pump(tester, 'aa bb\n');

    await command(tester, c, FormatAction.bold, over: (0, 2));
    expect(controller.text, '**aa** bb\n');
    await command(tester, c, FormatAction.bold, over: (7, 9));
    expect(controller.text, '**aa** **bb**\n');

    undo(c);
    await tester.pump();
    expect(controller.text, '**aa** bb\n', reason: '一次退回了两次加粗');

    undo(c);
    await tester.pump();
    expect(controller.text, 'aa bb\n');
  });

  testWidgets('two headings come back one at a time', (tester) async {
    final (c, controller) = await pump(tester, 'one\ntwo\n');

    await command(tester, c, FormatAction.heading1, at: 0);
    await command(tester, c, FormatAction.heading2, at: 6);
    expect(controller.text, '# one\n## two\n');

    undo(c);
    await tester.pump();
    expect(controller.text, '# one\ntwo\n', reason: '一次退回了两个标题');
  });

  testWidgets('two lines duplicated come back one at a time', (tester) async {
    final (c, controller) = await pump(tester, 'x\n');

    await command(tester, c, FormatAction.duplicateLine, at: 0);
    await command(tester, c, FormatAction.duplicateLine, at: 0);
    expect(controller.text, 'x\nx\nx\n');

    undo(c);
    await tester.pump();
    expect(controller.text, 'x\nx\n', reason: '一次退回了两次复制行');

    undo(c);
    await tester.pump();
    expect(controller.text, 'x\n');
  });

  testWidgets('two blocks moved come back one at a time', (tester) async {
    final (c, controller) = await pump(tester, 'a\n\nb\n\nc\n');

    await command(tester, c, FormatAction.moveBlockDown, at: 0);
    final once = controller.text;
    await command(tester, c, FormatAction.moveBlockDown, at: once.indexOf('a'));
    expect(controller.text, isNot(once), reason: '第二次移动没有发生');

    undo(c);
    await tester.pump();
    expect(controller.text, once, reason: '一次退回了两次移动');
  });
}

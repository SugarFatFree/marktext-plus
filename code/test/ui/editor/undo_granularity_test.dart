import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// How much one press of undo takes back.
///
/// Snapshots were governed by a 300 ms debounce alone, so a paragraph typed
/// without pausing produced no snapshot until the writer stopped — and one
/// press of undo took the whole paragraph away. Upstream MarkText fixed the
/// same fault (#3825); its end-to-end test states the result plainly: type
/// `hello world`, press undo once, and `hello` is still there.
void main() {
  late Directory configDir;
  late ProviderContainer container;
  var tabCounter = 0;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('undo_grain');
    container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          AppConfig(),
        ),
      ),
    ]);
  });
  tearDown(() {
    container.dispose();
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<TextEditingController> editor(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SourceEditor(tabId: 'tab-${tabCounter++}'),
          ),
        ),
      ),
    );
    await tester.pump();
    return tester.widget<TextField>(find.byType(TextField)).controller!;
  }

  /// Types [text] one character at a time with no pause between them, which
  /// is the case the debounce alone could not describe.
  Future<void> typeWithoutPausing(
    WidgetTester tester,
    TextEditingController controller,
    String text,
  ) async {
    for (var i = 1; i <= text.length; i++) {
      controller.value = TextEditingValue(
        text: text.substring(0, i),
        selection: TextSelection.collapsed(offset: i),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    // The writer stops, which closes the last step.
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('undo takes back one word, not the whole run', (tester) async {
    final controller = await editor(tester);
    await typeWithoutPausing(tester, controller, 'hello world');
    expect(controller.text, 'hello world');

    container.read(editorProvider.notifier).undo();
    await tester.pump();
    expect(controller.text, contains('hello'),
        reason: '一次撤销把整句都拿走了');
    expect(controller.text, isNot(contains('world')));

    container.read(editorProvider.notifier).undo();
    await tester.pump();
    expect(controller.text, isNot(contains('hello')));
  });

  testWidgets('a Chinese sentence is broken up by its own punctuation',
      (tester) async {
    // Chinese has no spaces, so without the CJK punctuation in the boundary
    // set every sentence would be one undo step again.
    final controller = await editor(tester);
    await typeWithoutPausing(tester, controller, '第一句。第二句。');
    expect(controller.text, '第一句。第二句。');

    container.read(editorProvider.notifier).undo();
    await tester.pump();
    expect(controller.text, '第一句。',
        reason: '中文标点没有断开撤销步，整段被一次拿走');
  });

  testWidgets('redo puts back exactly what undo took', (tester) async {
    final controller = await editor(tester);
    await typeWithoutPausing(tester, controller, 'hello world');

    container.read(editorProvider.notifier).undo();
    await tester.pump();
    final afterUndo = controller.text;

    container.read(editorProvider.notifier).redo();
    await tester.pump();
    expect(controller.text, 'hello world');

    container.read(editorProvider.notifier).undo();
    await tester.pump();
    expect(controller.text, afterUndo);
  });

  testWidgets('undoing to the beginning leaves an empty document',
      (tester) async {
    final controller = await editor(tester);
    await typeWithoutPausing(tester, controller, 'one two three');

    for (var i = 0; i < 10; i++) {
      container.read(editorProvider.notifier).undo();
      await tester.pump();
    }
    expect(controller.text, '');
  });
}

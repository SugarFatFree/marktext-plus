import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// Typing does not get an undo step per keystroke.
///
/// BUG-482 funnelled twenty-five command-like writes through one entry point
/// that records a restore point first, and deliberately left six alone: the
/// writes that happen while somebody is typing — auto-pairing a bracket,
/// deleting its other half with Backspace, continuing a list on Enter. A step
/// per keystroke makes undo character-by-character.
///
/// That half was guarded only by a test of the code's *shape*, which cannot
/// catch this: funnelling a keystroke write through the entry point — the thing
/// that looks like doing it right — leaves that guard green, because the entry
/// point is a name it allows. So the behaviour is asserted here.
///
/// Two things about the staging, both learnt the hard way:
///
/// A letter cannot be typed with `simulateKeyDownEvent`. When the editor does
/// not handle a key the framework inserts the character, and a widget test does
/// not simulate that — `autopair_test` says so too. So an ordinary letter is put
/// in through the controller, which is exactly the path the framework's own
/// insertion takes, and only the keys the editor *does* handle are simulated.
///
/// And each case types a letter *before* the keystroke under test. Without it
/// the state to come back to is already on the stack — the editor pushes the
/// document's first state when it is built — so an extra push changes nothing
/// and the mutation is equivalent. The letter makes the top of the stack stale,
/// which is the situation a reader is in whenever they are in the middle of a
/// word.
///
/// Four of the six keystroke writes are here, one test each, and mutating any
/// one of them into the entry point turns its own test red and only that one.
/// The other two are out of scope on purpose:
///
/// * `didUpdateWidget`, where text arrives from outside the pane — that is the
///   tab's history to record, and `what_an_agent_wrote_can_be_taken_back_test`
///   and `an_edit_in_the_preview_can_be_undone_test` hold that end;
/// * the write that only moves the caret past a closing character already
///   there. It changes no text, so there is nothing to come back to.
void main() {
  late Directory configDir;
  var tabCounter = 0;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('typing_undo');
    tabCounter = 0;
  });
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  /// An editor holding [initial], focused, with the caret at the end.
  Future<(ProviderContainer, TextEditingController)> open(
    WidgetTester tester,
    String initial,
  ) async {
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          AppConfig(editMode: EditMode.source),
        ),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SourceEditor(
              tabId: 'tab-${tabCounter++}',
              initialContent: initial,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(TextField));
    await tester.pump();

    final controller =
        tester.widget<TextField>(find.byType(TextField)).controller!;
    controller.value = TextEditingValue(
      text: initial,
      selection: TextSelection.collapsed(offset: initial.length),
    );
    await tester.pump();
    return (container, controller);
  }

  /// One ordinary character, the way the framework inserts one.
  Future<void> typeLetter(
    WidgetTester tester,
    TextEditingController controller,
    String letter,
  ) async {
    final at = controller.selection.baseOffset;
    final text = controller.text;
    controller.value = TextEditingValue(
      text: text.substring(0, at) + letter + text.substring(at),
      selection: TextSelection.collapsed(offset: at + letter.length),
    );
    await tester.pump();
  }

  /// A key the editor handles itself.
  Future<void> pressKey(
    WidgetTester tester,
    LogicalKeyboardKey key, {
    String? character,
  }) async {
    await simulateKeyDownEvent(key, character: character);
    await simulateKeyUpEvent(key);
    await tester.pump();
  }

  /// Long enough for the typing debounce to close the step, as a pause does.
  Future<void> pause(WidgetTester tester) =>
      tester.pump(const Duration(milliseconds: 400));

  void undo(ProviderContainer container) =>
      container.read(editorProvider.notifier).undo();

  testWidgets('an auto-paired bracket goes back with the word it is in',
      (tester) async {
    final (c, controller) = await open(tester, 'x');

    await typeLetter(tester, controller, 'y');
    await pressKey(tester, LogicalKeyboardKey.keyA, character: '(');
    expect(controller.text, 'xy()',
        reason: '没有自动配对，这条测的就不是它了');
    await pause(tester);

    undo(c);
    await tester.pump();

    expect(controller.text, 'x',
        reason: '配对那一下自己断开了撤销步——那会让撤销变成逐字，'
            '而这里只退回了同一次输入里的一部分');
  });

  testWidgets('a list continued on Enter is part of the same step',
      (tester) async {
    final (c, controller) = await open(tester, '- one');

    await typeLetter(tester, controller, 'z');
    await pressKey(tester, LogicalKeyboardKey.enter);
    expect(controller.text, '- onez\n- ',
        reason: '回车没有续上列表，这条测的就不是它了');
    await pause(tester);

    undo(c);
    await tester.pump();

    expect(controller.text, '- one',
        reason: '续列表那一下和它前面打的字被分成了两次撤销');
  });

  testWidgets('a pair typed over a selection wraps it in the same step',
      (tester) async {
    final (c, controller) = await open(tester, 'ab');

    await typeLetter(tester, controller, 'c');
    controller.selection =
        const TextSelection(baseOffset: 1, extentOffset: 2);
    await tester.pump();
    await pressKey(tester, LogicalKeyboardKey.keyA, character: '(');
    expect(controller.text, 'a(b)c',
        reason: '打配对键没有包裹选中的字，这条测的就不是它了');
    await pause(tester);

    undo(c);
    await tester.pump();

    expect(controller.text, 'ab',
        reason: '包裹那一下自己断开了撤销步');
  });

  testWidgets('Backspace taking both halves of a pair is one step with it',
      (tester) async {
    final (c, controller) = await open(tester, 'x');

    await typeLetter(tester, controller, 'y');
    await pressKey(tester, LogicalKeyboardKey.keyA, character: '(');
    expect(controller.text, 'xy()');
    await pressKey(tester, LogicalKeyboardKey.backspace);
    expect(controller.text, 'xy',
        reason: '退格没有带走配对的另一半，这条测的就不是它了');
    await pause(tester);

    undo(c);
    await tester.pump();

    expect(controller.text, 'x',
        reason: '配对与删除各自断开了撤销步，一次输入要按三次撤销');
  });
}

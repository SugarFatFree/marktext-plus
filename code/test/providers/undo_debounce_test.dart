import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/providers/editor_provider.dart';

/// Undo when the newest edit has not been recorded yet.
///
/// Snapshots go onto the stack on a 300 ms debounce, so pressing undo straight
/// after typing — which is exactly when people press it — finds a stack that
/// does not yet know about what they just typed. Both ways that went wrong
/// were silent: with one entry the key did nothing at all, and with more it
/// stepped back twice and took away an edit nobody asked to lose.
void main() {
  late EditorNotifier notifier;
  late TextEditingController controller;

  setUp(() {
    notifier = EditorNotifier();
    controller = TextEditingController();
    notifier.setController(controller);
    notifier.setHistoryTab('tab');
  });

  tearDown(() => controller.dispose());

  /// Types [text] without letting the debounce record it.
  void typeWithoutRecording(String text) => controller.text = text;

  test('undo steps back exactly one edit, not two', () {
    notifier.pushHistory('A');
    notifier.pushHistory('AB');
    typeWithoutRecording('ABC');

    notifier.undo();

    expect(controller.text, 'AB', reason: '退了两步，把 B 也吞掉了');
  });

  test('undo works when the only recorded state is the first one', () {
    notifier.pushHistory('A');
    typeWithoutRecording('AB');

    notifier.undo();

    expect(controller.text, 'A', reason: '什么都没发生 —— 撤销键像是坏的');
  });

  test('redo comes back to where undo was pressed', () {
    notifier.pushHistory('A');
    typeWithoutRecording('AB');
    notifier.undo();

    notifier.redo();

    expect(controller.text, 'AB');
  });

  test('undo at the very beginning leaves the document alone', () {
    // The document as it was opened: the text and the one recorded state
    // agree, which is what the editor sets up when a tab is first shown.
    controller.text = 'A';
    notifier.pushHistory('A');

    notifier.undo();

    expect(controller.text, 'A', reason: '没有更早的状态时不该动文本');
  });

  test('repeated undo walks back one step at a time', () {
    notifier.pushHistory('one');
    notifier.pushHistory('one two');
    notifier.pushHistory('one two three');
    typeWithoutRecording('one two three four');

    notifier.undo();
    expect(controller.text, 'one two three');
    notifier.undo();
    expect(controller.text, 'one two');
    notifier.undo();
    expect(controller.text, 'one');
  });

  test('an unrecorded edit is not lost — redo brings it back', () {
    // The edit that had not reached the stack still has to be reachable
    // again, or undo becomes a way of destroying work.
    notifier.pushHistory('A');
    typeWithoutRecording('A typed but not yet recorded');

    notifier.undo();
    notifier.redo();

    expect(controller.text, 'A typed but not yet recorded');
  });

  group('the caret comes back with the text', () {
    /// Types [text] and leaves the caret at [caret], without letting the
    /// debounce record it.
    void typeAt(String text, int caret) {
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: caret),
      );
    }

    test('undo puts the caret where the edit was, not at the end', () {
      // A long document: dropping the caret at the end throws the reader to
      // the bottom of the file, away from what they just undid.
      final long = 'x' * 500;
      typeAt('$long HERE', 5);
      notifier.pushHistory(controller.text);
      typeAt('$long HERE more', 8);

      notifier.undo();

      expect(controller.text, '$long HERE');
      expect(controller.selection.baseOffset, 5,
          reason: '光标被丢到文末，撤销之后要重新找回原处');
    });

    test('redo restores its own caret too', () {
      typeAt('one', 3);
      notifier.pushHistory('one');
      typeAt('one two', 7);

      notifier.undo();
      notifier.redo();

      expect(controller.text, 'one two');
      expect(controller.selection.baseOffset, 7);
    });

    test('a caret past the end of an older, shorter state is brought inside',
        () {
      // The recorded position belongs to a document that no longer exists;
      // offsets from it are not positions in this one.
      typeAt('short', 5);
      notifier.pushHistory('short');
      typeAt('short and then a good deal longer', 33);

      notifier.undo();

      expect(controller.selection.baseOffset,
          lessThanOrEqualTo(controller.text.length));
      expect(controller.selection.isValid, isTrue);
    });
  });
}

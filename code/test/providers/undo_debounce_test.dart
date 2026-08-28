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
  group('each tab has its own history', () {
    // The stacks are kept per tab and the editor points them at the tab it is
    // showing. Both editors that host one are keyed by tab id, so a switch
    // builds a fresh state and the pointing happens again — but nothing said
    // so, and undo reaching into another document is a silent way to lose work.
    test('undoing in one tab does not reach into another', () {
      notifier.setHistoryTab('a');
      notifier.pushHistory('a one');
      notifier.pushHistory('a two');

      notifier.setHistoryTab('b');
      notifier.pushHistory('b one');
      notifier.pushHistory('b two');

      controller.text = 'b two';
      notifier.undo();

      expect(controller.text, 'b one', reason: '撤销拿到了别的标签页的历史');
    });

    test('coming back to a tab finds its history where it was left', () {
      notifier.setHistoryTab('a');
      notifier.pushHistory('a one');
      notifier.pushHistory('a two');

      notifier.setHistoryTab('b');
      notifier.pushHistory('b one');

      notifier.setHistoryTab('a');
      controller.text = 'a two';
      notifier.undo();

      expect(controller.text, 'a one');
    });

    test('closing a tab drops its history', () {
      notifier.setHistoryTab('a');
      notifier.pushHistory('a one');
      notifier.pushHistory('a two');

      notifier.forgetHistory('a');
      notifier.setHistoryTab('a');
      controller.text = 'a two';
      notifier.undo();

      expect(controller.text, 'a two', reason: '关掉的标签页的历史还留着');
    });
  });

  test('redo survives the editor being rebuilt', () {
    // Switching between source and split view rebuilds the editor, which
    // records the document it is given. pushHistory clears the redo stack —
    // the one thing that must not happen when nothing was edited — and only
    // does not here because the content it records is the one already on top.
    notifier.pushHistory('one');
    notifier.pushHistory('two');
    controller.text = 'two';
    notifier.undo();
    expect(controller.text, 'one');

    // What a rebuilt editor does with the tab's current content.
    notifier.setHistoryTab('tab');
    notifier.pushHistory(controller.text);

    notifier.redo();
    expect(controller.text, 'two', reason: '重建编辑器把重做栈清掉了');
  });

}

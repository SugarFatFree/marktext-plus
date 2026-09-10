import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/providers/editor_provider.dart';

/// Undo has to work where there is no text field to undo into.
///
/// The right-hand rail offers a plugin's rewrite with an Apply button, and it
/// is used in preview mode — where there is no source editor at all. Apply
/// pushes the document onto the history and writes the new text, so the
/// history is right; then undo looked for a `TextEditingController` to restore
/// into, found none, and returned. Silently: the reader accepted a rewrite of
/// their document and could not take it back.
///
/// So undo and redo answer with the text the document should hold. With a
/// source editor on screen they also put it in the field and the caller can
/// ignore the answer; without one the caller writes it to the tab, which is
/// where the document lives when nothing is being typed into.
void main() {
  test('undo answers with the text to put back when nothing is on screen', () {
    final editor = EditorNotifier()..setHistoryTab('tab-1');

    // What Apply does: the old document onto the history, the new one into the
    // tab. Nothing here is holding the new text, so the caller — which read it
    // from the tab — is the one that can say what it is.
    editor.pushHistory('what the reader wrote');
    expect(
      editor.undo(current: "the plugin's rewrite"),
      'what the reader wrote',
      reason: '预览模式下撤销必须给出要写回的文本，而不是一声不响地什么都不做',
    );
  });

  test('redo answers with the text it took away again', () {
    final editor = EditorNotifier()..setHistoryTab('tab-1');

    editor.pushHistory('first');
    editor.pushHistory('second');
    expect(editor.undo(current: 'second'), 'first');
    expect(editor.redo(), 'second', reason: '重做也一样，否则只能回去不能回来');
  });

  test('with nothing to go back to it answers nothing', () {
    final editor = EditorNotifier()..setHistoryTab('tab-1');

    expect(editor.undo(), isNull);
    editor.pushHistory('only one');
    expect(editor.undo(current: 'only one'), isNull,
        reason: '只有一份快照时无处可退，不该假装退了一步');
  });
}

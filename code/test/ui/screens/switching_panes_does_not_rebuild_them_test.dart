import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/screens/home_screen.dart';

/// Switching panes keeps them; switching documents does not double-paint.
///
/// Measured on the reader's machine, 2026-09-23, with a 117 KB document open
/// beside a 6 KB one:
///
/// * every switch redrew the whole document — `preview drew 800 blocks in
///   255 ms`, then 218 ms, then 192 ms, once per switch;
/// * two of those lines carry the **same timestamp** — `85 blocks in 41 ms`
///   and `800 blocks in 255 ms` at 17:09:42.487286 — so both documents were
///   painting in the same frame;
/// * one switch took **3321 ms** where its neighbours took 75–144 ms;
/// * resident went 163 → 280 MB over six switches and did not come back.
///
/// Two causes, one line apart. The stack holding the three panes was keyed on
/// the **mode** as well as the document, so changing mode made it a different
/// widget: the stack and all three panes were thrown away and rebuilt. Its own
/// comment said it was there "to keep all editor states, avoiding rebuild on
/// mode switch", and `DeferredEditorBuilder` said the three panes "are all in
/// the tree at once so switching between them is instant" and that its spinner
/// would not come back. None of that was happening.
///
/// And the stack sat inside an `AnimatedSwitcher`, so each of those changes
/// cross-faded the outgoing tree against the incoming one — which is the two
/// documents painting in one frame, at the exact moment the reader is waiting.
///
/// The reader reported a third symptom, "closing the window stutters". The
/// trace says the close itself takes 19–36 ms in every recorded run; what
/// stutters is the click landing on a thread busy rebuilding a document tree.
/// One cause, three symptoms.
void main() {
  /// The screen's code with its comments taken out.
  ///
  /// Stripped because the first version of the checks below matched the comment
  /// that explains why the thing must not be there — a guard that cannot tell
  /// code from prose about code.
  final source = File('lib/ui/screens/home_screen.dart')
      .readAsLinesSync()
      .where((l) => !l.trimLeft().startsWith('//'))
      .join('\n');

  test('the pane stack is keyed on the document', () {
    // Mode-independence is not asserted here, because it cannot be: the
    // function takes a document and nothing else, so the compiler is the guard
    // and an assertion over the three modes would be a tautology — which is
    // what the first draft of this test was.
    //
    // What is worth pinning is the other half: the key has to *change* with
    // the document, or a new one would inherit the panes of the last.
    expect(
      HomeScreen.editorStackKey('tab-1'),
      isNot(HomeScreen.editorStackKey('tab-2')),
    );
    expect(
      HomeScreen.editorStackKey('tab-1'),
      HomeScreen.editorStackKey('tab-1'),
      reason: '同一个文档必须得到同一个 key',
    );
  });

  test('nothing in the editor area mentions the mode in its stack key', () {
    // The behaviour above can be satisfied while the call site keeps building
    // its own key, which is what it did.
    final stack =
        RegExp(r'key: [^\n]*editorStackKey\([^\n]*\),').firstMatch(source);
    expect(stack, isNotNull,
        reason: '编辑区的那个 key 不是从 editorStackKey 来的，取法或调用点变了');
    expect(stack!.group(0), isNot(contains(r'$currentIndex')));
    expect(stack.group(0), isNot(contains('editMode')));
    // Exactly one place spells that key out: the function above. A second is
    // a call site building its own again, which is how the mode got into it.
    expect(
      RegExp(r"ValueKey\('editors_").allMatches(source).length,
      1,
      reason: '这个 key 只该在 editorStackKey 里拼一次',
    );
  });

  test('the editor area is not cross-faded', () {
    // The fade is 150 ms during which both trees are built and painting. A
    // document swap does not want a fade; it wants to be over.
    expect(
      source.contains('AnimatedSwitcher('),
      isFalse,
      reason: '切换时两棵文档树同时在画，真机日志里两条预览行共用同一个时间戳',
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/code_highlighting.dart';

/// Colouring the same code block again is free.
///
/// The preview builds every block of the document on every rebuild — the
/// blocks sit in a Column, not a lazy list — and a rebuild is a caret move, a
/// theme change, a keystroke in the find bar. Twenty ordinary code blocks
/// cost 28 ms of highlighting each time, past the frame budget, to produce an
/// answer that had not changed.
void main() {
  const snippet = '''
class Foo {
  final int bar;
  Foo(this.bar);
  String describe() => 'bar is \$bar';
}
''';

  setUp(CodeHighlighting.clearCache);

  test('the same block gives back the same answer, not a new one', () {
    final first = CodeHighlighting.highlight(snippet, language: 'dart');
    final second = CodeHighlighting.highlight(snippet, language: 'dart');
    expect(identical(first, second), isTrue,
        reason: '同一个代码块被重新高亮了一遍');
  });

  test('the language is part of the question', () {
    final asDart = CodeHighlighting.highlight(snippet, language: 'dart');
    final asPython = CodeHighlighting.highlight(snippet, language: 'python');
    expect(identical(asDart, asPython), isFalse);
  });

  test('rebuilding a page of code blocks costs almost nothing', () {
    // A kilobyte each, which is what an ordinary code block in a README is.
    // Smaller blocks make the measurement unable to tell the two cases apart.
    final blocks = [
      for (var b = 0; b < 20; b++)
        '${List.filled(8, snippet).join()}// block $b\n',
    ];
    for (final block in blocks) {
      CodeHighlighting.highlight(block, language: 'dart');
    }

    var seen = 0;
    final watch = Stopwatch()..start();
    for (var rebuild = 0; rebuild < 10; rebuild++) {
      for (final block in blocks) {
        seen +=
            CodeHighlighting.highlight(block, language: 'dart').nodes?.length ??
                0;
      }
    }
    watch.stop();

    expect(seen, greaterThan(0));
    // Ten rebuilds of twenty kilobyte blocks. Cached this is under a
    // millisecond; re-highlighting them is 130. The budget is forty times
    // the one and a third of the other, so a slow machine does not fail it
    // and a return to re-highlighting does.
    expect(watch.elapsedMilliseconds, lessThan(40),
        reason: '代码块看起来又在每次重建时重新高亮了');
  });

  test('the cache is bounded, so a long document cannot fill memory', () {
    // Enough distinct blocks to go well past the budget. What is asked for
    // repeatedly is what is on screen, and that is far below it.
    final filler = List.filled(40, snippet).join();
    for (var i = 0; i < 40; i++) {
      CodeHighlighting.highlight('$filler// $i\n', language: 'dart');
    }
    expect(CodeHighlighting.cachedChars,
        lessThanOrEqualTo(CodeHighlighting.cacheCharBudget));
  });

  test('an unknown language is coloured as plain text, not an error', () {
    expect(
      () => CodeHighlighting.highlight('int x = 1;', language: 'nosuchlang'),
      returnsNormally,
    );
  });
}

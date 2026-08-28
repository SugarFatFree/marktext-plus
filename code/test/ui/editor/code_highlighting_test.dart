import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/code_highlighting.dart';

/// Which languages code blocks are coloured for.
///
/// `package:highlight/highlight.dart` registers all 189 definitions it ships,
/// and nothing can be tree-shaken after that, so the whole 1.9 MB went into the
/// AOT snapshot. That mattered once it was measured: on the machine where a
/// launch takes seconds, all of the time is inside `window.Create()` — engine
/// boot plus loading the snapshot — and taking 2.2 MB out of app.so took about
/// 450 ms off it.
void main() {
  test('the common languages are coloured', () {
    for (final language in [
      'dart', 'javascript', 'typescript', 'python', 'java', 'go', 'rust',
      'cpp', 'cs', 'ruby', 'php', 'shell', 'bash', 'sql', 'json', 'yaml',
      'xml', 'css', 'markdown', 'dockerfile', 'ini', 'diff',
    ]) {
      final result = CodeHighlighting.instance
          .parse('int x = 1;', language: language)
          .nodes;
      expect(result, isNotNull, reason: '$language 没有注册');
      expect(CodeHighlighting.languages, contains(language));
    }
  });

  test('an unregistered language shows its code, uncoloured', () {
    // The package falls back to plaintext rather than throwing, which is what
    // makes dropping the long tail safe: `isbl` (244 KB), `solidity` (196 KB)
    // and the rest were never going to appear in a code fence here, and if one
    // does, the code is still there to read.
    const source = 'let x = 1 in x';
    final nodes =
        CodeHighlighting.instance.parse(source, language: 'nix').nodes;

    expect(nodes, isNotNull);
    final text = nodes!.map((n) => n.value ?? '').join();
    expect(text, source, reason: '未注册的语言把代码弄丢了');
  });

  test('the list is a set, and small enough to be the point of the exercise',
      () {
    expect(CodeHighlighting.languages.toSet(),
        hasLength(CodeHighlighting.languages.length),
        reason: '有重复项');
    expect(CodeHighlighting.languages.length, lessThan(80),
        reason: '又回到「什么都注册」就失去意义了');
    expect(CodeHighlighting.languages.length, greaterThan(30),
        reason: '砍得太狠，常见语言会失去高亮');
  });
}

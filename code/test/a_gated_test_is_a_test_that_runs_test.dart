import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A test that waits for an environment variable has to be given one.
///
/// `packaged_plugin_test` unpacks the archive a reader downloads and runs the
/// plugin out of it — the guard for a fault that had happened twice, a plugin
/// "installed" by copying only its entrypoint, which is half a plugin. It
/// reads `PLUGIN_ZIP`, and nothing anywhere set it: not the workflow, not a
/// script, not a note. Its four tests had never run, here or on CI, from the
/// day they were written.
///
/// That is worse than not having written them. A suite reports them as
/// skipped, which reads as "not applicable here" rather than "never anywhere",
/// and the list of things this project checks says the archive is covered.
///
/// So: every variable a test gates itself on is named in the workflow that
/// runs the suite. Adding a gate now means arranging for it to open.
void main() {
  test('every environment gate a test waits on is opened by CI', () {
    // Without its comments, and looking for an assignment rather than for the
    // name anywhere. This test asked whether the workflow *mentioned* the
    // variable — and the workflow mentions `PLUGIN_ZIP` in the paragraph
    // explaining why this test exists, so deleting the line that actually
    // sets it left this green. The guard against guards that never run could
    // be satisfied by a comment about guards that never run.
    final workflow = File('../.github/workflows/ci.yml')
        .readAsLinesSync()
        .where((line) => !line.trimLeft().startsWith('#'))
        .join('\n');

    final gates = <String, List<String>>{};
    for (final file in Directory('test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_test.dart'))) {
      final source = file
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
      // A read with a fallback is not a gate. `plugin_js_runtime_test` looks
      // up `PUB_CACHE` and `HOME` to find a file, each with a `??` behind it,
      // and requires nothing of anybody — while `packaged_plugin_test` reads
      // `PLUGIN_ZIP` bare and skips without it. The rule is "no test is
      // skipped for want of a variable nobody sets", and a default is the
      // test saying it is not waiting.
      final withoutFallbacks = source.replaceAll(
          RegExp(r"Platform\.environment(\['\w+'\]|\.containsKey\('\w+'\))"
              r'\s*\?\?'),
          '');
      // Both spellings. This looked only for the subscript form, and
      // `plugin_js_runtime_test` asks `containsKey` — so the one test that
      // runs the JavaScript engine end to end was gated on a variable nothing
      // sets, and this test, whose whole subject is that, could not see it.
      for (final pattern in [
        RegExp(r"Platform\.environment\['(\w+)'\]"),
        RegExp(r"Platform\.environment\.containsKey\('(\w+)'\)"),
      ]) {
        for (final m in pattern.allMatches(withoutFallbacks)) {
          gates.putIfAbsent(m.group(1)!, () => []).add(file.path);
        }
      }
    }

    // Not an assertion about how many there are — one is enough to check, and
    // zero would mean the pattern changed and this stopped looking.
    expect(gates, isNotEmpty,
        reason: '一个环境变量开关都没找到，取法八成该更新了');

    final unopened = [
      for (final gate in gates.entries)
        // `NAME=` for `echo "NAME=…" >> $GITHUB_ENV` and for `NAME=… cmd`;
        // `NAME:` for an `env:` block. Both are a value arriving; the bare
        // name is somebody talking about it.
        if (!RegExp('\\b${gate.key}\\s*[=:]').hasMatch(workflow))
          '${gate.key}（${gate.value.join(', ')}）',
    ];

    expect(
      unopened,
      isEmpty,
      reason: '这些测试在等一个 CI 从不设置的环境变量，'
          '所以它们从来没跑过：\n${unopened.join('\n')}',
    );
  });
}

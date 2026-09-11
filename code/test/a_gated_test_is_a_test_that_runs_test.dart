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
      // Both spellings. This looked only for the subscript form, and
      // `plugin_js_runtime_test` asks `containsKey` — so the one test that
      // runs the JavaScript engine end to end was gated on a variable nothing
      // sets, and this test, whose whole subject is that, could not see it.
      for (final pattern in [
        RegExp(r"Platform\.environment\['(\w+)'\]"),
        RegExp(r"Platform\.environment\.containsKey\('(\w+)'\)"),
      ]) {
        for (final m in pattern.allMatches(source)) {
          gates.putIfAbsent(m.group(1)!, () => []).add(file.path);
        }
      }
    }

    // Not an assertion about how many there are — one is enough to check, and
    // zero would mean the pattern changed and this stopped looking.
    expect(gates, isNotEmpty,
        reason: '一个环境变量开关都没找到，取法八成该更新了');

    /// A gate CI cannot open, and what it would take.
    ///
    /// One entry, and it is a decision rather than an oversight — which is the
    /// distinction this whole test is about. `flutter test` runs Dart with no
    /// application around it, so the QuickJS library the JavaScript runtime
    /// needs is not loaded and cannot be: setting the variable would turn a
    /// skip into a failure, which is worse.
    ///
    /// What would open it is an `integration_test` running inside a built
    /// application — CI already builds one on Linux and on Windows — and that
    /// is a harness this project does not have yet. Until then the JavaScript
    /// engine is exercised end to end by nobody, which is written down in
    /// `docs/v1.6.3/bugfix.md` rather than left to be discovered.
    const cannotOpen = <String, String>{
      'MARKTEXT_QUICKJS_AVAILABLE':
          'needs a built application; `flutter test` has no QuickJS library',
    };

    final unopened = [
      for (final gate in gates.entries)
        // `NAME=` for `echo "NAME=…" >> $GITHUB_ENV` and for `NAME=… cmd`;
        // `NAME:` for an `env:` block. Both are a value arriving; the bare
        // name is somebody talking about it.
        if (!cannotOpen.containsKey(gate.key) &&
            !RegExp('\\b${gate.key}\\s*[=:]').hasMatch(workflow))
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

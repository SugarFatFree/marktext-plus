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
    final workflow = File('../.github/workflows/ci.yml').readAsStringSync();

    final gates = <String, List<String>>{};
    for (final file in Directory('test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_test.dart'))) {
      final source = file
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
      for (final m
          in RegExp(r"Platform\.environment\['(\w+)'\]").allMatches(source)) {
        gates.putIfAbsent(m.group(1)!, () => []).add(file.path);
      }
    }

    // Not an assertion about how many there are — one is enough to check, and
    // zero would mean the pattern changed and this stopped looking.
    expect(gates, isNotEmpty,
        reason: '一个环境变量开关都没找到，取法八成该更新了');

    final unopened = [
      for (final gate in gates.entries)
        if (!workflow.contains(gate.key))
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

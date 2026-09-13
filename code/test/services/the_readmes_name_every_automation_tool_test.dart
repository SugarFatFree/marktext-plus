import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/mcp_tools.dart';

/// The READMEs name every tool the automation server offers, and every action
/// its one multi-purpose tool takes.
///
/// The table said five tools where there are six, and described `control` as
/// "open and close tabs, change the view mode, write content, close a pane" —
/// four of its twelve actions. The seven it left out include running a plugin
/// command, changing a setting, **installing a plugin and replacing the
/// application with a build from CI**.
///
/// That is not a stale list like any other. This table is what somebody reads
/// to decide whether to open the port at all, so understating what reaches
/// through it understates the decision. The names are identifiers rather than
/// prose — `install_plugin` is spelt the same in every language — so a reader
/// of any of the twelve can be held to the same list.
void main() {
  final repo = Directory.current.path.endsWith('code')
      ? Directory(Directory.current.parent.path)
      : Directory.current;

  List<File> readmes() => [
        File('${repo.path}/README.md'),
        ...Directory('${repo.path}/docs/i18n')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.md')),
      ];

  /// Skipped rather than failed when the READMEs are not there: a checkout of
  /// `code/` alone is a thing people do.
  bool present() => File('${repo.path}/README.md').existsSync();

  /// Every tool name the server publishes, from the schema it publishes them in.
  Set<String> toolNames() => RegExp(r"name: '([a-z_]+)'")
      .allMatches(File('lib/services/mcp_tools.dart').readAsStringSync())
      .map((m) => m.group(1)!)
      .toSet();

  test('the server publishes the tools this test thinks it does', () {
    // The list is read out of the source, so it can go wrong in one direction:
    // the regular expression stops matching and the checks below pass on an
    // empty set.
    expect(toolNames().length, greaterThan(4),
        reason: '只读出 ${toolNames().length} 个工具名，取法要跟着改');
    expect(toolNames(), contains('control'));
  });

  test('every README names every tool', () {
    if (!present()) return;
    final wrong = <String>[];
    for (final file in readmes()) {
      final text = file.readAsStringSync();
      final missing = toolNames().where((t) => !text.contains('`$t`'));
      if (missing.isNotEmpty) {
        wrong.add('${file.uri.pathSegments.last}: ${missing.toList()..sort()}');
      }
    }
    expect(wrong, isEmpty,
        reason: '这些 README 没提到全部工具——读这份语言的人不知道有这个能力：\n'
            '${wrong.join('\n')}');
  });

  test('every README names every action control takes', () {
    if (!present()) return;
    final actions = McpAction.values.map((a) => a.wireName).toSet();
    expect(actions.length, greaterThan(8), reason: '动作读少了，取法要跟着改');

    final wrong = <String>[];
    for (final file in readmes()) {
      final text = file.readAsStringSync();
      final missing = actions.where((a) => !text.contains(a));
      if (missing.isNotEmpty) {
        wrong.add('${file.uri.pathSegments.last}: ${missing.toList()..sort()}');
      }
    }
    expect(wrong, isEmpty,
        reason: '这些 README 没说 control 能做什么——其中 install_plugin 与 update_app '
            '是「装代码」和「替换应用本体」，读者据这张表决定要不要开端口：\n'
            '${wrong.join('\n')}');
  });
}

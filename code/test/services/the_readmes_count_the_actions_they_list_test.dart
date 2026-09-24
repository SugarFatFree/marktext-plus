import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/mcp_tools.dart';

/// Every README's count of automation actions matches the list under it, and
/// both match the editor.
///
/// All twelve said "the twelve actions" directly above a list of nineteen of
/// them. The number was written when there were twelve and the list grew
/// underneath it, which is this project's most frequent defect in its most
/// public place: a reader does not need to run anything to be told two
/// different things in the same breath.
///
/// The number is written as digits in every language now, partly so a reader
/// counting a list of nineteen is not made to parse a word, and partly because
/// a spelled-out number is a number no test can read — which is how this one
/// survived a guard that already checked the count in the table above it.
void main() {
  final readmes = [
    File('../README.md'),
    ...Directory('../docs/i18n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md')),
  ];

  test('there are readmes to check', () {
    expect(readmes.length, 12, reason: '找到 ${readmes.length} 份，应当是 12 份');
  });

  for (final readme in readmes) {
    final name = readme.path.split('/').last;

    test('$name counts the actions it lists', () {
      final lines = readme.readAsLinesSync();
      final at = lines.indexWhere((l) => l.contains('`new_tab`'));
      expect(at, greaterThan(0), reason: '$name 里找不到动作名那一行');

      final listed = RegExp(r'`([a-z_]+)`')
          .allMatches(lines[at])
          .map((m) => m.group(1)!)
          .toSet();
      // The editor's own list, so a language nobody reads cannot drift either.
      expect(listed, McpAction.values.map((a) => a.wireName).toSet(),
          reason: '$name 列出的动作与编辑器实现的对不上');

      // The sentence introducing them, which is the line above, blank lines
      // aside.
      var above = at - 1;
      while (above > 0 && lines[above].trim().isEmpty) {
        above--;
      }
      final said = RegExp(r'\d+').allMatches(lines[above]).map((m) => m.group(0));
      expect(said, contains('${listed.length}'),
          reason: '$name 说「${lines[above].trim()}」，而下面列了 ${listed.length} 个');
    });
  }
}

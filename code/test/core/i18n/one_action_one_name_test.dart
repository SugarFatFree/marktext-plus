import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// One action, one name — in every language.
///
/// The same actions are named twice in the ARB files: once under a
/// `format*`/`edit*` key that the menus, the toolbar, the slash menu and the
/// command palette read, and once under a `keybinding*` key that the shortcut
/// list in Settings reads. Nothing tied the two together, so a wording change
/// on one side left the other behind and one command answered to two names.
///
/// Two had drifted when this was written: `mathBlock` was 数学公式 in the
/// palette and 数学公式块 in Settings, and Russian spelled strikethrough both
/// with and without its ё.
///
/// The pairs are read out of the two maps rather than listed here. A written
/// list would be a third copy of the same correspondence — which is the shape
/// of the bug this exists to catch.
///
/// The duplication itself is left alone: collapsing it means deleting keys
/// from twelve files and rewriting every reader, a larger change than the
/// problem. Keys that merely happen to share a word are deliberately not
/// compared — `editCopy` and `settingsMcpCopy` both read "Copy" and name
/// different things, so they are free to diverge.
void main() {
  /// Every `action → l10n key` a map states, skipping entries that take an
  /// argument: `formatHeading(1)` and `keybindingHeading1` are one name
  /// written two ways, and comparing them compares a template to its result.
  Map<String, String> mapIn(String source, RegExp pattern) {
    final found = <String, String>{};
    for (final match in pattern.allMatches(source)) {
      final key = RegExp(r'^l10n\.(\w+)$').firstMatch(match.group(2)!.trim());
      if (key != null) found[match.group(1)!] = key.group(1)!;
    }
    return found;
  }

  final settingsLabels = mapIn(
    File('lib/ui/widgets/action_labels.dart').readAsStringSync(),
    RegExp(r"'(\w+)' => (.+?),\n"),
  );
  final paletteLabels = mapIn(
    File('lib/ui/screens/home_screen.dart').readAsStringSync(),
    RegExp(r'FormatAction\.(\w+): (.+?),\n'),
  );

  /// The actions both maps name, with the two keys each of them uses.
  final pairs = {
    for (final action in settingsLabels.keys)
      if (paletteLabels.containsKey(action) &&
          paletteLabels[action] != settingsLabels[action])
        action: (paletteLabels[action]!, settingsLabels[action]!),
  };

  final files =
      Directory('lib/core/i18n/l10n')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.arb'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('the maps were read, and there are twelve languages', () {
    // Guards the guard. A regex that stopped matching, or a glob that found
    // no files, would let every assertion below pass in silence.
    //
    // Floors, not counts: the point is that the regexes still match. The
    // palette's map reads lower than its 52 entries because six headings take
    // an argument and a few labels are built across two lines.
    expect(settingsLabels.length, greaterThan(50), reason: '设置的译名映射没读到');
    expect(paletteLabels.length, greaterThan(30), reason: '命令面板的译名映射没读到');
    expect(pairs.length, greaterThan(15), reason: '两边共有的动作太少，正则大概坏了');
    expect(files.length, 12);
  });

  for (final file in files) {
    final language = file.path.split(Platform.pathSeparator).last;

    test('$language names each action the same way twice', () {
      final arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final disagreements = <String>[];

      pairs.forEach((action, keys) {
        final (palette, settings) = keys;
        expect(arb, contains(palette), reason: '$language 缺 $palette');
        expect(arb, contains(settings), reason: '$language 缺 $settings');
        if (arb[palette] != arb[settings]) {
          disagreements.add(
            '$action: $palette="${arb[palette]}" ≠ '
            '$settings="${arb[settings]}"',
          );
        }
      });

      expect(
        disagreements,
        isEmpty,
        reason:
            '$language 里同一个动作有两个名字——命令面板与设置里会显示得不一样：\n'
            '${disagreements.join('\n')}',
      );
    });
  }
}

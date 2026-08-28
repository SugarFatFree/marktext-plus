import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/providers/editor_provider.dart';

/// Every formatting action should be reachable from the command palette.
///
/// The palette builds its formatting commands from a map written out by hand
/// in `home_screen.dart`. That map listed 21 of the 38 `FormatAction` values,
/// so seventeen of them — underline, highlight, superscript, subscript, inline
/// code, inline maths, clear formatting, copy as Markdown, copy as HTML, select
/// all, duplicate line, promote and demote heading, to paragraph, loose list,
/// create and delete paragraph — sat in the menus and could not be found in the
/// palette at all. Nothing was broken; the second list of the same things had
/// simply not kept up, which is what second lists do.
void main() {
  String labelMap() {
    final source = File('lib/ui/screens/home_screen.dart').readAsStringSync();
    final start = source.indexOf('formatLabels');
    expect(start, greaterThan(-1), reason: '找不到 formatLabels，测试需要更新');
    return source.substring(start, source.indexOf('};', start));
  }

  test('the palette offers every FormatAction', () {
    final map = labelMap();
    final missing = FormatAction.values
        .where((action) => !map.contains('FormatAction.${action.name}:'))
        .map((action) => action.name)
        .toList();

    expect(missing, isEmpty,
        reason: '这些格式动作在菜单里有，但命令面板里找不到：${missing.join(', ')}');
  });

  test('the palette does not name an action that no longer exists', () {
    final named = RegExp(r'FormatAction\.(\w+):')
        .allMatches(labelMap())
        .map((m) => m.group(1)!)
        .toSet();
    final known = FormatAction.values.map((a) => a.name).toSet();

    expect(named.difference(known), isEmpty);
    expect(named.length, FormatAction.values.length);
  });
}

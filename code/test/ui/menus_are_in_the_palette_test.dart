import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Everything in the menu bar can be found in the command palette.
///
/// The palette used to list nine commands written out by hand, and was fixed
/// by generating it from `WindowActions` — "anything added there now appears
/// here as well". That closed it for commands **with a key** and quietly left
/// out the ones without, because everything in `WindowActions` must be
/// bindable. Export as PDF could be found and Export as HTML could not, from
/// the same submenu, because one of the two has a shortcut. Across the whole
/// bar it was fifteen commands, the entire Help menu among them.
///
/// Read from the source rather than from a running screen. The menus are
/// built inside a widget and the registry is filled during its build; what
/// matters here is that the two lists agree, not how either is drawn.
void main() {
  /// Menu entries that are deliberately not palette commands.
  const notCommands = <String, String>{
    'editCut': '作用于当前选区，而打开面板就会移走焦点；键是操作系统级的',
    'editCopy': '同上',
    'editPaste': '同上',
    'fileNoRecentFiles': '「没有最近文件」是一句提示，不是命令（onPressed 为 null）',
  };

  test('every menu entry is reachable from the palette', () {
    final menu = File('lib/ui/widgets/app_menu_bar.dart').readAsStringSync();
    final home = File('lib/ui/screens/home_screen.dart').readAsStringSync();

    final builders = RegExp(r'Widget (_build\w*Menu)\(')
        .allMatches(menu)
        .map((m) => m.group(1)!)
        .toList();
    expect(
      builders.length,
      greaterThan(5),
      reason: '只找到 ${builders.length} 个菜单构造方法，取法大概坏了',
    );

    final label = RegExp(r'Text\(l10n\.(\w+)\)');
    final callee = RegExp(r'=> ([A-Za-z_]\w*)\(|onPressed:\s*([A-Za-z_]\w*),');
    final format = RegExp(r'FormatAction\.(\w+)');

    final missing = <String>[];
    var seen = 0;
    for (final builder in builders) {
      final begins = menu.indexOf('Widget $builder(');
      final ends = menu.indexOf('\n  Widget _build', begins + 10);
      final block = menu.substring(begins, ends == -1 ? menu.length : ends);

      for (final chunk in block.split('MenuItemButton(').skip(1)) {
        final named = label.firstMatch(chunk);
        if (named == null) continue;
        final name = named.group(1)!;
        if (notCommands.containsKey(name)) continue;
        seen++;

        // Reachable three ways: it has a key, so the palette's loop over
        // WindowActions picks it up; it is a format action, which the palette
        // registers from its own table; or it is registered by hand, matched
        // on the function it calls rather than on its label, since some are
        // registered under a wording of their own.
        if (chunk.contains('_shortcut(')) continue;
        final fmt = format.firstMatch(chunk);
        if (fmt != null && home.contains('FormatAction.${fmt.group(1)}')) {
          continue;
        }
        final calls = callee.firstMatch(chunk);
        final called = calls?.group(1) ?? calls?.group(2);
        if (called != null && home.contains('AppMenuBar.$called(')) continue;

        missing.add('$builder: $name');
      }
    }

    expect(
      seen,
      greaterThan(60),
      reason: '只读出 $seen 项，区间大概取窄了，下面的检查会变成空话',
    );
    expect(
      missing,
      isEmpty,
      reason: '这些菜单项在命令面板里找不到——面板自称能找到命令，而它们只在菜单里：\n'
          '${missing.join('\n')}',
    );
  });

  test('the entries left out are left out on purpose', () {
    // A name here that no menu draws means the list has gone stale, and a
    // stale exclusion silently forgives whatever takes that name next.
    final menu = File('lib/ui/widgets/app_menu_bar.dart').readAsStringSync();
    for (final name in notCommands.keys) {
      expect(
        menu.contains('Text(l10n.$name)'),
        isTrue,
        reason: '$name 已经不在菜单里了，这条豁免该删掉',
      );
    }
  });
}

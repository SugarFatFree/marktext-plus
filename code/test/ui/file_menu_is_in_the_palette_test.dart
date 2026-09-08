import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Everything in the File menu can be found in the command palette.
///
/// The palette used to list nine commands written out by hand, and was fixed
/// by generating it from `WindowActions` — "anything added there now appears
/// here as well". That closed it for commands **with a key** and quietly left
/// out the ones without: Export as PDF could be found in the palette and
/// Export as HTML could not, because one of the two has a shortcut.
///
/// Read from the source rather than from a running screen. The menu is built
/// inside a widget and the registry is filled during its build; what matters
/// here is that the two lists agree, not how either is drawn.
void main() {
  test('every File menu entry is reachable from the palette', () {
    final menu = File('lib/ui/widgets/app_menu_bar.dart').readAsStringSync();
    final home = File('lib/ui/screens/home_screen.dart').readAsStringSync();

    // From the builder that makes the File menu to the label that names it.
    // Anchored on the method rather than on a `SubmenuButton`, because the
    // Export submenu nests one inside this one.
    final begins = menu.indexOf('Widget _buildFileMenu(');
    expect(begins, isNot(-1), reason: '文件菜单的构造方法改名了，区间取法要跟着改');
    final ends = menu.indexOf('child: Text(l10n.menuFile,', begins);
    expect(ends, isNot(-1), reason: '文件菜单的标签变了，区间取法要跟着改');
    final block = menu.substring(begins, ends);

    // Each entry, with the key it draws and the function it calls. Matched on
    // the function rather than on the label: "New" is registered in the
    // palette under a wording of its own, and comparing the two strings would
    // have called it missing.
    final label = RegExp(r'Text\(l10n\.(file[A-Za-z]+)\)');
    final callee = RegExp(r'=> ([A-Za-z_]\w*)\(');

    final missing = <String>[];
    var seen = 0;
    for (final chunk in block.split('MenuItemButton(').skip(1)) {
      final named = label.firstMatch(chunk);
      if (named == null) continue;
      seen++;
      final hasKey = chunk.contains('_shortcut(');
      final calls = callee.firstMatch(chunk);
      final byHand =
          calls != null && home.contains('AppMenuBar.${calls.group(1)}(');
      if (!hasKey && !byHand) missing.add(named.group(1)!);
    }

    expect(
      seen,
      greaterThan(10),
      reason: '只读出 $seen 项，区间大概取窄了，下面的检查会变成空话',
    );
    expect(
      missing,
      isEmpty,
      reason: '这些菜单项在命令面板里找不到——面板自称能找到命令，而它们只在菜单里：$missing',
    );
  });
}

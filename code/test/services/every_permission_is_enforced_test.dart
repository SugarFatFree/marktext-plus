import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';

/// Every permission the editor publishes, against the place that enforces it.
///
/// The install dialog shows the reader a list and asks them to decide on it.
/// That only means something if each line is a door somebody is standing at.
/// Ten of the eighteen were not: they appeared in the dialog, and nowhere else
/// in the editor except the table that turns them into readable names.
///
/// Two kinds of nothing hide behind one symptom, and they need different
/// answers, so they are separated below. Either the capability exists and is
/// simply not gated — `ui.contextMenu` was that, with the menu bar checking
/// its own permission since the day it was written while the right-click menu
/// checked none — or the capability does not exist at all, and the permission
/// grants what nobody can do.
void main() {
  // Resolved once, here: the sibling repositories sit beside this checkout on
  // the machine this was written on and nowhere on CI, and a test that reads
  // one without a `skip` fails there with LateInitializationError after
  // passing locally. `repo_dependent_tests_test` holds every such test to it.
  final sdk = _findSdk();

  /// The permission, and the file that refuses a plugin without it.
  const enforced = <String, String>{
    'document.read': 'plugin_command_service.dart',
    'document.write': 'plugin_document_edit.dart',
    'ui.contextMenu': 'plugin_command_actions.dart',
    'ui.menuBar': 'plugin_menu_bar_entries.dart',
    'ui.sidebar': 'right_side_bar.dart',
    'ui.settings': 'plugin_panel.dart',
    'ui.notifications': 'plugin_command_service.dart',
    'ai.chat': 'plugin_command_service.dart',
    'network.request': 'plugin_image_loader.dart',
    'ui.webview': 'plugin_command_service.dart',
  };

  /// The permission, and why nothing stands at that door yet.
  ///
  /// Split in two because the two need different answers, and because the
  /// SDK's README has to say the difference out loud: one of these can be
  /// used and simply is not checked, and the other seven grant something the
  /// editor has not built. An author reading "add a toolbar button" and
  /// getting no button has lost an evening.
  const noCapability = <String, String>{
    'ui.toolbar': '清单里的 toolbar 字段 lib 里没有任何地方画'
        '（见 what_a_plugin_declares_is_used_test）——权限授予的是一个不存在的能力',
    'ui.statusBar': '清单里根本没有状态栏这一类贡献，插件无从往那里放东西',
    'ui.commandPalette': '命令面板读的是 CommandRegistry，'
        '而没有任何地方把插件的命令注册进去',
    'clipboard.read': '两个脚本运行时里都没有剪贴板能力，一个字都没有',
    'clipboard.write': '同上',
    'workspace.read': '两个脚本运行时里都没有工作区能力',
    'workspace.write': '同上',
  };

  /// The capability is there and reachable; nothing checks the permission.
  const ungated = <String, String>{
    'storage.local': '能力存在而没设卡：每个脚本都无条件拿到 storage.get/set，'
        '而 SDK 写着「需要 storage.local」。**没有连夜强制**是因为拒绝的方式'
        '（在脚本里抛错）容易变成一句难懂的报错、打断本来能用的插件，'
        '而它管的只是插件自己目录里的设置文件。要做的话先定拒绝的形状',
  };

  const unenforced = <String, String>{...noCapability, ...ungated};

  /// The table that turns a permission into words for the install dialog.
  /// Naming one there is not enforcing it — that is the whole point.
  const namesOnly = 'plugin_permission_text.dart';

  Map<String, String> libCode() {
    final out = <String, String>{};
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('plugin_manifest.dart'))
        .where((f) => !f.path.endsWith(namesOnly))) {
      out[file.path] = file
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
    }
    return out;
  }

  /// Where [permission] is asked about, by its value or by its constant.
  List<String> gatesFor(String permission, Map<String, String> code) {
    final constant = _constantFor(permission);
    return code.entries
        .where((e) =>
            e.value.contains("'$permission'") ||
            (constant != null && e.value.contains('PluginPermission.$constant')))
        .map((e) => e.key)
        .toList();
  }

  test('the two lists together are the published list', () {
    expect(
      {...enforced.keys, ...unenforced.keys},
      PluginPermission.all.toSet(),
      reason: '新增一条权限就要在这里说清楚：谁来把门，或者为什么还没有门',
    );
    expect(enforced.keys.toSet().intersection(unenforced.keys.toSet()), isEmpty);
  });

  test('an enforced permission is refused somewhere', () {
    final code = libCode();
    expect(code, isNotEmpty, reason: '一个文件都没读到，取法要跟着改');

    enforced.forEach((permission, file) {
      final gates = gatesFor(permission, code);
      expect(gates, isNotEmpty,
          reason: '$permission 只剩显示名了——把门的那处没了');
      expect(gates.any((path) => path.endsWith(file)), isTrue,
          reason: '$permission 说是在 $file 把门，那里已经不问它了。'
              '实际问它的是：$gates');
    });
  });

  test('an unenforced permission really is unenforced', () {
    // The half that keeps this honest. Standing somebody at one of these doors
    // without coming back here fails, and coming back here is where the
    // install dialog's list gets one line closer to meaning something.
    final code = libCode();

    unenforced.forEach((permission, why) {
      expect(gatesFor(permission, code), isEmpty,
          reason: '$permission 现在有人查了——把它挪到 enforced 那张表。'
              '原本记的是：$why');
    });
  });
  test('the SDK says which permissions have nothing behind them', () {
    // The other end of the same fact. The SDK's README is what an author
    // reads before writing anything, and its permissions table promised a
    // toolbar button, a status-bar item, a palette command, the clipboard and
    // the workspace — five rows for seven permissions the editor has never
    // built anything for. Declaring one and finding nothing happens is the
    // most expensive kind of documentation error there is.
    //
    // Marked with a dagger there, and the dagger is what this checks: it is
    // the same character in all twelve languages, while the sentence under
    // the table is not. Implementing one of these means taking its dagger
    // out, and this is what says so.
    final readmes = [
      File('$sdk/README.md'),
      ...Directory('$sdk/docs/i18n')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md')),
    ];
    expect(readmes, hasLength(12), reason: '读到的 README 份数不对，取法要跟着改');

    // A row for `clipboard.read` covers `clipboard.write` too, and the same
    // for workspace: the table pairs them.
    final expected = noCapability.keys
        .where((p) => !p.endsWith('.write') || !noCapability.containsKey(
            p.replaceAll('.write', '.read')))
        .toSet();

    for (final file in readmes) {
      final marked = <String>{};
      for (final line in file.readAsLinesSync()) {
        final m = RegExp(r'^\| `([\w.]+)`').firstMatch(line);
        if (m == null) continue;
        if (line.contains('†')) marked.add(m.group(1)!);
      }
      expect(marked, expected,
          reason: '${file.uri.pathSegments.last} 的权限表标记与编辑器对不上。'
              '打了 † 的应当正是「编辑器还没有做出这个能力」的那些');
    }
  }, skip: sdk != null ? null : 'SDK 仓库不在这台机器上');
}

/// The SDK checkout, when it is beside the editor's. Null on a machine that
/// has only this repository — the same walk the other SDK tests use.
Directory? _findSdkDirectory() {
  var directory = Directory.current;
  for (var level = 0; level < 6; level++) {
    final candidate =
        '${directory.path}/marktext-plus-plugins/marktext-plus-plugin-sdk';
    if (File('$candidate/README.md').existsSync()) return Directory(candidate);
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  return null;
}

String? _findSdk() => _findSdkDirectory()?.path;

/// `document.read` → `documentRead`, the way the constants are named.
String? _constantFor(String permission) {
  final parts = permission.split('.');
  if (parts.length != 2) return null;
  return parts[0] + parts[1][0].toUpperCase() + parts[1].substring(1);
}

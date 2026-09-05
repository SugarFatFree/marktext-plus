import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The shipped plugin asks for what it uses, and only that.
///
/// The SDK tells authors to "ask for what you use — a plugin asking for
/// `network.request` to add a menu entry is one the reader should decline".
/// The plugin this project ships is the one every author will read first, so
/// that sentence is worth being true of it.
///
/// Both directions matter and they fail differently. Declaring too little is
/// a plugin whose feature is refused at the moment someone uses it; declaring
/// too much is a permission list that means less every time a reader sees one.
///
/// The action-to-permission rule is read out of the editor's own guard, so
/// this follows the editor rather than repeating it.
void main() {
  const path = 'marktext-plus-plugins/marktext-plus-ai-translate-plugin';
  String? findRepo() {
    var directory = Directory.current;
    for (var level = 0; level < 6; level++) {
      final candidate = '${directory.path}/$path';
      if (File('$candidate/manifest.json').existsSync()) return candidate;
      final parent = directory.parent;
      if (parent.path == directory.path) break;
      directory = parent;
    }
    return null;
  }

  final repo = findRepo();
  final skip = repo == null ? '插件仓库不在这台机器上' : null;

  test('what it declares is what it uses', () {
    final manifest =
        jsonDecode(File('$repo/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    final declared = {...(manifest['permissions'] as List).cast<String>()};

    final lua = Directory(repo!)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.lua'))
        .map((f) => f.readAsStringSync())
        .join('\n');

    // action name -> permission, straight out of `_guard`.
    final guard = File(
      'lib/services/plugin_command_service.dart',
    ).readAsStringSync();
    final manifestSource = File(
      'lib/services/plugin_manifest.dart',
    ).readAsStringSync();
    final constants = {
      for (final m in RegExp(
        r"static const (\w+) = '([a-z]+\.[a-zA-Z]+)'",
      ).allMatches(manifestSource))
        m.group(1)!: m.group(2)!,
    };
    final needs = <String, String>{
      for (final m in RegExp(
        r'Plugin(\w+)Action\(\)[^=]*?=>\s*\n?\s*PluginPermission\.(\w+)',
        dotAll: true,
      ).allMatches(guard))
        m.group(1)!.toLowerCase(): constants[m.group(2)!]!,
    };
    expect(needs, isNotEmpty, reason: '没能从 _guard 读出映射，正则该更新了');

    final used = <String>{};
    needs.forEach((action, permission) {
      // A returned action is a key in a Lua table literal: `{ ai = ... }`.
      if (RegExp('\\b$action\\s*=').hasMatch(lua)) used.add(permission);
    });
    // What the manifest itself contributes, and what the script reaches for.
    if ((manifest['menus'] as List?)?.isNotEmpty ?? false) {
      used.add('ui.contextMenu');
    }
    if ((manifest['settings'] as List?)?.isNotEmpty ?? false) {
      used.add('ui.settings');
    }
    if ((manifest['panels'] as List?)?.isNotEmpty ?? false) {
      used.add('ui.sidebar');
    }
    if (RegExp(r'\bstorage\.(get|set)\b').hasMatch(lua)) {
      used.add('storage.local');
    }
    if (RegExp(r'ctx\.(document|selection)\b').hasMatch(lua)) {
      used.add('document.read');
    }

    expect(
      used.difference(declared),
      isEmpty,
      reason: '插件用到了这些权限却没声明——功能会在读者用它的那一刻被拒',
    );
    expect(
      declared.difference(used),
      isEmpty,
      reason: '声明了却没有用到——多要一项，读者看到的整张清单就少一分意义',
    );
  }, skip: skip);
}

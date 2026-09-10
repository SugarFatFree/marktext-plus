import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What a plugin may declare, against what the editor does with it.
///
/// `plugin_contract_test` freezes the *names* a plugin writes down. This asks
/// the next question, which nothing asked: having read the name, does the
/// editor do anything at all?
///
/// It matters because a manifest field is a promise made in public. The schema
/// in the SDK lists it, the SDK's README explains it, and an author spends an
/// evening on it. If the editor parses the field and then never looks at it
/// again, the author finds out by installing the plugin and watching nothing
/// happen — the most expensive way there is to learn it.
///
/// Three of these are in that state today. They are written down here rather
/// than left to be rediscovered, and the day one of them is implemented this
/// list is what says the SDK's wording has to change with it.
void main() {
  /// Where a plugin's declaration is turned into something the reader meets,
  /// named by the file it happens in. Empty means the editor reads the field
  /// and does nothing else with it.
  const surfaces = <String, String>{
    'commands': 'plugin_menu_bar_entries',
    'menus': 'plugin_command_actions',
    'panels': 'right_side_bar',
    'toolbar': '',
    'pages': '',
  };

  /// Why a surface has nowhere to be drawn, and what is already built.
  const known = <String, String>{
    'toolbar': '声明了 PluginToolbarItem 与 ui.toolbar 权限，解析也有测试，'
        '但 lib/ 里没有任何地方画它——插件写了工具栏项，编辑器不显示',
    'pages': '声明了 PluginSettingPage，lib/ 与 test/ 里零引用；'
        '插件自己的设置走的是 settings 字段（那个是接上的）',
  };

  /// A file's code, without its comment lines.
  ///
  /// A comment that mentions `.toolbar` while explaining why nothing draws it
  /// would otherwise be read as somebody drawing it — the guard would report
  /// the field answered by the very sentence saying it is not.
  String codeOf(File file) => file
      .readAsLinesSync()
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  List<File> libFiles() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      // The parser is where every field is read; it is not where any of them
      // is used, so counting it would make all five look answered.
      .where((f) => !f.path.endsWith('plugin_manifest.dart'))
      .toList();

  test('a surface said to be drawn is drawn somewhere', () {
    final sources = {for (final f in libFiles()) f.path: codeOf(f)};
    expect(sources, isNotEmpty, reason: '一个文件都没读到，取法要跟着改');

    surfaces.forEach((field, where) {
      if (where.isEmpty) return;
      final users = sources.entries
          .where((e) => e.value.contains('.$field'))
          .map((e) => e.key)
          .toList();
      expect(users, isNotEmpty,
          reason: '$field 说是在 $where 用到，实际 lib/ 里没有任何地方读它');
      expect(users.any((path) => path.contains(where)), isTrue,
          reason: '$field 不再出现在 $where 里了；'
              '要么改这张表，要么它是被删掉了没人发现');
    });
  });

  test('a surface said to be unused really is unused', () {
    // The half that keeps this honest. Implementing one of these without
    // coming back here fails, and coming back here is where somebody has to
    // decide what the SDK now says.
    final sources = {for (final f in libFiles()) f.path: codeOf(f)};

    known.forEach((field, why) {
      final users = sources.entries
          .where((e) => e.value.contains('.$field'))
          .map((e) => e.key)
          .toList();
      expect(users, isEmpty,
          reason: '$field 现在有人用了（$users）——把它从这张表挪到 surfaces，'
              '并检查 SDK 的说法是否还对。原本记的是：$why');
    });

    expect(known.keys.every(surfaces.containsKey), isTrue,
        reason: '两张表要说的是同一批字段');
  });

  test('the editor does not launch a compiled plugin yet', () {
    // PluginProcessHost, the launch token, the per-platform entrypoints and
    // the process registry are all written and tested. Nothing dispatches a
    // command to them: `startPlugin` has no caller outside tests, and
    // plugin_command_service refuses `runtime: process` outright.
    //
    // The SDK describes this runtime in the present tense. The two disagree,
    // and this is where that is written down — so that wiring it up fails
    // here, and whoever does it is sent to the SDK's wording.
    final callers = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('plugin_manager.dart'))
        .where((f) => codeOf(f).contains('startPlugin'))
        .map((f) => f.path)
        .toList();

    expect(callers, isEmpty,
        reason: '有人开始启动编译型插件了（$callers）。这条测试到此为止——'
            '删掉它，并把 SDK README 里 process 那一节从「即将」改成事实，'
            '同时把 PluginRuntimeCommands.runsCommands 加上 process');
  });
}

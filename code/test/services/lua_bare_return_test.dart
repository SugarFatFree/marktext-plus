import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// A valueless `return` inside a nested function does nothing here.
///
/// The editor runs plugin Lua on `lua_dardo`, a pure-Dart interpreter, and in
/// it `return` with no value inside a nested function is not a return at all:
/// execution carries on to the next statement. `return nil` behaves.
///
/// `if not ok then return end` is how every Lua programmer writes a guard, so
/// this is not an exotic corner. It found its way into this suite because a
/// guard written that way in the shipped plugin let an empty request be sent.
/// Inside `while true` the same fault is a loop with no exit, which reaches
/// the reader as an editor that has stopped answering.
///
/// Two tests: one pins the interpreter's behaviour so the day it is fixed is
/// noticed rather than guessed at, and one keeps the Lua this project ships
/// from using the form that does not work.
void main() {
  String run(String body) {
    final action = PluginScriptRuntime('function on_command(ctx)\n$body\nend')
        .runCommand(const PluginScriptContext(command: 'c')) as PluginShowAction;
    return action.text;
  }

  test('the interpreter still swallows a bare return, and still honours nil',
      () {
    // Deliberately asserting the broken behaviour. When this test fails, the
    // interpreter has been fixed — at which point the workaround below can go
    // and this note is the record of why it was ever there.
    expect(
      run('''
  local reached = 0
  local function guarded()
    if true then return end
    reached = 1
  end
  guarded()
  return { show = tostring(reached) }'''),
      '1',
      reason: 'lua_dardo 里嵌套函数中的裸 return 是空操作；'
          '这条一旦失败，说明上游修好了',
    );

    expect(
      run('''
  local reached = 0
  local function guarded()
    if true then return nil end
    reached = 1
  end
  guarded()
  return { show = tostring(reached) }'''),
      '0',
      reason: 'return nil 是可靠的，所以它是那个绕法',
    );
  });

  // The plugin repositories sit beside this one, and are not on the CI
  // machine. Found once, here, so the test below can say it is skipping
  // rather than fail on an empty list.
  Directory? sibling(String name) {
    var directory = Directory.current;
    for (var level = 0; level < 6; level++) {
      final candidate = Directory('${directory.path}/$name');
      if (candidate.existsSync()) return candidate;
      final parent = directory.parent;
      if (parent.path == directory.path) break;
      directory = parent;
    }
    return null;
  }

  final repositories = [
    'marktext-plus-plugins/marktext-plus-plugin-sdk',
    'marktext-plus-plugins/marktext-plus-ai-translate-plugin',
  ].map(sibling).whereType<Directory>().toList();

  test('no Lua this project ships uses the form that does not work', () {
    final roots = <Directory>[
      Directory('${Directory.current.path}/test'),
      ...repositories,
    ];

    final files = <File>[
      for (final root in roots)
        ...root
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.lua'))
            .where((f) => !f.path.contains('/.git/')),
    ];
    expect(files, isNotEmpty, reason: '一个 .lua 都没扫到，这条守卫已失效');

    final offenders = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // A comment line cannot run, and this file's own prose says
        // "return end" while explaining the problem.
        if (line.trimLeft().startsWith('--')) continue;
        // `return` carrying no value, in every way Lua lets one be written:
        // alone on its line, before `end`, before `else`, closed with a
        // semicolon, or followed by a comment. The first two were the only
        // ones named, and the other three are the same statement — a plugin
        // that wrote `return  -- nothing to do` would have shipped a guard
        // that does not guard, and inside `while true` that reaches the reader
        // as an editor which has stopped answering.
        if (RegExp(r'\breturn\s*(end\b|else\b|;|--|$)').hasMatch(line)) {
          offenders.add('${file.path}:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: '这些地方的 return 不会真的返回，改成 return nil：\n'
            '${offenders.join('\n')}');
  }, skip: repositories.isEmpty ? '插件仓库不在这台机器上' : null);
}

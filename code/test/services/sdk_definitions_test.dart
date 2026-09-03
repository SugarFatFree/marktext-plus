import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The SDK's API module offers every action the editor understands.
///
/// It is a hand-written file in another repository wrapping the inside of this
/// one — the exact shape that goes stale quietly. A plugin author reaching for
/// `sdk.panel` and finding nothing there would conclude the editor cannot do
/// it.
void main() {
  String? findSdk() {
    var directory = Directory.current;
    for (var level = 0; level < 6; level++) {
      final candidate =
          '${directory.path}/marktext-plus-plugins/marktext-plus-plugin-sdk';
      if (Directory('$candidate/examples').existsSync()) return candidate;
      final parent = directory.parent;
      if (parent.path == directory.path) break;
      directory = parent;
    }
    return null;
  }

  final sdk = findSdk();
  final skip = sdk == null ? 'SDK 仓库不在这台机器上' : null;

  const actionKeys = <String>{
    'ask', 'default', 'choices', 'ai', 'show', 'panel',
    'title', 'notify', 'diff', 'original', 'result', 'replace',
  };
  const contextFields = <String>{
    'command', 'selection', 'document', 'answer',
  };
  // What the API module re-exports or wraps. `require` and the two entry
  // points are the editor's, not the module's: a plugin defines on_command
  // itself and calls require directly.
  const wrapped = <String>{'storage', 't'};

  test('the runtime reads exactly the keys the definitions describe', () {
    // Read out of the runtime rather than listed here a second time: a list
    // written twice is the thing that drifts.
    final runtime =
        File('lib/services/plugin_script_runtime.dart').readAsStringSync();
    final read = RegExp(r"_field\('(\w+)'\)|_stringList\('(\w+)'\)")
        .allMatches(runtime)
        .map((m) => m.group(1) ?? m.group(2)!)
        .toSet();
    final pushed = RegExp(r"setField\(-2, '(\w+)'\)")
        .allMatches(runtime)
        .map((m) => m.group(1)!)
        .toSet();

    expect(read, isNotEmpty, reason: '解析写错了，一个键都没抽出来');
    expect(read.difference(actionKeys), isEmpty,
        reason: '运行时读了定义文件里没有的键');
    expect(pushed.intersection(contextFields), contextFields,
        reason: '上下文字段和定义文件对不上');
  });

  test('the JavaScript module exports every capability and action', () {
    // What is *exported*, not what the file happens to mention: `panel`
    // appears in a comment beside its function, so a substring search passes
    // even after the function itself is renamed away.
    final source =
        File('$sdk/examples/js/lib/marktext-plus.js').readAsStringSync();
    final declared = <String>{
      // The keys of module.exports, and the keys of the objects the action
      // constructors return.
      ...RegExp(r'(?:^|[\s{,])(\w+):', multiLine: true)
          .allMatches(source)
          .map((m) => m.group(1)!),
    };

    expect(declared, isNotEmpty, reason: '解析写错了，一个声明都没抽出来');
    for (final name in {...wrapped, ...actionKeys}) {
      expect(declared, contains(name), reason: 'JS 模块没有导出 $name');
    }
  }, skip: skip);

  test('the Lua module exports every capability and action', () {
    final source =
        File('$sdk/examples/lua/lib/marktext-plus.lua').readAsStringSync();
    final declared = <String>{
      ...RegExp(r'M\.(\w+)').allMatches(source).map((m) => m.group(1)!),
      // The action tables the constructors return.
      ...RegExp(r'(\w+) =').allMatches(source).map((m) => m.group(1)!),
    };

    expect(declared, isNotEmpty, reason: '解析写错了，一个声明都没抽出来');
    for (final name in {...wrapped, ...actionKeys}) {
      expect(declared, contains(name), reason: 'Lua 模块没有导出 $name');
    }
  }, skip: skip);

  test('the two API modules offer the same thing', () {
    // An author picking a language must not be picking what the editor will
    // let them say.
    Set<String> exported(String path, RegExp pattern) => pattern
        .allMatches(File(path).readAsStringSync())
        .map((m) => m.group(1) ?? m.group(2))
        .whereType<String>()
        .toSet();

    final lua = exported(
      '$sdk/examples/lua/lib/marktext-plus.lua',
      RegExp(r'^function M\.(\w+)|^M\.(\w+) =', multiLine: true),
    );
    final js = exported(
      '$sdk/examples/js/lib/marktext-plus.js',
      RegExp(r'^  (\w+): ', multiLine: true),
    );

    expect(lua, isNotEmpty);
    expect(js, containsAll(lua), reason: 'JS 缺了 Lua 有的东西');
    expect(lua, containsAll(js), reason: 'Lua 缺了 JS 有的东西');
  }, skip: skip);
}

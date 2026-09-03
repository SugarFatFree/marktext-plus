import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The SDK's type definitions describe what the editor actually injects.
///
/// They are hand-written files in another repository describing the inside of
/// this one — the exact shape that goes stale quietly. An author whose editor
/// completes a capability that no longer exists is worse off than one with no
/// completion at all.
void main() {
  String? findSdk() {
    var directory = Directory.current;
    for (var level = 0; level < 6; level++) {
      final candidate =
          '${directory.path}/marktext-plus-plugins/marktext-plus-plugin-sdk';
      if (Directory('$candidate/packages').existsSync()) return candidate;
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
  const capabilities = <String>{
    'storage', 't', 'require', 'on_command', 'on_result',
  };

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

  test('the JavaScript declarations declare every capability and action', () {
    // What is *declared*, not what the file happens to mention: `panel`
    // appears in a comment beside the declaration, so a substring search
    // passes even after the declaration itself is renamed away.
    final source =
        File('$sdk/packages/js/sdk/marktext-plus.d.ts').readAsStringSync();
    final declared = <String>{
      // Not anchored to the start of a line: `diff` holds an inline object,
      // so `original` and `result` share a line with it.
      ...RegExp(r'(?:^|[\s{;])(?:readonly\s+)?(\w+)\??:', multiLine: true)
          .allMatches(source)
          .map((m) => m.group(1)!),
      ...RegExp(r'^declare (?:const|function) (\w+)', multiLine: true)
          .allMatches(source)
          .map((m) => m.group(1)!),
      ...RegExp(r'^\s*(\w+)\(', multiLine: true)
          .allMatches(source)
          .map((m) => m.group(1)!),
    };

    expect(declared, isNotEmpty, reason: '解析写错了，一个声明都没抽出来');
    for (final name in {...capabilities, ...actionKeys, ...contextFields}) {
      expect(declared, contains(name), reason: 'd.ts 没有声明 $name');
    }
  }, skip: skip);

  test('the Lua definitions declare every capability and action', () {
    final source =
        File('$sdk/packages/lua/sdk/marktext-plus.lua').readAsStringSync();
    final declared = <String>{
      // Action keys are shown as `key = ` in the shapes block.
      ...RegExp(r'(\w+) =').allMatches(source).map((m) => m.group(1)!),
      ...RegExp(r'---@field (\w+)').allMatches(source).map((m) => m.group(1)!),
      ...RegExp(r'^function (\w+)', multiLine: true)
          .allMatches(source)
          .map((m) => m.group(1)!),
      ...RegExp(r'^(\w+) = \{\}', multiLine: true)
          .allMatches(source)
          .map((m) => m.group(1)!),
    };

    expect(declared, isNotEmpty, reason: '解析写错了，一个声明都没抽出来');
    for (final name in {...capabilities, ...actionKeys, ...contextFields}) {
      expect(declared, contains(name), reason: 'Lua 定义没有声明 $name');
    }
  }, skip: skip);

  test('the definitions say what the sandbox leaves out', () {
    // `os` is what a Lua author reaches for next after `require`, and unlike
    // `require` it really is gone.
    final lua =
        File('$sdk/packages/lua/sdk/marktext-plus.lua').readAsStringSync();
    expect(lua, contains('os'),
        reason: '沙箱拿掉了 os，定义文件该说清楚');
  }, skip: skip);
}

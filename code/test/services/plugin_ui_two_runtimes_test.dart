import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_js_runtime.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';
import 'package:marktext_plus/services/plugin_ui.dart';

/// One interface, written twice, arriving at the same tree.
///
/// "A plugin author picks the language and nothing else changes" is written on
/// `PluginJsRuntime.parseUiNode`, and there are two hand-written parsers
/// behind it — one walking a Lua stack, one walking a decoded JSON map. Eleven
/// node types and their fields are spelled out separately in each, and nothing
/// held them to each other.
///
/// The JavaScript side's *actions* are well covered. Its *nodes* were reached
/// by a single test using two of the eleven. Nothing here compared the two
/// parsers: the test named "a JS action becomes the same thing a Lua action
/// does" never ran the Lua one — it checked the JavaScript side against
/// written-out values, which is a different and weaker thing. A name that
/// promises a comparison is how a missing comparison stays missing, so that
/// one has been renamed to what it does.
///
/// `_describe` switches over the sealed node type, so a twelfth node breaks
/// this file at compile time rather than passing quietly. That is the point of
/// putting the comparison here rather than in a regular expression over the
/// two sources.
void main() {
  /// Every field of every node, in a form two trees can be compared by.
  ///
  /// Not `toString`: these are plain classes with no `==`, and a comparison
  /// that only checked types would pass while a field drifted.
  String describe(PluginUiNode node) => switch (node) {
        PluginUiText(:final text, :final emphasis) =>
          'text($text, emphasis: $emphasis)',
        PluginUiInput(
          :final id,
          :final value,
          :final placeholder,
          :final multiline
        ) =>
          'input($id, value: $value, placeholder: $placeholder, '
              'multiline: $multiline)',
        PluginUiChips(:final id, :final options) =>
          'chips($id, options: $options)',
        PluginUiButton(:final id, :final label, :final primary) =>
          'button($id, label: $label, primary: $primary)',
        PluginUiSelect(:final id, :final options, :final value) =>
          'select($id, options: $options, value: $value)',
        PluginUiCheckbox(:final id, :final label, :final value) =>
          'checkbox($id, label: $label, value: $value)',
        PluginUiMarkdown(:final source) => 'markdown($source)',
        PluginUiImage(:final source, :final height) =>
          'image($source, height: $height)',
        PluginUiSpacer() => 'spacer()',
        PluginUiRow(:final children) =>
          'row[${children.map(describe).join(', ')}]',
        PluginUiColumn(:final children) =>
          'column[${children.map(describe).join(', ')}]',
      };

  // The same interface in both languages. Written out rather than generated,
  // because generating it from one side would be comparing a thing to itself.
  const luaTree = '''{ ui = { column = {
    { text = "Heading", emphasis = true },
    { input = { id = "brief", value = "start", placeholder = "...",
                multiline = true } },
    { chips = { id = "idea", options = { "shorter", "formal" } } },
    { select = { id = "lang", options = { "en", "zh" }, value = "zh" } },
    { checkbox = { id = "keep", label = "Keep formatting", value = true } },
    { markdown = "## A heading" },
    { image = { source = "logo.png", height = 40 } },
    { row = {
      { spacer = true },
      { button = { id = "go", label = "Write", primary = true } },
    }},
  }}, title = "AI" }''';

  const jsonTree = '''{"ui":{"column":[
    {"text":"Heading","emphasis":true},
    {"input":{"id":"brief","value":"start","placeholder":"...",
              "multiline":true}},
    {"chips":{"id":"idea","options":["shorter","formal"]}},
    {"select":{"id":"lang","options":["en","zh"],"value":"zh"}},
    {"checkbox":{"id":"keep","label":"Keep formatting","value":true}},
    {"markdown":"## A heading"},
    {"image":{"source":"logo.png","height":40}},
    {"row":[
      {"spacer":true},
      {"button":{"id":"go","label":"Write","primary":true}}
    ]}
  ]},"title":"AI"}''';

  PluginUiAction fromLua(String body) => PluginScriptRuntime(
        'function on_command(ctx) return $body end',
      ).runCommand(const PluginScriptContext(command: 'c')) as PluginUiAction;

  test('the two runtimes read the same interface into the same tree', () {
    final lua = fromLua(luaTree);
    final js = PluginJsRuntime.parseAction(jsonTree) as PluginUiAction;

    expect(js.title, lua.title);
    expect(
      describe(js.root),
      describe(lua.root),
      reason: '插件作者换一种语言，别的都不该变',
    );
  });

  test('the fixture uses every node type there is', () {
    // Otherwise the comparison above stays green while a whole node type goes
    // unread by one of the two parsers — which is exactly the drift it is
    // here to catch.
    final defined = RegExp(r'class PluginUi(\w+) extends PluginUiNode')
        .allMatches(File('lib/services/plugin_ui.dart').readAsStringSync())
        .map((m) => m.group(1)!.toLowerCase())
        .toSet();
    expect(defined, isNotEmpty, reason: '一个节点类都没扫到，这条守卫已失效');

    final drawn = describe(fromLua(luaTree).root);
    final missing = defined.where((name) => !drawn.contains('$name(') &&
        !drawn.contains('$name[')).toList();
    expect(missing, isEmpty, reason: '这些节点类型没进 fixture：$missing');
  });

  group('the JavaScript parser on its own', () {
    // Reached directly, since `parseUiNode` takes a Map and needs no QuickJS.
    // Until now the only JavaScript tree in the suite used two node types.
    //
    // Refusal is a thrown exception on both sides, not a null: a plugin whose
    // tree was dropped needs to hear about it, and so does the reader who ran
    // the command.

    test('a node with no id is refused, as on the Lua side', () {
      expect(
        () => PluginJsRuntime.parseAction('{"ui":{"input":{"placeholder":"x"}}}'),
        throwsA(isA<PluginScriptException>()),
        reason: '插件说不出名字的输入框，是个吞掉输入的盒子',
      );
    });

    test('an image with no source is refused', () {
      expect(
        () => PluginJsRuntime.parseAction('{"ui":{"image":{"height":10}}}'),
        throwsA(isA<PluginScriptException>()),
      );
    });

    test('a tree deeper than the limit is refused whole', () {
      // maxDepth + 2, so it is over the line however the ends are counted.
      var body = '{"text":"deep"}';
      for (var i = 0; i < PluginUiLimits.maxDepth + 2; i++) {
        body = '{"column":[$body]}';
      }
      expect(
        () => PluginJsRuntime.parseAction('{"ui":$body}'),
        throwsA(isA<PluginScriptException>()),
        reason: '半棵树比没有树更糟：读者填了看得见的那半，'
            '按下一个从没画出来的按钮',
      );
    });

    test('a tree with more nodes than the limit is refused whole', () {
      final many = List.filled(
        PluginUiLimits.maxNodes + 10,
        '{"text":"x"}',
      ).join(',');
      expect(
        () => PluginJsRuntime.parseAction('{"ui":{"column":[$many]}}'),
        throwsA(isA<PluginScriptException>()),
      );
    });
  });
}

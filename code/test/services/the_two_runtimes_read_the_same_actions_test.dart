import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_js_runtime.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';
import 'package:marktext_plus/services/plugin_ui.dart';

/// One vocabulary of actions, read by two hand-written parsers.
///
/// `plugin_ui_two_runtimes_test` holds the two runtimes to the same *interface*
/// tree, and its own note says why: the test that claimed to compare them
/// never ran the Lua side, it checked the JavaScript side against written-out
/// values, "which is a different and weaker thing". That is still true of the
/// *actions*. Each side has tests against written-out values and nothing
/// compares them, so the two vocabularies agree today because both were written
/// by the same hand on the same day.
///
/// [describe] switches over the sealed action type, so a twelfth action breaks
/// this file at compile time rather than passing quietly. Fields are compared
/// and not only types: a pane whose `append` drifted in one runtime would pass a
/// type check.
///
/// The interface tree is described only by the kind of its root here. Comparing
/// the trees themselves is the other file's job, and doing it twice would mean
/// two places to keep right.
void main() {
  String describe(PluginScriptAction action) => switch (action) {
        PluginAskAction(:final label, :final defaultValue, :final choices) =>
          'ask($label, default: $defaultValue, choices: $choices)',
        PluginAiAction(:final prompt) => 'ai($prompt)',
        PluginShowAction(:final text, :final title) => 'show($text, $title)',
        PluginPaneAction(
          :final text,
          :final title,
          :final slot,
          :final render,
          :final append,
          :final canApply,
          :final replaces,
          :final nextPrompt,
        ) =>
          'pane($text, title: $title, slot: ${slot.name}, '
              'as: ${render.name}, append: $append, apply: $canApply, '
              'replaces: $replaces, ai: $nextPrompt)',
        PluginPanelAction(:final text, :final title) => 'panel($text, $title)',
        PluginDiffAction(:final original, :final result) =>
          'diff($original, $result)',
        PluginNotifyAction(:final message) => 'notify($message)',
        PluginReplaceAction(:final text) => 'replace($text)',
        PluginUiAction(:final root, :final title) =>
          'ui(${rootKind(root)}, $title)',
        PluginNoAction() => 'nothing()',
        PluginPermissionRefusedAction(:final pluginName, :final permission) =>
          'refused($pluginName, $permission)',
      };

  PluginScriptAction fromLua(String body) => PluginScriptRuntime(
        'function on_command(ctx) return $body end',
      ).runCommand(const PluginScriptContext(command: 'c'));

  /// The same action written in both languages, one row each.
  ///
  /// Written out on both sides rather than generated from one: generating the
  /// JSON from the Lua would be comparing a thing with itself.
  const pairs = <String, (String, String)>{
    'ask': (
      '{ ask = "Language", default = "en", choices = { "en", "zh" } }',
      '{"ask":"Language","default":"en","choices":["en","zh"]}',
    ),
    'ai': ('{ ai = "translate this" }', '{"ai":"translate this"}'),
    'show': (
      '{ show = "the answer", title = "AI" }',
      '{"show":"the answer","title":"AI"}',
    ),
    'panel': (
      '{ panel = "the answer", title = "AI" }',
      '{"panel":"the answer","title":"AI"}',
    ),
    'notify': ('{ notify = "nothing selected" }', '{"notify":"nothing selected"}'),
    'replace': ('{ replace = "new text" }', '{"replace":"new text"}'),
    'diff': (
      '{ diff = {}, original = "before", result = "after" }',
      '{"diff":{},"original":"before","result":"after"}',
    ),
    'pane, every field': (
      '{ pane = "body", title = "AI", slot = "bottom", as = "preview", '
          'append = true, apply = true, replaces = "old", ai = "next" }',
      '{"pane":"body","title":"AI","slot":"bottom","as":"preview",'
          '"append":true,"apply":true,"replaces":"old","ai":"next"}',
    ),
    'pane, defaults': ('{ pane = "body" }', '{"pane":"body"}'),
    'ui': (
      '{ ui = { column = { { text = "x" } } }, title = "AI" }',
      '{"ui":{"column":[{"text":"x"}]},"title":"AI"}',
    ),
    'nothing at all': ('{ }', '{}'),
    'an unknown slot is refused the same way': (
      '{ pane = "body", slot = "middle" }',
      '{"pane":"body","slot":"middle"}',
    ),
    'an unknown rendering is refused the same way': (
      '{ pane = "body", as = "hologram" }',
      '{"pane":"body","as":"hologram"}',
    ),
  };

  pairs.forEach((name, pair) {
    test(name, () {
      final lua = describe(fromLua(pair.$1));
      final js = describe(PluginJsRuntime.parseAction(pair.$2));
      expect(js, lua, reason: 'the two runtimes read "$name" differently');
    });
  });

  /// The rows above cover every action a script can return. The one left out is
  /// the host's own refusal, which no script writes.
  test('every action a script can return has a row', () {
    final covered = <String>{
      for (final pair in pairs.values) describe(fromLua(pair.$1)).split('(').first,
    };
    expect(
      covered,
      {
        'ask',
        'ai',
        'show',
        'panel',
        'notify',
        'replace',
        'diff',
        'pane',
        'ui',
        'nothing',
      },
      reason: 'an action kind has no row here, or a row stopped producing the '
          'kind it was written for. The one deliberately absent is '
          'PluginPermissionRefusedAction, which the host makes when it turns a '
          'plugin down — no script can ask for it.',
    );
  });
}

/// The kind of an interface tree's root, which is all this file compares.
String rootKind(PluginUiNode node) => node.runtimeType.toString();

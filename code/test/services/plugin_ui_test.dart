import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_js_runtime.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';
import 'package:marktext_plus/services/plugin_ui.dart';
import 'package:marktext_plus/ui/widgets/plugin_ui_view.dart';

/// A plugin drawing its own interface.
///
/// Until now a plugin's answer was a string and the editor drew it as text.
/// Anything more — a form, a row of choices, a button — was out of reach, so
/// the one official plugin asked its question through the editor's own box
/// and could not offer anything else.
///
/// The tree is deliberately not HTML: a WebView costs a browser context in
/// memory and, on Linux, a system library the reader may not have. These are
/// the editor's own widgets, so they cost nothing at startup and follow the
/// reader's theme without the plugin knowing what the theme is.
void main() {
  PluginScriptAction lua(String body) => PluginScriptRuntime(
        'function on_command(ctx) return $body end',
      ).runCommand(const PluginScriptContext(command: 'c'));

  group('reading a tree', () {
    test('a form comes back as nodes, not as text', () {
      final action = lua('''{ ui = { column = {
        { text = "What should it say?", emphasis = true },
        { input = { id = "brief", multiline = true, placeholder = "..." } },
        { chips = { id = "idea", options = { "shorter", "formal" } } },
        { row = {
          { spacer = true },
          { button = { id = "go", label = "Write", primary = true } },
        }},
      }}, title = "AI" }''') as PluginUiAction;

      expect(action.title, 'AI');
      final root = action.root as PluginUiColumn;
      expect(root.children, hasLength(4));

      final text = root.children[0] as PluginUiText;
      expect(text.text, 'What should it say?');
      expect(text.emphasis, isTrue);

      final input = root.children[1] as PluginUiInput;
      expect(input.id, 'brief');
      expect(input.multiline, isTrue);
      expect(input.placeholder, '...');

      expect((root.children[2] as PluginUiChips).options,
          ['shorter', 'formal']);

      final row = root.children[3] as PluginUiRow;
      expect(row.children.first, isA<PluginUiSpacer>());
      expect((row.children.last as PluginUiButton).primary, isTrue);
    });

    test('JavaScript reads the same shapes', () {
      // A plugin author picks the language and nothing else changes.
      final action = PluginJsRuntime.parseAction(
        '{"ui":{"column":[{"text":"hi"},'
        '{"button":{"id":"go","label":"Write","primary":true}}]}}',
      ) as PluginUiAction;
      final root = action.root as PluginUiColumn;
      expect((root.children[0] as PluginUiText).text, 'hi');
      expect((root.children[1] as PluginUiButton).id, 'go');
    });

    test('a node with no id is not a node', () {
      // An input the plugin cannot be told about is a box that swallows what
      // the reader types.
      expect(() => lua('{ ui = { input = { placeholder = "x" } } }'),
          throwsA(isA<PluginScriptException>()));
    });

    test('a tree too deep is refused whole', () {
      // The parser recurses, so depth is the editor's stack. A plugin does
      // not get to decide how much of it to use.
      var body = '{ text = "deep" }';
      for (var i = 0; i < PluginUiLimits.maxDepth + 2; i++) {
        body = '{ column = { $body } }';
      }
      expect(() => lua('{ ui = $body }'),
          throwsA(isA<PluginScriptException>()));
    });

    test('a tree too wide is refused whole', () {
      final many = List.filled(
        PluginUiLimits.maxNodes + 10,
        '{ text = "x" }',
      ).join(', ');
      expect(() => lua('{ ui = { column = { $many } } }'),
          throwsA(isA<PluginScriptException>()));
    });

    test('refused rather than drawn in part', () {
      // Half a form is worse than none: the reader fills in what is there and
      // presses a button that was never drawn.
      var body = '{ text = "deep" }';
      for (var i = 0; i < PluginUiLimits.maxDepth + 2; i++) {
        body = '{ column = { $body } }';
      }
      expect(
        () => lua('{ ui = { column = { { text = "kept?" }, $body } } }'),
        throwsA(isA<PluginScriptException>()),
        reason: '一个孩子不合法就该拒绝整棵树',
      );
    });
  });

  group('the nodes added for forms', () {
    test('select, checkbox and markdown come back as nodes', () {
      final action = lua('''{ ui = { column = {
        { select = { id = "lang", options = { "en", "ja" }, value = "ja" } },
        { checkbox = { id = "keep", label = "Keep formatting", value = true } },
        { markdown = "## A heading\\n\\nand a paragraph" },
      }}}''') as PluginUiAction;
      final root = action.root as PluginUiColumn;

      final select = root.children[0] as PluginUiSelect;
      expect(select.options, ['en', 'ja']);
      expect(select.value, 'ja', reason: '插件记得的选择该已经选上');

      final checkbox = root.children[1] as PluginUiCheckbox;
      expect(checkbox.label, 'Keep formatting');
      expect(checkbox.value, isTrue);

      expect((root.children[2] as PluginUiMarkdown).source,
          contains('## A heading'));
    });

    testWidgets('a checkbox sends true or false as a string', (tester) async {
      // Everything a plugin is told is a string, so a script in any of the
      // three languages reads it the same way.
      Map<String, String>? values;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PluginUiView(
            root: const PluginUiColumn([
              PluginUiCheckbox(id: 'keep', label: 'Keep formatting'),
            ]),
            onEvent: (_, v) => values = v,
          ),
        ),
      ));

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(values, {'keep': 'true'});
    });
  });

  group('drawing a tree', () {
    testWidgets('what the reader typed comes back with the button they pressed',
        (tester) async {
      String? pressed;
      Map<String, String>? values;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PluginUiView(
            root: const PluginUiColumn([
              PluginUiText('What should it say?'),
              PluginUiInput(id: 'brief', placeholder: 'shorter…'),
              PluginUiChips(id: 'idea', options: ['formal', 'casual']),
              PluginUiRow([
                PluginUiSpacer(),
                PluginUiButton(id: 'go', label: 'Write', primary: true),
              ]),
            ]),
            onEvent: (id, v) {
              pressed = id;
              values = v;
            },
          ),
        ),
      ));

      expect(find.text('What should it say?'), findsOneWidget);
      expect(find.text('formal'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'make it shorter');
      await tester.tap(find.text('formal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Write'));

      expect(pressed, 'go');
      expect(values, {'brief': 'make it shorter', 'idea': 'formal'},
          reason: '按钮要带上它旁边所有输入的值，'
              '否则插件得自己记住一步之前画过什么');
    });

    testWidgets('a new tree is a new form', (tester) async {
      // Keeping what was typed would put an answer from the last question
      // into this one.
      Widget wrap(PluginUiNode root) => MaterialApp(
            home: Scaffold(
              body: PluginUiView(root: root, onEvent: (_, __) {}),
            ),
          );

      // Not `const`: two identical const trees are canonicalised to the same
      // object, and the view treats the same object as the same form — which
      // is right, and would make this test pass without drawing anything new.
      // A tree from a plugin is built at runtime and is never the old one.
      await tester.pumpWidget(wrap(PluginUiColumn([
        const PluginUiInput(id: 'a'),
      ])));
      await tester.enterText(find.byType(TextField), 'first answer');

      await tester.pumpWidget(wrap(PluginUiColumn([
        const PluginUiInput(id: 'a'),
      ])));
      await tester.pump();

      expect(find.text('first answer'), findsNothing);
    });
  });
}

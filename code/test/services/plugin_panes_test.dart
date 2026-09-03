import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// Two capabilities the editor has and plugins could not reach.
///
/// The editor splits a tab between source and preview, and it has a side bar
/// with panels. Neither was offered to a plugin: `ui.sidebar` was in the
/// permission list with nothing behind it, and the only way a plugin could put
/// text on screen beside the document was the one fixed panel on the right.
void main() {
  _rendering();

  group('a pane the plugin fills', () {
    PluginScriptAction run(String action) => PluginScriptRuntime(
          'function on_command(ctx) return $action end',
        ).runCommand(const PluginScriptContext(command: 'c'));

    test('a pane says where it goes', () {
      final action = run('{ pane = "text", title = "T", slot = "bottom" }')
          as PluginPaneAction;
      expect(action.text, 'text');
      expect(action.title, 'T');
      expect(action.slot, PluginPaneSlot.bottom);
    });

    test('a pane with no slot goes beside the document', () {
      expect((run('{ pane = "text" }') as PluginPaneAction).slot,
          PluginPaneSlot.right);
    });

    test('the grid is two by two, and those are its cells', () {
      // The document holds the first cell; a plugin may fill the other three.
      expect(PluginPaneSlot.values.map((s) => s.name).toSet(),
          {'right', 'bottom', 'corner'});
    });

    test('a slot the editor does not know is refused, not guessed', () {
      // Guessing would put the pane somewhere the author did not ask for, and
      // they would have no way to find out why.
      expect(run('{ pane = "text", slot = "topLeft" }'),
          isA<PluginNotifyAction>());
    });

    test('panel still means what it meant', () {
      // Plugins already return `panel`. Removing it would break them.
      final action = run('{ panel = "text", title = "T" }');
      expect(action, isA<PluginPanelAction>());
    });
  });

  group('a panel a plugin contributes to the side bar', () {
    PluginManifest manifest(Map<String, dynamic> extra) =>
        PluginManifest.fromJson({
          'id': 'com.example.demo',
          'name': 'Demo',
          'version': '1.0.0',
          'runtime': 'lua',
          'entrypoint': 'plugin.lua',
          ...extra,
        });

    test('a plugin declares a panel with a command to fill it', () {
      final m = manifest({
        'permissions': ['ui.sidebar'],
        'panels': [
          {'id': 'outline', 'title': 'panel.outline', 'icon': 'list'},
        ],
      });

      expect(m.panels.single.id, 'outline');
      expect(m.panels.single.title, 'panel.outline');
      expect(m.panels.single.icon, 'list');
    });

    test('a panel needs the side bar permission to appear', () {
      final declared = {
        'panels': [
          {'id': 'outline', 'title': 'T', 'icon': 'list'},
        ],
      };
      expect(manifest(declared).hasPermission(PluginPermission.uiSidebar),
          isFalse);
      expect(
        manifest({...declared, 'permissions': ['ui.sidebar']})
            .hasPermission(PluginPermission.uiSidebar),
        isTrue,
      );
    });

    test('a panel without an icon is refused', () {
      // The right side bar is a rail of icons. A panel with nothing to draw
      // would be a gap that opens something.
      expect(
        () => manifest({
          'panels': [
            {'id': 'outline', 'title': 'T'},
          ],
        }),
        throwsFormatException,
      );
    });
  });
}

/// A pane can be drawn the way the document is being read.
///
/// A translated document shown as raw Markdown beside a rendered preview is
/// not comparable to what it is beside — and the plugin cannot pick unless it
/// is told which view the reader is in, which `ctx` never said.
void _rendering() {
  PluginScriptAction run(String action, {String view = ''}) =>
      PluginScriptRuntime('function on_command(ctx) return $action end')
          .runCommand(PluginScriptContext(command: 'c', view: view));

  test('a pane says how it should be drawn', () {
    final action =
        run('{ pane = "t", as = "preview" }') as PluginPaneAction;
    expect(action.render, PluginPaneRender.preview);
  });

  test('a pane that does not say is plain text', () {
    expect((run('{ pane = "t" }') as PluginPaneAction).render,
        PluginPaneRender.text);
  });

  test('the ways a pane can be drawn', () {
    expect(PluginPaneRender.values.map((r) => r.name).toSet(),
        {'text', 'source', 'preview'});
  });

  test('a way of drawing the editor does not know is refused', () {
    expect(run('{ pane = "t", as = "hologram" }'), isA<PluginNotifyAction>());
  });

  test('the script is told which view the reader is in', () {
    final action = run('{ notify = ctx.view }', view: 'preview')
        as PluginNotifyAction;
    expect(action.message, 'preview');
  });

  test('a plugin can mirror the reader view without knowing the names', () {
    // What the translate plugin does: draw the translation the way the thing
    // it sits beside is drawn.
    final action = run('{ pane = "t", as = ctx.view }', view: 'source')
        as PluginPaneAction;
    expect(action.render, PluginPaneRender.source);
  });
}

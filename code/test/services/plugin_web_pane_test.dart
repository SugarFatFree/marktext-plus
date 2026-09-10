import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_command_service.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// A plugin drawing its own page needs the engine as well as the room.
///
/// `ui.webview` was declared, described to the reader in the plugin's own page,
/// listed in the SDK in twelve languages, and had a proxy written for it — and
/// nothing behind it: no way for a plugin to open a page, and nothing that
/// would have said so. This is that way, and the check that goes with it.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('webpane_'));
  tearDown(() => root.existsSync() ? root.deleteSync(recursive: true) : null);

  PluginManifest install(String id, String body, List<String> permissions) {
    final manifest = PluginManifest(
      id: id,
      name: 'Demo',
      version: '1.0.0',
      entrypoint: 'plugin.lua',
      runtime: PluginRuntime.lua,
      permissions: permissions,
    );
    Directory('${root.path}/$id').createSync(recursive: true);
    File('${root.path}/$id/plugin.lua').writeAsStringSync(
      'function on_command(ctx)\n  return $body\nend\n',
    );
    return manifest;
  }

  PluginScriptAction run(PluginManifest manifest) {
    final service = PluginCommandService(root.path);
    addTearDown(service.dispose);
    return service.start(
      manifest,
      const PluginScriptContext(command: 'go', document: 'a document'),
    );
  }

  const page = '{ pane = "<h1>hello</h1>", title = "Mine", as = "web" }';

  test('a plugin can ask for its own page', () {
    final action = run(install('draws', page, const ['ui.webview']));

    expect(action, isA<PluginPaneAction>());
    expect((action as PluginPaneAction).render, PluginPaneRender.web);
    expect(action.text, '<h1>hello</h1>');
  });

  test('without ui.webview it cannot, even holding ui.sidebar', () {
    // The pane permission is not enough. A reader who agreed to a plugin
    // filling a pane did not agree to it running a browser in one.
    final action = run(install('sneaky', page, const ['ui.sidebar']));

    expect(action, isA<PluginNotifyAction>());
    expect((action as PluginNotifyAction).message, contains('ui.webview'));
  });

  test('the engine carries the room and the network with it', () {
    // Declaring the engine grants the pane it needs and the network a page
    // reaches on its own — and the reader is shown all three, because a list
    // that understates what was granted is worse than no list.
    final granted = PluginPermission.withImplied(const ['ui.webview']);

    expect(granted, contains(PluginPermission.uiSidebar));
    expect(granted, contains(PluginPermission.networkRequest));
  });

  test('an ordinary pane still needs only the side bar', () {
    // The new branch must not have made every pane cost the engine.
    final action = run(install(
      'plain',
      '{ pane = "just words", title = "Plain" }',
      const ['ui.sidebar'],
    ));

    expect(action, isA<PluginPaneAction>());
    expect((action as PluginPaneAction).render, PluginPaneRender.text);
  });
}

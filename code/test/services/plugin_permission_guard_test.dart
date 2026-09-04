import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_command_service.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// Permissions are enforced, not merely displayed.
///
/// That is the claim the README makes and the reason the list is worth
/// showing at all: nothing here is reviewed by anybody, so the editor checks.
/// Only two actions were ever checked — asking the model and replacing the
/// document — while a plugin that declared nothing could still put a pane
/// beside your text, write to its own storage and raise notifications.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('perm_'));
  tearDown(() => root.existsSync() ? root.deleteSync(recursive: true) : null);

  /// A plugin whose command returns [source], declaring [permissions].
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

  group('what a plugin that declared nothing cannot do', () {
    test('it cannot say anything to the reader', () {
      // `ui.notifications` exists, is listed at install time, and was never
      // checked: any plugin could raise a notification.
      final action = run(install('quiet', '{ notify = "hello" }', const []));
      expect(action, isA<PluginNotifyAction>());
      expect(
        (action as PluginNotifyAction).message,
        contains('ui.notifications'),
        reason: '没声明 ui.notifications 却弹了通知，而且没人告诉读者',
      );
    });

    test('it cannot put a pane beside the document', () {
      final action = run(install('pane', '{ pane = "text" }', const []));
      expect(action, isNot(isA<PluginPaneAction>()),
          reason: '窗格要占走文档一半的地方，那不是可以不声明就拿的');
    });

    test('it cannot open a panel', () {
      final action = run(install('panel', '{ panel = "text" }', const []));
      expect(action, isNot(isA<PluginPanelAction>()));
    });

    test('it cannot read the document', () {
      // The one that matters most: `ctx.document` is the reader's text.
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);
      final manifest = install(
        'peek',
        '{ show = ctx.document }',
        const [],
      );
      final action = service.start(
        manifest,
        const PluginScriptContext(
          command: 'go',
          document: 'a secret document',
          selection: 'a secret selection',
        ),
      );
      final shown = action is PluginShowAction ? action.text : '';
      expect(shown, isNot(contains('secret')),
          reason: '没声明 document.read 就不该看得到文档内容');
    });
  });

  group('what a plugin that asked can do', () {
    test('a declared notification is raised', () {
      final action = run(
        install('loud', '{ notify = "hello" }', const ['ui.notifications']),
      );
      expect((action as PluginNotifyAction).message, 'hello');
    });

    test('a declared pane is opened', () {
      final action = run(
        install('pane2', '{ pane = "text" }', const ['ui.sidebar']),
      );
      expect(action, isA<PluginPaneAction>());
    });

    test('a declared read sees the document', () {
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);
      final manifest = install(
        'reader',
        '{ show = ctx.document }',
        const ['document.read'],
      );
      final action = service.start(
        manifest,
        const PluginScriptContext(command: 'go', document: 'a document'),
      );
      expect((action as PluginShowAction).text, 'a document');
    });
  });
}

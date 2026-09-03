import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_command_service.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// The plugin that ships alongside the editor, run exactly as an installation
/// would run it: its own manifest, its own script, nothing stubbed.
void main() {
  const repo =
      '/iflytek/workspace/znhu/github/marktext-plus-plugins/marktext-plus-ai-translate-plugin';

  late Directory root;
  late PluginManifest manifest;

  setUp(() {
    root = Directory.systemTemp.createTempSync('ai_translate_');
    manifest = PluginManifest.fromJson(
      jsonDecode(File('$repo/manifest.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final dir = Directory('${root.path}/${manifest.id}')
      ..createSync(recursive: true);
    File('$repo/plugin.lua').copySync('${dir.path}/plugin.lua');
  });
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('it contributes both commands to the editor right-click menu', () {
    expect(manifest.runtime, PluginRuntime.lua);
    expect(
      manifest.menus.map((m) => m.location).toSet(),
      {'editor.contextMenu'},
    );
    expect(
      manifest.menus.map((m) => m.id),
      containsAll(['translate.selection', 'translate.document']),
    );
  });

  test('it asks for the language, in the reader own language', () {
    final service = PluginCommandService(root.path, locale: 'zh_CN');

    final action = service.start(
      manifest,
      const PluginScriptContext(
        command: 'translate.selection',
        selection: '你好世界',
      ),
    );

    expect(action, isA<PluginAskAction>());
    expect((action as PluginAskAction).label, '目标语言');
    expect(action.defaultValue, 'English',
        reason: '第一次运行用 manifest 里声明的默认值');
  });

  test('the prompt it builds carries the document and the language', () {
    final service = PluginCommandService(root.path);

    final action = service.start(
      manifest,
      const PluginScriptContext(
        command: 'translate.document',
        selection: 'ignored',
        document: '# 标题\n\n正文',
        answer: '日本語',
      ),
    );

    expect(action, isA<PluginAiAction>());
    final prompt = (action as PluginAiAction).prompt;
    expect(prompt, contains('日本語'));
    expect(prompt, contains('# 标题'));
    expect(prompt, isNot(contains('ignored')));
    expect(prompt, contains('Markdown'));
  });

  test('it remembers the language the reader chose last time', () async {
    final service = PluginCommandService(root.path);
    service.start(
      manifest,
      const PluginScriptContext(
        command: 'translate.selection',
        selection: 'hi',
        answer: '日本語',
      ),
    );
    await service.flush(manifest);

    final next = PluginCommandService(root.path, locale: 'zh_CN');
    final action = next.start(
      manifest,
      const PluginScriptContext(command: 'translate.selection', selection: 'hi'),
    );

    expect((action as PluginAskAction).defaultValue, '日本語');
  });

  test('with nothing selected it says so instead of calling the model', () {
    final service = PluginCommandService(root.path, locale: 'zh_CN');

    final action = service.start(
      manifest,
      const PluginScriptContext(command: 'translate.selection'),
    );

    expect(action, isA<PluginNotifyAction>());
    expect((action as PluginNotifyAction).message, contains('请先选中'));
  });

  test('the model reply comes back as two panes, not as an edit', () {
    final service = PluginCommandService(root.path);

    final action = service.resumeWithResult(
      manifest,
      const PluginScriptContext(
        command: 'translate.selection',
        selection: '你好',
        answer: 'English',
      ),
      'Hello',
    );

    expect(action, isA<PluginDiffAction>());
    expect((action as PluginDiffAction).original, '你好');
    expect(action.result, 'Hello');
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_command_service.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// The plugin that ships alongside the editor, run exactly as an installation
/// would run it: its own manifest, its own script, nothing stubbed.
void main() {
  // The plugin is its own repository, checked out beside this one. CI has the
  // editor and not the plugin, so these run where the plugin is and say so
  // where it is not — rather than reading an absolute path off one machine and
  // failing everywhere else, which is how they first reached CI.
  const path = 'marktext-plus-plugins/marktext-plus-ai-translate-plugin';
  String? findRepo() {
    var directory = Directory.current;
    // Walked upwards rather than named by an absolute path: the plugin sits
    // beside the editor's checkout, and where that is differs per machine.
    for (var level = 0; level < 6; level++) {
      final candidate = '${directory.path}/$path';
      if (File('$candidate/manifest.json').existsSync()) return candidate;
      final parent = directory.parent;
      if (parent.path == directory.path) break;
      directory = parent;
    }
    return null;
  }

  final repo = findRepo();
  final present = repo != null;

  late Directory root;
  late PluginManifest manifest;

  setUp(() {
    if (!present) return;
    root = Directory.systemTemp.createTempSync('ai_translate_');
    manifest = PluginManifest.fromJson(
      jsonDecode(File('$repo/manifest.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final dir = Directory('${root.path}/${manifest.id}')
      ..createSync(recursive: true);
    // Everything the plugin ships, not just the entrypoint: it requires the
    // SDK module, so installing half of it proves nothing about the half that
    // matters.
    for (final relative in const [
      'plugin.lua',
      'lib/marktext-plus.lua',
    ]) {
      final target = File('${dir.path}/$relative')
        ..parent.createSync(recursive: true);
      File('$repo/$relative').copySync(target.path);
    }
  });
  tearDown(() {
    if (present && root.existsSync()) root.deleteSync(recursive: true);
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
  }, skip: present ? null : '插件仓库不在这台机器上');

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
  }, skip: present ? null : '插件仓库不在这台机器上');

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
  }, skip: present ? null : '插件仓库不在这台机器上');

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
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('with nothing selected it says so instead of calling the model', () {
    final service = PluginCommandService(root.path, locale: 'zh_CN');

    final action = service.start(
      manifest,
      const PluginScriptContext(command: 'translate.selection'),
    );

    expect(action, isA<PluginNotifyAction>());
    expect((action as PluginNotifyAction).message, contains('请先选中'));
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('a translated selection is one small answer, not an edit', () {
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

    expect(action, isA<PluginShowAction>());
    expect((action as PluginShowAction).text, 'Hello');
    expect(action.title, 'English');
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('a translated document goes beside the document, not over it', () {
    final service = PluginCommandService(root.path);

    final action = service.resumeWithResult(
      manifest,
      const PluginScriptContext(
        command: 'translate.document',
        document: '# 标题',
        answer: '日本語',
      ),
      '# Title',
    );

    expect(action, isA<PluginPanelAction>(),
        reason: '整篇译文放弹窗会盖住读者要对照的原文');
    expect((action as PluginPanelAction).text, '# Title');
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('the language question offers the usual answers and takes any other',
      () {
    final service = PluginCommandService(root.path);

    final action = service.start(
      manifest,
      const PluginScriptContext(
        command: 'translate.selection',
        selection: '你好',
      ),
    ) as PluginAskAction;

    expect(action.choices, contains('日本語'));
    expect(action.choices, contains('English'));
    expect(action.defaultValue, isNotEmpty);
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('each entry is offered only when it makes sense', () {
    final selection = manifest.menus
        .firstWhere((menu) => menu.id == 'translate.selection');
    final document = manifest.menus
        .firstWhere((menu) => menu.id == 'translate.document');

    expect(selection.appliesTo(hasSelection: true), isTrue);
    expect(selection.appliesTo(hasSelection: false), isFalse);
    expect(document.appliesTo(hasSelection: false), isTrue);
    expect(document.appliesTo(hasSelection: true), isFalse);
  }, skip: present ? null : '插件仓库不在这台机器上');
}

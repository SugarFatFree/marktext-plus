import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
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
    // Everything the plugin ships, listed by walking it rather than by naming
    // files here: it required the SDK module and then a second one, and both
    // times a hand-written list installed half a plugin.
    for (final entry in Directory(repo).listSync(recursive: true)) {
      if (entry is! File) continue;
      final relative = p.relative(entry.path, from: repo);
      if (!relative.endsWith('.lua') && relative != 'manifest.json') continue;
      final target = File('${dir.path}/$relative')
        ..parent.createSync(recursive: true);
      entry.copySync(target.path);
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

    // The pane goes up before the first request, not after it: the editor
    // reads `pane` ahead of `ai`, so an empty pane with a request behind it is
    // what it draws as "working". Asking first left the screen unchanged for
    // the several seconds the first block takes.
    expect(action, isA<PluginPaneAction>());
    final opened = action as PluginPaneAction;
    expect(opened.text, isEmpty, reason: 'nothing has come back yet');
    expect(opened.append, isFalse, reason: 'this is the pane being opened');

    final prompt = opened.nextPrompt!;
    expect(prompt, contains('日本語'));
    expect(prompt, contains('# 标题'));
    expect(prompt, isNot(contains('ignored')));
    expect(prompt, contains('Markdown'));
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('the list can say what this plugin is, in the reader\'s language', () {
    // The plugin list showed a bare name and nothing else, because a manifest
    // had no description to show. Both go through the plugin's own strings.
    expect(manifest.description, isNotEmpty,
        reason: '插件要能在列表里说清自己是做什么的');

    // Read from each language's own table, not through `stringsFor`: that
    // falls back per key to the default language, so a language missing half
    // its strings still answers every lookup — with English. Asking it here
    // would assert nothing at all.
    final needed = {
      manifest.name,
      manifest.description,
      for (final menu in manifest.menus) menu.title,
      for (final field in manifest.settings) field.title,
    };
    expect(manifest.locales.keys, containsAll(const [
      'en', 'zh', 'ja', 'ko', 'de', 'fr', 'it', 'ru', 'es', 'pt', 'pt_BR', 'ar',
    ]), reason: '插件的语言要跟上主应用的十二种');

    for (final entry in manifest.locales.entries) {
      expect(entry.value.keys, containsAll(needed),
          reason: '${entry.key} 少了该有的翻译；'
              '逐键回退会用英文补上，读者看不出这里漏了');
    }
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('a name that is not a key still reads as a name', () {
    // The name is its own translation key, so an editor that does not resolve
    // names shows "AI Translate" rather than the word "plugin.name".
    expect(manifest.name, isNot(startsWith('plugin.')));
    expect(manifest.stringsFor('zh')[manifest.name], isNot(manifest.name),
        reason: '中文下应当拿到译名，否则这个键白设了');
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

  test('a translated document arrives a block at a time, drawn as it is read',
      () {
    final service = PluginCommandService(root.path);
    const document = '# Title\n\nFirst paragraph.\n\nSecond paragraph.';

    // Asked in the source view, so the answer is drawn as source.
    final first = service.start(
      manifest,
      const PluginScriptContext(
        command: 'translate.document',
        document: document,
        answer: 'English',
        view: 'source',
      ),
    ) as PluginPaneAction;
    expect(first.text, isEmpty, reason: '窗格先开，说明自己在做，再去问模型');
    expect(first.render, PluginPaneRender.source,
        reason: '源码视图里问的，空窗格也该按源码画');
    expect(first.nextPrompt, contains('# Title'));
    expect(first.nextPrompt, isNot(contains('Second paragraph')),
        reason: '整篇一次喂给模型正是要避免的事');

    final one = service.resumeWithResult(
      manifest,
      const PluginScriptContext(
          command: 'translate.document', answer: 'English', view: 'source'),
      '# 标题',
    ) as PluginPaneAction;
    expect(one.text, '# 标题');
    expect(one.render, PluginPaneRender.source, reason: '源码视图里问的，就该按源码画');
    expect(one.append, isFalse, reason: '第一块是开头，不是追加');
    expect(one.nextPrompt, contains('First paragraph'));

    final two = service.resumeWithResult(
      manifest,
      const PluginScriptContext(
          command: 'translate.document', answer: 'English', view: 'source'),
      '第一段。',
    ) as PluginPaneAction;
    expect(two.append, isTrue, reason: '后续的块要接在前面下面');
    expect(two.nextPrompt, contains('Second paragraph'));

    final three = service.resumeWithResult(
      manifest,
      const PluginScriptContext(
          command: 'translate.document', answer: 'English', view: 'source'),
      '第二段。',
    ) as PluginPaneAction;
    expect(three.nextPrompt, isNull, reason: '没有下一块了');
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('a document read as a preview comes back rendered', () {
    final service = PluginCommandService(root.path);
    service.start(
      manifest,
      const PluginScriptContext(
        command: 'translate.document',
        document: 'One.\n\nTwo.',
        answer: 'English',
        view: 'preview',
      ),
    );
    final pane = service.resumeWithResult(
      manifest,
      const PluginScriptContext(
          command: 'translate.document', answer: 'English', view: 'preview'),
      'x',
    ) as PluginPaneAction;

    expect(pane.render, PluginPaneRender.preview);
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('a fenced block is not cut in half', () {
    final service = PluginCommandService(root.path);
    final first = service.start(
      manifest,
      const PluginScriptContext(
        command: 'translate.document',
        document: 'Before.\n\n```dart\nvoid main() {\n\n}\n```\n\nAfter.',
        answer: 'English',
        view: 'source',
      ),
    ) as PluginPaneAction;

    expect(first.nextPrompt, contains('Before.'));
    expect(first.nextPrompt, isNot(contains('void main')),
        reason: '第一块只该是第一段');
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

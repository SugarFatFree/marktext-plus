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

  test('a translated document arrives a batch at a time, drawn as it is read',
      () {
    final service = PluginCommandService(root.path);
    // Long enough to need more than one request, so the stepping is visible.
    final document = List.generate(
      30,
      (i) => i == 0 ? '# Title' : 'Paragraph $i. ${'word ' * 30}',
    ).join('\n\n');

    // Asked in the source view, so the answer is drawn as source.
    final first = service.start(
      manifest,
      PluginScriptContext(
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
    expect(first.nextPrompt, isNot(contains('Paragraph 29.')),
        reason: '整篇一次喂给模型正是要避免的事');

    final one = service.resumeWithResult(
      manifest,
      const PluginScriptContext(
        command: 'translate.document',
        answer: 'English',
        view: 'source',
      ),
      '# 标题',
    ) as PluginPaneAction;
    expect(one.text, '# 标题');
    expect(one.render, PluginPaneRender.source, reason: '源码视图里问的，就该按源码画');
    expect(one.append, isFalse, reason: '第一批是开头，不是追加');
    expect(one.nextPrompt, isNotNull, reason: '还有没译完的');

    final two = service.resumeWithResult(
      manifest,
      const PluginScriptContext(
        command: 'translate.document',
        answer: 'English',
        view: 'source',
      ),
      '第一批。',
    ) as PluginPaneAction;
    expect(two.append, isTrue, reason: '后续的批要接在前面下面');

    // Walk to the end: the last one has nothing left to ask for.
    var last = two;
    for (var step = 0; step < 40 && last.nextPrompt != null; step++) {
      last = service.resumeWithResult(
        manifest,
        const PluginScriptContext(
          command: 'translate.document',
          answer: 'English',
          view: 'source',
        ),
        '译文。',
      ) as PluginPaneAction;
    }
    expect(last.nextPrompt, isNull, reason: '没有下一批了');
    service.dispose();
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

  test('short paragraphs travel together, not one request each', () {
    // A paragraph per request is a request per paragraph: a long document
    // became dozens of round trips, each with its own latency, for text that
    // would have fitted in one. Batched, the first request carries as much as
    // the budget allows.
    final service = PluginCommandService(root.path);
    final short = List.generate(20, (i) => 'Paragraph number $i.').join('\n\n');
    final first = service.start(
      manifest,
      PluginScriptContext(
        command: 'translate.document',
        document: short,
        answer: 'English',
        view: 'source',
      ),
    ) as PluginPaneAction;

    final prompt = first.nextPrompt!;
    var carried = 0;
    for (var i = 0; i < 20; i++) {
      if (prompt.contains('Paragraph number $i.')) carried++;
    }
    expect(carried, greaterThan(5),
        reason: '这些段落加起来还很短，不该一段一个请求');
    service.dispose();
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('a long paragraph still travels alone', () {
    final service = PluginCommandService(root.path);
    final long = '${'x' * 4000}\n\nAfterwards.';
    final first = service.start(
      manifest,
      PluginScriptContext(
        command: 'translate.document',
        document: long,
        answer: 'English',
        view: 'source',
      ),
    ) as PluginPaneAction;

    expect(first.nextPrompt, contains('xxxx'));
    expect(first.nextPrompt, isNot(contains('Afterwards.')),
        reason: '一个块已经装满预算时，不该再把下一个塞进去');
    service.dispose();
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('a heading is not sent on its own', () {
    // "## Results" by itself gives the model no idea of the register or the
    // subject it is translating. The case that matters is a heading landing on
    // a batch boundary — a short document merges everything regardless, and
    // asserting on one proves nothing about the rule.
    final service = PluginCommandService(root.path);
    final filling = 'word ' * 320; // comfortably over the batch budget
    final document = '$filling\n\n## Results';

    final first = service.start(
      manifest,
      PluginScriptContext(
        command: 'translate.document',
        document: document,
        answer: 'English',
        view: 'source',
      ),
    ) as PluginPaneAction;

    // Whatever the split does, the heading must not end up as a request by
    // itself — here it is the last block, so without the rule it would be.
    var prompt = first.nextPrompt!;
    var sawHeading = false;
    for (var step = 0; step < 20; step++) {
      if (prompt.contains('## Results')) {
        sawHeading = true;
        expect(prompt, contains('word'),
            reason: '标题必须和正文一起发，单独一条模型无从判断语域和主题');
        break;
      }
      final next = service.resumeWithResult(
        manifest,
        const PluginScriptContext(
          command: 'translate.document',
          answer: 'English',
          view: 'source',
        ),
        '译文。',
      ) as PluginPaneAction;
      if (next.nextPrompt == null) break;
      prompt = next.nextPrompt!;
    }
    expect(sawHeading, isTrue, reason: '标题得真的被发出去过');
    service.dispose();
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('a fenced block is not cut in half', () {
    // The blank line inside the fence is part of the code. Splitting there
    // would hand the model half a program — which is what this is about, not
    // which request the code ends up in.
    final service = PluginCommandService(root.path);
    final code = '```dart\nvoid main() {\n\n}\n```';
    final first = service.start(
      manifest,
      PluginScriptContext(
        command: 'translate.document',
        document: 'Before.\n\n$code\n\nAfter.',
        answer: 'English',
        view: 'source',
      ),
    ) as PluginPaneAction;

    final prompt = first.nextPrompt!;
    expect(prompt, contains(code),
        reason: '围栏内的空行不能成为切点，代码要整块走');
    service.dispose();
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('a long document is still more than one request', () {
    // Batching is not "send everything": what fails costs one batch, and the
    // reader sees the beginning while the end is still arriving.
    final service = PluginCommandService(root.path);
    final long = List.generate(
      40,
      (i) => 'Paragraph $i. ${'word ' * 30}',
    ).join('\n\n');
    final first = service.start(
      manifest,
      PluginScriptContext(
        command: 'translate.document',
        document: long,
        answer: 'English',
        view: 'source',
      ),
    ) as PluginPaneAction;

    expect(first.nextPrompt, contains('Paragraph 0.'));
    expect(first.nextPrompt, isNot(contains('Paragraph 39.')),
        reason: '整篇一次喂给模型正是要避免的事');
    service.dispose();
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

  group('the prompt is the reader\'s to change', () {
    Future<void> writePrompt(String template) async {
      final service = PluginCommandService(root.path);
      await service.writeSettings(manifest, {'prompt': template});
      service.dispose();
    }

    test('a template of their own is what gets sent', () async {
      await writePrompt('把下面的内容翻译成{{language}}：\n\n{{text}}');
      final service = PluginCommandService(root.path);
      final action =
          service.start(
                manifest,
                const PluginScriptContext(
                  command: 'translate.document',
                  document: 'Hello.',
                  answer: '中文',
                  view: 'source',
                ),
              )
              as PluginPaneAction;

      expect(action.nextPrompt, '把下面的内容翻译成中文：\n\nHello.');
      service.dispose();
    });

    test('a per-cent sign in the document survives', () async {
      // The replacement is a document, and `gsub` reads `%` in a replacement
      // as an escape: "100%" came out mangled, or raised.
      await writePrompt('{{language}}\n{{text}}');
      final service = PluginCommandService(root.path);
      final action =
          service.start(
                manifest,
                const PluginScriptContext(
                  command: 'translate.document',
                  document: 'Coverage rose to 100% this week.',
                  answer: 'English',
                  view: 'source',
                ),
              )
              as PluginPaneAction;

      expect(action.nextPrompt, contains('100%'));
      service.dispose();
    });

    test('a template that forgets {{text}} still carries the source',
        () async {
      // A prompt with nothing to translate in it is worse than an untidy one.
      await writePrompt('Translate into {{language}}, carefully.');
      final service = PluginCommandService(root.path);
      final action =
          service.start(
                manifest,
                const PluginScriptContext(
                  command: 'translate.document',
                  document: 'Hello.',
                  answer: 'English',
                  view: 'source',
                ),
              )
              as PluginPaneAction;

      expect(action.nextPrompt, contains('Hello.'));
      expect(action.nextPrompt, contains('carefully'));
      service.dispose();
    });

    test('with nothing written, the default prompt is used', () async {
      final service = PluginCommandService(root.path);
      await service.writeSettings(manifest, {'prompt': ''});
      final action =
          service.start(
                manifest,
                const PluginScriptContext(
                  command: 'translate.document',
                  document: 'Hello.',
                  answer: 'English',
                  view: 'source',
                ),
              )
              as PluginPaneAction;

      expect(action.nextPrompt, contains('Markdown'));
      expect(action.nextPrompt, contains('Hello.'));
      service.dispose();
    });

    test('the settings page offers the prompt, not a language nobody uses', () {
      // The default target language was a field whose value the next question
      // overwrote; the prompt is a thing only the reader can fix.
      expect(manifest.settings.map((f) => f.key), ['prompt']);
      final strings = manifest.stringsFor('zh_CN');
      expect(strings[manifest.settings.first.title], contains('提示词'));
    });
  });
}

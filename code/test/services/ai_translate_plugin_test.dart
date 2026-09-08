import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:marktext_plus/services/plugin_command_service.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';
import 'package:marktext_plus/ui/widgets/plugin_icons.dart';

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

  // The SDK, for the one test that compares what the plugin carries against
  // what the SDK publishes.
  String? findSdk() {
    var directory = Directory.current;
    for (var level = 0; level < 6; level++) {
      final candidate =
          '${directory.path}/marktext-plus-plugins/marktext-plus-plugin-sdk';
      if (File('$candidate/packages/lua/lib/marktext-plus.lua').existsSync()) {
        return candidate;
      }
      final parent = directory.parent;
      if (parent.path == directory.path) break;
      directory = parent;
    }
    return null;
  }

  final sdk = findSdk();

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

  test('every setting it offers is one the script reads', () {
    // A settings page is a promise: change this and something changes. A
    // field the script never reads is a box the reader types into for
    // nothing, and nothing about the page would say so.
    //
    // Looked for as a bare string rather than through a call, because the
    // reads go through a local helper — `setting("writingSystem", default)`
    // over `storage.get(key)` — and matching the call would have found none
    // of the six and reported all six as dead. Twice today a literal-only
    // scan has said code was not using something it uses.
    final declared = manifest.settings.map((f) => f.key).toSet();
    expect(declared, isNotEmpty, reason: '这个插件是有设置的，读不到说明取法坏了');

    final source = Directory(repo!)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.lua'))
        .map((f) => f.readAsStringSync())
        .join('\n');
    expect(source, isNotEmpty);

    final dead = declared.where((key) => !source.contains('"$key"')).toList();
    expect(
      dead,
      isEmpty,
      reason: '设置页里有这些字段，脚本从不读它们——读者改了不会有任何变化：$dead',
    );
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('every key the script looks up is one the manifest declares', () {
    // The test below holds each language to the keys the *manifest* names. A
    // script asks for keys of its own, and an unknown key comes back as
    // itself, so a missing declaration shows the reader `idea.shorter` where
    // a sentence belongs. Different list, nothing comparing them.
    //
    // Matching `t('literal')` is not enough: the writing ideas live in a
    // table and go through `t` by variable, which is how six of them would
    // slip past. So anything shaped like a key is a candidate, minus the two
    // things that share that shape and are not keys — module names inside
    // `require`, and the command ids the manifest itself declares.
    final declared = manifest.locales[manifest.defaultLocale]?.keys.toSet();
    expect(declared, isNotNull, reason: '默认语言的表读不到，下面的比较就是空的');
    expect(declared, isNotEmpty);

    final commandIds = manifest.commandIds.toSet();
    final candidates = <String>{};
    for (final file in Directory(repo!)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.lua'))) {
      final source = file.readAsStringSync();
      final required = RegExp(r'''require\s*\(?\s*['"]([^'"]+)['"]''')
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toSet();

      for (final match in RegExp(
        r'''['"]([a-z][a-zA-Z0-9_]*\.[a-zA-Z][a-zA-Z0-9_.]*)['"]''',
      ).allMatches(source)) {
        final key = match.group(1)!;
        if (key.endsWith('.lua') || key.endsWith('.json')) continue;
        if (required.contains(key)) continue;
        if (commandIds.contains(key)) continue;
        candidates.add(key);
      }
    }

    expect(
      candidates.length,
      greaterThan(5),
      reason: '只找到 ${candidates.length} 个候选键，多半是正则坏了而不是脚本不翻译',
    );
    expect(
      candidates.difference(declared!),
      isEmpty,
      reason: '脚本要这些键，manifest 没有——读者会看到键名本身：'
          '${candidates.difference(declared)}',
    );
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

  test('a heading travels with the text under it, not the text above it', () {
    // The sibling of the case above, and the one the rule is actually about:
    // "It goes with the text under it" is what the comment on `is_heading`
    // says. A heading never triggers a flush, so it joins whatever batch is
    // open — and when the block after it overflows, the flush happens on that
    // block. The heading stays behind with the paragraph it had nothing to do
    // with, and its own text starts the next request alone.
    //
    // The previous test has the heading last, where there is no "after" for
    // it to be separated from. That is why this one exists.
    final service = PluginCommandService(root.path);
    addTearDown(service.dispose);
    final filling = 'word ' * 320; // comfortably over the batch budget
    const body = 'Recovery reached ninety per cent within the hour.';
    final document = '$filling\n\n## Results\n\n$body';

    final prompts = <String>[];
    var action = service.start(
      manifest,
      PluginScriptContext(
        command: 'translate.document',
        document: document,
        answer: 'English',
        view: 'source',
      ),
    ) as PluginPaneAction;
    for (var step = 0; step < 20; step++) {
      final prompt = action.nextPrompt;
      if (prompt == null) break;
      prompts.add(prompt);
      action = service.resumeWithResult(
        manifest,
        const PluginScriptContext(
          command: 'translate.document',
          answer: 'English',
          view: 'source',
        ),
        '译文。',
      ) as PluginPaneAction;
    }

    expect(prompts, isNotEmpty);
    final carrying = prompts.where((p) => p.contains('## Results')).toList();
    expect(carrying, hasLength(1), reason: '标题应该只被发送一次');
    expect(
      carrying.single,
      contains(body),
      reason: '标题要跟着它下面的正文走。留在上一批里，模型看到的是'
          '一个和它无关的段落加一行光秃秃的标题，而正文另起一条请求',
    );
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('a document opening with a heading sends no empty request', () {
    // The batch being closed can be nothing but headings: a document that
    // starts with one, followed by a paragraph bigger than the budget. The
    // overflow flushes, everything held back is a heading, and there is
    // nothing left to send.
    //
    // Carrying them all forward and sending what remains would post an empty
    // prompt — a request that costs a round trip and can only come back
    // wrong. Reached by mutation: removing the guard broke nothing, which is
    // how a branch nobody exercises looks.
    final service = PluginCommandService(root.path);
    addTearDown(service.dispose);
    final huge = 'word ' * 400; // one block, larger than the budget on its own
    final document = '## Overview\n\n$huge';

    final prompts = <String>[];
    var action = service.start(
      manifest,
      PluginScriptContext(
        command: 'translate.document',
        document: document,
        answer: 'English',
        view: 'source',
      ),
    ) as PluginPaneAction;
    for (var step = 0; step < 20; step++) {
      final prompt = action.nextPrompt;
      if (prompt == null) break;
      prompts.add(prompt);
      action = service.resumeWithResult(
        manifest,
        const PluginScriptContext(
          command: 'translate.document',
          answer: 'English',
          view: 'source',
        ),
        '译文。',
      ) as PluginPaneAction;
    }

    expect(prompts, isNotEmpty);
    for (final prompt in prompts) {
      // The prompt always carries the template around it, so "empty" means
      // the part that was meant to be a document is missing: the whole thing
      // is the system and user prompts with nothing between them.
      expect(prompt, contains('word'),
          reason: '每一条请求都得带着要翻译的内容；空请求白跑一趟，'
              '而且只可能换回一个错的答案');
    }
    expect(
      prompts.where((p) => p.contains('## Overview')).single,
      contains('word'),
      reason: '标题仍旧要和它下面的正文一起走',
    );
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

  test('what follows a fence is not swallowed by it', () {
    // The test above checks the fence is not cut open. It cannot see the
    // other failure: a fence that never closes takes the rest of the document
    // with it, and "the code is all in one request" stays true while that one
    // request is the whole file.
    //
    // That has happened. `lua_dardo` answers `("" ):match("^%s*$")` with nil
    // where standard Lua matches, so the line-blank test that closed a fence
    // said no to every blank line.
    //
    // The paragraph after the fence is long enough to need a request of its
    // own, so it can only appear in the first one by having been counted as
    // part of the fence.
    final service = PluginCommandService(root.path);
    final code = '```dart\nvoid main() {}\n```';
    final after = 'y' * 4000;
    final first =
        service.start(
              manifest,
              PluginScriptContext(
                command: 'translate.document',
                document: 'Before.\n\n$code\n\n$after',
                answer: 'English',
                view: 'source',
              ),
            )
            as PluginPaneAction;

    expect(first.nextPrompt, contains('void main'));
    expect(
      first.nextPrompt,
      isNot(contains('yyyy')),
      reason: '围栏没有闭合，它后面的正文被当成了代码的一部分',
    );
    service.dispose();
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('a line of nothing but a tab still separates two paragraphs', () {
    // An editor that indents with tabs leaves lines that look empty and are
    // not. Read as text, the two paragraphs are one, and the model is handed a
    // run-on it has to guess the shape of.
    //
    // Both are long enough to need a request each, so they can only share one
    // by having been read as a single block.
    final service = PluginCommandService(root.path);
    final first =
        service.start(
              manifest,
              PluginScriptContext(
                command: 'translate.document',
                document: '${'x' * 4000}\n\t\n${'y' * 4000}',
                answer: 'English',
                view: 'source',
              ),
            )
            as PluginPaneAction;

    expect(first.nextPrompt, contains('xxxx'));
    expect(
      first.nextPrompt,
      isNot(contains('yyyy')),
      reason: '只有制表符的那一行没被当作空行，两段被并成了一段',
    );
    service.dispose();
  }, skip: present ? null : '插件仓库不在这台机器上');

  test('a document written on Windows still has paragraphs', () {
    // Lines are split on "\n", so every line of a CRLF document ends with a
    // stray "\r" and a blank line arrives as "\r" rather than "". Read as
    // text, that document is one paragraph from top to bottom.
    //
    // This editor has met the same thing before: `\r\n` once stopped Markdown
    // syntax working for exactly this reason.
    final service = PluginCommandService(root.path);
    final first =
        service.start(
              manifest,
              PluginScriptContext(
                command: 'translate.document',
                document: '${'x' * 4000}\r\n\r\n${'y' * 4000}',
                answer: 'English',
                view: 'source',
              ),
            )
            as PluginPaneAction;

    expect(first.nextPrompt, contains('xxxx'));
    expect(
      first.nextPrompt,
      isNot(contains('yyyy')),
      reason: 'CRLF 文档的空行只剩一个 \\r，没被认作空行，整篇成了一段',
    );
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

  group("the prompts are the reader's to change", () {
    // Six of them: a system prompt and a user prompt for each of the three
    // commands. What the model is, and what it is being given, are two
    // different things to want to change.
    Future<void> write(Map<String, String> values) async {
      final service = PluginCommandService(root.path);
      await service.writeSettings(manifest, values);
      service.dispose();
    }

    test('a translation template of their own is what gets sent', () async {
      await write({
        'translationSystem': '把内容翻译成 {{language}}。',
        'translationUser': '原文：\n{{text}}',
      });
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);
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

      expect(action.nextPrompt, '把内容翻译成 中文。\n\n原文：\nHello.');
    }, skip: present ? null : '插件仓库不在这台机器上');

    test('a per-cent sign in the document survives', () async {
      // The replacement is a document, and `gsub` reads `%` in a replacement
      // as an escape: "100%" came out mangled, or raised.
      await write({'translationSystem': '{{language}}', 'translationUser': '{{text}}'});
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);
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
    }, skip: present ? null : '插件仓库不在这台机器上');

    test('a template that forgets {{text}} still carries the source', () async {
      // A prompt with nothing to work on in it is worse than an untidy one.
      await write({
        'translationSystem': 'Translate into {{language}}, carefully.',
        'translationUser': 'No placeholder here.',
      });
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);
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
    }, skip: present ? null : '插件仓库不在这台机器上');

    test('a template that forgets {{instruction}} still carries the brief',
        () async {
      // The sibling of the {{text}} case above, and it loses the reader's own
      // words rather than the document's: they typed a brief into the ask box
      // one second earlier. A system prompt that says "Follow the brief" with
      // no brief in it is worse than an untidy prompt.
      await write({
        'writingSystem': 'You rewrite Markdown. Follow the brief.',
        'writingUser': 'No placeholder here:\n{{text}}',
      });
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);
      final action = service.start(
        manifest,
        const PluginScriptContext(
          command: 'ai.write',
          document: 'Hello.',
          answer: 'make it rhyme',
          view: 'source',
        ),
      ) as PluginPaneAction;

      expect(action.nextPrompt, contains('make it rhyme'),
          reason: '读者一秒钟前才输入的写作要求，不能因为模板被改过就静默丢掉');
      expect(action.nextPrompt, contains('Hello.'));
    }, skip: present ? null : '插件仓库不在这台机器上');

    test('a template that forgets {{language}} still says which language',
        () async {
      await write({
        'translationSystem': 'You translate Markdown.',
        'translationUser': 'Document:\n{{text}}',
      });
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);
      final action = service.start(
        manifest,
        const PluginScriptContext(
          command: 'translate.document',
          document: 'Hello.',
          answer: 'Français',
          view: 'source',
        ),
      ) as PluginPaneAction;

      expect(action.nextPrompt, contains('Français'),
          reason: '读者在下拉框里选了目标语言，模板丢了变量不该让模型自己猜');
    }, skip: present ? null : '插件仓库不在这台机器上');

    test('every placeholder the templates use has somewhere to fall back to',
        () {
      // The net under a dropped placeholder is a list, and a list is what
      // drifts. A fourth placeholder added to the templates without a line in
      // `APPENDED` would be exactly as silent as the two this group just
      // fixed — the reader edits a template, their input disappears, the
      // model answers anyway.
      final source = File('$repo/lib/prompts.lua').readAsStringSync();
      // Code only: the file's own doc comment names the placeholders too, and
      // a comment cannot break anything.
      final code = source
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('--'))
          .join('\n');

      final used = RegExp(r'\{\{(\w+)\}\}')
          .allMatches(code)
          .map((m) => m.group(1)!)
          .toSet();
      expect(used, isNotEmpty, reason: '一个占位符都没扫到，这条守卫已失效');

      // `text` is appended last and unlabelled; the rest are listed.
      final caught = {
        'text',
        ...RegExp(r'key\s*=\s*"(\w+)"')
            .allMatches(code)
            .map((m) => m.group(1)!),
      };
      expect(used.difference(caught), isEmpty,
          reason: '这些占位符没有兜底：${used.difference(caught)}');
    }, skip: present ? null : '插件仓库不在这台机器上');

    test('the README lists the placeholders the templates actually use', () {
      // Twelve READMEs describe these to the reader, in a table. A table that
      // names one the code does not fill is a promise; one that leaves out a
      // real one is a field they will never think to use.
      final code = File('$repo/lib/prompts.lua')
          .readAsStringSync()
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('--'))
          .join('\n');
      final used = RegExp(r'\{\{(\w+)\}\}')
          .allMatches(code)
          .map((m) => m.group(1)!)
          .toSet();

      final readme = File('$repo/README.md').readAsStringSync();
      final documented = RegExp(r'^\| `\{\{(\w+)\}\}` \|', multiLine: true)
          .allMatches(readme)
          .map((m) => m.group(1)!)
          .toSet();

      expect(documented, isNotEmpty, reason: 'README 里没扫到占位符表');
      expect(documented, used);
    }, skip: present ? null : '插件仓库不在这台机器上');

    test('with nothing written, the defaults are used', () async {
      await write({'translationSystem': '', 'translationUser': ''});
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);
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
    }, skip: present ? null : '插件仓库不在这台机器上');

    test('writing and proofreading have their own, kept apart', () async {
      // Changing how it rewrites must not change how it translates.
      await write({'writingSystem': 'ONLY FOR WRITING'});
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);

      final writing =
          service.start(
                manifest,
                const PluginScriptContext(
                  command: 'ai.write',
                  document: 'x',
                  answer: 'shorter',
                ),
              )
              as PluginPaneAction;
      expect(writing.nextPrompt, contains('ONLY FOR WRITING'));

      final translating =
          service.start(
                manifest,
                const PluginScriptContext(
                  command: 'translate.document',
                  document: 'x',
                  answer: 'English',
                  view: 'source',
                ),
              )
              as PluginPaneAction;
      expect(translating.nextPrompt, isNot(contains('ONLY FOR WRITING')));
    }, skip: present ? null : '插件仓库不在这台机器上');

    test('the settings page offers all six', () {
      expect(manifest.settings.map((f) => f.key), [
        'writingSystem',
        'writingUser',
        'proofreadingSystem',
        'proofreadingUser',
        'translationSystem',
        'translationUser',
      ]);
      // Each shows its default, so the reader can see what they are changing.
      for (final field in manifest.settings) {
        expect(field.defaultValue, isNotEmpty, reason: '\${field.key} 没有默认值');
      }
    }, skip: present ? null : '插件仓库不在这台机器上');
  });

  group('AI writing', () {
    test('it asks what to do before doing anything', () {
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);
      final action = service.start(
        manifest,
        const PluginScriptContext(
          command: 'ai.write',
          selection: 'a paragraph',
          document: 'a paragraph',
        ),
      );
      expect(action, isA<PluginAskAction>());
      expect((action as PluginAskAction).choices, isNotEmpty,
          reason: '常见改法该作为选项给出来，而不是每次都要自己想');
    }, skip: present ? null : '插件仓库不在这台机器上');

    test('the brief and the text both reach the model', () {
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);
      final action = service.start(
        manifest,
        const PluginScriptContext(
          command: 'ai.write',
          selection: 'the old words',
          document: 'before the old words after',
          answer: 'Make it shorter',
        ),
      ) as PluginPaneAction;

      expect(action.nextPrompt, contains('Make it shorter'));
      expect(action.nextPrompt, contains('the old words'));
      expect(action.text, isEmpty, reason: '窗格先开，说明自己在做');
    }, skip: present ? null : '插件仓库不在这台机器上');

    test('the pane is drawn the way the reader is reading', () {
      // `as` was one of two fields nothing here asserted — deleting it from
      // the plugin left every test green. The translation path covers it;
      // the writing path did not.
      //
      // `as` decides whether the answer is legible beside the thing it is
      // answering: Markdown source shown next to a rendered preview cannot be
      // compared with it.
      //
      // `slot` is not asserted here, and the reason is worth writing down:
      // `PluginPaneAction.slot` defaults to `right`, which is also what all
      // three of the plugin's panes ask for. Deleting `slot = "right"` from
      // the plugin leaves an assertion that it equals `right` perfectly
      // green — it would be measuring the default. There is no input that
      // tells the two apart until something here wants a different half.
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);
      const views = {
        'source': PluginPaneRender.source,
        'preview': PluginPaneRender.preview,
        // Anything else is the preview: a pane of raw Markdown is the
        // surprising answer, so it is not the one an unknown view gets.
        '': PluginPaneRender.preview,
      };
      for (final view in views.entries) {
        final action = service.start(
          manifest,
          PluginScriptContext(
            command: 'ai.write',
            selection: 'the old words',
            document: 'before the old words after',
            answer: 'Make it shorter',
            view: view.key,
          ),
        ) as PluginPaneAction;
        expect(action.render, view.value,
            reason: '在 "${view.key}" 视图里问的，窗格该照着画');
      }
    }, skip: present ? null : '插件仓库不在这台机器上');

    test('the result offers to replace what it was looking at', () {
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);
      service.start(
        manifest,
        const PluginScriptContext(
          command: 'ai.write',
          selection: 'the old words',
          document: 'before the old words after',
          answer: 'Make it shorter',
        ),
      );
      final action = service.resumeWithResult(
        manifest,
        const PluginScriptContext(
          command: 'ai.write',
          answer: 'Make it shorter',
        ),
        'the new words',
      ) as PluginPaneAction;

      expect(action.text, 'the new words');
      expect(action.canApply, isTrue, reason: '改写就是要替换原文的');
      expect(action.replaces, 'the old words');
    }, skip: present ? null : '插件仓库不在这台机器上');

    test('with nothing selected it replaces the whole document', () {
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);
      service.start(
        manifest,
        const PluginScriptContext(
          command: 'ai.write',
          document: 'the whole thing',
          answer: 'Expand with detail',
        ),
      );
      final action = service.resumeWithResult(
        manifest,
        const PluginScriptContext(command: 'ai.write', answer: 'x'),
        'more of it',
      ) as PluginPaneAction;
      expect(action.replaces, isEmpty, reason: '空字符串表示整篇');
    }, skip: present ? null : '插件仓库不在这台机器上');

    test('an empty document is a blank page, not an error', () {
      // The side bar icon on a tab with nothing in it: writing from nothing is
      // the point, so it must not refuse.
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);
      final action = service.start(
        manifest,
        const PluginScriptContext(
          command: 'ai.write',
          document: '',
          answer: 'Draft a release note',
        ),
      );
      expect(action, isA<PluginPaneAction>());
      expect((action as PluginPaneAction).nextPrompt,
          contains('Draft a release note'));
    }, skip: present ? null : '插件仓库不在这台机器上');
  });

  group('AI proofreading', () {
    test('it goes straight to the model, with no question', () {
      // There is nothing to ask: correcting mistakes is the whole brief.
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);
      final action = service.start(
        manifest,
        const PluginScriptContext(
          command: 'ai.proofread',
          selection: 'teh cat',
          document: 'teh cat sat',
        ),
      );
      expect(action, isA<PluginPaneAction>());
      expect((action as PluginPaneAction).nextPrompt, contains('teh cat'));
    }, skip: present ? null : '插件仓库不在这台机器上');

    test('it offers to replace, like writing does', () {
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);
      service.start(
        manifest,
        const PluginScriptContext(
          command: 'ai.proofread',
          selection: 'teh cat',
          document: 'teh cat sat',
        ),
      );
      final action = service.resumeWithResult(
        manifest,
        const PluginScriptContext(command: 'ai.proofread'),
        'the cat',
      ) as PluginPaneAction;
      expect(action.canApply, isTrue);
      expect(action.replaces, 'teh cat');
    }, skip: present ? null : '插件仓库不在这台机器上');

    test('an empty document has nothing to correct', () {
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);
      expect(
        service.start(
          manifest,
          const PluginScriptContext(command: 'ai.proofread', document: ''),
        ),
        isA<PluginNotifyAction>(),
      );
    }, skip: present ? null : '插件仓库不在这台机器上');
  });

  group('translation still offers nothing to apply', () {
    test('a translation is to read, not to accept', () {
      // Replacing a document with its translation is not what anyone meant by
      // "translate", and an Apply button there would be an accident waiting.
      final service = PluginCommandService(root.path);
      addTearDown(service.dispose);
      service.start(
        manifest,
        const PluginScriptContext(
          command: 'translate.document',
          document: 'one\n\ntwo',
          answer: 'English',
          view: 'source',
        ),
      );
      final action = service.resumeWithResult(
        manifest,
        const PluginScriptContext(
          command: 'translate.document',
          answer: 'English',
          view: 'source',
        ),
        'uno',
      ) as PluginPaneAction;
      expect(action.canApply, isFalse);
    }, skip: present ? null : '插件仓库不在这台机器上');

    test('every icon it names is one the editor can draw', () {
      // Flutter tree-shakes icon fonts, so the editor keeps a table of the
      // icons a plugin may name. That table had seven entries and this
      // plugin asks for `edit_note`, so the side bar drew the generic
      // extension square for a writing tool — the plugin had done its part.
      for (final panel in manifest.panels) {
        expect(PluginIcons.byName.keys, contains(panel.icon),
            reason: '${panel.icon} 不在编辑器的图标表里，侧边栏会画成通用插件图标');
      }
      for (final item in manifest.toolbar) {
        expect(PluginIcons.byName.keys, contains(item.icon),
            reason: '${item.icon} 不在编辑器的图标表里');
      }
    }, skip: present ? null : '插件仓库不在这台机器上');

    test('the API module it carries is the one the SDK publishes', () {
      // The SDK says this file ships with your plugin: you copy it and it is
      // yours, so drift is allowed by design. This plugin is also the
      // reference one, and its copy had fallen five options behind — `as`,
      // `append`, `ai`, `apply` and `replaces`, every one of them added for
      // this plugin's own features. It got away with it by building the
      // table literally instead of calling `sdk.pane`, which is the thing
      // the constructor exists to stop.
      expect(
        File('$repo/lib/marktext-plus.lua').readAsStringSync(),
        File('$sdk/packages/lua/lib/marktext-plus.lua').readAsStringSync(),
        reason: '插件带的 API 模块落后于 SDK——'
            '它自己不调用，所以没人会发现，直到有人调用',
      );
    }, skip: present && sdk != null ? null : '插件或 SDK 仓库不在这台机器上');
  });
}

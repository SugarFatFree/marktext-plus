@Tags(['packaging'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_command_service.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// The zip that is about to be uploaded, installed and run.
///
/// Not the working tree — the archive. Twice now a plugin has been "installed"
/// by copying only its entrypoint, which is half a plugin; this unpacks what
/// the reader would actually download and runs it.
/// The plugin checkout beside this one, or null where there is none.
///
/// Walked upwards rather than named by an absolute path: the plugin sits
/// beside the editor's checkout, and where that is differs per machine.
String? _findPluginRepo() {
  const path = 'marktext-plus-plugins/marktext-plus-ai-translate-plugin';
  var directory = Directory.current;
  for (var level = 0; level < 6; level++) {
    final candidate = '${directory.path}/$path';
    if (File('$candidate/manifest.json').existsSync()) return candidate;
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  return null;
}

void main() {
  final zip = Platform.environment['PLUGIN_ZIP'];
  final present = zip != null && File(zip).existsSync();

  late Directory root;
  late PluginManifest manifest;

  setUpAll(() {
    if (!present) return;
    root = Directory.systemTemp.createTempSync('packaged_');
    final into = Directory('${root.path}/unpacked')..createSync();
    final result = Process.runSync('unzip', ['-q', zip, '-d', into.path]);
    expect(result.exitCode, 0, reason: '解包失败: ${result.stderr}');

    manifest = PluginManifest.fromJson(
      jsonDecode(File('${into.path}/manifest.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    // Installed the way the editor installs: the whole directory.
    final dir = Directory('${root.path}/${manifest.id}')..createSync();
    for (final entity in into.listSync(recursive: true)) {
      if (entity is! File) continue;
      final rel = entity.path.substring(into.path.length + 1);
      final target = File('${dir.path}/$rel');
      target.parent.createSync(recursive: true);
      entity.copySync(target.path);
    }
  });

  tearDownAll(() {
    if (present && root.existsSync()) root.deleteSync(recursive: true);
  });

  test('the archive holds everything the plugin requires', () {
    final dir = Directory('${root.path}/${manifest.id}');
    expect(File('${dir.path}/${manifest.entrypoint}').existsSync(), isTrue);
    expect(File('${dir.path}/lib/marktext-plus.lua').existsSync(), isTrue,
        reason: '入口 require 的模块必须在包里');
    expect(File('${dir.path}/lib/blocks.lua').existsSync(), isTrue);
    expect(File('${dir.path}/lib/prompts.lua').existsSync(), isTrue,
        reason: '提示词模块不在包里，三个功能一个也跑不起来');
  }, skip: present ? null : 'PLUGIN_ZIP 未指向一个存在的 zip');

  test('the packaged version is the one in the repository', () {
    // Read from the checkout rather than written here: a number spelled twice
    // is one that drifts, and this one had to be edited by hand at every
    // release. What matters is that the archive carries what the repository
    // says — the marketplace shows the release's version and the installed
    // list shows the manifest's, and two different numbers are the editor
    // saying something untrue about itself.
    final repo = _findPluginRepo();
    if (repo == null) return;
    final inRepo =
        jsonDecode(File('$repo/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(manifest.version, inRepo['version'],
        reason: '包里的版本和仓库里的对不上');
  }, skip: present ? null : 'PLUGIN_ZIP 未指向一个存在的 zip');

  test('it runs out of the archive, and opens its pane before asking', () {
    final service = PluginCommandService(root.path, locale: 'zh_CN');
    final action = service.start(
      manifest,
      const PluginScriptContext(
        command: 'translate.document',
        document: '# 标题\n\n正文一段。\n\n正文二段。',
        answer: 'English',
        view: 'source',
      ),
    );

    expect(action, isA<PluginPaneAction>(), reason: '打包出来的插件必须真的能跑');
    final pane = action as PluginPaneAction;
    expect(pane.text, isEmpty, reason: '窗格先开，再去问模型');
    expect(pane.render, PluginPaneRender.source);
    expect(pane.nextPrompt, contains('# 标题'));
    // These three paragraphs are well under one request's budget, so they
    // travel together — a request each would be three round trips for text
    // that fits in one.
    expect(pane.nextPrompt, contains('正文二段'));
    service.dispose();
  }, skip: present ? null : 'PLUGIN_ZIP 未指向一个存在的 zip');

  test('its menus and strings survived packaging', () {
    final strings = manifest.stringsFor('zh_CN');
    expect(strings[manifest.name], 'AI 助手');
    expect(strings[manifest.description], isNotEmpty);
    expect(manifest.locales.length, 12);
    for (final menu in manifest.menus) {
      expect(strings[menu.title], isNotNull);
    }
  }, skip: present ? null : 'PLUGIN_ZIP 未指向一个存在的 zip');
}

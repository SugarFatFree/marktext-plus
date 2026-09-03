import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_command_service.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

void main() {
  _permissions();

  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('plugin_cmd_'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  PluginManifest install(String script, {Map<String, dynamic> extra = const {}}) {
    final dir = Directory('${root.path}/com.example.demo')..createSync(recursive: true);
    File('${dir.path}/plugin.lua').writeAsStringSync(script);
    final json = {
      'id': 'com.example.demo',
      'name': 'Demo',
      'version': '1.0.0',
      'runtime': 'lua',
      'entrypoint': 'plugin.lua',
      ...extra,
    };
    File('${dir.path}/manifest.json').writeAsStringSync(jsonEncode(json));
    return PluginManifest.fromJson(json);
  }

  test('the script runs from the plugin directory the reader installed', () {
    final manifest = install(r'''
function on_command(ctx)
  return { notify = "ran " .. ctx.command }
end
''');
    final service = PluginCommandService(root.path);

    final action = service.start(manifest, const PluginScriptContext(command: 'demo.run'));

    expect((action as PluginNotifyAction).message, 'ran demo.run');
  });

  test('a plugin sees its own strings in the reader language', () {
    final manifest = install(
      'function on_command(ctx) return { notify = t("hi") } end',
      extra: {
        'defaultLocale': 'en',
        'locales': {
          'en': {'hi': 'Hello'},
          'zh': {'hi': '你好'},
        },
      },
    );
    final service = PluginCommandService(root.path, locale: 'zh_CN');

    final action = service.start(manifest, const PluginScriptContext(command: 'x'));
    expect((action as PluginNotifyAction).message, '你好');
  });

  test('settings a plugin writes survive into the next command', () async {
    final manifest = install(r'''
function on_command(ctx)
  if ctx.command == "save" then
    storage.set("lang", "ja")
    return { notify = "saved" }
  end
  return { notify = storage.get("lang") or "unset" }
end
''');
    final service = PluginCommandService(root.path);

    service.start(manifest, const PluginScriptContext(command: 'save'));
    await service.flush(manifest);

    final fresh = PluginCommandService(root.path);
    final action = fresh.start(manifest, const PluginScriptContext(command: 'read'));
    expect((action as PluginNotifyAction).message, 'ja');
  });

  test('declared defaults are there the first time the plugin runs', () {
    final manifest = install(
      'function on_command(ctx) return { notify = storage.get("target") or "none" } end',
      extra: {
        'settings': [
          {'key': 'target', 'title': 'Target', 'type': 'text', 'default': 'English'},
        ],
      },
    );
    final service = PluginCommandService(root.path);

    final action = service.start(manifest, const PluginScriptContext(command: 'x'));
    expect((action as PluginNotifyAction).message, 'English');
  });

  test('a plugin whose script is missing says so rather than throwing raw', () {
    final manifest = PluginManifest.fromJson({
      'id': 'com.example.ghost',
      'name': 'Ghost',
      'version': '1.0.0',
      'runtime': 'lua',
      'entrypoint': 'plugin.lua',
    });
    final service = PluginCommandService(root.path);

    expect(
      () => service.start(manifest, const PluginScriptContext(command: 'x')),
      throwsA(isA<PluginScriptException>()),
    );
  });

  test('a data plugin has no script to run', () {
    final manifest = PluginManifest.fromJson({
      'id': 'com.example.theme',
      'name': 'Theme',
      'version': '1.0.0',
      'entrypoint': 'theme.json',
    });
    final service = PluginCommandService(root.path);

    expect(
      () => service.start(manifest, const PluginScriptContext(command: 'x')),
      throwsA(isA<PluginScriptException>()),
    );
  });

  test('a settings page starts from what the plugin declared as defaults', () {
    final manifest = install('', extra: {
      'settings': [
        {'key': 'target', 'title': 'Language', 'default': 'Japanese'},
        {'key': 'tone', 'title': 'Tone'},
      ],
    });

    expect(PluginCommandService(root.path).readSettings(manifest),
        {'target': 'Japanese'},
        reason: '没默认值的字段不该凭空造出一个空字符串');
  });

  test('what the reader saves on the settings page is what the script reads',
      () async {
    final manifest = install(r'''
function on_command(ctx)
  return { notify = storage.get("target") }
end
''', extra: {
      'settings': [
        {'key': 'target', 'title': 'Language', 'default': 'Japanese'},
      ],
    });
    final service = PluginCommandService(root.path);

    // The script runs once first, so the saved value has to reach a plugin
    // that is already loaded — not only the next time the editor starts.
    service.start(manifest, const PluginScriptContext(command: 'x'));
    await service.writeSettings(manifest, {'target': 'Korean'});

    expect(service.readSettings(manifest), {'target': 'Korean'});
    final action = service.start(manifest, const PluginScriptContext(command: 'x'));
    expect((action as PluginNotifyAction).message, 'Korean');
  });

  test('saving settings leaves other plugins alone', () async {
    final manifest = install('', extra: {
      'settings': [
        {'key': 'target', 'title': 'Language'},
      ],
    });
    final service = PluginCommandService(root.path);

    await service.writeSettings(manifest, {'target': 'Korean'});

    final saved = jsonDecode(
      File('${root.path}/com.example.demo/settings.json').readAsStringSync(),
    );
    expect(saved, {'target': 'Korean'});
  });
}

void _permissions() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('plugin_perm_'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  PluginManifest install(String script, List<String> permissions) {
    final dir = Directory('${root.path}/com.example.perm')..createSync(recursive: true);
    File('${dir.path}/plugin.lua').writeAsStringSync(script);
    return PluginManifest.fromJson({
      'id': 'com.example.perm',
      'name': 'Perm',
      'version': '1.0.0',
      'runtime': 'lua',
      'entrypoint': 'plugin.lua',
      'permissions': permissions,
    });
  }

  test('calling the model needs the ai.chat permission', () {
    const script = 'function on_command(ctx) return { ai = "hi" } end';
    final service = PluginCommandService(root.path);

    final granted = service.start(
      install(script, [PluginPermission.aiChat]),
      const PluginScriptContext(command: 'x'),
    );
    expect(granted, isA<PluginAiAction>());

    final denied = service.start(
      install(script, const []),
      const PluginScriptContext(command: 'x'),
    );
    expect(denied, isA<PluginNotifyAction>());
    expect((denied as PluginNotifyAction).message, contains(PluginPermission.aiChat));
  });

  test('editing the document needs document.write', () {
    const script = 'function on_command(ctx) return { replace = "new" } end';
    final service = PluginCommandService(root.path);

    expect(
      service.start(install(script, [PluginPermission.documentWrite]),
          const PluginScriptContext(command: 'x')),
      isA<PluginReplaceAction>(),
    );
    expect(
      service.start(install(script, const []),
          const PluginScriptContext(command: 'x')),
      isA<PluginNotifyAction>(),
    );
  });

  test('showing a result needs no permission at all', () {
    const script =
        'function on_command(ctx) return { diff = { original = "a", result = "b" } } end';
    final service = PluginCommandService(root.path);

    expect(
      service.start(install(script, const []), const PluginScriptContext(command: 'x')),
      isA<PluginDiffAction>(),
    );
  });

  test('a permission the host does not know grants nothing and breaks nothing',
      () {
    final manifest = install(
      'function on_command(ctx) return { ai = "hi" } end',
      const ['ai.chat', 'some.future.capability'],
    );

    expect(manifest.permissions, contains('some.future.capability'));
    expect(manifest.hasPermission(PluginPermission.aiChat), isTrue);
    expect(manifest.hasPermission('some.future.capability'), isFalse,
        reason: '未知权限不该被当成已授予');
  });

  test('every declared permission has a description the reader can read', () {
    for (final permission in PluginPermission.all) {
      expect(PluginPermission.describe(permission), isNotEmpty);
    }
  });
}

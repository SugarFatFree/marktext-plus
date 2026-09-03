import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';

void main() {
  test('manifest rejects missing identity and keeps capabilities immutable', () {
    expect(
      () => PluginManifest.fromJson({'name': 'broken'}),
      throwsFormatException,
    );

    final manifest = PluginManifest.fromJson({
      'id': 'com.example.theme',
      'name': 'Example Theme',
      'version': '1.0.0',
      'entrypoint': 'bin/plugin.exe',
      'capabilities': ['theme', 'command'],
    });

    expect(manifest.id, 'com.example.theme');
    expect(manifest.capabilities, containsAll(['theme', 'command']));
    expect(() => manifest.capabilities.add('network'), throwsUnsupportedError);
  });

  _scriptPlugins();

  test('manifest declares permissions and constrained UI contributions', () {
    final manifest = PluginManifest.fromJson({
      'id': 'com.example.tools',
      'name': 'Tools',
      'version': '1.0.0',
      'entrypoint': 'bin/tools',
      'permissions': ['document.read', 'context-menu'],
      'commands': [
        {'id': 'tools.run', 'title': 'Run tool'},
      ],
      'toolbar': [
        {'id': 'tools.button', 'title': 'Tool', 'icon': 'build'},
      ],
    });

    expect(manifest.permissions, contains('document.read'));
    expect(manifest.commands.single.id, 'tools.run');
    expect(manifest.toolbar.single.icon, 'build');
  });
}

void _scriptPlugins() {
  test('a script plugin declares its runtime, settings and its own strings',
      () {
    final manifest = PluginManifest.fromJson({
      'id': 'com.example.translate',
      'name': 'AI Translate',
      'version': '1.0.0',
      'runtime': 'lua',
      'entrypoint': 'plugin.lua',
      'permissions': ['document.read', 'ai.chat'],
      'defaultLocale': 'en',
      'locales': {
        'en': {'title': 'Translate'},
        'zh': {'title': '翻译'},
      },
      'settings': [
        {
          'key': 'targetLanguage',
          'title': 'Default target language',
          'type': 'text',
          'default': 'English',
        },
      ],
      'menus': [
        {
          'id': 'translate.sel',
          'title': 'Translate selection',
          'location': 'editor.contextMenu',
        },
      ],
    });

    expect(manifest.runtime, PluginRuntime.lua);
    expect(manifest.settings.single.key, 'targetLanguage');
    expect(manifest.settings.single.defaultValue, 'English');
    expect(manifest.menus.single.location, 'editor.contextMenu');
  });

  test('the reader gets their own language, or the plugin default', () {
    final manifest = PluginManifest.fromJson({
      'id': 'com.example.translate',
      'name': 'AI Translate',
      'version': '1.0.0',
      'runtime': 'lua',
      'entrypoint': 'plugin.lua',
      'defaultLocale': 'en',
      'locales': {
        'en': {'title': 'Translate'},
        'zh': {'title': '翻译'},
      },
    });

    expect(manifest.stringsFor('zh'), containsPair('title', '翻译'));
    expect(manifest.stringsFor('zh_CN'), containsPair('title', '翻译'),
        reason: '地区变体应回落到语言');
    expect(manifest.stringsFor('fr'), containsPair('title', 'Translate'),
        reason: '没有该语言时用插件声明的默认语言');
  });

  test('an entrypoint no machine can run is rejected at parse time', () {
    expect(
      () => PluginManifest.fromJson({
        'id': 'com.example.broken',
        'name': 'Broken',
        'version': '1.0.0',
        'runtime': 'lua',
        'entrypoint': 'bin/plugin.dart',
      }),
      throwsFormatException,
      reason: 'Dart 源码需要用户装 Dart SDK，装不了就不该允许声明',
    );
  });

  test('a plugin with no runtime is a data plugin, not a broken one', () {
    final manifest = PluginManifest.fromJson({
      'id': 'com.example.theme',
      'name': 'Theme',
      'version': '1.0.0',
      'entrypoint': 'theme.json',
    });
    expect(manifest.runtime, PluginRuntime.data);
  });
}

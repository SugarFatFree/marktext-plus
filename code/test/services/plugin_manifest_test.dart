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
  _dualRuntime();
  _nativePlugins();

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

void _dualRuntime() {
  test('a plugin picks its own language and the editor takes either', () {
    Map<String, dynamic> base(String runtime) => {
          'id': 'com.example.x',
          'name': 'X',
          'version': '1.0.0',
          'runtime': runtime,
          'entrypoint': runtime == 'js' ? 'plugin.js' : 'plugin.lua',
        };

    expect(PluginManifest.fromJson(base('lua')).runtime, PluginRuntime.lua);
    expect(PluginManifest.fromJson(base('js')).runtime, PluginRuntime.js);
    expect(
      () => PluginManifest.fromJson(base('python')),
      throwsFormatException,
      reason: '声明一个宿主跑不了的运行时，应当在安装时就说清楚',
    );
  });
}

void _nativePlugins() {
  Map<String, dynamic> base(Map<String, dynamic> extra) => {
        'id': 'com.example.native',
        'name': 'Native',
        'version': '1.0.0',
        'runtime': 'process',
        ...extra,
      };

  test('an executable is named per system, and per architecture under it', () {
    final manifest = PluginManifest.fromJson(base({
      'entrypoints': {
        'windows': {'x64': r'bin\win-x64\plugin.exe', 'arm64': r'bin\win-arm64\plugin.exe'},
        'linux': {'x64': 'bin/linux-x64/plugin'},
      },
    }));

    expect(manifest.entrypointFor('windows-x64'), r'bin\win-x64\plugin.exe');
    expect(manifest.entrypointFor('windows-arm64'), r'bin\win-arm64\plugin.exe');
    expect(manifest.entrypointFor('linux-x64'), 'bin/linux-x64/plugin');
    expect(manifest.entrypointFor('linux-arm64'), isNull);
  });

  test('one file may serve every architecture of a system', () {
    // A macOS universal binary is one file holding both architectures — this
    // application ships exactly that. Naming it once should not mean writing
    // the same path under two keys.
    final manifest = PluginManifest.fromJson(base({
      'entrypoints': {'macos': 'bin/macos/plugin'},
    }));

    expect(manifest.entrypointFor('macos-arm64'), 'bin/macos/plugin');
    expect(manifest.entrypointFor('macos-x64'), 'bin/macos/plugin');
    expect(manifest.supportsPlatform('macos-x64'), isTrue);
    expect(manifest.supportsPlatform('linux-x64'), isFalse);
  });

  test('a shared default and one specialised architecture live together', () {
    final manifest = PluginManifest.fromJson(base({
      'entrypoints': {
        'linux': {
          'default': 'bin/linux/plugin',
          'arm64': 'bin/linux-arm64/plugin',
        },
      },
    }));

    expect(manifest.entrypointFor('linux-arm64'), 'bin/linux-arm64/plugin',
        reason: '专门为 arm64 编的那个要优先于共用的');
    expect(manifest.entrypointFor('linux-x64'), 'bin/linux/plugin');
  });

  test('what it supports is reported as concrete platforms', () {
    final manifest = PluginManifest.fromJson(base({
      'entrypoints': {
        'macos': 'bin/macos/plugin',
        'windows': {'arm64': r'bin\plugin.exe'},
      },
    }));

    expect(
      manifest.supportedPlatforms.toSet(),
      {'macos-x64', 'macos-arm64', 'windows-arm64'},
      reason: '告诉用户"它带了 macos"没用，用户要知道自己这台在不在里面',
    );
  });

  test('a script plugin uses its one entrypoint on every platform', () {
    final manifest = PluginManifest.fromJson({
      'id': 'com.example.lua',
      'name': 'Lua',
      'version': '1.0.0',
      'runtime': 'lua',
      'entrypoint': 'plugin.lua',
    });

    expect(manifest.entrypointFor('linux-x64'), 'plugin.lua');
    expect(manifest.entrypointFor('windows-arm64'), 'plugin.lua');
    expect(manifest.supportsPlatform('anything'), isTrue,
        reason: '脚本插件本来就跨平台');
  });

  test('a compiled plugin with no executable at all is rejected', () {
    expect(
      () => PluginManifest.fromJson(base({'entrypoints': <String, dynamic>{}})),
      throwsFormatException,
    );
    expect(
      () => PluginManifest.fromJson(base({})),
      throwsFormatException,
      reason: 'runtime 是 process 却没说任何平台的入口，装了也跑不了',
    );
  });

  test('a system named but left empty is rejected', () {
    expect(
      () => PluginManifest.fromJson(base({
        'entrypoints': {'linux': <String, dynamic>{}},
      })),
      throwsFormatException,
      reason: '声明支持 linux 却没给任何可执行文件，比不声明更糟',
    );
  });

  test('an unknown system or architecture is refused, not ignored', () {
    expect(
      () => PluginManifest.fromJson(base({
        'entrypoints': {'freebsd': 'bin/plugin'},
      })),
      throwsFormatException,
    );
    expect(
      () => PluginManifest.fromJson(base({
        'entrypoints': {
          'linux': {'riscv': 'bin/plugin'},
        },
      })),
      throwsFormatException,
      reason: '拼错的架构名会静悄悄地变成"这个平台不支持"',
    );
  });

  test('a manifest written back out still says the same thing', () {
    final original = PluginManifest.fromJson(base({
      'entrypoints': {
        'macos': 'bin/macos/plugin',
        'linux': {'default': 'bin/linux/plugin', 'arm64': 'bin/linux-arm64/plugin'},
      },
    }));

    final reparsed = PluginManifest.fromJson(original.toJson());

    expect(reparsed.supportedPlatforms.toSet(),
        original.supportedPlatforms.toSet());
    expect(reparsed.entrypointFor('macos-x64'), 'bin/macos/plugin');
    expect(reparsed.entrypointFor('linux-arm64'), 'bin/linux-arm64/plugin');
  });

  test('a per-platform entrypoint may not be Dart source either', () {
    expect(
      () => PluginManifest.fromJson(base({
        'entrypoints': {
          'linux': {'x64': 'bin/plugin.dart'},
        },
      })),
      throwsFormatException,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/ui/widgets/plugin_menu_bar_entries.dart';

/// What a plugin may put in the menu bar.
///
/// Everything a plugin declared was put there: a menu entry contributed to the
/// editor's right-click menu appeared as a top-level Plugins menu as well, and
/// its title was the untranslated key — `AI Translate: menu.selection` — since
/// the plugin's own strings were never consulted. Two entries that meant
/// nothing, in a menu nothing asked for.
PluginManifest plugin(Map<String, dynamic> extra) => PluginManifest.fromJson({
      'id': 'com.example.demo',
      'name': 'Demo',
      'version': '1.0.0',
      'runtime': 'lua',
      'entrypoint': 'plugin.lua',
      ...extra,
    });

void main() {
  test('a right-click contribution stays in the right-click menu', () {
    final entries = pluginMenuBarEntries([
      plugin({
        'permissions': ['ui.contextMenu'],
        'menus': [
          {
            'id': 'translate.selection',
            'title': 'menu.selection',
            'location': 'editor.contextMenu',
          }
        ],
      })
    ], 'en');

    expect(entries, isEmpty,
        reason: '右键菜单的贡献不该同时出现在顶部菜单栏');
  });

  test('a command needs the menu bar permission to reach the menu bar', () {
    final declared = {
      'commands': [
        {'id': 'run', 'title': 'Run it'}
      ],
    };

    expect(pluginMenuBarEntries([plugin(declared)], 'en'), isEmpty,
        reason: '没申请 ui.menuBar 就不该出现在菜单栏');
    expect(
      pluginMenuBarEntries([
        plugin({...declared, 'permissions': ['ui.menuBar']})
      ], 'en'),
      hasLength(1),
    );
  });

  test('the title is the plugin own string in the reader language', () {
    final entries = pluginMenuBarEntries([
      plugin({
        'permissions': ['ui.menuBar'],
        'commands': [
          {'id': 'run', 'title': 'command.run'}
        ],
        'defaultLocale': 'en',
        'locales': {
          'en': {'command.run': 'Run it'},
          'zh': {'command.run': '运行'},
        },
      })
    ], 'zh_CN');

    expect(entries.single.title, '运行');
    expect(entries.single.pluginName, 'Demo');
    expect(entries.single.commandId, 'run');
  });

  test('a title with no translation is shown as written', () {
    final entries = pluginMenuBarEntries([
      plugin({
        'permissions': ['ui.menuBar'],
        'commands': [
          {'id': 'run', 'title': 'Run it'}
        ],
      })
    ], 'en');

    expect(entries.single.title, 'Run it');
  });
}

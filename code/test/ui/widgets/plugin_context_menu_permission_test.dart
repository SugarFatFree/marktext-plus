import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/ui/widgets/plugin_command_actions.dart';

/// What a plugin may put in the right-click menu.
///
/// The menu bar has asked for `ui.menuBar` since it was written. The
/// right-click menu asked for nothing at all: a plugin that never declared
/// `ui.contextMenu` still appeared there, on a permission list the reader had
/// approved without it. Two places implementing one idea, and only one of them
/// was told.
///
/// A permission the editor publishes and never checks is worse than no
/// permission: the reader is shown a list, reads it, and decides on it.
PluginManifest plugin(Map<String, dynamic> extra) => PluginManifest.fromJson({
      'id': 'com.example.demo',
      'name': 'Demo',
      'version': '1.0.0',
      'runtime': 'lua',
      'entrypoint': 'plugin.lua',
      'menus': [
        {
          'id': 'translate.document',
          'title': 'menu.document',
          'location': 'editor.contextMenu',
        }
      ],
      ...extra,
    });

  List<(PluginManifest, PluginMenuItem)> entries(PluginManifest p) =>
      pluginContextMenuContributions([p],
          location: 'editor.contextMenu', hasSelection: false);

void main() {
  test('the right-click menu needs the right-click permission', () {
    expect(entries(plugin(const {})), isEmpty,
        reason: '没申请 ui.contextMenu 就不该出现在右键菜单里');
    expect(
      entries(plugin(const {'permissions': ['ui.contextMenu']})),
      hasLength(1),
    );
  });

  test('a neighbouring permission does not open this door', () {
    // ui.menuBar is the one this was compared against while being fixed, and
    // holding it says nothing about the right-click menu.
    expect(
      entries(plugin(const {'permissions': ['ui.menuBar']})),
      isEmpty,
    );
  });

  test('a menu location nobody has granted is refused, not allowed', () {
    // The editor has one right-click menu today. A second one added later
    // without a permission named for it must contribute nothing rather than
    // contribute freely — the failure this function exists to stop, arriving
    // by a different door.
    final p = PluginManifest.fromJson({
      'id': 'com.example.demo',
      'name': 'Demo',
      'version': '1.0.0',
      'runtime': 'lua',
      'entrypoint': 'plugin.lua',
      'permissions': ['ui.contextMenu', 'ui.menuBar', 'ui.sidebar'],
      'menus': [
        {'id': 'x', 'title': 't', 'location': 'editor.contextMenu'}
      ],
    });

    expect(
      pluginContextMenuContributions([p],
          location: 'sidebar.folderMenu', hasSelection: false),
      isEmpty,
      reason: '没有为这个位置命名权限之前，它一条都不该收',
    );
  });
}

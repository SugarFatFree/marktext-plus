import '../../services/plugin_manifest.dart';

/// One plugin command offered in the editor's menu bar.
class PluginMenuBarEntry {
  const PluginMenuBarEntry({
    required this.plugin,
    required this.pluginName,
    required this.commandId,
    required this.title,
  });

  final PluginManifest plugin;
  final String pluginName;
  final String commandId;

  /// Already in the reader's language, as the plugin translated it.
  final String title;
}

/// What [plugins] may put in the menu bar, for a reader on [locale].
///
/// Only `commands`, and only from a plugin that asked for `ui.menuBar`.
/// Everything a plugin declared used to go here — a menu entry contributed to
/// the editor's right-click menu turned into a top-level Plugins menu too, and
/// its title was the untranslated key, because the plugin's own strings were
/// never consulted. The result was a menu nobody asked for holding two entries
/// that read `Demo: menu.selection`.
List<PluginMenuBarEntry> pluginMenuBarEntries(
  List<PluginManifest> plugins,
  String locale,
) =>
    [
      for (final plugin in plugins)
        if (plugin.hasPermission(PluginPermission.uiMenuBar))
          for (final command in plugin.commands)
            PluginMenuBarEntry(
              plugin: plugin,
              pluginName: plugin.name,
              commandId: command.id,
              title: plugin.stringsFor(locale)[command.title] ?? command.title,
            ),
    ];

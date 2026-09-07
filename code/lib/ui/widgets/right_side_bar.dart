import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/plugin_provider.dart';
import '../../services/plugin_manifest.dart';
import 'plugin_command_actions.dart';
import 'plugin_icons.dart';

/// The rail of plugin panels down the right-hand side, and the drawer one of
/// them opens.
///
/// `ui.sidebar` was a permission a plugin could ask for and nothing acted on.
/// With nothing contributed there is no rail: a strip of icons with no icons
/// in it is width taken from the document for nothing.
class RightSideBar extends ConsumerStatefulWidget {
  const RightSideBar({super.key});

  @override
  ConsumerState<RightSideBar> createState() => _RightSideBarState();
}

class _RightSideBarState extends ConsumerState<RightSideBar> {
  /// `pluginId/panelId` of the open drawer, or null when only the rail shows.
  String? _open;

  /// What the panel's command last returned, so the drawer has something to
  /// draw before — and if — the plugin answers again.
  String _content = '';

  /// The table moved to `plugin_icons.dart` when it turned out to be seven
  /// entries against a plugin asking for an eighth.
  static IconData icon(String name) => PluginIcons.resolve(name);

  Future<void> _toggle(PluginManifest plugin, PluginSidePanel panel) async {
    final key = '${plugin.id}/${panel.id}';
    if (_open == key) {
      setState(() => _open = null);
      return;
    }
    setState(() {
      _open = key;
      _content = '';
    });
    // Filled by running the plugin's command of the same id: a panel is a
    // command with a place to put its answer, so there is no second way for a
    // plugin to draw and no second thing for the editor to render.
    //
    // The whole command, not one step of it. It used to be one step, so a
    // plugin that asks a question first — which the one official plugin does
    // — filled the drawer with the sentence "a panel cannot ask a question"
    // and there was nowhere to type an answer. The question is asked in the
    // card, the same as from a menu; what comes back lands here.
    await PluginCommandActions.runInto(
      ref,
      context: context,
      plugin: plugin,
      command: panel.id,
      into: (text, {bool append = false}) {
        if (!mounted || _open != key) return;
        setState(() => _content = append ? '$_content\n\n$text' : text);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final plugins = ref.watch(installedPluginManifestsProvider).valueOrNull ??
        const <PluginManifest>[];
    final contributions = [
      for (final plugin in plugins)
        if (plugin.hasPermission(PluginPermission.uiSidebar))
          for (final panel in plugin.panels) (plugin, panel),
    ];
    if (contributions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    String label((PluginManifest, PluginSidePanel) c) =>
        c.$1.stringsFor(locale)[c.$2.title] ?? c.$2.title;

    final open = contributions
        .where((c) => '${c.$1.id}/${c.$2.id}' == _open)
        .firstOrNull;

    return Row(
      children: [
        if (open != null) ...[
          VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Text(label(open), style: theme.textTheme.titleSmall),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(_content),
                  ),
                ),
              ],
            ),
          ),
        ],
        VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),
        Container(
          width: 44,
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              const SizedBox(height: 6),
              for (final c in contributions)
                IconButton(
                  tooltip: label(c),
                  isSelected: '${c.$1.id}/${c.$2.id}' == _open,
                  icon: Icon(icon(c.$2.icon), size: 20),
                  onPressed: () => _toggle(c.$1, c.$2),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

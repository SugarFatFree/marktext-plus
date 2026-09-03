import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../services/plugin_catalog_service.dart';
import '../../services/plugin_manager.dart';
import '../../services/plugin_manifest.dart';
import '../screens/plugin_settings_screen.dart';
import '../../providers/plugin_provider.dart';
import '../../utils/file_reveal.dart';

class PluginPanel extends ConsumerStatefulWidget {
  const PluginPanel({super.key});

  @override
  ConsumerState<PluginPanel> createState() => _PluginPanelState();
}

class _PluginPanelState extends ConsumerState<PluginPanel> {
  Future<PluginManager>? _managerFuture;
  Future<List<PluginManifest>>? _installedFuture;
  Future<List<PluginCatalogEntry>>? _catalogFuture;
  Object? _error;
  String? _installingId;

  Future<PluginManager> _manager() => _managerFuture ??=
      getApplicationSupportDirectory().then(
        (dir) => PluginManager(p.join(dir.path, 'plugins')),
      );

  Future<void> _installZip() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      final path = picked?.files.single.path;
      if (path == null) return;
      final manager = await _manager();
      await manager.installZip(File(path));
      if (!mounted) return;
      setState(() {
        _error = null;
        _installedFuture = manager.loadInstalled();
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  /// The plugin's own directory, which is also where its settings file is.
  Future<void> _openFolder(PluginManifest plugin) async {
    final manager = await _manager();
    await FileReveal.openDirectory(manager.directoryOf(plugin));
  }

  Future<void> _showPluginMenu(PluginManifest plugin, Offset position) async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final selected = await showMenu<String>(
      context: context,
      // A zero-sized anchor rect, so the menu is placed at the pointer and
      // sized by its own contents; giving it the distance to the far edges
      // instead squeezes the entry until the label overflows.
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'folder',
          height: 36,
          child: Text(
            AppLocalizations.of(context)!.pluginOpenFolder,
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        ),
      ],
    );
    if (selected == 'folder') await _openFolder(plugin);
  }

  Future<void> _openSettings(PluginManifest plugin) async {
    final manager = await _manager();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PluginSettingsScreen(
          plugin: plugin,
          installDirectory: manager.installDirectory,
        ),
      ),
    );
  }

  void _discover() {
    setState(() {
      _error = null;
      _catalogFuture = PluginCatalogService().searchGitHubTopic();
    });
  }

  Future<void> _installCommunity(PluginCatalogEntry plugin) async {
    if (_installingId != null) return;
    setState(() {
      _error = null;
      _installingId = plugin.id;
    });
    try {
      final manager = await _manager();
      await PluginCatalogService().install(plugin, manager);
      if (!mounted) return;
      setState(() {
        _installingId = null;
        _installedFuture = manager.loadInstalled();
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _installingId = null;
          _error = error;
        });
      }
    }
  }

  void _showDetails(PluginCatalogEntry plugin) {
    ref.read(pluginDetailProvider.notifier).state = plugin;
  }

  Future<void> _openSdk() async {
    final uri = Uri.parse(
      'https://github.com/marktext-plus-plugins/marktext-plus-plugin-sdk',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      setState(() => _error = StateError('Could not open plugin SDK'));
    }
  }

  Future<void> _toggle(PluginManifest plugin, bool enabled) async {
    final manager = await _manager();
    await manager.setEnabled(plugin.id, enabled);
    if (mounted) setState(() {});
  }

  Future<void> _uninstall(PluginManifest plugin) async {
    final manager = await _manager();
    await manager.uninstall(plugin.id);
    if (mounted) setState(() => _installedFuture = manager.loadInstalled());
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(title, style: Theme.of(context).textTheme.labelLarge),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final installed = _installedFuture ??= _manager().then(
      (manager) => manager.loadInstalled(),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 14),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.settingsPlugins,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            IconButton(
              tooltip: l10n.settingsPluginsInstallZip,
              icon: const Icon(Icons.folder_open, size: 18),
              onPressed: _installZip,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: l10n.settingsPluginsDiscover,
              icon: const Icon(Icons.travel_explore, size: 18),
              onPressed: _discover,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: 'Develop a plugin',
              icon: const Icon(Icons.code, size: 18),
              onPressed: _openSdk,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        Text(l10n.settingsPluginsUnverified,
            style: Theme.of(context).textTheme.bodySmall),
        if (_error != null) ...[
          const SizedBox(height: 8),
          SelectableText(
            '$_error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        _sectionTitle(l10n.settingsPluginsInstalled),
        FutureBuilder<List<PluginManifest>>(
          future: installed,
          builder: (context, snapshot) {
            if (snapshot.hasError) return SelectableText('${snapshot.error}');
            if (!snapshot.hasData) return const LinearProgressIndicator();
            if (snapshot.data!.isEmpty) return Text(l10n.settingsPluginsEmpty);
            return Column(
              children: snapshot.data!.map((plugin) {
                return FutureBuilder<bool>(
                  future: _manager().then((manager) => manager.isEnabled(plugin.id)),
                  builder: (context, enabled) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.extension, size: 17),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onSecondaryTapDown: (details) =>
                                        _showPluginMenu(plugin, details.globalPosition),
                                    child: Text(plugin.name,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                                Switch(
                                  value: enabled.data ?? true,
                                  onChanged: enabled.connectionState == ConnectionState.waiting
                                      ? null
                                      : (value) => _toggle(plugin, value),
                                ),
                              ],
                            ),
                            Text('${plugin.id} · ${plugin.version}',
                                style: Theme.of(context).textTheme.bodySmall),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (plugin.settings.isNotEmpty)
                                  TextButton.icon(
                                    onPressed: () => _openSettings(plugin),
                                    icon: const Icon(Icons.settings, size: 16),
                                    label: const Text('Settings'),
                                  ),
                                IconButton(
                                  tooltip: 'Uninstall',
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  onPressed: () => _uninstall(plugin),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        if (_catalogFuture != null) ...[
          _sectionTitle(l10n.settingsPluginsDiscover),
          FutureBuilder<List<PluginCatalogEntry>>(
            future: _catalogFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) return SelectableText('${snapshot.error}');
              if (!snapshot.hasData) return const LinearProgressIndicator();
              if (snapshot.data!.isEmpty) {
                return const Text('No installable releases found for this topic.');
              }
              return Column(
                children: snapshot.data!
                    .map((plugin) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.public, size: 17),
                          title: Text(plugin.name, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${plugin.version} · Community / Unverified'),
                          onTap: () => _showDetails(plugin),
                          trailing: _installingId == plugin.id
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : IconButton(
                                  tooltip: 'Install',
                                  icon: const Icon(Icons.download, size: 18),
                                  onPressed: () => _installCommunity(plugin),
                                  visualDensity: VisualDensity.compact,
                                ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ],
    );
  }
}

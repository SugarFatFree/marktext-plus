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
import '../../providers/plugin_provider.dart';
import '../../utils/file_reveal.dart';

class PluginPanel extends ConsumerStatefulWidget {
  const PluginPanel({super.key});

  @override
  ConsumerState<PluginPanel> createState() => _PluginPanelState();
}

class _PluginPanelState extends ConsumerState<PluginPanel> {
  Future<PluginManager>? _managerFuture;
  Object? _error;
  String? _installingId;

  /// Anything that changed what is installed. The provider is what the rest of
  /// the editor reads — the right-click menu among it — so refreshing a list
  /// held here would have left the menus behind until the next launch, which
  /// is exactly what it did.
  void _installedChanged() {
    ref.invalidate(installedPluginManifestsProvider);
    // And where they came from: a pre-release updated in place changes the
    // archive, not the version, so this is what tells the list it moved.
    ref.invalidate(installedPluginSourcesProvider);
  }

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
      setState(() => _error = null);
      _installedChanged();
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

  void _openSettings(PluginManifest plugin) =>
      openPluginSettingsTab(ref, plugin);

  Future<void> _discover() async {
    final discovery = ref.read(pluginDiscoveryProvider.notifier);
    discovery.started();
    setState(() => _error = null);
    try {
      discovery.succeeded(await PluginCatalogService().searchGitHubTopic());
    } catch (error) {
      discovery.failed('$error');
    }
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
      setState(() => _installingId = null);
      _installedChanged();
    } catch (error) {
      if (mounted) {
        setState(() {
          _installingId = null;
          _error = error;
        });
      }
    }
  }

  void _showDetails(PluginCatalogEntry plugin) =>
      openPluginDetailTab(ref, plugin);

  /// The button beside a search result — or, when the reader already has it,
  /// the fact that they do.
  ///
  /// A download button on something already installed said nothing about what
  /// pressing it would do, and the list that had just installed a plugin
  /// looked exactly as it had before.
  Widget _discoverAction(
    PluginCatalogEntry plugin,
    AsyncValue<List<PluginManifest>> installed,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final state = PluginInstallState.of(
      plugin,
      installed.valueOrNull ?? const <PluginManifest>[],
      // A pre-release is updated in place, so the archive is what says whether
      // there is anything new.
      sources: ref.watch(installedPluginSourcesProvider).valueOrNull ??
          const <String, PluginSource>{},
    );
    return switch (state) {
      PluginInstallState.installed => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            l10n.pluginInstalled,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      // An update is still one press away. Reporting "installed" and stopping
      // there is how a reader stops getting them.
      PluginInstallState.updatable => IconButton(
          tooltip: l10n.pluginUpdateTo(plugin.version),
          icon: const Icon(Icons.upgrade, size: 18),
          onPressed: () => _installCommunity(plugin),
          visualDensity: VisualDensity.compact,
        ),
      PluginInstallState.installable => IconButton(
          tooltip: l10n.pluginInstall,
          icon: const Icon(Icons.download, size: 18),
          onPressed: () => _installCommunity(plugin),
          visualDensity: VisualDensity.compact,
        ),
    };
  }

  /// The version, and whether the reader took a pre-release.
  ///
  /// The source is recorded at install time; a plugin installed before that
  /// was kept, or from a ZIP by hand, simply shows its version. Guessing
  /// "pre-release" from a leading zero would be a guess.
  String _versionLine(PluginManifest plugin) {
    final l10n = AppLocalizations.of(context)!;
    final source = ref.watch(installedPluginSourcesProvider).valueOrNull;
    final prerelease = source?[plugin.id]?.prerelease ?? false;
    return prerelease
        ? '${plugin.version} · ${l10n.pluginPrerelease}'
        : plugin.version;
  }

  /// The same line for something not installed yet.
  String _catalogLine(PluginCatalogEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    return entry.isPrerelease
        ? '${entry.version} · ${l10n.pluginPrerelease}'
        : entry.version;
  }

  /// A plugin's own string in the reader's language.
  ///
  /// A plugin ships its own translations; the name and the description go
  /// through them like every other string it shows. A plugin that wrote a
  /// plain name rather than a key gets that name back unchanged.
  String _localised(PluginManifest plugin, String value) =>
      plugin.stringsFor(_locale)[value] ?? value;

  String get _locale => Localizations.localeOf(context).toString();

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
    if (mounted) _installedChanged();
  }

  /// A heading for a group of entries.
  ///
  /// A rule beside it, and muted: the installed section's heading sat directly
  /// above "No plugins installed yet" in the same weight and colour, so the
  /// two read as a heading and its one child — a plugin apparently named "not
  /// installed yet".
  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Row(
          children: [
            Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).hintColor,
                    letterSpacing: 0.8,
                  ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Divider(color: Theme.of(context).dividerColor)),
          ],
        ),
      );

  /// Something the panel has to say, rather than something it is listing.
  Widget _note(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final installed = ref.watch(installedPluginManifestsProvider);
    final discovery = ref.watch(pluginDiscoveryProvider);
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
        installed.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => SelectableText('$error'),
          data: (plugins) {
            if (plugins.isEmpty) return _note(l10n.settingsPluginsEmpty);
            return Column(
              children: plugins.map((plugin) {
                return FutureBuilder<bool>(
                  future: _manager().then((manager) => manager.isEnabled(plugin.id)),
                  builder: (context, enabled) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    // The whole entry answers the right-click, not only the
                    // name: someone reaching for a list entry is as likely to
                    // land on the version line or the space beside it.
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onSecondaryTapDown: (details) =>
                          _showPluginMenu(plugin, details.globalPosition),
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
                                    child: InkWell(
                                      onTap: () => openPluginDetailTab(
                                        ref,
                                        PluginCatalogEntry.installed(plugin, locale: _locale),
                                      ),
                                      child: Text(
                                        _localised(plugin, plugin.name),
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                              // What it does, before what it is called
                              // internally: the id and version answer "which
                              // build is this", which is not the question
                              // someone scanning the list is asking.
                              if (plugin.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    _localised(plugin, plugin.description),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              // The version, and whether it was a
                              // pre-release. Not the package id: nobody
                              // scanning a list is asking what a plugin is
                              // called internally.
                              Text(
                                _versionLine(plugin),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
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
                  ),
                );
              }).toList(),
            );
          },
        ),
        if (discovery.searching ||
            discovery.results != null ||
            discovery.error != null) ...[
          _sectionTitle(l10n.settingsPluginsDiscover),
          if (discovery.error != null)
            SelectableText(
              discovery.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else if (discovery.searching)
            const LinearProgressIndicator()
          else if (discovery.results!.isEmpty)
            _note('No installable releases found for this topic.')
          else
            Column(
                children: discovery.results!
                    .map((plugin) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.public, size: 17),
                          title: Text(plugin.name, overflow: TextOverflow.ellipsis),
                          subtitle: Text(_catalogLine(plugin)),
                          onTap: () => _showDetails(plugin),
                          trailing: _installingId == plugin.id
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : _discoverAction(plugin, installed),
                        ))
                    .toList(),
            ),
        ],
      ],
    );
  }
}

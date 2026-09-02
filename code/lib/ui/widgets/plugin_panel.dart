import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../services/plugin_catalog_service.dart';
import '../../services/plugin_manager.dart';
import '../../services/plugin_manifest.dart';

class PluginPanel extends StatefulWidget {
  const PluginPanel({super.key});

  @override
  State<PluginPanel> createState() => _PluginPanelState();
}

class _PluginPanelState extends State<PluginPanel> {
  Future<PluginManager>? _managerFuture;
  Future<List<PluginManifest>>? _installedFuture;
  Future<List<PluginCatalogEntry>>? _catalogFuture;
  Object? _error;

  Future<PluginManager> _manager() => _managerFuture ??= getApplicationSupportDirectory()
      .then((dir) => PluginManager(p.join(dir.path, 'plugins')));

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

  void _discover() {
    setState(() {
      _error = null;
      _catalogFuture = PluginCatalogService().searchGitHubTopic();
    });
  }

  Future<void> _openSdk() async {
    final uri = Uri.parse(
      'https://github.com/marktext-plus-plugins/marktext-plus-plugin-sdk',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      setState(() => _error = StateError('Could not open plugin SDK')); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final installed = _installedFuture ??= _manager().then((manager) => manager.loadInstalled());
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      children: [
        Text(l10n.settingsPlugins,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(l10n.settingsPluginsUnverified,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            OutlinedButton.icon(
              onPressed: _installZip,
              icon: const Icon(Icons.folder_open, size: 16),
              label: Text(l10n.settingsPluginsInstallZip),
            ),
            OutlinedButton.icon(
              onPressed: _discover,
              icon: const Icon(Icons.travel_explore, size: 16),
              label: Text(l10n.settingsPluginsDiscover),
            ),
            TextButton.icon(
              onPressed: _openSdk,
              icon: const Icon(Icons.code, size: 16),
              label: const Text('Develop a plugin'),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text('${_error!}', style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 14),
        Text(l10n.settingsPluginsInstalled,
            style: Theme.of(context).textTheme.titleSmall),
        FutureBuilder<List<PluginManifest>>(
          future: installed,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('${snapshot.error}');
            if (!snapshot.hasData) return const LinearProgressIndicator();
            if (snapshot.data!.isEmpty) return Text(l10n.settingsPluginsEmpty);
            return Column(
              children: snapshot.data!
                  .map((plugin) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.extension, size: 18),
                        title: Text(plugin.name),
                        subtitle: Text('${plugin.id} · ${plugin.version}'),
                      ))
                  .toList(),
            );
          },
        ),
        if (_catalogFuture != null) ...[
          const SizedBox(height: 14),
          FutureBuilder<List<PluginCatalogEntry>>(
            future: _catalogFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text('${snapshot.error}');
              if (!snapshot.hasData) return const LinearProgressIndicator();
              if (snapshot.data!.isEmpty) {
                return const Text('No installable releases found for this topic.');
              }
              return Column(
                children: snapshot.data!
                    .map((plugin) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.public, size: 18),
                          title: Text(plugin.name),
                          subtitle: Text('${plugin.version} · Community / Unverified'),
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

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../providers/editor_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/plugin_catalog_service.dart';
import '../../services/plugin_manager.dart';
import '../../services/plugin_manifest.dart';
import '../../services/plugin_process_host.dart';
import '../../services/plugin_secret_store.dart';

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

  Future<void> _translateSelection(PluginManifest plugin) async {
    final editor = ref.read(editorProvider.notifier).controller;
    if (editor == null || editor.selection.isCollapsed) {
      setState(() => _error = StateError('Select Markdown text first'));
      return;
    }
    final targetController = TextEditingController(text: 'English');
    final target = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Translate selection'),
        content: TextField(
          controller: targetController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Target language'),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(targetController.text.trim()),
            child: const Text('Translate'),
          ),
        ],
      ),
    );
    targetController.dispose();
    if (target == null || target.isEmpty || !mounted) return;

    final selection = editor.selection;
    final source = editor.text.substring(selection.start, selection.end);
    final config = ref.read(settingsProvider);
    final apiKey = await PluginSecretBridge(PlatformSecretStore())
        .resolve(config.aiApiKeyRef);
    if (apiKey == null || apiKey.isEmpty) {
      setState(() => _error = StateError('Configure the AI key reference first'));
      return;
    }

    PluginProcessHost? host;
    try {
      final manager = await _manager();
      host = await manager.startPlugin(plugin);
      await host.call('initialize', params: {
        'provider': config.aiProvider.name,
        'endpoint': config.aiEndpoint,
        'model': config.aiModel,
        'apiKey': apiKey,
      });
      final response = await host.call('translate', params: {
        'text': source,
        'targetLanguage': target,
      });
      final translated = response['result'];
      if (translated is! String || translated.isEmpty) {
        throw const FormatException('AI plugin returned no translation');
      }
      editor.value = editor.value.copyWith(
        text: editor.text.substring(0, selection.start) +
            translated +
            editor.text.substring(selection.end),
        selection: TextSelection.collapsed(
          offset: selection.start + translated.length,
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      await host?.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final installed = _installedFuture ??= _manager().then(
      (manager) => manager.loadInstalled(),
    );
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
          Text(
            '$_error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
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
              children: snapshot.data!.map((plugin) {
                return FutureBuilder<bool>(
                  future: _manager().then((manager) => manager.isEnabled(plugin.id)),
                  builder: (context, enabled) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.extension, size: 18),
                    title: Text(plugin.name),
                    subtitle: Text('${plugin.id} · ${plugin.version}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: enabled.data ?? true,
                          onChanged: enabled.connectionState == ConnectionState.waiting
                              ? null
                              : (value) => _toggle(plugin, value),
                        ),
                        if (plugin.id.contains('ai-translate'))
                          IconButton(
                            tooltip: 'Translate selection',
                            icon: const Icon(Icons.translate, size: 18),
                            onPressed: enabled.data == true
                                ? () => _translateSelection(plugin)
                                : null,
                          ),
                        IconButton(
                          tooltip: 'Uninstall',
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => _uninstall(plugin),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
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

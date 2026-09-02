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
import '../../providers/tab_provider.dart';
import '../../services/plugin_catalog_service.dart';
import '../../services/plugin_manager.dart';
import '../../services/plugin_manifest.dart';
import '../screens/plugin_settings_screen.dart';
import '../../providers/plugin_provider.dart';

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

  Future<String> _translateText(PluginManifest plugin, String source, String target) async {
    final config = ref.read(settingsProvider);
    final apiKey = config.aiApiKey.trim();
    if (apiKey.isEmpty) {
      throw StateError('Configure and save the AI API key first');
    }

    final manager = await _manager();
    final host = await manager.startPlugin(plugin);
    try {
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
      return translated;
    } finally {
      await host.stop();
    }
  }

  Future<String?> _askTargetLanguage(String title) async {
    final controller = TextEditingController(text: 'English');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Target language'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Translate'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result?.isEmpty ?? true ? null : result;
  }

  Future<void> _showTranslation(String source, String translated, {required bool fullDocument}) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(fullDocument ? 'Full document translation' : 'Translation result'),
        content: SizedBox(
          width: 900,
          height: 520,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SelectableText(source),
              ),
              const VerticalDivider(width: 24),
              Expanded(
                child: SelectableText(translated),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _translateSelection(PluginManifest plugin) async {
    final source = ref.read(editorProvider).selectedText;
    if (source.trim().isEmpty) {
      setState(() => _error = StateError('Select Markdown text first'));
      return;
    }
    final target = await _askTargetLanguage('Translate selection');
    if (target == null || !mounted) return;
    try {
      final translated = await _translateText(plugin, source, target);
      if (mounted) await _showTranslation(source, translated, fullDocument: false);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _translateFullDocument(PluginManifest plugin) async {
    final document = ref.read(activeTabProvider)?.content;
    if (document == null || document.trim().isEmpty) {
      setState(() => _error = StateError('Open a Markdown document first'));
      return;
    }
    final target = await _askTargetLanguage('Translate full document');
    if (target == null || !mounted) return;
    try {
      final translated = await _translateText(plugin, document, target);
      if (mounted) await _showTranslation(document, translated, fullDocument: true);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
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
                                Expanded(child: Text(plugin.name, overflow: TextOverflow.ellipsis)),
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
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PluginSettingsScreen(plugin: plugin),
                                      ),
                                    ),
                                    icon: const Icon(Icons.settings, size: 16),
                                    label: const Text('Settings'),
                                  ),
                                if (plugin.id.contains('ai-translate'))
                                  PopupMenuButton<String>(
                                    tooltip: 'Translation actions',
                                    icon: const Icon(Icons.translate, size: 18),
                                    enabled: enabled.data == true,
                                    onSelected: (action) {
                                      if (action == 'selection') {
                                        _translateSelection(plugin);
                                      } else {
                                        _translateFullDocument(plugin);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'selection',
                                        child: Text('Translate selection'),
                                      ),
                                      PopupMenuItem(
                                        value: 'document',
                                        child: Text('Translate full document'),
                                      ),
                                    ],
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

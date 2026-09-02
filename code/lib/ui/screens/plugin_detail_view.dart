import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/plugin_provider.dart';
import '../../services/plugin_catalog_service.dart';
import '../../services/plugin_manager.dart';
import '../editor/markdown_renderer.dart';

class PluginDetailView extends ConsumerStatefulWidget {
  const PluginDetailView({required this.plugin, super.key});

  final PluginCatalogEntry plugin;

  @override
  ConsumerState<PluginDetailView> createState() => _PluginDetailViewState();
}

class _PluginDetailViewState extends ConsumerState<PluginDetailView> {
  bool _installing = false;
  Object? _error;

  Future<void> _install() async {
    setState(() {
      _installing = true;
      _error = null;
    });
    try {
      final dir = await getApplicationSupportDirectory();
      await PluginCatalogService().install(
        widget.plugin,
        PluginManager(p.join(dir.path, 'plugins')),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }

  void _close() => ref.read(pluginDetailProvider.notifier).state = null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Close plugin details',
                  icon: const Icon(Icons.close),
                  onPressed: _close,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.plugin.name,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _installing ? null : _install,
                  icon: _installing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: const Text('Install'),
                ),
              ],
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              '$_error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: FutureBuilder<String>(
            future: PluginCatalogService().fetchReadme(widget.plugin.repositoryUrl!),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: SelectableText('${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return MarkdownRenderer(markdown: snapshot.data!);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => launchUrl(
                widget.plugin.repositoryUrl!,
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open repository'),
            ),
          ),
        ),
      ],
    );
  }
}

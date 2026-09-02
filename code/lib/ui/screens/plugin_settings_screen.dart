import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../providers/settings_provider.dart';
import '../../services/plugin_manager.dart';
import '../../services/plugin_manifest.dart';
import '../../services/plugin_process_host.dart';

/// Host-rendered settings for a plugin. The plugin supplies JSON data, never
/// Flutter widgets, so a plugin cannot alter the editor's layout tree.
class PluginSettingsScreen extends ConsumerStatefulWidget {
  const PluginSettingsScreen({required this.plugin, super.key});

  final PluginManifest plugin;

  @override
  ConsumerState<PluginSettingsScreen> createState() =>
      _PluginSettingsScreenState();
}

class _PluginSettingsScreenState extends ConsumerState<PluginSettingsScreen> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  PluginProcessHost? _host;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _host?.stop();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final manager = PluginManager(p.join(dir.path, 'plugins'));
      final host = await manager.startPlugin(widget.plugin);
      _host = host;
      final config = ref.read(settingsProvider);
      final key = config.aiApiKey.trim();
      await host.call('initialize', params: {
        'provider': config.aiProvider.name,
        'endpoint': config.aiEndpoint,
        'model': config.aiModel,
        if (key.isNotEmpty) 'apiKey': key,
      });
      final response = await host.call('getSettings');
      final settings = response['result'];
      _controller.text = const JsonEncoder.withIndent('  ').convert(
        settings is Map ? settings : <String, dynamic>{},
      );
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final value = jsonDecode(_controller.text);
      if (value is! Map) throw const FormatException('Settings must be a JSON object');
      final host = _host;
      if (host == null) throw StateError('Plugin settings process is not running');
      await host.call('setSettings', params: {'settings': value});
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.plugin.name} settings')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    SelectableText(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      style: const TextStyle(fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        labelText: 'Plugin settings (JSON)',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Save settings'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

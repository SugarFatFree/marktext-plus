import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/plugin_command_service.dart';
import '../../services/plugin_manifest.dart';
import '../../providers/plugin_provider.dart';

/// A plugin's own settings, drawn by the editor from what the plugin declared.
///
/// The plugin supplies field names, types and defaults as data; the editor
/// draws the controls and owns the file the values go in. A plugin never hands
/// the editor widgets, so no plugin can change the editor's layout, and a
/// plugin with a broken settings page cannot take the settings screen down.
class PluginSettingsScreen extends ConsumerStatefulWidget {
  const PluginSettingsScreen({
    required this.plugin,
    this.installDirectory,
    super.key,
  });

  final PluginManifest plugin;

  /// Where plugins are installed. The plugin's settings file lives in its own
  /// directory under here, so one plugin cannot read or write another's.
  /// Where plugins are installed. Null when this is a tab rather than a page
  /// pushed with the directory already in hand — it resolves it itself.
  final String? installDirectory;

  @override
  ConsumerState<PluginSettingsScreen> createState() =>
      _PluginSettingsScreenState();
}

class _PluginSettingsScreenState extends ConsumerState<PluginSettingsScreen> {
  String? _directory;
  final _controllers = <String, TextEditingController>{};
  final _values = <String, String>{};
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Reads what is saved, once the directory is known.
  ///
  /// As a tab this page is built before anything has looked up where plugins
  /// live, so the fields arrive a frame later rather than the page refusing to
  /// open until a directory lookup finishes.
  Future<void> _load() async {
    final directory = widget.installDirectory ?? await _resolveDirectory();
    if (!mounted) return;
    final saved = PluginCommandService(directory).readSettings(widget.plugin);
    setState(() {
      _directory = directory;
      _values.addAll(saved);
      for (final field in widget.plugin.settings) {
        if (_isSwitch(field)) continue;
        _controllers[field.key] = TextEditingController(
          text: _values[field.key] ?? '',
        );
      }
    });
  }

  Future<String> _resolveDirectory() =>
      ref.read(pluginInstallDirectoryProvider.future);

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  static bool _isSwitch(PluginSettingField field) => field.type == 'boolean';

  /// Fields that cannot grow: `obscureText` needs one line, and a number is
  /// one. Everything else is prose and may be as long as it likes.
  static bool _isSingleLine(PluginSettingField field) =>
      field.type == 'password' || field.type == 'number';

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final values = <String, String>{
        for (final field in widget.plugin.settings)
          field.key: _isSwitch(field)
              ? (_values[field.key] == 'true').toString()
              : _controllers[field.key]!.text,
      };
      await PluginCommandService(
        _directory!,
      ).writeSettings(widget.plugin, values);
      if (mounted) Navigator.of(context).maybePop();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.plugin.stringsFor(
      Localizations.localeOf(context).toString(),
    );
    // A plugin ships its own translations, so a title that is a key is shown
    // in the reader's language; a title with no translation is shown as it was
    // written, which is what a plugin with one language wants.
    String label(PluginSettingField field) =>
        strings[field.title] ?? field.title;

    // No Scaffold and no app bar: this is a tab, and the tab bar above it
    // already says which plugin it belongs to and closes it.
    if (_directory == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (_error != null)
          SelectableText(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        for (final field in widget.plugin.settings)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _isSwitch(field)
                ? SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(label(field)),
                    value: _values[field.key] == 'true',
                    onChanged: (value) =>
                        setState(() => _values[field.key] = value.toString()),
                  )
                : TextField(
                    controller: _controllers[field.key],
                    obscureText: field.type == 'password',
                    keyboardType: field.type == 'number'
                        ? TextInputType.number
                        : TextInputType.multiline,
                    // Grows with what is in it. A prompt is the reason this
                    // page exists and prompts are several lines long — the
                    // proofreading one is `Text:\n{{text}}`, so a single-line
                    // field showed `Text:` and hid the only part worth
                    // editing. A password stays on one line because
                    // `obscureText` requires it, and so does a number.
                    minLines: _isSingleLine(field) ? null : 3,
                    maxLines: _isSingleLine(field) ? 1 : null,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: label(field),
                      alignLabelWithHint: !_isSingleLine(field),
                    ),
                  ),
          ),
        if (widget.plugin.settings.isEmpty)
          Text('${widget.plugin.name} has no settings.'),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _saving || widget.plugin.settings.isEmpty ? null : _save,
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
    );
  }
}

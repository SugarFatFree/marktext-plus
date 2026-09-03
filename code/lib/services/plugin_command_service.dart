import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'plugin_js_runtime.dart';
import 'plugin_manifest.dart';
import 'plugin_script_runtime.dart';

/// Runs one installed plugin's commands.
///
/// Holds the three things a script needs and cannot reach on its own: the
/// script text, the plugin's own saved settings, and the plugin's own strings
/// in the reader's language. Each plugin gets its own settings file inside its
/// own directory, so one plugin cannot read or overwrite another's.
class PluginCommandService {
  PluginCommandService(this.installDirectory, {this.locale = 'en'});

  final String installDirectory;

  /// The reader's language, used to pick among the plugin's own translations.
  final String locale;

  final _runtimes = <String, PluginRuntimeHost>{};

  String _directoryOf(PluginManifest manifest) =>
      p.join(installDirectory, manifest.id);

  File _settingsFile(PluginManifest manifest) =>
      File(p.join(_directoryOf(manifest), 'settings.json'));

  /// Starts [context]'s command and returns what the plugin wants done first.
  PluginScriptAction start(
    PluginManifest manifest,
    PluginScriptContext context,
  ) =>
      _guard(manifest, _runtimeFor(manifest).runCommand(context));

  /// Hands a model reply back to the plugin.
  PluginScriptAction resumeWithResult(
    PluginManifest manifest,
    PluginScriptContext context,
    String result,
  ) =>
      _guard(manifest, _runtimeFor(manifest).onResult(context, result));

  /// Refuses an action the plugin did not declare a permission for.
  ///
  /// Enforced here rather than where the action is carried out, so every
  /// caller gets the same answer and a new caller cannot forget to ask.
  PluginScriptAction _guard(
    PluginManifest manifest,
    PluginScriptAction action,
  ) {
    final needed = switch (action) {
      PluginAiAction() => PluginPermission.aiChat,
      PluginReplaceAction() => PluginPermission.documentWrite,
      _ => null,
    };
    if (needed == null || manifest.hasPermission(needed)) return action;
    return PluginNotifyAction(
      '${manifest.name} did not ask for the "$needed" permission',
    );
  }

  /// Writes the plugin's settings back, if it changed any.
  Future<void> flush(PluginManifest manifest) async {
    final runtime = _runtimes[manifest.id];
    if (runtime == null || !runtime.storageChanged) return;
    final file = _settingsFile(manifest);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(runtime.storage), flush: true);
  }

  /// Drops the loaded scripts. Called when the reader disables or uninstalls.
  void dispose() {
    for (final runtime in _runtimes.values) {
      runtime.dispose();
    }
    _runtimes.clear();
  }

  PluginRuntimeHost _runtimeFor(PluginManifest manifest) {
    final existing = _runtimes[manifest.id];
    if (existing != null) return existing;

    if (manifest.runtime == PluginRuntime.data ||
        manifest.runtime == PluginRuntime.process) {
      throw PluginScriptException(
        '${manifest.name} has no script to run: its runtime is '
        '${manifest.runtime.name}',
      );
    }

    final script = File(p.join(_directoryOf(manifest), manifest.entrypoint));
    if (!script.existsSync()) {
      throw PluginScriptException(
        '${manifest.name} declares ${manifest.entrypoint}, which is not in the '
        'installed plugin',
      );
    }

    final source = script.readAsStringSync();
    final settings = _loadSettings(manifest);
    final strings = manifest.stringsFor(locale);
    // The plugin chose its language; nothing else in the editor cares which,
    // because both runtimes answer with the same actions.
    final runtime = switch (manifest.runtime) {
      PluginRuntime.js =>
        PluginJsRuntime(source, storage: settings, strings: strings),
      _ => PluginScriptRuntime(source, storage: settings, strings: strings),
    };
    _runtimes[manifest.id] = runtime;
    return runtime;
  }

  /// The plugin's saved settings, over the defaults it declared.
  ///
  /// The defaults go in first so a plugin's first run sees the values its
  /// settings page shows, rather than nothing.
  Map<String, String> _loadSettings(PluginManifest manifest) {
    final values = <String, String>{
      for (final field in manifest.settings)
        if (field.defaultValue.isNotEmpty) field.key: field.defaultValue,
    };
    final file = _settingsFile(manifest);
    if (!file.existsSync()) return values;
    try {
      final json = jsonDecode(file.readAsStringSync());
      if (json is Map) {
        for (final entry in json.entries) {
          if (entry.key is String && entry.value is String) {
            values[entry.key as String] = entry.value as String;
          }
        }
      }
    } catch (_) {
      // A settings file the plugin corrupted is not a reason to make the
      // plugin unusable: it starts again from its declared defaults.
    }
    return values;
  }
}

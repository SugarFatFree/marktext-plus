import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/constants.dart';
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
  PluginCommandService(
    this.installDirectory, {
    this.locale = 'en',
    String? appVersion,
  }) : appVersion = appVersion ?? AppConstants.appVersion;

  final String installDirectory;

  /// The editor's own version. Checked before a plugin runs, not only when it
  /// is installed: a plugin directory outlives the editor that installed it —
  /// copied between machines, or left behind when the editor is replaced with
  /// an older one.
  final String appVersion;

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
      _guard(manifest, _runtimeFor(manifest).runCommand(_seen(manifest, context)));

  /// Hands a model reply back to the plugin.
  PluginScriptAction resumeWithResult(
    PluginManifest manifest,
    PluginScriptContext context,
    String result,
  ) =>
      _guard(
        manifest,
        _runtimeFor(manifest).onResult(_seen(manifest, context), result),
      );

  /// The context as this plugin is allowed to see it.
  ///
  /// `document.read` is the permission the reader is most likely to be
  /// weighing, and it was the one that meant nothing: the document and the
  /// selection were handed to every plugin regardless. Withheld rather than
  /// refused, so a plugin that never asked simply sees an empty document —
  /// which is a state it has to handle anyway.
  PluginScriptContext _seen(
    PluginManifest manifest,
    PluginScriptContext context,
  ) {
    if (manifest.hasPermission(PluginPermission.documentRead)) return context;
    return PluginScriptContext(
      command: context.command,
      selection: '',
      document: '',
      answer: context.answer,
      view: context.view,
    );
  }

  /// Refuses an action the plugin did not declare a permission for.
  ///
  /// Enforced here rather than where the action is carried out, so every
  /// caller gets the same answer and a new caller cannot forget to ask.
  PluginScriptAction _guard(
    PluginManifest manifest,
    PluginScriptAction action,
  ) {
    // Every action that reaches the reader, not just the two that were once
    // thought interesting. A pane takes half the document's room; a
    // notification interrupts; a panel occupies the side bar. None of those
    // is something a plugin should have without saying so, and the list is
    // only worth showing at install time if it is checked afterwards.
    final needed = switch (action) {
      PluginAiAction() => PluginPermission.aiChat,
      PluginReplaceAction() => PluginPermission.documentWrite,
      PluginNotifyAction() => PluginPermission.uiNotifications,
      PluginPaneAction() || PluginPanelAction() => PluginPermission.uiSidebar,
      // `show`, `ask` and `diff` are deliberately absent, and this note is
      // here because they look exactly like an omission — they reach the
      // reader as surely as a notification does, and I started adding them
      // before finding the test that says otherwise, by name: "showing a
      // result needs no permission at all".
      //
      // The case for leaving them: they are how a command answers the reader
      // who just ran it. A plugin that may not answer cannot do anything, so
      // requiring the permission would mean every plugin declares it — and a
      // permission everybody holds tells the reader nothing. `notify` is the
      // one that can speak without being asked a question.
      //
      // The case against is real too: a card sits over the document and
      // stays until it is closed, which is more of the reader's screen than
      // a notification takes. Whoever settles this should settle it out
      // loud, here.
      _ => null,
    };
    if (needed == null || manifest.hasPermission(needed)) return action;
    // Reported to the reader rather than dropped: a plugin that does nothing
    // and says nothing is one they will file a bug about.
    //
    // In both languages this has to be read in: the sentence, for the reader
    // deciding whether they mind, and the identifier, for whoever has to put
    // it in the manifest.
    return PluginNotifyAction(
      '${manifest.name} did not ask for the "$needed" permission '
      '— ${PluginPermission.describe(needed)}',
    );
  }

  /// The plugin's settings as the reader's settings page should show them.
  Map<String, String> readSettings(PluginManifest manifest) =>
      _loadSettings(manifest);

  /// Saves what the reader entered on the plugin's settings page.
  ///
  /// The loaded script is dropped afterwards, so a plugin that is already
  /// running picks the new values up on its next command rather than at the
  /// next launch of the editor.
  Future<void> writeSettings(
    PluginManifest manifest,
    Map<String, String> values,
  ) async {
    final file = _settingsFile(manifest);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(values), flush: true);
    _runtimes.remove(manifest.id)?.dispose();
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

    if (!manifest.isSupportedBy(appVersion)) {
      throw PluginScriptException(
        '${manifest.name} needs MarkText Plus ${manifest.minAppVersion} '
        'or newer; this is $appVersion',
      );
    }

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
    final modules = _moduleLoader(manifest);
    final runtime = switch (manifest.runtime) {
      PluginRuntime.js => PluginJsRuntime(source,
          storage: settings, strings: strings, modules: modules),
      _ => PluginScriptRuntime(source,
          storage: settings, strings: strings, modules: modules),
    };
    _runtimes[manifest.id] = runtime;
    return runtime;
  }

  /// Resolves one of a plugin's module names to source, inside its own
  /// directory and nowhere else.
  ///
  /// A module name is dotted — `lib.text` is `lib/text.lua` — and it is a
  /// name, not a path: anything with a separator, a `..`, or a drive in it is
  /// refused before it reaches the disk, and the resolved file is checked to
  /// be under the plugin's directory afterwards as well. The second check
  /// catches what the first cannot, a symbolic link pointing out of the
  /// plugin.
  PluginModuleLoader _moduleLoader(PluginManifest manifest) {
    final extension = manifest.runtime == PluginRuntime.js ? '.js' : '.lua';
    final directory = Directory(_directoryOf(manifest)).absolute;
    final root = _real(directory.path);

    return (String name) {
      if (name.isEmpty) return null;
      if (name.contains('/') ||
          name.contains(r'\') ||
          name.contains('..') ||
          name.startsWith('.')) {
        return null;
      }
      final file = File(
        p.join(directory.path, '${name.replaceAll('.', p.separator)}$extension'),
      );
      if (!file.existsSync()) return null;
      if (!p.isWithin(root, _real(file.path))) return null;
      return file.readAsStringSync();
    };
  }

  /// The path with symbolic links resolved, or the path itself when it cannot
  /// be resolved — a link that goes nowhere is not a way out of the directory.
  static String _real(String path) {
    try {
      return File(path).resolveSymbolicLinksSync();
    } catch (_) {
      return path;
    }
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

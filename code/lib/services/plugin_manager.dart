import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../core/constants.dart';
import 'plugin_manifest.dart';
import 'plugin_logger.dart';
import 'plugin_process_host.dart';
import 'plugin_process_registry.dart';
import 'plugin_script_runtime.dart';

/// Discovers and installs data/sidecar-process plugins without importing them.
class PluginManager {
  PluginManager(this.installDirectory, {String? appVersion})
      : appVersion = appVersion ?? AppConstants.appVersion;

  final String installDirectory;

  /// The editor's own version, which decides which plugins it will take.
  final String appVersion;

  Future<List<PluginManifest>> loadInstalled() async {
    final directory = Directory(installDirectory);
    if (!await directory.exists()) return const [];
    final manifests = <PluginManifest>[];
    await for (final entry in directory.list()) {
      if (entry is! Directory) continue;
      final manifestFile = File(p.join(entry.path, 'manifest.json'));
      if (!await manifestFile.exists()) continue;
      try {
        manifests.add(
          PluginManifest.fromJson(
            jsonDecode(await manifestFile.readAsString())
                as Map<String, dynamic>,
          ),
        );
      } catch (_) {
        // A broken plugin is ignored and cannot stop the editor from starting.
      }
    }
    return manifests;
  }

  File get _stateFile => File(p.join(installDirectory, 'state.json'));

  Future<Map<String, bool>> _readState() async {
    try {
      if (!await _stateFile.exists()) return {};
      final json = jsonDecode(await _stateFile.readAsString());
      if (json is! Map) return {};
      return {
        for (final entry in json.entries)
          if (entry.key is String && entry.value is bool)
            entry.key as String: entry.value as bool,
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeState(Map<String, bool> state) async {
    await Directory(installDirectory).create(recursive: true);
    await _stateFile.writeAsString(jsonEncode(state), flush: true);
  }

  Future<bool> isEnabled(String id) async => (await _readState())[id] ?? true;

  Future<void> setEnabled(String id, bool enabled) async {
    final state = await _readState();
    state[id] = enabled;
    await _writeState(state);
  }

  File get _sourcesFile => File(p.join(installDirectory, 'sources.json'));

  Future<Map<String, dynamic>> _readSources() async {
    try {
      if (!await _sourcesFile.exists()) return {};
      final json = jsonDecode(await _sourcesFile.readAsString());
      return json is Map ? Map<String, dynamic>.from(json) : {};
    } catch (_) {
      // A file nobody can read is no record, not a reason to stop: the plugin
      // itself is installed and works, and this only decorates a list.
      return {};
    }
  }

  /// Where [id] came from, or null if nothing was recorded.
  ///
  /// Null for every plugin installed before this was kept, and for one
  /// installed from a ZIP by hand — there is no release behind those to have
  /// an answer about.
  Future<PluginSource?> sourceOf(String id) async {
    final entry = (await _readSources())[id];
    return entry is Map ? PluginSource.fromJson(entry) : null;
  }

  /// Every recorded source, by plugin id.
  Future<Map<String, PluginSource>> sources() async => {
        for (final entry in (await _readSources()).entries)
          if (entry.value is Map)
            entry.key: PluginSource.fromJson(entry.value as Map),
      };

  Future<void> recordSource(String id, PluginSource source) async {
    final all = await _readSources();
    all[id] = source.toJson();
    await Directory(installDirectory).create(recursive: true);
    await _sourcesFile.writeAsString(jsonEncode(all), flush: true);
  }

  Future<void> forgetSource(String id) async {
    final all = await _readSources();
    if (all.remove(id) == null) return;
    await _sourcesFile.writeAsString(jsonEncode(all), flush: true);
  }

  /// The key a plugin uses in its manifest to name a build for this machine.
  ///
  /// A compiled plugin ships one executable per platform, so the editor has to
  /// say which one it is running on in the same vocabulary the plugin author
  /// wrote in the manifest.
  static String get currentPlatform {
    final os = Platform.isWindows
        ? 'windows'
        : Platform.isMacOS
            ? 'macos'
            : 'linux';
    final arch = Platform.version.contains('arm64') ? 'arm64' : 'x64';
    return '$os-$arch';
  }

  /// The environment variable a compiled plugin is handed its launch token in.
  ///
  /// A compiled plugin is a real executable in a folder the reader can open,
  /// so sooner or later one is double-clicked or typed at a shell. **No
  /// program can stop a file on the reader's own disk from being executed**,
  /// and this does not try to. What it makes unforgeable is the plugin's
  /// answer to "did the editor start me": a token generated for that one
  /// launch cannot be typed by anyone who was not given it.
  ///
  /// The environment rather than the command line, because argv is readable by
  /// anything that can run `ps` — a fixed argument, or a token sitting in
  /// argv, is a lock with the key taped to it.
  static const launchTokenVariable = 'MARKTEXT_PLUS_PLUGIN_TOKEN';

  /// A token for one launch of one plugin.
  static String newLaunchToken() {
    final random = Random.secure();
    return [
      for (var i = 0; i < 16; i++)
        random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }

  /// The record of plugin processes this editor started.
  PluginProcessRegistry get processRegistry =>
      PluginProcessRegistry(File(p.join(installDirectory, 'running.json')));

  /// Kills plugin processes an earlier run left behind.
  ///
  /// Called once when the editor starts. A plugin that ignored the closing of
  /// its stdin — or never read it — would otherwise keep running after a crash
  /// with nothing left that knows it exists.
  Future<int> reapOrphanedPlugins() => processRegistry.reapOrphans();

  /// Where the plugin's own files live: its manifest, its script, and the
  /// settings file it keeps for itself.
  String directoryOf(PluginManifest manifest) =>
      p.join(installDirectory, manifest.id);

  String entrypointPath(PluginManifest manifest) => p.join(
        installDirectory,
        manifest.id,
        manifest.entrypointFor(currentPlatform) ?? manifest.entrypoint,
      );

  /// Starts a compiled plugin's own executable.
  ///
  /// The editor never spawns an interpreter here. Running a source file would
  /// mean assuming a toolchain the reader has no reason to have installed, and
  /// the one time this code did that it launched the editor's own binary and
  /// waited forever for it to speak JSON-RPC. A compiled plugin ships a real
  /// executable per platform, or it does not run on that platform at all.
  Future<PluginProcessHost> startPlugin(PluginManifest manifest) async {
    if (manifest.runtime != PluginRuntime.process) {
      throw PluginScriptException(
        '${manifest.name} is a ${manifest.runtime.name} plugin and runs inside '
        'the editor, not as a separate program',
      );
    }

    final relative = manifest.entrypointFor(currentPlatform);
    if (relative == null) {
      throw PluginScriptException(
        '${manifest.name} has no build for $currentPlatform; it ships '
        '${manifest.supportedPlatforms.join(', ')}',
      );
    }

    final executable = p.join(installDirectory, manifest.id, relative);
    if (!await File(executable).exists()) {
      throw PluginScriptException(
        '${manifest.name} names $relative for $currentPlatform but that file '
        'is not in the installed plugin',
      );
    }

    final logger = PluginLogger(
      manifest.id,
      p.join(Directory(installDirectory).parent.path, 'logs', 'plugins'),
    );
    final host = PluginProcessHost(
      executable: executable,
      arguments: const [],
      environment: {launchTokenVariable: newLaunchToken()},
      logger: logger,
      registry: processRegistry,
    );
    await host.start();
    return host;
  }

  Future<void> uninstall(String id) async {
    final target = Directory(p.join(installDirectory, id));
    if (await target.exists()) await target.delete(recursive: true);
    final state = await _readState()..remove(id);
    if (state.isEmpty) {
      if (await _stateFile.exists()) await _stateFile.delete();
    } else {
      await _writeState(state);
    }
    await forgetSource(id);
  }

  Future<PluginManifest> installZip(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final manifestEntry = archive.files
        .where((file) => file.isFile && file.name == 'manifest.json')
        .firstOrNull;
    if (manifestEntry == null) {
      throw const FormatException('plugin ZIP has no root manifest.json');
    }

    final manifest = PluginManifest.fromJson(
      jsonDecode(utf8.decode(manifestEntry.content as List<int>))
          as Map<String, dynamic>,
    );
    // Before anything is written: a plugin that says which editor it needs is
    // told here, once, rather than reaching for something absent later and
    // failing in whatever way that happens to fail.
    if (!manifest.isSupportedBy(appVersion)) {
      throw FormatException(
        '${manifest.name} needs MarkText Plus ${manifest.minAppVersion} '
        'or newer; this is $appVersion',
      );
    }

    final temporary = Directory(
      p.join(installDirectory, '.${manifest.id}.installing'),
    );
    final target = Directory(p.join(installDirectory, manifest.id));
    await temporary.create(recursive: true);
    try {
      for (final file in archive.files) {
        if (!file.isFile) continue;
        final relative = p.normalize(file.name);
        if (p.isAbsolute(relative) || relative == '..' || relative.startsWith('..${p.separator}')) {
          throw const FormatException('plugin ZIP contains an unsafe path');
        }
        final output = File(p.join(temporary.path, relative));
        await output.parent.create(recursive: true);
        await output.writeAsBytes(file.content as List<int>, flush: true);
      }
      if (await target.exists()) await target.delete(recursive: true);
      await temporary.rename(target.path);
      return manifest;
    } catch (_) {
      if (await temporary.exists()) await temporary.delete(recursive: true);
      rethrow;
    }
  }
}


/// Where an installed plugin came from.
///
/// The manifest cannot say whether the reader took a pre-release — that is a
/// property of the release, not of the plugin — and the release is not on
/// disk. Inferring it from a leading zero would be a guess: plenty of finished
/// software is 0.x, and a 1.0.0 pre-release is a thing that happens.
class PluginSource {
  const PluginSource({required this.prerelease, required this.tag});

  final bool prerelease;

  /// The release this came from, as its author tagged it.
  final String tag;

  factory PluginSource.fromJson(Map<dynamic, dynamic> json) => PluginSource(
        prerelease: json['prerelease'] == true,
        tag: json['tag'] is String ? json['tag'] as String : '',
      );

  Map<String, dynamic> toJson() => {'prerelease': prerelease, 'tag': tag};
}

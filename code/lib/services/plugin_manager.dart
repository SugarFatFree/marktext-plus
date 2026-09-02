import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import 'plugin_manifest.dart';
import 'plugin_logger.dart';
import 'plugin_process_host.dart';

/// Discovers and installs data/sidecar-process plugins without importing them.
class PluginManager {
  PluginManager(this.installDirectory);

  final String installDirectory;

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

  String entrypointPath(PluginManifest manifest) =>
      p.join(installDirectory, manifest.id, manifest.entrypoint);

  Future<PluginProcessHost> startPlugin(PluginManifest manifest) async {
    final entrypoint = entrypointPath(manifest);
    final logger = PluginLogger(
      manifest.id,
      p.join(Directory(installDirectory).parent.path, 'logs', 'plugins'),
    );
    final isDart = entrypoint.toLowerCase().endsWith('.dart');
    final host = PluginProcessHost(
      executable: isDart ? Platform.resolvedExecutable : entrypoint,
      arguments: isDart ? [entrypoint] : const [],
      logger: logger,
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

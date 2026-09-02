import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../services/plugin_manager.dart';
import '../services/plugin_manifest.dart';
import '../services/plugin_catalog_service.dart';

/// Loads only manifests; plugin processes and network requests remain lazy.
final installedPluginManifestsProvider = FutureProvider<List<PluginManifest>>((ref) async {
  final directory = await getApplicationSupportDirectory();
  return PluginManager(p.join(directory.path, 'plugins')).loadInstalled();
});


/// The community plugin currently open in the main content detail tab.
final pluginDetailProvider = StateProvider<PluginCatalogEntry?>((ref) => null);

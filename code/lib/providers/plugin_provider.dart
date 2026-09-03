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

/// What the plugin panel found the last time it looked for community plugins.
///
/// Held outside the panel because the side bar destroys it when another tab is
/// chosen: results that had just cost a network round trip were thrown away by
/// a visit to Files, with nothing on screen to say why the list had emptied.
class PluginDiscovery {
  const PluginDiscovery({this.results, this.searching = false, this.error});

  /// Null until a search has been run — which is not the same as a search that
  /// came back with nothing, and the panel says something different for each.
  final List<PluginCatalogEntry>? results;
  final bool searching;
  final String? error;
}

class PluginDiscoveryNotifier extends StateNotifier<PluginDiscovery> {
  PluginDiscoveryNotifier() : super(const PluginDiscovery());

  void started() => state = PluginDiscovery(
        results: state.results,
        searching: true,
      );

  void succeeded(List<PluginCatalogEntry> results) =>
      state = PluginDiscovery(results: results);

  void failed(String error) => state = PluginDiscovery(
        results: state.results,
        error: error,
      );
}

final pluginDiscoveryProvider =
    StateNotifierProvider<PluginDiscoveryNotifier, PluginDiscovery>(
  (ref) => PluginDiscoveryNotifier(),
);

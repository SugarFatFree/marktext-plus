import '../core/config/app_config.dart';
import '../services/plugin_manager.dart';
import '../services/plugin_manifest.dart';

/// Executes manifest-declared actions through the isolated plugin process.
class PluginActionService {
  const PluginActionService._();

  static Future<void> execute(
    PluginManifest plugin,
    String action, {
    Map<String, dynamic> params = const {},
    required AppConfig config,
    required PluginManager manager,
  }) async {
    if (!await manager.isEnabled(plugin.id)) return;
    final host = await manager.startPlugin(plugin);
    try {
      final key = config.aiApiKey.trim();
      await host.call('initialize', params: {
        'provider': config.aiProvider.name,
        'endpoint': config.aiEndpoint,
        'model': config.aiModel,
        if (key.isNotEmpty) 'apiKey': key,
      });
      await host.call('execute', params: {'action': action, ...params});
    } finally {
      await host.stop();
    }
  }
}

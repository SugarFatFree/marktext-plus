import '../core/config/app_config.dart';
import 'plugin_manager.dart';
import 'plugin_manifest.dart';

class PluginTranslationService {
  const PluginTranslationService._();

  static Future<String> translate({
    required PluginManifest plugin,
    required String source,
    required String targetLanguage,
    required AppConfig config,
    required PluginManager manager,
  }) async {
    final apiKey = config.aiApiKey.trim();
    if (apiKey.isEmpty) {
      throw StateError('Configure and save the AI API key first');
    }
    final host = await manager.startPlugin(plugin);
    try {
      await host.call('initialize', params: {
        'provider': config.aiProvider.name,
        'endpoint': config.aiEndpoint,
        'model': config.aiModel,
        'apiKey': apiKey,
      });
      final response = await host.call('translate', params: {
        'text': source,
        'targetLanguage': targetLanguage,
      });
      final result = response['result'];
      if (result is! String || result.isEmpty) {
        throw const FormatException('AI plugin returned no translation');
      }
      return result;
    } finally {
      await host.stop();
    }
  }
}

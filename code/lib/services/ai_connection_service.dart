import 'dart:convert';
import 'dart:io';

import '../core/config/app_config.dart';
import 'plugin_secret_store.dart';

class AiConnectionService {
  const AiConnectionService._();

  static Uri requestUri(AiProvider provider, String endpoint) {
    final base = Uri.tryParse(endpoint.trim());
    if (base == null || !(base.isScheme('https') || base.isScheme('http'))) {
      throw const FormatException('AI endpoint must use http or https');
    }
    final path = base.path.replaceFirst(RegExp(r'/+$'), '');
    if (path.endsWith('/v1/messages') || path.endsWith('/v1/chat/completions')) {
      throw const FormatException(
        'Enter the provider endpoint root without /v1/messages or /v1/chat/completions',
      );
    }
    final suffix = provider == AiProvider.anthropic
        ? '/v1/messages'
        : '/v1/chat/completions';
    return base.replace(path: '$path$suffix');
  }

  static Future<void> testConnection(
    AppConfig config,
    PluginSecretBridge secrets,
  ) async {
    if (!config.aiEnabled) {
      throw const FormatException('Enable AI plugins before testing the connection');
    }
    if (config.aiModel.trim().isEmpty || config.aiApiKeyRef.trim().isEmpty) {
      throw const FormatException('Model and API key reference are required');
    }
    final key = await secrets.resolve(config.aiApiKeyRef);
    if (key == null || key.isEmpty) {
      throw const FormatException('The API key reference was not found');
    }
    final client = HttpClient();
    client.findProxy = (uri) => HttpClient.findProxyFromEnvironment(
          uri,
          environment: Platform.environment,
        );
    try {
      final request = await client.postUrl(requestUri(config.aiProvider, config.aiEndpoint));
      request.headers.contentType = ContentType.json;
      if (config.aiProvider == AiProvider.anthropic) {
        request.headers.set('x-api-key', key);
        request.headers.set('anthropic-version', '2023-06-01');
        request.write(jsonEncode({
          'model': config.aiModel,
          'max_tokens': 1,
          'messages': [{'role': 'user', 'content': 'Reply with OK.'}],
        }));
      } else {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $key');
        request.write(jsonEncode({
          'model': config.aiModel,
          'max_tokens': 1,
          'messages': [{'role': 'user', 'content': 'Reply with OK.'}],
        }));
      }
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('AI provider returned HTTP ${response.statusCode}');
      }
    } finally {
      client.close(force: true);
    }
  }
}

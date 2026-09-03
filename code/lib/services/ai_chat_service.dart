import 'dart:convert';
import 'dart:io';

import '../core/config/app_config.dart';
import 'ai_connection_service.dart';

/// One turn with the model the reader configured in Settings.
///
/// This is the capability behind a plugin's `ai` action. The prompt belongs to
/// the plugin — it decides what to ask and how to phrase it — while the
/// endpoint, the model and the API key stay here. A plugin never sees the key.
class AiChatService {
  const AiChatService._();

  /// How much of a reply to allow. A translated document grows — CJK to
  /// English roughly doubles the token count — so this is generous rather than
  /// tight, and the provider stops early on its own.
  static const _maxTokens = 8192;

  /// The request body each provider documents for a single-turn completion.
  static Map<String, dynamic> buildRequestBody({
    required AiProvider provider,
    required String model,
    required String prompt,
  }) {
    return {
      'model': model,
      'max_tokens': _maxTokens,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    };
  }

  /// The translated text, wherever the provider puts it.
  static String parseResponse(AiProvider provider, Map<String, dynamic> json) {
    if (provider == AiProvider.anthropic) {
      final content = json['content'];
      if (content is List) {
        for (final block in content) {
          if (block is Map && block['text'] is String) {
            final text = (block['text'] as String).trim();
            if (text.isNotEmpty) return text;
          }
        }
      }
    } else {
      final choices = json['choices'];
      if (choices is List) {
        for (final choice in choices) {
          final message = choice is Map ? choice['message'] : null;
          final content = message is Map ? message['content'] : null;
          if (content is String && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      }
    }
    throw const FormatException('The AI provider returned no translated text');
  }

  /// Sends [prompt] to the configured provider and returns what it replied.
  static Future<String> complete({
    required AppConfig config,
    required String prompt,
  }) async {
    if (!config.aiEnabled) {
      throw const FormatException('Enable AI in Settings first');
    }
    if (config.aiEndpoint.trim().isEmpty ||
        config.aiModel.trim().isEmpty ||
        config.aiApiKey.trim().isEmpty) {
      throw const FormatException(
        'Set the AI endpoint, model and API key in Settings first',
      );
    }
    if (prompt.trim().isEmpty) {
      throw const FormatException('The plugin sent an empty prompt');
    }

    final client = HttpClient();
    // The corporate proxy the rest of the app already honours.
    client.findProxy = (uri) => HttpClient.findProxyFromEnvironment(
          uri,
          environment: Platform.environment,
        );
    try {
      final request = await client.postUrl(
        AiConnectionService.requestUri(config.aiProvider, config.aiEndpoint),
      );
      request.headers.contentType = ContentType.json;
      final key = config.aiApiKey.trim();
      if (config.aiProvider == AiProvider.anthropic) {
        request.headers.set('x-api-key', key);
        request.headers.set('anthropic-version', '2023-06-01');
      } else {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $key');
      }
      request.write(jsonEncode(buildRequestBody(
        provider: config.aiProvider,
        model: config.aiModel.trim(),
        prompt: prompt,
      )));

      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        // The provider's own message says far more than the status code:
        // a wrong model name and an expired key are both 400 otherwise.
        throw HttpException(
          'AI provider returned HTTP ${response.statusCode}: '
          '${body.length > 400 ? '${body.substring(0, 400)}…' : body}',
        );
      }
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('The AI provider returned an unexpected reply');
      }
      return parseResponse(config.aiProvider, json);
    } finally {
      client.close(force: true);
    }
  }
}

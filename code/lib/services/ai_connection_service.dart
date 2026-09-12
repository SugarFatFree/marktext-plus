import 'dart:convert';
import 'dart:io';

import '../core/config/app_config.dart';
import '../core/net/answered_within.dart';

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
    // The base URL every provider documents already ends in `/v1` — OpenAI's
    // `https://api.openai.com/v1`, Anthropic's `https://api.anthropic.com/v1`,
    // and so does every service that speaks the same protocol: Ollama's
    // `http://localhost:11434/v1`, OpenRouter's `https://openrouter.ai/api/v1`.
    // So that is what a reader pastes, and appending the version anyway made
    // `/v1/v1/chat/completions` and a 404 whose body says nothing about the
    // doubled path.
    //
    // Left out of the suffix rather than stripped from the endpoint. The two
    // spell out the same URL for every shape there is — a mutation swapping
    // them passes every case here — so the reason is only that this one does
    // not rewrite what the reader typed: the path that goes on the wire is the
    // one they can see in the field, plus a resource.
    const version = '/v1';
    final resource =
        path.endsWith(version) ? suffix.substring(version.length) : suffix;
    return base.replace(path: '$path$resource');
  }

  /// [within] bounds the wait for a reply. A provider that accepts the
  /// connection and then says nothing would otherwise leave the button in
  /// Settings spinning with nothing to report.
  static Future<void> testConnection(
    AppConfig config, {
    Duration within = const Duration(seconds: 30),
  }) async {
    if (!config.aiEnabled) {
      throw const FormatException('Enable AI plugins before testing the connection');
    }
    if (config.aiModel.trim().isEmpty || config.aiApiKey.trim().isEmpty) {
      throw const FormatException('Model and API key are required');
    }
    final key = config.aiApiKey.trim();
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
      final response = await request
          .close()
          .answeredWithin(within, 'the AI provider');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('AI provider returned HTTP ${response.statusCode}');
      }
    } finally {
      client.close(force: true);
    }
  }
}

import 'dart:convert';
import 'dart:io';

import '../core/config/app_config.dart';
import 'ai_connection_service.dart';
import 'package:flutter/foundation.dart';

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
    bool stream = false,
  }) {
    return {
      'model': model,
      'max_tokens': _maxTokens,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      if (stream) 'stream': true,
    };
  }

  /// The piece of text in one line of a streamed response, or null.
  ///
  /// A model sends its answer a few characters at a time, as `data:` lines.
  /// Everything else on the wire — the `[DONE]` marker, the events that carry
  /// no text, blank lines between records — is not an error and not an answer,
  /// so it comes back null and the caller keeps reading.
  ///
  /// Kept apart from the socket because this is the part that is easy to get
  /// wrong and the only part worth testing: the two providers put the text in
  /// different places, and neither puts it where the finished-answer parser
  /// above looks.
  static String? deltaFrom(AiProvider provider, String line) {
    if (!line.startsWith('data:')) return null;
    final payload = line.substring(5).trim();
    if (payload.isEmpty || payload == '[DONE]') return null;

    final Object? json;
    try {
      json = jsonDecode(payload);
    } on FormatException {
      // A record split across reads, or something this provider sends that is
      // not JSON. Dropping it loses a few characters; throwing would lose the
      // answer.
      return null;
    }
    if (json is! Map) return null;

    if (provider == AiProvider.anthropic) {
      // `content_block_delta` carries `delta.text`; the rest carry none.
      final delta = json['delta'];
      final text = delta is Map ? delta['text'] : null;
      return text is String && text.isNotEmpty ? text : null;
    }

    final choices = json['choices'];
    if (choices is! List) return null;
    for (final choice in choices) {
      final delta = choice is Map ? choice['delta'] : null;
      final text = delta is Map ? delta['content'] : null;
      if (text is String && text.isNotEmpty) return text;
    }
    return null;
  }

  /// Whether [line] is the provider announcing that it has finished.
  ///
  /// Reading until the socket closes is not enough. A provider that holds the
  /// connection open after its last event leaves the editor loading forever —
  /// no error to show, nothing in the log, and no way for the reader to stop
  /// it. That shipped once and was measured at fifteen minutes before anyone
  /// gave up. The end of an answer is announced on the wire; this reads the
  /// announcement instead of waiting for the wire to go away.
  static bool isDone(AiProvider provider, String line) {
    final text = line.trim();
    if (text == 'data: [DONE]' || text == 'data:[DONE]') return true;
    if (provider != AiProvider.anthropic) return false;
    if (text == 'event: message_stop' || text == 'event:message_stop') {
      return true;
    }
    if (!text.startsWith('data:')) return false;
    final Object? json;
    try {
      json = jsonDecode(text.substring(5).trim());
    } on FormatException {
      return false;
    }
    return json is Map && json['type'] == 'message_stop';
  }

  /// Collects a streamed answer, handing each larger piece to [onChunk].
  ///
  /// Kept apart from the socket so that both ways this can fail to end are
  /// testable without a network: the provider says it is done, or the provider
  /// goes quiet. [idle] is the wait between two lines, not the wait for the
  /// whole answer — a long document can take a while to think about, but a
  /// stream that has started does not then pause for minutes.
  ///
  /// Going quiet mid-answer gives back what did arrive: the reader watched it
  /// being written and can see where it stops. Going quiet having said nothing
  /// is an error, and it carries the line count, because "no text" and "no
  /// bytes at all" are different faults and the wire is not there to ask.
  @visibleForTesting
  static Future<String> readStream(
    AiProvider provider,
    Stream<String> lines,
    void Function(String soFar) onChunk, {
    Duration idle = const Duration(seconds: 120),
  }) async {
    final answer = StringBuffer();
    var read = 0;
    final bounded = lines.timeout(idle, onTimeout: (sink) => sink.close());
    await for (final line in bounded) {
      read++;
      if (isDone(provider, line)) break;
      final piece = deltaFrom(provider, line);
      if (piece == null) continue;
      answer.write(piece);
      onChunk(answer.toString());
    }
    final text = answer.toString().trim();
    if (text.isEmpty) {
      throw FormatException(
        'The AI provider streamed $read lines and no text',
      );
    }
    return text;
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
  /// Answers instead of the model, when something has been put here.
  ///
  /// The `ai` continuation — a plugin returning a prompt, the host asking the
  /// model, the answer coming back as a second pane — is where several reported
  /// bugs lived, and none of it could be tested: this reached the network
  /// through a static, so a test had nothing to stand in for the model and the
  /// whole path went unexercised. Tests set this and clear it again.
  ///
  /// It is handed the same `emit` the model's own pieces go through, so a test
  /// can answer a bit at a time and check that the pieces are drawn — which is
  /// the half of streaming that a reader actually sees.
  @visibleForTesting
  static Future<String> Function(String prompt, void Function(String soFar) emit)?
      answerFor;

  static Future<String> complete({
    required AppConfig config,
    required String prompt,
    void Function(String soFar)? onChunk,
  }) async {
    final stub = answerFor;
    if (stub != null) {
      return stub(prompt, (soFar) => onChunk?.call(soFar));
    }

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
      // Streamed only when somebody is watching. A caller with nowhere to put
      // the pieces gains nothing from them and would pay for the parsing.
      final streaming = onChunk != null;
      if (streaming) request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      request.write(jsonEncode(buildRequestBody(
        provider: config.aiProvider,
        model: config.aiModel.trim(),
        prompt: prompt,
        stream: streaming,
      )));

      final response = await request.close();
      if (streaming && response.statusCode >= 200 && response.statusCode < 300) {
        // Awaited, not returned: the `finally` below closes the socket, and it
        // runs at the return statement — not when the returned future finishes.
        return await readStream(
          config.aiProvider,
          utf8.decoder.bind(response).transform(const LineSplitter()),
          onChunk,
        );
      }
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

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/services/ai_connection_service.dart';

/// The base URL every provider's documentation gives ends in `/v1`.
///
/// OpenAI writes `https://api.openai.com/v1`, Anthropic writes
/// `https://api.anthropic.com/v1`, and so does every service that speaks the
/// same protocol — Ollama's `http://localhost:11434/v1`, OpenRouter's
/// `https://openrouter.ai/api/v1`, DeepSeek's `https://api.deepseek.com/v1`. So
/// that is what a reader pastes into the endpoint field.
///
/// The version segment was appended regardless, producing
/// `https://api.openai.com/v1/v1/chat/completions` and a 404 from the provider
/// with nothing in it about the doubled path. The field already knew to strip a
/// trailing slash and to refuse a full request path with a message saying what
/// to enter instead; this was the shape in between, and it is the likeliest one.
void main() {
  String uri(AiProvider provider, String endpoint) =>
      AiConnectionService.requestUri(provider, endpoint).toString();

  group('a base URL that already carries the version', () {
    test('OpenAI', () {
      expect(uri(AiProvider.openai, 'https://api.openai.com/v1'),
          'https://api.openai.com/v1/chat/completions');
    });

    test('Anthropic', () {
      expect(uri(AiProvider.anthropic, 'https://api.anthropic.com/v1'),
          'https://api.anthropic.com/v1/messages');
    });

    test('with a trailing slash as well', () {
      expect(uri(AiProvider.openai, 'https://api.openai.com/v1/'),
          'https://api.openai.com/v1/chat/completions');
    });

    test('a local model server', () {
      expect(uri(AiProvider.openai, 'http://localhost:11434/v1'),
          'http://localhost:11434/v1/chat/completions');
    });

    test('a version segment that is not at the root', () {
      expect(uri(AiProvider.openai, 'https://openrouter.ai/api/v1'),
          'https://openrouter.ai/api/v1/chat/completions');
    });
  });

  group('what already worked still works', () {
    test('a bare host', () {
      expect(uri(AiProvider.openai, 'https://api.openai.com'),
          'https://api.openai.com/v1/chat/completions');
      expect(uri(AiProvider.anthropic, 'https://api.anthropic.com'),
          'https://api.anthropic.com/v1/messages');
    });

    test('a bare host with a trailing slash', () {
      expect(uri(AiProvider.anthropic, 'https://api.anthropic.com/'),
          'https://api.anthropic.com/v1/messages');
    });

    test('a path that is not a version segment is kept', () {
      expect(uri(AiProvider.openai, 'https://gateway.example.com/openai'),
          'https://gateway.example.com/openai/v1/chat/completions');
    });

    test('the full request path is still refused, with advice', () {
      expect(
        () => uri(AiProvider.anthropic, 'https://api.anthropic.com/v1/messages'),
        throwsFormatException,
      );
      expect(
        () => uri(AiProvider.openai, 'https://api.openai.com/v1/chat/completions'),
        throwsFormatException,
      );
    });

    test('something that is not a URL is still refused', () {
      expect(() => uri(AiProvider.openai, 'api.openai.com'),
          throwsFormatException);
      expect(() => uri(AiProvider.openai, 'ftp://api.openai.com'),
          throwsFormatException);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';

void main() {
  test('AI settings round-trip with one visible API key field', () {
    final config = AppConfig(
      aiEnabled: true,
      aiProvider: AiProvider.anthropic,
      aiEndpoint: 'https://api.anthropic.com',
      aiModel: 'claude-opus-5',
      aiApiKey: 'test-secret',
    );

    final json = config.toJson();
    final restored = AppConfig.fromJson(json);

    expect(restored.aiEnabled, isTrue);
    expect(restored.aiProvider, AiProvider.anthropic);
    expect(restored.aiEndpoint, 'https://api.anthropic.com');
    expect(restored.aiModel, 'claude-opus-5');
    expect(restored.aiApiKey, 'test-secret');
    expect(json['aiApiKey'], 'test-secret');
    expect(json.containsKey('aiApiKeyRef'), isFalse);
  });

  test('unknown provider values fall back to OpenAI-compatible settings', () {
    final config = AppConfig.fromJson({'aiProvider': 'future-provider'});
    expect(config.aiProvider, AiProvider.openai);
    expect(config.aiEnabled, isFalse);
  });
}

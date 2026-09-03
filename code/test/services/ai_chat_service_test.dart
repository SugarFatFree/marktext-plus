import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/services/ai_chat_service.dart';

void main() {
  test('each provider gets the body shape it documents', () {
    final openai = AiChatService.buildRequestBody(
      provider: AiProvider.openai,
      model: 'gpt-4o-mini',
      prompt: 'ask something',
    );
    expect(openai['model'], 'gpt-4o-mini');
    expect((openai['messages'] as List).last['content'], 'ask something');
    expect(openai.containsKey('max_tokens'), isTrue);

    final anthropic = AiChatService.buildRequestBody(
      provider: AiProvider.anthropic,
      model: 'claude-opus-5',
      prompt: 'ask something',
    );
    expect(anthropic['model'], 'claude-opus-5');
    expect((anthropic['messages'] as List).single['content'], 'ask something');
    expect(anthropic['max_tokens'], isA<int>());
  });

  test('the reply is read out of either response shape', () {
    expect(
      AiChatService.parseResponse(AiProvider.openai, {
        'choices': [
          {'message': {'content': 'Hello'}},
        ],
      }),
      'Hello',
    );
    expect(
      AiChatService.parseResponse(AiProvider.anthropic, {
        'content': [
          {'type': 'text', 'text': 'Hello'},
        ],
      }),
      'Hello',
    );
  });

  test('a response with no text is an error, not an empty reply', () {
    expect(
      () => AiChatService.parseResponse(AiProvider.openai, {'choices': []}),
      throwsFormatException,
    );
  });

  test('a plugin cannot call the model before the reader configures one',
      () async {
    await expectLater(
      AiChatService.complete(
        config: AppConfig(aiEnabled: false),
        prompt: 'hello',
      ),
      throwsA(isA<Exception>()),
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/services/ai_connection_service.dart';

void main() {
  test('builds provider paths from an endpoint root', () {
    expect(
      AiConnectionService.requestUri(
        AiProvider.openai,
        'https://api.openai.com',
      ).toString(),
      'https://api.openai.com/v1/chat/completions',
    );
    expect(
      AiConnectionService.requestUri(
        AiProvider.anthropic,
        'https://api.anthropic.com/',
      ).toString(),
      'https://api.anthropic.com/v1/messages',
    );
  });

  test('rejects an endpoint that already contains an API suffix', () {
    expect(
      () => AiConnectionService.requestUri(
        AiProvider.anthropic,
        'https://api.anthropic.com/v1/messages',
      ),
      throwsFormatException,
    );
  });
}

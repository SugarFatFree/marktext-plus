import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/services/ai_chat_service.dart';

/// Ending the wait for a streamed answer.
///
/// The first version of streaming read until the socket closed, and nothing
/// else. On a provider that keeps the connection open after its last event
/// that is not slow — it never returns: the editor span forever, no error was
/// shown and nothing reached the log. Measured live at fifteen minutes.
///
/// So the two ways a stream ends both have to be read here, and neither of
/// them is the socket: the provider says it is done, or the provider goes
/// quiet. A stream nobody closes must not outlive either.
void main() {
  test('the end marker ends it, even though the stream stays open', () async {
    final lines = StreamController<String>();
    addTearDown(lines.close);
    final seen = <String>[];
    final answer = AiChatService.readStream(
      AiProvider.openai,
      lines.stream,
      seen.add,
    );

    lines.add('data: {"choices":[{"delta":{"content":"Hel"}}]}');
    lines.add('data: {"choices":[{"delta":{"content":"lo"}}]}');
    lines.add('data: [DONE]');
    // Deliberately never closed: the socket is not what says the answer ended.

    expect(await answer.timeout(const Duration(seconds: 3)), 'Hello');
    expect(seen, ['Hel', 'Hello'], reason: 'each larger piece is drawn');
  });

  test('an Anthropic stream ends on message_stop', () async {
    final lines = StreamController<String>();
    addTearDown(lines.close);
    final answer = AiChatService.readStream(
      AiProvider.anthropic,
      lines.stream,
      (_) {},
    );

    lines.add('data: {"type":"content_block_delta","delta":{"text":"Hi"}}');
    lines.add('data: {"type":"message_stop"}');

    expect(await answer.timeout(const Duration(seconds: 3)), 'Hi');
  });

  test('a provider that goes quiet gives back what it did say', () async {
    final lines = StreamController<String>();
    addTearDown(lines.close);
    final answer = AiChatService.readStream(
      AiProvider.openai,
      lines.stream,
      (_) {},
      idle: const Duration(milliseconds: 150),
    );

    lines.add('data: {"choices":[{"delta":{"content":"half an ans"}}]}');
    // Then silence, and the socket still open.

    expect(await answer.timeout(const Duration(seconds: 3)), 'half an ans');
  });

  test('a provider that says nothing at all is an error, not a wait', () async {
    final lines = StreamController<String>();
    addTearDown(lines.close);
    final answer = AiChatService.readStream(
      AiProvider.openai,
      lines.stream,
      (_) {},
      idle: const Duration(milliseconds: 150),
    );

    lines.add(': keep-alive comment');

    await expectLater(
      answer.timeout(const Duration(seconds: 3)),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('1'),
        ),
      ),
      reason: 'the count of lines read says whether the wire was silent',
    );
  });
}

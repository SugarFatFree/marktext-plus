import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/services/ai_chat_service.dart';

/// Reading one line of a streamed answer.
///
/// The two providers put the text in different places, and neither puts it
/// where the finished-answer parser looks — so this is the part worth testing,
/// and the socket around it is not. Everything that is not text has to come
/// back as nothing rather than as an error: a stream that threw on its own
/// `[DONE]` marker would lose the answer at the very end of it.
void main() {
  String? open(String line) => AiChatService.deltaFrom(AiProvider.openai, line);
  String? anthropic(String line) =>
      AiChatService.deltaFrom(AiProvider.anthropic, line);

  group('an OpenAI-shaped stream', () {
    test('a delta is the text it carries', () {
      expect(
        open('data: {"choices":[{"delta":{"content":"Hel"}}]}'),
        'Hel',
      );
    });

    test('the first record carries a role and no text', () {
      expect(open('data: {"choices":[{"delta":{"role":"assistant"}}]}'), isNull);
    });

    test('the last record carries a reason and no text', () {
      expect(
        open('data: {"choices":[{"delta":{},"finish_reason":"stop"}]}'),
        isNull,
      );
    });
  });

  group('an Anthropic-shaped stream', () {
    test('a content block delta is the text it carries', () {
      expect(
        anthropic('data: {"type":"content_block_delta",'
            '"delta":{"type":"text_delta","text":"Hel"}}'),
        'Hel',
      );
    });

    test('the events around it carry none', () {
      expect(anthropic('data: {"type":"message_start"}'), isNull);
      expect(anthropic('data: {"type":"content_block_stop"}'), isNull);
    });
  });

  group('what is not an answer', () {
    test('the end of the stream is not text and not a failure', () {
      expect(open('data: [DONE]'), isNull);
    });

    test('the blank lines between records', () {
      expect(open(''), isNull);
      expect(open('data:'), isNull);
    });

    test('a comment, which some servers send to hold the connection open', () {
      expect(open(': keep-alive'), isNull);
    });

    test('half a record, which a read can end in the middle of', () {
      // Dropping it costs a few characters; throwing would cost the answer.
      expect(open('data: {"choices":[{"delta":{"cont'), isNull);
    });

    test('a shape neither provider sends', () {
      expect(open('data: {"unexpected":true}'), isNull);
      expect(anthropic('data: []'), isNull);
    });
  });
}

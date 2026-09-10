import 'dart:async';
import 'dart:io';

/// A bound on waiting for a reply.
///
/// A server that refuses the connection, or answers with an error, ends the
/// wait by itself. The case that does not is the one with no reply at all:
/// the connection is accepted and then nothing comes back. There is no
/// natural end to that — the socket stays open, so a size limit never trips
/// and a status code never arrives, and the reader is left looking at a
/// spinner with no way to stop it and nothing in the log.
///
/// This shipped once, on the AI stream (BUG-404), and was measured at fifteen
/// minutes before anyone gave up. Every request this editor makes goes through
/// here so that the next one cannot repeat it; `network_calls_can_end_test`
/// checks that none has been added that does not.
extension AnsweredWithin<T> on Future<T> {
  /// Fails with a sentence naming [what] if no reply arrives inside [within].
  ///
  /// [what] is the thing being waited on as the reader would name it — "the AI
  /// provider", "the plugin registry" — because the message it lands in is
  /// shown to them, and "timeout" alone does not say what timed out.
  Future<T> answeredWithin(Duration within, String what) => timeout(
        within,
        onTimeout: () => throw HttpException(
          '$what did not answer within ${within.inSeconds}s',
        ),
      );
}

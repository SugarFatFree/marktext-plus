import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/services/ai_connection_service.dart';
import 'package:marktext_plus/services/plugin_image_loader.dart';
import 'package:marktext_plus/services/plugin_logger.dart';

/// Every request this editor makes has to be able to end.
///
/// A server that refuses the connection, or answers with an error, was always
/// handled. The case none of these three handled is the one that has no reply
/// at all: the connection is accepted and then nothing comes back. Waiting for
/// that has no natural end — the socket stays open, so a size limit never
/// trips and a status code never arrives.
///
/// BUG-404 was this shape on the AI stream and it span for fifteen minutes.
/// These three are its siblings: `update_service` bounds its request, and the
/// three written after it did not.
void main() {
  /// Accepts the connection and never answers. Held open until teardown, so
  /// the request cannot end by the socket dropping either.
  Future<Uri> silentServer(String path) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) {/* deliberately no response */});
    return Uri.parse('http://127.0.0.1:${server.port}$path');
  }

  test('testing the AI connection gives up instead of spinning', () async {
    final uri = await silentServer('');
    final config = AppConfig(
      aiEnabled: true,
      aiEndpoint: uri.toString(),
      aiModel: 'a-model',
      aiApiKey: 'a-key',
    );

    await expectLater(
      AiConnectionService.testConnection(
        config,
        within: const Duration(milliseconds: 300),
      ),
      throwsA(
        predicate((e) => '$e'.contains('did not answer')),
      ),
    ).timeout(const Duration(seconds: 5));
  });

  // The registry is the third of these and is not reached from here: it
  // refuses anything that is not HTTPS, and relaxing that for a loopback
  // server would weaken the check that a marketplace download cannot be
  // tampered with in transit — a worse trade than leaving one call site to a
  // guard. It waits through the same `answeredWithin`, and
  // `network_calls_can_end_test` is what holds it there.

  test('a picture that never arrives is not waited for forever', () async {
    final uri = await silentServer('/pic.png');
    final root = Directory.systemTemp.createTempSync('never_answers_');
    addTearDown(() => root.deleteSync(recursive: true));
    final loader = PluginImageLoader(
      pluginDirectory: root.path,
      logger: PluginLogger('com.example.demo', '${root.path}/logs'),
      allowNetwork: true,
      within: const Duration(milliseconds: 300),
    );

    await expectLater(
      loader.load(uri.toString()),
      throwsA(predicate((e) => '$e'.contains('did not answer'))),
    ).timeout(const Duration(seconds: 5));
  });
}

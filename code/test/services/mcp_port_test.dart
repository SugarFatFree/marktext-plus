import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/mcp_server.dart';

/// Finding a port to listen on.
void main() {
  test('the port asked for, when it is free', () async {
    final server = McpServer();
    addTearDown(server.stop);
    await server.start(port: 0, token: 'tok');
    expect(server.port, isNot(0), reason: '0 表示随便挑一个，挑完要说挑了哪个');
    expect(server.running, isTrue);
  });

  test('the next one up, when it is taken', () async {
    // Somebody else already has it.
    final squatter = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    addTearDown(squatter.close);
    final taken = squatter.port;

    final server = McpServer();
    addTearDown(server.stop);
    await server.start(port: taken, token: 'tok');

    expect(server.port, greaterThan(taken));
    expect(server.port, lessThanOrEqualTo(taken + 20), reason: '往上找，不是随便挑一个');
  });

  test('it gives up rather than scanning the whole range', () async {
    // Every port in the window taken. Trying for ever would hang the editor at
    // startup with nothing on screen to say why.
    final held = <ServerSocket>[];
    final first = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    held.add(first);
    for (var i = 1; i < McpServer.portAttempts; i++) {
      try {
        held.add(
          await ServerSocket.bind(InternetAddress.anyIPv4, first.port + i),
        );
      } catch (_) {
        // Someone else has it; that is just as good for this test.
      }
    }
    addTearDown(() async {
      for (final socket in held) {
        await socket.close();
      }
    });

    final server = McpServer();
    addTearDown(server.stop);
    await expectLater(
      server.start(port: first.port, token: 'tok', attempts: 1),
      throwsA(isA<SocketException>()),
    );
    expect(server.running, isFalse);
  });

  test('stopping twice is not an error', () async {
    final server = McpServer();
    await server.start(port: 0, token: 'tok');
    await server.stop();
    await server.stop();
    expect(server.running, isFalse);
  });
}

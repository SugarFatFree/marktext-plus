import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/app_log.dart';
import 'package:marktext_plus/services/mcp_server.dart';
import 'package:marktext_plus/services/mcp_tools.dart';

/// The protocol an agent speaks to the editor.
void main() {
  Future<Map<String, dynamic>?> ask(
    McpServer server,
    Map<String, dynamic> message,
  ) => server.handleMessage(jsonEncode(message));

  group('the handshake', () {
    test('initialize says what this is and what it can do', () async {
      final reply = await ask(McpServer(), {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {'protocolVersion': '2025-06-18'},
      });
      final result = reply!['result'] as Map;
      expect(result['serverInfo']['name'], 'marktext-plus');
      expect((result['capabilities'] as Map).containsKey('tools'), isTrue);
      expect(reply['id'], 1);
    });

    test('a notification gets no reply', () async {
      // Answering one is a protocol error at the other end.
      expect(
        await ask(McpServer(), {
          'jsonrpc': '2.0',
          'method': 'notifications/initialized',
        }),
        isNull,
      );
    });

    test('ping is answered', () async {
      final reply = await ask(McpServer(), {
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'ping',
      });
      expect(reply!['result'], isNotNull);
    });

    test('a method nobody implements is said so, not ignored', () async {
      final reply = await ask(McpServer(), {
        'jsonrpc': '2.0',
        'id': 3,
        'method': 'resources/list',
      });
      expect(reply!['error']['code'], -32601);
    });

    test('rubbish in is an error out, not a crash', () async {
      expect(
        (await McpServer().handleMessage('not json'))!['error']['code'],
        -32700,
      );
      expect((await McpServer().handleMessage('[]'))!['error']['code'], -32700);
    });
  });

  group('the tools', () {
    test('every one is listed with a schema', () async {
      final reply = await ask(McpServer(), {
        'jsonrpc': '2.0',
        'id': 4,
        'method': 'tools/list',
      });
      final tools = (reply!['result']['tools'] as List).cast<Map>();
      expect(
        tools.map((t) => t['name']),
        containsAll([
          'read_logs',
          'screenshot',
          'record_gif',
          'get_state',
          'control',
        ]),
      );
      for (final tool in tools) {
        expect(tool['description'], isNotEmpty, reason: '${tool['name']} 缺说明');
        expect(tool['inputSchema']['type'], 'object');
      }
    });

    test('the log comes back as text', () async {
      final log = AppLog(limit: 10)
        ..info('opened a file')
        ..error('a plugin fell over', source: 'com.example.demo');
      final server = McpServer(tools: McpToolset(log: log));

      final reply = await ask(server, {
        'jsonrpc': '2.0',
        'id': 5,
        'method': 'tools/call',
        'params': {'name': 'read_logs', 'arguments': {}},
      });
      final text = reply!['result']['content'][0]['text'] as String;
      expect(text, contains('opened a file'));
      expect(text, contains('com.example.demo'));
    });

    test('the log can be narrowed to one plugin', () async {
      final log = AppLog(limit: 10)
        ..info('editor thing')
        ..info('plugin thing', source: 'com.example.demo');
      final server = McpServer(tools: McpToolset(log: log));

      final reply = await ask(server, {
        'jsonrpc': '2.0',
        'id': 6,
        'method': 'tools/call',
        'params': {
          'name': 'read_logs',
          'arguments': {'source': 'com.example.demo'},
        },
      });
      final text = reply!['result']['content'][0]['text'] as String;
      expect(text, contains('plugin thing'));
      expect(text, isNot(contains('editor thing')));
    });

    test('a screenshot comes back as an image', () async {
      final server = McpServer(
        tools: McpToolset(screenshot: () async => [1, 2, 3]),
      );
      final reply = await ask(server, {
        'jsonrpc': '2.0',
        'id': 7,
        'method': 'tools/call',
        'params': {'name': 'screenshot', 'arguments': {}},
      });
      final part = reply!['result']['content'][0] as Map;
      expect(part['type'], 'image');
      expect(part['mimeType'], 'image/png');
      expect(base64Decode(part['data'] as String), [1, 2, 3]);
    });

    test('a recording is capped at five seconds', () async {
      Duration? asked;
      final server = McpServer(
        tools: McpToolset(
          recordGif: (length, fps) async {
            asked = length;
            return [7];
          },
        ),
      );
      await ask(server, {
        'jsonrpc': '2.0',
        'id': 8,
        'method': 'tools/call',
        'params': {
          'name': 'record_gif',
          'arguments': {'seconds': 30},
        },
      });
      expect(asked, McpToolset.maxRecording, reason: '要的是看动画，不是录一整段会话');
    });

    test('a tool that is not wired up says so, and does not crash', () async {
      final reply = await ask(McpServer(), {
        'jsonrpc': '2.0',
        'id': 9,
        'method': 'tools/call',
        'params': {'name': 'screenshot', 'arguments': {}},
      });
      expect(reply!['result']['isError'], isTrue);
    });

    test(
      'a tool that throws is a failed call, not a dropped connection',
      () async {
        final server = McpServer(
          tools: McpToolset(
            screenshot: () async => throw StateError('no window'),
          ),
        );
        final reply = await ask(server, {
          'jsonrpc': '2.0',
          'id': 10,
          'method': 'tools/call',
          'params': {'name': 'screenshot', 'arguments': {}},
        });
        expect(reply!['result']['isError'], isTrue);
        expect(reply['result']['content'][0]['text'], contains('no window'));
      },
    );

    test('an unknown tool is named in the answer', () async {
      final reply = await ask(McpServer(), {
        'jsonrpc': '2.0',
        'id': 11,
        'method': 'tools/call',
        'params': {'name': 'make_coffee', 'arguments': {}},
      });
      expect(reply!['result']['content'][0]['text'], contains('make_coffee'));
    });
  });

  group('the door', () {
    test('a server without a token is refused', () {
      expect(
        () => McpServer().start(port: 0, token: ''),
        throwsArgumentError,
        reason: '开着的端口没有令牌就是一扇敞开的门',
      );
    });

    Future<HttpClientResponse> post(
      int port, {
      String? token,
      String body = '{"jsonrpc":"2.0","id":1,"method":"ping"}',
    }) async {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('http://127.0.0.1:$port/mcp'),
      );
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      request.write(body);
      final response = await request.close();
      await response.drain<void>();
      client.close();
      return response;
    }

    test('the right token gets in', () async {
      final server = McpServer();
      addTearDown(server.stop);
      await server.start(port: 0, token: 'secret', localOnly: true);
      final response = await post(server.port!, token: 'secret');
      expect(response.statusCode, HttpStatus.ok);
    });

    test('a wrong token does not', () async {
      final server = McpServer();
      addTearDown(server.stop);
      await server.start(port: 0, token: 'secret', localOnly: true);
      final response = await post(server.port!, token: 'guess');
      expect(response.statusCode, HttpStatus.unauthorized);
    });

    test('no token does not', () async {
      final server = McpServer();
      addTearDown(server.stop);
      await server.start(port: 0, token: 'secret', localOnly: true);
      final response = await post(server.port!);
      expect(response.statusCode, HttpStatus.unauthorized);
    });

    test('a stopped server keeps nothing', () async {
      final server = McpServer();
      await server.start(port: 0, token: 'secret', localOnly: true);
      await server.stop();
      expect(server.token, isEmpty, reason: '停了就不该还留着令牌');
      expect(server.port, isNull);
    });
  });
}

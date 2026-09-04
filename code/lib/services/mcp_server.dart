import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'app_log.dart';
import 'mcp_tools.dart';

/// The editor, offered to an agent over MCP.
///
/// Off unless the reader turns it on. It is a port on their machine that lets
/// whatever reaches it read their documents and drive their editor, so it is
/// opt-in, it carries a token, and the token is not optional.
class McpServer {
  McpServer({McpToolset tools = const McpToolset()}) : _tools = tools;

  /// The port the editor asks for first.
  static const defaultPort = 10100;

  /// How many ports above it to try before giving up.
  ///
  /// Bounded, because trying for ever would hang startup with nothing on
  /// screen to say why.
  static const portAttempts = 20;

  McpToolset _tools;

  /// What this server can be asked to do.
  McpToolset get tools => _tools;

  HttpServer? _http;
  String _token = '';

  bool get running => _http != null;

  /// The port actually listening, or null when it is not.
  int? get port => _http?.port;

  String get token => _token;

  /// Starts listening, from [port] upward.
  ///
  /// Throws the last [SocketException] if every port in the window is taken:
  /// the reader asked for this and is entitled to be told it did not happen.
  Future<void> start({
    int port = defaultPort,
    required String token,
    int attempts = portAttempts,
    bool localOnly = false,
    McpToolset? tools,
  }) async {
    if (token.isEmpty) {
      throw ArgumentError('an MCP server without a token is an open door');
    }
    await stop();
    if (tools != null) _tools = tools;
    final address = localOnly
        ? InternetAddress.loopbackIPv4
        : InternetAddress.anyIPv4;
    Object? lastError;
    for (var offset = 0; offset < attempts; offset++) {
      try {
        // Port 0 means "anything free", so there is nothing to walk upward.
        final wanted = port == 0 ? 0 : port + offset;
        _http = await HttpServer.bind(address, wanted);
        _token = token;
        _http!.listen(_handle);
        AppLog.instance.info('MCP server listening on port ${_http!.port}');
        return;
      } on SocketException catch (error) {
        lastError = error;
        if (port == 0) rethrow;
      }
    }
    AppLog.instance.error(
      'MCP server could not find a free port from $port upward',
    );
    throw lastError!;
  }

  Future<void> stop() async {
    final http = _http;
    _http = null;
    _token = '';
    if (http == null) return;
    await http.close(force: true);
    AppLog.instance.info('MCP server stopped');
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      if (request.method != 'POST') {
        // A browser that wandered in, or a health check.
        request.response.statusCode = HttpStatus.methodNotAllowed;
        await request.response.close();
        return;
      }
      if (!_authorised(request)) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.write('{"error":"bad or missing token"}');
        await request.response.close();
        return;
      }

      final body = await utf8.decoder.bind(request).join();
      final reply = await handleMessage(body);
      request.response.headers.contentType = ContentType.json;
      // A notification has no reply, and answering one anyway is a protocol
      // error at the other end.
      if (reply != null) request.response.write(jsonEncode(reply));
      await request.response.close();
    } catch (error) {
      AppLog.instance.error('MCP request failed: $error');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {
        // The connection went away; nothing to report it to.
      }
    }
  }

  bool _authorised(HttpRequest request) {
    final header = request.headers.value(HttpHeaders.authorizationHeader) ?? '';
    final bearer = header.startsWith('Bearer ') ? header.substring(7) : '';
    final query = request.uri.queryParameters['token'] ?? '';
    final offered = bearer.isNotEmpty ? bearer : query;
    return offered.isNotEmpty && offered == _token;
  }

  /// One JSON-RPC message in, one reply out — or null for a notification.
  ///
  /// Separate from the socket so the protocol can be tested without one.
  Future<Map<String, dynamic>?> handleMessage(String body) async {
    Map<String, dynamic> request;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return _error(null, -32700, 'not a JSON object');
      request = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return _error(null, -32700, 'parse error');
    }

    final id = request['id'];
    final method = request['method'];
    if (method is! String) {
      return _error(id, -32600, 'no method');
    }
    final params = request['params'] is Map
        ? Map<String, dynamic>.from(request['params'] as Map)
        : <String, dynamic>{};

    try {
      switch (method) {
        case 'initialize':
          return _result(id, {
            'protocolVersion': '2025-06-18',
            'capabilities': {
              'tools': {'listChanged': false},
            },
            'serverInfo': {
              'name': 'marktext-plus',
              'version': appVersionForMcp,
            },
          });
        case 'notifications/initialized':
          return null;
        case 'ping':
          return _result(id, const {});
        case 'tools/list':
          return _result(id, {
            'tools': [for (final tool in _tools.all) tool.describe()],
          });
        case 'tools/call':
          final name = params['name'];
          if (name is! String) return _error(id, -32602, 'no tool name');
          final arguments = params['arguments'] is Map
              ? Map<String, dynamic>.from(params['arguments'] as Map)
              : <String, dynamic>{};
          return _result(id, await _tools.call(name, arguments));
        default:
          return _error(id, -32601, 'unknown method "$method"');
      }
    } catch (error) {
      AppLog.instance.error('MCP $method failed: $error');
      return _error(id, -32603, '$error');
    }
  }

  static Map<String, dynamic> _result(Object? id, Object? result) => {
    'jsonrpc': '2.0',
    'id': id,
    'result': result,
  };

  static Map<String, dynamic> _error(Object? id, int code, String message) => {
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': code, 'message': message},
  };
}

/// Reported in `initialize`, so an agent can tell which editor it reached.
const appVersionForMcp = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: 'dev',
);

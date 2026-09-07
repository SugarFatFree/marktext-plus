import 'dart:async';
import 'dart:io';

import 'plugin_logger.dart';

/// The way out to the network for anything a plugin renders itself.
///
/// A web view fetches whatever its page asks for, and the platform APIs for
/// intercepting that differ on every one of the three desktops — WebView2 has
/// `WebResourceRequested`, WKWebView wants a scheme handler, WebKitGTK emits a
/// signal. A local proxy is the one mechanism all three already speak.
///
/// It buys two things the reader was promised:
///
/// - **the system proxy**, because this forwards through the same environment
///   settings the editor's own requests use, rather than each web view finding
///   its own way out;
/// - **a log**, because every request passes through here on its way.
///
/// What the log can hold: an `https` request arrives as `CONNECT host:443` and
/// everything after that is encrypted, so the host, the byte counts and the
/// duration are visible and the contents are not. Reading the contents would
/// mean a man-in-the-middle certificate — heavy, and a real risk of its own —
/// and "which server did this plugin talk to" is the question a reader
/// actually has. A plugin that wants the host to see everything can use
/// `network.request`, which the host makes on its behalf.
class PluginProxy {
  PluginProxy({required this.logger});

  final PluginLogger logger;

  ServerSocket? _server;

  /// Where it is listening. Loopback, and a test can check that rather than
  /// taking the comment's word for it.
  InternetAddress? get address => _server?.address;

  /// The port to point a web view at, or null before [start].
  int? get port => _server?.port;

  Future<int> start() async {
    // Loopback only. A proxy on a public interface would be an open relay
    // running inside somebody's text editor.
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    // Deliberately not awaited: accepting runs for as long as the proxy is
    // up, and `start` has to return the port to whoever is about to use it.
    // `stop` is what ends it.
    unawaited(_accept(server));
    return server.port;
  }

  Future<void> _accept(ServerSocket server) async {
    await for (final client in server) {
      // Deliberately not awaited: one connection must not hold up the next,
      // and a page opens many at once.
      unawaited(
        _serve(client).catchError((Object error) async {
          await logger.warning('proxy connection failed: $error');
        }),
      );
    }
  }

  /// Reads the request line and headers, then hands the connection on.
  ///
  /// The subscription is passed along rather than the socket being listened
  /// to again: a Socket's stream can only be listened to once, and reading
  /// the headers here and then tunnelling from `_tunnel` meant listening
  /// twice. The tunnel opened, said "200 Connection established", and then
  /// moved nothing.
  Future<void> _serve(Socket client) async {
    final buffer = <int>[];
    final done = Completer<void>();
    var handled = false;

    final subscription = client.listen(null);
    subscription.onData((chunk) {
      if (handled) return;
      buffer.addAll(chunk);
      final headerEnd = _endOfHeaders(buffer);
      if (headerEnd == null) {
        // A request line and its headers are small; anything this large is
        // not one, and reading forever is how a proxy becomes a memory leak.
        if (buffer.length > 64 * 1024) {
          client.destroy();
          if (!done.isCompleted) done.complete();
        }
        return;
      }
      handled = true;
      final head = String.fromCharCodes(buffer.take(headerEnd));
      final rest = buffer.sublist(headerEnd);
      // Deliberately not awaited: this is inside `onData`, which cannot wait,
      // and the completer below is what `_serve` waits on instead — so the
      // connection is still seen through to its end.
      unawaited(_dispatch(client, subscription, head, rest).whenComplete(() {
        if (!done.isCompleted) done.complete();
      }));
    });
    subscription.onDone(() {
      if (!handled && !done.isCompleted) done.complete();
    });
    subscription.onError((Object error) {
      if (!done.isCompleted) done.complete();
    });

    await done.future;
  }

  static int? _endOfHeaders(List<int> buffer) {
    for (var i = 3; i < buffer.length; i++) {
      if (buffer[i - 3] == 13 &&
          buffer[i - 2] == 10 &&
          buffer[i - 1] == 13 &&
          buffer[i] == 10) {
        return i + 1;
      }
    }
    return null;
  }

  Future<void> _dispatch(
    Socket client,
    StreamSubscription<List<int>> subscription,
    String head,
    List<int> rest,
  ) async {
    final requestLine = head.split('\r\n').first;
    final parts = requestLine.split(' ');
    if (parts.length < 3) {
      client.destroy();
      return;
    }
    final method = parts[0];
    final target = parts[1];

    if (method == 'CONNECT') {
      await _tunnel(client, subscription, target, rest);
      return;
    }
    await _forward(client, method, target, head, rest);
  }

  /// `CONNECT host:port` — everything after this is the page's own TLS.
  Future<void> _tunnel(
    Socket client,
    StreamSubscription<List<int>> subscription,
    String target,
    List<int> pending,
  ) async {
    final split = target.lastIndexOf(':');
    final host = split == -1 ? target : target.substring(0, split);
    final port = split == -1 ? 443 : int.tryParse(target.substring(split + 1));
    if (port == null) {
      client.destroy();
      return;
    }

    final started = DateTime.now();
    var up = 0;
    var down = 0;
    Socket? server;
    final finished = Completer<void>();
    try {
      server = await Socket.connect(host, port,
          timeout: const Duration(seconds: 20));
      client.add('HTTP/1.1 200 Connection established\r\n\r\n'.codeUnits);

      // Whatever arrived in the same packet as the CONNECT line.
      if (pending.isNotEmpty) {
        up += pending.length;
        server.add(pending);
      }

      final opened = server;
      subscription.onData((chunk) {
        up += chunk.length;
        opened.add(chunk);
      });
      subscription.onDone(() {
        opened.destroy();
        if (!finished.isCompleted) finished.complete();
      });

      opened.listen(
        (chunk) {
          down += chunk.length;
          client.add(chunk);
        },
        onDone: () {
          client.destroy();
          if (!finished.isCompleted) finished.complete();
        },
        onError: (Object _) {
          client.destroy();
          if (!finished.isCompleted) finished.complete();
        },
      );

      await finished.future;
    } catch (error) {
      await logger.warning('proxy $host:$port failed: $error');
      client.destroy();
      return;
    } finally {
      server?.destroy();
      final took = DateTime.now().difference(started).inMilliseconds;
      await logger
          .info('webview CONNECT $host:$port ${up}B↑ ${down}B↓ ${took}ms');
    }
  }

  /// A plain `http` request, forwarded through the editor's own client so it
  /// takes the system proxy with it.
  Future<void> _forward(
    Socket client,
    String method,
    String target,
    String head,
    List<int> body,
  ) async {
    final uri = Uri.tryParse(target);
    if (uri == null || !uri.hasScheme) {
      client.destroy();
      return;
    }
    final started = DateTime.now();
    final http = HttpClient()
      ..findProxy = (target) => HttpClient.findProxyFromEnvironment(
        target,
        environment: Platform.environment,
      );
    try {
      final request = await http.openUrl(method, uri);
      for (final line in head.split('\r\n').skip(1)) {
        final colon = line.indexOf(':');
        if (colon <= 0) continue;
        final name = line.substring(0, colon).trim();
        // Hop-by-hop headers belong to the connection this proxy is ending,
        // not to the request it is making.
        if (const {
          'host',
          'connection',
          'proxy-connection',
          'keep-alive',
        }.contains(name.toLowerCase())) {
          continue;
        }
        request.headers.set(name, line.substring(colon + 1).trim());
      }
      if (body.isNotEmpty) request.add(body);
      final response = await request.close();

      final out = StringBuffer('HTTP/1.1 ${response.statusCode} \r\n');
      response.headers.forEach((name, values) {
        // `transfer-encoding` and `content-length` describe how the body
        // travelled on the connection this proxy already ended: HttpClient
        // decoded a chunked body before handing it over, so passing the
        // header on made the caller parse plain bytes as chunks — "104 is
        // expected to be a Hex digit". The body goes out as-is and the
        // connection closes to mark its end.
        if (const {'transfer-encoding', 'content-length', 'connection'}
            .contains(name.toLowerCase())) {
          return;
        }
        for (final value in values) {
          out.write('$name: $value\r\n');
        }
      });
      out.write('Connection: close\r\n');
      out.write('\r\n');
      client.add(out.toString().codeUnits);
      var down = 0;
      await for (final chunk in response) {
        down += chunk.length;
        client.add(chunk);
      }
      final took = DateTime.now().difference(started).inMilliseconds;
      await logger.info(
        'webview $method ${uri.scheme}://${uri.host} '
        '${response.statusCode} ${down}B ${took}ms',
      );
    } catch (error) {
      await logger.warning('proxy ${uri.host} failed: $error');
    } finally {
      http.close(force: true);
      await client.flush().catchError((_) {});
      client.destroy();
    }
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }
}

import '../core/net/answered_within.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'plugin_logger.dart';
import 'plugin_manifest.dart';

/// Fetches the pictures a plugin's interface asks for.
///
/// Three shapes, and which one it is decides where the bytes come from:
///
/// - `data:` — decoded in place, nothing leaves the machine;
/// - a relative path — read from inside the plugin's own directory;
/// - `http(s)` — fetched through this client, which means it follows the
///   system proxy and is written to the plugin's log.
///
/// That last one is the point. A plugin may reach the network — that is what
/// `network.request` grants — and the reader should be able to find out where
/// it went. Logging it here rather than trusting the plugin to say so is the
/// difference between a permission and a promise.
class PluginImageLoader {
  PluginImageLoader({
    required this.pluginDirectory,
    required this.logger,
    required this.allowNetwork,
    this.maxBytes = 8 * 1024 * 1024,
    this.within = const Duration(seconds: 30),
  });

  /// How long to wait for the picture's server to say anything. A size limit
  /// does not bound this: a server that sends nothing stays under it forever.
  final Duration within;

  /// Where the plugin's own files are. A relative source is resolved against
  /// this and refused if it lands outside.
  final String pluginDirectory;

  /// Whether this plugin holds `network.request`.
  ///
  /// Required rather than defaulted on purpose. Either default is wrong at a
  /// call site that forgot to think: `true` hands the network to a plugin
  /// that never asked, `false` takes it from one that did.
  final bool allowNetwork;

  final PluginLogger logger;

  /// A picture larger than this is refused. Generous for anything meant to be
  /// looked at inside a drawer, and far below what would hurt.
  final int maxBytes;

  Future<Uint8List> load(String source) async {
    if (source.startsWith('data:')) return _fromDataUri(source);

    final uri = Uri.tryParse(source);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return _fromNetwork(uri);
    }

    return _fromDirectory(source);
  }

  Uint8List _fromDataUri(String source) {
    // `parse`, not `fromString`: the latter builds a data URI out of the text
    // it is handed, so it cheerfully returned the bytes of the string
    // "data:image/png;base64,…" itself.
    final Uint8List bytes;
    try {
      bytes = UriData.parse(source).contentAsBytes();
    } on FormatException catch (error) {
      throw PluginImageException('the data URI is malformed: ${error.message}');
    }
    if (bytes.length > maxBytes) {
      throw PluginImageException('the picture is larger than $maxBytes bytes');
    }
    return bytes;
  }

  Future<Uint8List> _fromDirectory(String source) async {
    if (p.isAbsolute(source)) {
      // A plugin's pictures are its own. Reading arbitrary files off the
      // reader's disk is what `workspace.read` is for, and it is asked for
      // separately.
      throw const PluginImageException(
        'a picture path must be relative to the plugin directory',
      );
    }
    final resolved = p.normalize(p.join(pluginDirectory, source));
    if (!p.isWithin(pluginDirectory, resolved)) {
      throw const PluginImageException(
        'a picture path may not leave the plugin directory',
      );
    }
    final file = File(resolved);
    if (!await file.exists()) {
      throw PluginImageException('no such picture: $source');
    }
    if (await file.length() > maxBytes) {
      throw PluginImageException('the picture is larger than $maxBytes bytes');
    }
    return file.readAsBytes();
  }

  Future<Uint8List> _fromNetwork(Uri uri) async {
    if (!allowNetwork) {
      // Before the request, not after it. A URL is itself a message — the
      // query string can carry whatever the plugin just read — so an editor
      // that sends it and then throws has already handed over the thing the
      // permission was protecting.
      //
      // Logged, because a plugin reaching for a permission it does not hold
      // is exactly what the reader keeps this log to find out.
      await logger.warning(
        'image ${uri.scheme}://${uri.host} refused: '
        'the plugin did not ask for ${PluginPermission.networkRequest}',
      );
      throw PluginImageException(
        'this plugin did not ask for the '
        '"${PluginPermission.networkRequest}" permission',
      );
    }
    final client = HttpClient()
      // The reader's proxy settings, the same as every other request this
      // editor makes. A plugin does not get its own way onto the network.
      ..findProxy = (target) => HttpClient.findProxyFromEnvironment(
        target,
        environment: Platform.environment,
      );
    final started = DateTime.now();
    try {
      final response = await (await client.getUrl(uri))
          .close()
          .answeredWithin(within, 'the picture\'s server');
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
        if (bytes.length > maxBytes) {
          throw PluginImageException(
            'the picture is larger than $maxBytes bytes',
          );
        }
      }
      final took = DateTime.now().difference(started).inMilliseconds;
      // Host, not the whole URL: a query string can carry what the plugin was
      // sending, and the log is meant to say where it went rather than to
      // become a second copy of the document.
      await logger.info(
        'image ${uri.scheme}://${uri.host} '
        '${response.statusCode} ${bytes.length}B ${took}ms',
      );
      if (response.statusCode != HttpStatus.ok) {
        throw PluginImageException(
          'the server answered ${response.statusCode}',
        );
      }
      return Uint8List.fromList(bytes);
    } on PluginImageException {
      rethrow;
    } catch (error) {
      await logger.warning('image ${uri.scheme}://${uri.host} failed: $error');
      throw PluginImageException('$error');
    } finally {
      client.close(force: true);
    }
  }
}

class PluginImageException implements Exception {
  const PluginImageException(this.message);

  final String message;

  @override
  String toString() => message;
}

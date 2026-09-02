import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'plugin_manager.dart';
import 'plugin_manifest.dart';

class PluginCatalogEntry {
  const PluginCatalogEntry({
    required this.id,
    required this.name,
    required this.version,
    required this.downloadUrl,
    required this.sha256,
    this.description = '',
    this.repositoryUrl,
  });

  final String id;
  final String name;
  final String version;
  final Uri downloadUrl;
  final String sha256;
  final String description;
  final Uri? repositoryUrl;

  factory PluginCatalogEntry.fromJson(Map<String, dynamic> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('catalog entry requires $key');
      }
      return value.trim();
    }

    final url = Uri.tryParse(requiredString('downloadUrl'));
    if (url == null || !url.isScheme('https')) {
      throw const FormatException('plugin downloadUrl must use HTTPS');
    }
    return PluginCatalogEntry(
      id: requiredString('id'),
      name: requiredString('name'),
      version: requiredString('version'),
      downloadUrl: url,
      sha256: requiredString('sha256').toLowerCase(),
      description: (json['description'] as String?)?.trim() ?? '',
      repositoryUrl: Uri.tryParse((json['repository'] as String?) ?? ''),
    );
  }
}

/// Reads the signed/transport-secured plugin registry lazily.
class PluginCatalogService {
  /// Uses the operating system proxy variables when present. GitHub requests
  /// are user-triggered, so a proxy failure is reported by the panel rather
  /// than delaying application startup.
  HttpClient _client() {
    final client = HttpClient();
    client.findProxy = (uri) => HttpClient.findProxyFromEnvironment(
          uri,
          environment: Platform.environment,
        );
    client.userAgent = 'MarkTextPlus/1.6.0';
    return client;
  }

  Future<List<PluginCatalogEntry>> fetch(Uri registryUrl) async {
    if (!registryUrl.isScheme('https')) {
      throw ArgumentError.value(registryUrl, 'registryUrl', 'must use HTTPS');
    }
    final client = _client();
    try {
      final request = await client.getUrl(registryUrl);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('registry returned ${response.statusCode}');
      }
      final json = jsonDecode(await utf8.decoder.bind(response).join());
      if (json is! Map || json['plugins'] is! List) {
        throw const FormatException('registry must contain a plugins list');
      }
      return [
        for (final item in json['plugins'])
          PluginCatalogEntry.fromJson(item as Map<String, dynamic>),
      ];
    } finally {
      client.close(force: true);
    }
  }

  /// Discovers public plugin repositories through GitHub Topics.
  ///
  /// This is deliberately uncurated: any public repository may opt in by
  /// adding `marktext-plus-plugin`. Repositories without a latest release, a
  /// ZIP asset, or GitHub's SHA-256 asset digest are listed nowhere as
  /// installable, because discovery and installation trust are separate.
  Future<List<PluginCatalogEntry>> searchGitHubTopic({
    int perPage = 30,
  }) async {
    final client = _client();
    try {
      final searchUrl = Uri.https('api.github.com', '/search/repositories', {
        'q': 'topic:marktext-plus-plugin',
        'per_page': '$perPage',
      });
      final request = await client.getUrl(searchUrl);
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('GitHub topic search returned ${response.statusCode}');
      }
      final payload = jsonDecode(await utf8.decoder.bind(response).join());
      if (payload is! Map || payload['items'] is! List) {
        throw const FormatException('GitHub topic response has no items');
      }
      final entries = <PluginCatalogEntry>[];
      for (final item in payload['items']) {
        if (item is! Map || item['full_name'] is! String) continue;
        final fullName = item['full_name'] as String;
        final releaseUrl = Uri.https(
          'api.github.com',
          '/repos/$fullName/releases/latest',
        );
        final releaseRequest = await client.getUrl(releaseUrl);
        releaseRequest.headers
            .set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
        final releaseResponse = await releaseRequest.close();
        if (releaseResponse.statusCode != HttpStatus.ok) continue;
        final release = jsonDecode(
          await utf8.decoder.bind(releaseResponse).join(),
        );
        if (release is! Map || release['assets'] is! List) continue;
        for (final asset in release['assets']) {
          if (asset is! Map || asset['name'] is! String) continue;
          final name = asset['name'] as String;
          final browserUrl = asset['browser_download_url'];
          final digest = asset['digest'];
          if (!name.endsWith('.zip') ||
              browserUrl is! String ||
              digest is! String ||
              !digest.startsWith('sha256:')) {
            continue;
          }
          entries.add(
            PluginCatalogEntry(
              id: 'github.$fullName'.toLowerCase().replaceAll('/', '.'),
              name: (item['name'] as String?) ?? fullName,
              version: (release['tag_name'] as String?) ?? 'unknown',
              downloadUrl: Uri.parse(browserUrl),
              sha256: digest.substring('sha256:'.length),
              description: (item['description'] as String?) ?? '',
              repositoryUrl: Uri.https('github.com', '/$fullName'),
            ),
          );
          break;
        }
      }
      return entries;
    } finally {
      client.close(force: true);
    }
  }

  /// Downloads one catalog entry to a temporary file, verifies its digest,
  /// then delegates extraction and manifest validation to [manager].
  Future<PluginManifest> install(
    PluginCatalogEntry entry,
    PluginManager manager,
  ) async {
    final client = _client();
    final temporary = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'marktext-plugin-${entry.id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}.zip',
    );
    try {
      final request = await client.getUrl(entry.downloadUrl);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('plugin download returned ${response.statusCode}');
      }
      final bytes = await response.fold<List<int>>([], (all, chunk) {
        all.addAll(chunk);
        return all;
      });
      final digest = sha256.convert(bytes).toString();
      if (digest != entry.sha256) {
        throw const FormatException('plugin SHA-256 does not match catalog');
      }
      await temporary.writeAsBytes(bytes, flush: true);
      return await manager.installZip(temporary);
    } finally {
      client.close(force: true);
      if (await temporary.exists()) await temporary.delete();
    }
  }
}

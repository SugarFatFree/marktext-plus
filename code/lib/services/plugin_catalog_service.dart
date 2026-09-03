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
    this.releaseNotes = '',
    this.publishedAt,
  });

  final String id;
  final String name;
  final String version;
  /// Null for a plugin that is already installed: there is nothing to fetch.
  final Uri? downloadUrl;
  final String sha256;
  final String description;
  final Uri? repositoryUrl;

  /// What the release said had changed. Markdown, as its author wrote it.
  ///
  /// The one thing someone deciding whether to install or update is looking
  /// for, and the detail page had no way to show it.
  final String releaseNotes;

  /// When that release was published, if the date could be read.
  final DateTime? publishedAt;

  /// Whether this is a plugin already on the reader's machine.
  ///
  /// The detail page was built from a search result, so installing a plugin
  /// took its page away: clicking it in the installed list did nothing, and
  /// the version and notes that had been there a moment ago were gone.
  bool get isInstalled => downloadUrl == null;

  /// A page for a plugin that is already installed.
  ///
  /// It has no download to offer and, unless its manifest says otherwise, no
  /// repository to read a README from — so the page shows what the manifest
  /// knows rather than fetching something that is not there.
  factory PluginCatalogEntry.installed(PluginManifest manifest) =>
      PluginCatalogEntry(
        id: manifest.id,
        name: manifest.name,
        version: manifest.version,
        downloadUrl: null,
        sha256: '',
        repositoryUrl: manifest.repository.isEmpty
            ? null
            : Uri.tryParse(manifest.repository),
      );

  factory PluginCatalogEntry.fromJson(Map<String, dynamic> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('catalog entry requires $key');
      }
      return value.trim();
    }

    final published = json['publishedAt'];
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
      releaseNotes: (json['releaseNotes'] as String?)?.trim() ?? '',
      // A date nobody can read is worth less than the plugin it is attached
      // to, so it is dropped rather than allowed to hide the entry.
      publishedAt:
          published is String ? DateTime.tryParse(published)?.toUtc() : null,
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
              releaseNotes: (release['body'] as String?)?.trim() ?? '',
              publishedAt: DateTime.tryParse(
                (release['published_at'] as String?) ?? '',
              )?.toUtc(),
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

  Future<String> fetchReadme(Uri repositoryUrl) async {
    final segments = repositoryUrl.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) throw const FormatException('Invalid plugin repository URL');
    final raw = Uri.https('raw.githubusercontent.com', '/${segments[0]}/${segments[1]}/HEAD/README.md');
    final client = _client();
    try {
      final response = await (await client.getUrl(raw)).close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('README returned HTTP ${response.statusCode}');
      }
      return await utf8.decoder.bind(response).join();
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
    final downloadUrl = entry.downloadUrl;
    if (downloadUrl == null) {
      throw const FormatException(
        'this plugin is already installed; there is nothing to download',
      );
    }
    try {
      final request = await client.getUrl(downloadUrl);
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

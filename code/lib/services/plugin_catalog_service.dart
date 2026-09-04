import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../models/plugin_catalog_entry.dart';
import 'plugin_manager.dart';
import 'plugin_manifest.dart';

// Re-exported so every caller keeps importing the catalogue from the service
// that fetches it. Moving the type was about layering, not about churn.
export '../models/plugin_catalog_entry.dart';


/// Reads the signed/transport-secured plugin registry lazily.
class PluginCatalogService {
  /// Uses the operating system proxy variables when present. GitHub requests
  /// are user-triggered, so a proxy failure is reported by the panel rather
  /// than delaying application startup.
  /// The most recently published release, pre-release or not.
  ///
  /// Drafts are left out — they are not published, so nobody but their author
  /// is meant to have them — and so is anything with no publication date,
  /// since there is nothing to compare it by.
  static Map<String, dynamic>? newestRelease(List<dynamic> releases) {
    Map<String, dynamic>? best;
    DateTime? bestAt;
    for (final entry in releases) {
      if (entry is! Map) continue;
      if (entry['draft'] == true) continue;
      final published = entry['published_at'];
      if (published is! String) continue;
      final at = DateTime.tryParse(published);
      if (at == null) continue;
      if (bestAt == null || at.isAfter(bestAt)) {
        bestAt = at;
        best = Map<String, dynamic>.from(entry);
      }
    }
    return best;
  }

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
  /// What went wrong, in terms the reader can act on.
  ///
  /// GitHub allows ten unauthenticated searches a minute, and pressing the
  /// button a few times in a row reaches that. "returned 403" reads as the
  /// plugin list being broken, which sends the reader looking for a fault that
  /// is not there; it is a wait.
  static String describeFailure({
    required int status,
    required String? remaining,
    required DateTime? resetAt,
  }) {
    final limited = status == HttpStatus.forbidden || status == 429;
    if (!limited || remaining != '0') {
      return 'GitHub topic search returned $status';
    }
    final seconds = resetAt?.difference(DateTime.now()).inSeconds;
    return seconds == null || seconds <= 0
        ? 'GitHub is rate-limiting searches from this machine; '
            'try again in a minute.'
        : 'GitHub is rate-limiting searches from this machine; '
            'try again in $seconds seconds.';
  }

  static String _describeFailure(HttpClientResponse response) {
    final resets = int.tryParse(
      response.headers.value('x-ratelimit-reset') ?? '',
    );
    return describeFailure(
      status: response.statusCode,
      remaining: response.headers.value('x-ratelimit-remaining'),
      resetAt: resets == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(resets * 1000),
    );
  }

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
        throw HttpException(_describeFailure(response));
      }
      final payload = jsonDecode(await utf8.decoder.bind(response).join());
      if (payload is! Map || payload['items'] is! List) {
        throw const FormatException('GitHub topic response has no items');
      }
      final entries = <PluginCatalogEntry>[];
      for (final item in payload['items']) {
        if (item is! Map || item['full_name'] is! String) continue;
        final fullName = item['full_name'] as String;
        // Every release, not `releases/latest`: that endpoint leaves out
        // pre-releases, and a plugin here is Community/Unverified — most will
        // sit at 0.x for a long time and publish nothing else.
        final releaseUrl = Uri.https(
          'api.github.com',
          '/repos/$fullName/releases',
          {'per_page': '20'},
        );
        final releaseRequest = await client.getUrl(releaseUrl);
        releaseRequest.headers
            .set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
        final releaseResponse = await releaseRequest.close();
        if (releaseResponse.statusCode != HttpStatus.ok) continue;
        final releases = jsonDecode(
          await utf8.decoder.bind(releaseResponse).join(),
        );
        if (releases is! List) continue;
        final release = newestRelease(releases);
        if (release == null || release['assets'] is! List) continue;
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
              isPrerelease: release['prerelease'] == true,
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
      final manifest = await manager.installZip(temporary);
      // Which release this was is not in the plugin — it is a property of the
      // release — so it is written down here, at the one moment it is known.
      await manager.recordSource(
        manifest.id,
        PluginSource(
          prerelease: entry.isPrerelease,
          tag: entry.version,
          digest: entry.sha256,
        ),
      );
      return manifest;
    } finally {
      client.close(force: true);
      if (await temporary.exists()) await temporary.delete();
    }
  }
}

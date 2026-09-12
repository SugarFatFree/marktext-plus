import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../core/net/answered_within.dart';
import '../core/constants.dart';
import '../models/plugin_catalog_entry.dart';
import 'plugin_manager.dart';
import 'plugin_manifest.dart';

// Re-exported so every caller keeps importing the catalogue from the service
// that fetches it. Moving the type was about layering, not about churn.
export '../models/plugin_catalog_entry.dart';


/// Why the plugin catalogue could not be read.
///
/// A kind rather than a sentence, so the reader can be told in their own
/// language. Every message on this path used to be English prose built inside
/// the service and rendered straight into the panel — so the reader got their
/// own language while it worked and English the moment it stopped, which is
/// when they most need to understand what happened. The same shape
/// `MermaidFailureKind` has had since diagrams needed it.
enum PluginCatalogFailureKind {
  /// Nothing reached GitHub at all: no network, or a proxy in the way.
  unreachable,

  /// GitHub is refusing searches from this machine for the moment. The one
  /// failure a reader can act on by waiting, which is why it is worth its own
  /// kind and its own count of seconds.
  rateLimited,

  /// Anything else. [PluginCatalogFailure.detail] is the best there is, and
  /// it is technical: a status code, a digest that did not match, an archive
  /// that unpacks to too much.
  other,
}

/// A failure the panel can word for itself.
@immutable
class PluginCatalogFailure {
  const PluginCatalogFailure(this.kind, {this.detail = '', this.retryAfter});

  final PluginCatalogFailureKind kind;

  /// The English sentence, for [PluginCatalogFailureKind.other] and for
  /// anywhere with no reader to translate for — the automation interface
  /// answers an agent, and an agent reads English.
  final String detail;

  /// Seconds until the limit lifts, when GitHub said how long.
  final int? retryAfter;

  /// The English wording. One source for both: the panel picks a translation
  /// by [kind], and everything without a reader uses this.
  String describe() => switch (kind) {
        PluginCatalogFailureKind.unreachable =>
          'could not reach GitHub; check the network or a proxy',
        PluginCatalogFailureKind.rateLimited => retryAfter == null
            ? 'GitHub is rate-limiting searches from this machine; '
                'try again in a minute.'
            : 'GitHub is rate-limiting searches from this machine; '
                'try again in $retryAfter seconds.',
        PluginCatalogFailureKind.other => detail,
      };
}

/// A failure with its kind still attached.
///
/// Thrown where the kind is known, so it survives the throw: the seconds
/// until a rate limit lifts are worked out from a response header and there
/// is no reading them back out of a sentence afterwards.
class PluginCatalogException implements Exception {
  const PluginCatalogException(this.failure);

  final PluginCatalogFailure failure;

  @override
  String toString() => failure.describe();
}

/// Finds plugins on GitHub, and installs the one a reader picks.
///
/// It used to carry a `fetch(registryUrl)` as well — the curated registry this
/// marketplace was going to have before it became open discovery by topic.
/// Nothing called it, in `lib` or in `test`, and the sentence that used to
/// stand here described it: anyone reading the class was told the editor reads
/// a signed registry, which it has not done for a long time. Dead code that
/// explains how something works is worse than dead code that does not.
class PluginCatalogService {
  /// [cache] is where a listing is kept between launches; null does not cache.
  const PluginCatalogService({
    this.cache,
    this.within = const Duration(seconds: 30),
  });

  /// How long to wait for GitHub to say anything at all.
  final Duration within;

  /// Where the last listing was written, so a launch need not fetch one.
  ///
  /// Discovery costs one search plus a request for each repository it finds —
  /// up to thirty, against sixty unauthenticated requests an hour. Doing that
  /// on every start runs a reader out of quota in two or three launches, and
  /// what they see is "GitHub is rate-limiting searches from this machine;
  /// try again in 819 seconds" where a list of plugins should be.
  final File? cache;

  /// How long a written listing is used before asking GitHub again.
  ///
  /// Long enough that opening the editor several times in an afternoon costs
  /// one search; short enough that a plugin published this morning is found
  /// today. The refresh button ignores it — that press is the reader saying
  /// they want the current answer.
  static const cacheFor = Duration(hours: 6);

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

  /// Uses the operating system proxy variables when present. GitHub requests
  /// are user-triggered, so a proxy failure is reported by the panel rather
  /// than delaying application startup.
  HttpClient _client() {
    final client = HttpClient();
    client.findProxy = (uri) => HttpClient.findProxyFromEnvironment(
          uri,
          environment: Platform.environment,
        );
    client.userAgent = 'MarkTextPlus/${AppConstants.appVersion}';
    return client;
  }

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
  }) =>
      failureFor(status: status, remaining: remaining, resetAt: resetAt)
          .describe();

  /// The same answer with its kind still on it.
  ///
  /// [describeFailure] is this rendered to English. One source for both, so
  /// the sentence the automation interface reads and the kind the panel
  /// translates cannot come to disagree.
  static PluginCatalogFailure failureFor({
    required int status,
    required String? remaining,
    required DateTime? resetAt,
  }) {
    final limited = status == HttpStatus.forbidden || status == 429;
    if (!limited || remaining != '0') {
      return PluginCatalogFailure(
        PluginCatalogFailureKind.other,
        detail: 'GitHub topic search returned $status',
      );
    }
    final seconds = resetAt?.difference(DateTime.now()).inSeconds;
    return PluginCatalogFailure(
      PluginCatalogFailureKind.rateLimited,
      retryAfter: seconds == null || seconds <= 0 ? null : seconds,
    );
  }

  /// What to tell the reader about [error], without the class name.
  ///
  /// `'$error'` on an `HttpException` reads "HttpException: …", and the part
  /// before the colon means nothing to somebody looking at a list of plugins
  /// that did not appear. The same note is on `PluginManager._describe`,
  /// which does this for the manifest reader — the lesson was learned once
  /// and applied in one place.
  static String describeError(Object error) => classify(error).describe();

  /// [error] as something the panel can word in the reader's language.
  static PluginCatalogFailure classify(Object error) => switch (error) {
        // Thrown where the kind was known, so nothing has to be guessed.
        PluginCatalogException(:final failure) => failure,
        SocketException() =>
          const PluginCatalogFailure(PluginCatalogFailureKind.unreachable),
        HttpException(:final message) =>
          PluginCatalogFailure(PluginCatalogFailureKind.other, detail: message),
        FormatException(:final message) =>
          PluginCatalogFailure(PluginCatalogFailureKind.other, detail: message),
        _ => PluginCatalogFailure(PluginCatalogFailureKind.other,
            detail: '$error'),
      };

  static String _describeFailure(HttpClientResponse response) =>
      _failureFor(response).describe();

  /// The response's failure, kind and all.
  static PluginCatalogFailure _failureFor(HttpClientResponse response) {
    final resets = int.tryParse(
      response.headers.value('x-ratelimit-reset') ?? '',
    );
    return failureFor(
      status: response.statusCode,
      remaining: response.headers.value('x-ratelimit-remaining'),
      resetAt: resets == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(resets * 1000),
    );
  }

  /// What to say when a topic search produced nothing, or null to say
  /// nothing and show an empty list.
  ///
  /// A repository with no release yet is not a refusal — the SDK's own
  /// repository carries the topic and publishes no plugin — so nothing found
  /// and nothing refused is a true empty list. Something refused and nothing
  /// found is the case worth speaking up about: that is rate limiting, or a
  /// proxy, or no network, and every one of them used to read as "there are
  /// no plugins".
  ///
  /// One refusal among results that did come back is not worth interrupting
  /// for — the reader has a list, and one repository missing from it is not
  /// something they can act on.
  static String? refusalFor({
    required int found,
    required List<String> refusals,
  }) =>
      found == 0 && refusals.isNotEmpty ? refusals.first : null;

  /// Reads the cached listing, or null when there is none worth using.
  @visibleForTesting
  List<PluginCatalogEntry>? cached({DateTime? now}) {
    final file = cache;
    if (file == null || !file.existsSync()) return null;
    try {
      final json = jsonDecode(file.readAsStringSync());
      if (json is! Map) return null;
      final at = DateTime.tryParse('${json['fetchedAt']}');
      if (at == null) return null;
      final age = (now ?? DateTime.now()).difference(at);
      // A clock that moved backwards leaves a listing from the future. Its
      // age is negative, which is not "fresh for another six hours"; it is a
      // file this cannot reason about.
      if (age.isNegative || age > cacheFor) return null;
      final entries = json['entries'];
      if (entries is! List) return null;
      return [
        for (final entry in entries)
          if (entry is Map<String, dynamic>) PluginCatalogEntry.fromJson(entry),
      ];
    } catch (_) {
      // A half-written or outdated cache costs one search, not a broken
      // plugin list.
      return null;
    }
  }

  /// The listing to use without asking GitHub, if there is one.
  ///
  /// Null when [refresh] is set: that is the reader pressing the button,
  /// which is them saying they want the current answer rather than the one
  /// this has.
  @visibleForTesting
  List<PluginCatalogEntry>? keptFor({required bool refresh, DateTime? now}) =>
      refresh ? null : cached(now: now);

  void _writeCache(List<PluginCatalogEntry> entries, {DateTime? now}) {
    final file = cache;
    if (file == null) return;
    try {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
        jsonEncode({
          'fetchedAt': (now ?? DateTime.now()).toIso8601String(),
          'entries': [for (final entry in entries) entry.toJson()],
        }),
      );
    } catch (_) {
      // Not being able to write it costs a search next time, which is what
      // used to happen every time.
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
    bool refresh = false,
    DateTime? now,
  }) async {
    final kept = keptFor(refresh: refresh, now: now);
    if (kept != null) return kept;
    final client = _client();
    try {
      final searchUrl = Uri.https('api.github.com', '/search/repositories', {
        'q': 'topic:marktext-plus-plugin',
        'per_page': '$perPage',
      });
      final request = await client.getUrl(searchUrl);
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final response = await request.close().answeredWithin(within, 'GitHub');
      if (response.statusCode != HttpStatus.ok) {
        throw PluginCatalogException(_failureFor(response));
      }
      final payload = jsonDecode(await utf8.decoder.bind(response).join());
      if (payload is! Map || payload['items'] is! List) {
        throw const FormatException('GitHub topic response has no items');
      }
      final entries = <PluginCatalogEntry>[];
      // Why a listing can come back empty, when it is not simply empty.
      //
      // Each result needs a second request for its releases, and those are
      // unauthenticated too — sixty an hour against ten searches a minute, so
      // the second kind runs out first. Every one of them used to fail with a
      // bare `continue`, which turned rate limiting, a proxy refusal and a
      // dropped connection alike into "no plugins found": the reader goes
      // looking for a fault in the editor, and the fault is that they should
      // wait a minute.
      final refusals = <String>[];
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
        final releaseResponse =
            await releaseRequest.close().answeredWithin(within, 'GitHub');
        if (releaseResponse.statusCode != HttpStatus.ok) {
          refusals.add('$fullName: ${_describeFailure(releaseResponse)}');
          continue;
        }
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
      final refusal = refusalFor(found: entries.length, refusals: refusals);
      if (refusal != null) throw HttpException(refusal);
      // Written only on a listing that came back whole: a run that hit the
      // limit part way through has fewer plugins than there are, and keeping
      // that for six hours would hide the rest of them for six hours.
      _writeCache(entries, now: now);
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
      final response = await (await client.getUrl(raw))
          .close()
          .answeredWithin(within, "the plugin's README");
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('README returned HTTP ${response.statusCode}');
      }
      return await utf8.decoder.bind(response).join();
    } finally {
      client.close(force: true);
    }
  }

  /// Refuses an address that is not HTTPS.
  ///
  /// The registry's own URL is checked where it is set. This is the other
  /// half, and it was missing: the address a plugin is downloaded from
  /// arrives inside the registry's answer — `Uri.parse` of whatever the JSON
  /// held — and was used as given. Two rules were asked for here, HTTPS and a
  /// matching digest, and only one of them covered both ends.
  ///
  /// A name of its own because the download itself cannot be tested: it
  /// builds a client and talks to the network. The rule can be.
  @visibleForTesting
  static void refuseInsecureDownload(Uri url) {
    if (!url.isScheme('https')) {
      throw FormatException(
        'plugin downloads must use https; this one is "${url.scheme}"',
      );
    }
  }

  /// Whether [bytes] are what the catalog said they would be.
  ///
  /// Compared exactly, not case-insensitively. Hexadecimal digests are
  /// case-insensitive by definition, so this is stricter than it has to be —
  /// and that is the safe side to be wrong on. A difference in case cannot
  /// make a tampered file match; it can only refuse a genuine one, which is
  /// loud, reversible, and nobody's data.
  @visibleForTesting
  static bool digestMatches(List<int> bytes, String expected) =>
      sha256.convert(bytes).toString() == expected;

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
      refuseInsecureDownload(downloadUrl);
      final request = await client.getUrl(downloadUrl);
      final response =
          await request.close().answeredWithin(within, 'the plugin download');
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('plugin download returned ${response.statusCode}');
      }
      final bytes = await response.fold<List<int>>([], (all, chunk) {
        all.addAll(chunk);
        return all;
      });
      if (!digestMatches(bytes, entry.sha256)) {
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

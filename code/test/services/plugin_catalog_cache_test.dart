import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_catalog_service.dart';

/// Discovery is kept between launches, because it is expensive to ask.
///
/// One search plus a request for every repository it finds — up to thirty,
/// against sixty unauthenticated requests an hour. Searching on every launch
/// spent a reader's quota in two or three of them, and what they saw where
/// the plugin list should be was "GitHub is rate-limiting searches from this
/// machine; try again in 819 seconds".
void main() {
  late Directory dir;
  late File cache;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('catalog_cache');
    cache = File('${dir.path}/plugin-catalog.json');
  });
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  PluginCatalogEntry entry(String id) => PluginCatalogEntry(
    id: id,
    name: 'Plugin $id',
    version: '0.1.0',
    downloadUrl: Uri.parse('https://example.invalid/$id.zip'),
    sha256: 'a' * 64,
    description: 'about $id',
    repositoryUrl: Uri.parse('https://example.invalid/$id'),
    releaseNotes: 'what changed',
    publishedAt: DateTime.utc(2026, 9, 1),
    isPrerelease: true,
  );

  void write(List<PluginCatalogEntry> entries, DateTime at) {
    cache.writeAsStringSync(
      jsonEncode({
        'fetchedAt': at.toIso8601String(),
        'entries': [for (final e in entries) e.toJson()],
      }),
    );
  }

  test('an entry survives being written and read', () {
    write([entry('one')], DateTime.utc(2026, 9, 8, 10));
    final kept = PluginCatalogService(
      cache: cache,
    ).cached(now: DateTime.utc(2026, 9, 8, 11))!;

    expect(kept, hasLength(1));
    final only = kept.single;
    expect(only.id, 'one');
    expect(only.name, 'Plugin one');
    expect(only.version, '0.1.0');
    expect(only.downloadUrl, Uri.parse('https://example.invalid/one.zip'));
    expect(only.sha256, 'a' * 64);
    expect(only.description, 'about one');
    expect(only.releaseNotes, 'what changed');
    expect(only.publishedAt, DateTime.utc(2026, 9, 1));
    expect(
      only.isPrerelease,
      isTrue,
      reason: '"0.1.3" 和 "0.1.3 预发布" 不是同一个承诺，读者有权知道拿的是哪个',
    );
  });

  test('a listing kept within the window is used', () {
    write([entry('one')], DateTime.utc(2026, 9, 8, 10));
    expect(
      PluginCatalogService(cache: cache).cached(now: DateTime.utc(2026, 9, 8, 15)),
      isNotNull,
    );
  });

  test('a listing older than the window is not', () {
    write([entry('one')], DateTime.utc(2026, 9, 8, 10));
    expect(
      PluginCatalogService(cache: cache).cached(now: DateTime.utc(2026, 9, 8, 17)),
      isNull,
      reason: '六小时之后该重新去问，否则今早发布的插件今天都找不到',
    );
  });

  test('a listing from the future is not used either', () {
    // A clock that moved back leaves one. Its age is negative, which is not
    // "fresh for another six hours" — it is a file this cannot reason about.
    write([entry('one')], DateTime.utc(2026, 9, 9));
    expect(
      PluginCatalogService(cache: cache).cached(now: DateTime.utc(2026, 9, 8)),
      isNull,
    );
  });

  test('a half-written cache costs a search, not the plugin list', () {
    cache.writeAsStringSync('{"fetchedAt": "2026-09-08T10:00:00Z", "entr');
    expect(PluginCatalogService(cache: cache).cached(), isNull);
  });

  test('no cache file, and no cache at all, both read as nothing kept', () {
    expect(PluginCatalogService(cache: cache).cached(), isNull);
    expect(const PluginCatalogService().cached(), isNull);
  });

  test('an entry the reader cannot fetch is dropped, not carried', () {
    // `fromJson` refuses a download URL that is not HTTPS. One bad entry in
    // the file must not take the rest of the listing with it — but it must
    // not come back either.
    cache.writeAsStringSync(
      jsonEncode({
        'fetchedAt': DateTime.now().toIso8601String(),
        'entries': [
          {
            'id': 'bad',
            'name': 'Bad',
            'version': '1.0.0',
            'downloadUrl': 'http://example.invalid/bad.zip',
            'sha256': 'b' * 64,
          },
        ],
      }),
    );
    expect(PluginCatalogService(cache: cache).cached(), isNull);
  });

  test('the refresh button does not get the kept answer', () {
    write([entry('one')], DateTime.utc(2026, 9, 8, 10));
    final service = PluginCatalogService(cache: cache);
    final now = DateTime.utc(2026, 9, 8, 11);

    expect(
      service.keptFor(refresh: false, now: now),
      isNotNull,
      reason: '一小时前的结果，开编辑器时该直接用',
    );
    expect(
      service.keptFor(refresh: true, now: now),
      isNull,
      reason: '读者按了刷新，就是要现在的答案',
    );
  });
}

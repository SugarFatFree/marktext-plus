import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_catalog_service.dart';

void main() {
  test('catalog entries require HTTPS and a digest', () {
    final entry = PluginCatalogEntry.fromJson({
      'id': 'com.example.demo',
      'name': 'Demo',
      'version': '1.0.0',
      'downloadUrl': 'https://example.com/demo.zip',
      'sha256': 'ABC123',
      'repository': 'https://github.com/example/demo',
    });
    expect(entry.downloadUrl!.scheme, 'https');
    expect(entry.sha256, 'abc123');
    expect(entry.repositoryUrl.toString(), 'https://github.com/example/demo');
    expect(
      () => PluginCatalogEntry.fromJson({
        'id': 'bad',
        'name': 'Bad',
        'version': '1.0.0',
        'downloadUrl': 'http://example.com/bad.zip',
        'sha256': 'abc',
      }),
      throwsFormatException,
    );
  });

  group('an empty topic search', () {
    // Every result needs a second, unauthenticated request for its releases,
    // and those run out before the search does — sixty an hour against ten
    // searches a minute. Each of those failures used to be a bare `continue`,
    // so rate limiting, a proxy refusal and a dropped connection all reached
    // the reader as "no plugins found", which sends them looking for a fault
    // in the editor when the answer is to wait a minute.
    test('says why when everything was refused', () {
      expect(
        PluginCatalogService.refusalFor(
          found: 0,
          refusals: const ['owner/one: GitHub is rate-limiting searches'],
        ),
        contains('rate-limiting'),
      );
    });

    test('stays quiet when there was simply nothing to find', () {
      // The SDK's own repository carries the topic and publishes no plugin,
      // so a search that finds only repositories without releases is a true
      // empty list, not a failure.
      expect(
        PluginCatalogService.refusalFor(found: 0, refusals: const []),
        isNull,
      );
    });

    test('does not interrupt a list that did come back', () {
      // One repository missing from a list the reader can use is not
      // something they can act on.
      expect(
        PluginCatalogService.refusalFor(
          found: 3,
          refusals: const ['owner/one: GitHub topic search returned 500'],
        ),
        isNull,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_catalog_service.dart';

/// What a plugin's release says about itself reaches the detail page.
///
/// The entry carried a name, a version and the repository description, and
/// nothing about the release: the detail page showed the README and had no
/// version on it and no word of what had changed, which is the one thing
/// someone deciding whether to install or update is looking for.
void main() {
  test('an entry keeps the release notes and when it was published', () {
    final entry = PluginCatalogEntry.fromJson({
      'id': 'com.example.demo',
      'name': 'Demo',
      'version': 'v1.2.0',
      'downloadUrl': 'https://example.com/p.zip',
      'sha256': 'abc',
      'releaseNotes': '### Fixed\n- the thing',
      'publishedAt': '2026-09-03T10:00:00Z',
    });

    expect(entry.releaseNotes, contains('the thing'));
    expect(entry.publishedAt, DateTime.utc(2026, 9, 3, 10));
  });

  test('a release with no notes is empty rather than missing', () {
    final entry = PluginCatalogEntry.fromJson({
      'id': 'com.example.demo',
      'name': 'Demo',
      'version': 'v1.2.0',
      'downloadUrl': 'https://example.com/p.zip',
      'sha256': 'abc',
    });

    expect(entry.releaseNotes, isEmpty);
    expect(entry.publishedAt, isNull);
  });

  test('a date nobody can parse does not stop the plugin being listed', () {
    final entry = PluginCatalogEntry.fromJson({
      'id': 'com.example.demo',
      'name': 'Demo',
      'version': 'v1.2.0',
      'downloadUrl': 'https://example.com/p.zip',
      'sha256': 'abc',
      'publishedAt': 'last Tuesday',
    });

    expect(entry.publishedAt, isNull);
  });
}

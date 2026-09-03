import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_catalog_service.dart';

/// A community plugin is found even before it calls itself finished.
///
/// Discovery asked GitHub for `releases/latest`, and that endpoint leaves out
/// pre-releases entirely. Every plugin here is Community/Unverified and most
/// will sit at 0.x for a long time, so the one kind of release they actually
/// publish was the one kind the editor could not see.
void main() {
  Map<String, dynamic> release(
    String tag, {
    bool prerelease = false,
    String? published,
    bool draft = false,
  }) =>
      {
        'tag_name': tag,
        'prerelease': prerelease,
        'draft': draft,
        'published_at': published,
        'assets': const [],
      };

  test('a pre-release is the newest release when it is the newest', () {
    final chosen = PluginCatalogService.newestRelease([
      release('v0.1.0', prerelease: true, published: '2026-08-01T00:00:00Z'),
      release('v0.2.0', prerelease: true, published: '2026-09-03T00:00:00Z'),
    ]);

    expect(chosen?['tag_name'], 'v0.2.0');
  });

  test('a finished release still wins when it is the newer one', () {
    final chosen = PluginCatalogService.newestRelease([
      release('v0.2.0', prerelease: true, published: '2026-08-01T00:00:00Z'),
      release('v1.0.0', published: '2026-09-03T00:00:00Z'),
    ]);

    expect(chosen?['tag_name'], 'v1.0.0');
  });

  test('a draft is nobody business but its author', () {
    final chosen = PluginCatalogService.newestRelease([
      release('v0.1.0', prerelease: true, published: '2026-08-01T00:00:00Z'),
      release('v9.9.9', draft: true, published: '2026-09-03T00:00:00Z'),
    ]);

    expect(chosen?['tag_name'], 'v0.1.0',
        reason: '草稿还没发布，不该被当成可安装的版本');
  });

  test('a release with no date is not treated as the newest', () {
    final chosen = PluginCatalogService.newestRelease([
      release('v0.1.0', prerelease: true, published: '2026-08-01T00:00:00Z'),
      release('v0.0.1', published: null),
    ]);

    expect(chosen?['tag_name'], 'v0.1.0');
  });

  test('a repository with no releases at all offers nothing', () {
    expect(PluginCatalogService.newestRelease(const []), isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_catalog_service.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';

/// An installed plugin has a detail page too.
///
/// The page was built from a catalog entry, which only a search produces.
/// Installing therefore took the page away: clicking the plugin in the
/// installed list did nothing at all, and the version and notes that had been
/// there a moment ago were gone.
void main() {
  PluginManifest manifest(Map<String, dynamic> extra) =>
      PluginManifest.fromJson({
        'id': 'com.example.demo',
        'name': 'Demo',
        'version': '1.2.0',
        'runtime': 'lua',
        'entrypoint': 'plugin.lua',
        ...extra,
      });

  test('an installed plugin can be shown on the same page', () {
    final entry = PluginCatalogEntry.installed(manifest({}));

    expect(entry.id, 'com.example.demo');
    expect(entry.name, 'Demo');
    expect(entry.version, '1.2.0');
    expect(entry.isInstalled, isTrue,
        reason: '页面据此把 Install 换成 Installed，而不是再装一遍');
  });

  test('a community entry is not marked as installed', () {
    final entry = PluginCatalogEntry(
      id: 'com.example.demo',
      name: 'Demo',
      version: '1.0.0',
      downloadUrl: Uri.https('example.com', '/p.zip'),
      sha256: 'abc',
    );

    expect(entry.isInstalled, isFalse);
  });

  test('an installed plugin with no repository has nothing to fetch', () {
    final entry = PluginCatalogEntry.installed(manifest({}));

    expect(entry.repositoryUrl, isNull,
        reason: '没有仓库地址就不该去拉 README，那会变成一个说不清的错误');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/models/plugin_catalog_entry.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';

/// What the discover list should say about a plugin the reader already has.
///
/// It offered a download button for every result, installed or not: the list
/// that had just installed something showed no sign of it, and the only way
/// to find out was to press download again.
void main() {
  PluginCatalogEntry result(String id, String version) => PluginCatalogEntry(
    id: id,
    name: 'Demo',
    version: version,
    downloadUrl: Uri.parse('https://example.test/$id-$version.zip'),
    sha256: 'a' * 64,
  );

  PluginManifest installed(String id, String version) => PluginManifest(
    id: id,
    name: 'Demo',
    version: version,
    entrypoint: 'plugin.lua',
    runtime: PluginRuntime.lua,
  );

  test('nothing installed leaves every result installable', () {
    expect(
      PluginInstallState.of(result('a', '1.0.0'), const []),
      PluginInstallState.installable,
    );
  });

  test('the same plugin at the same version is installed', () {
    expect(
      PluginInstallState.of(result('a', '1.0.0'), [installed('a', '1.0.0')]),
      PluginInstallState.installed,
    );
  });

  test('a newer version in the catalogue is an update, not "installed"', () {
    // Saying "installed" here would hide the update behind a disabled button,
    // which is how the reader would stop getting them.
    expect(
      PluginInstallState.of(result('a', '1.1.0'), [installed('a', '1.0.0')]),
      PluginInstallState.updatable,
    );
  });

  test('an older version in the catalogue is not an update', () {
    expect(
      PluginInstallState.of(result('a', '0.9.0'), [installed('a', '1.0.0')]),
      PluginInstallState.installed,
    );
  });

  test('a different plugin does not mark this one installed', () {
    expect(
      PluginInstallState.of(result('a', '1.0.0'), [installed('b', '1.0.0')]),
      PluginInstallState.installable,
    );
  });

  test('a version that cannot be compared is treated as installed', () {
    // Two unreadable versions say nothing about which is newer. Offering an
    // update on that basis would download the same thing over and over.
    expect(
      PluginInstallState.of(result('a', 'nightly'), [installed('a', 'dev')]),
      PluginInstallState.installed,
    );
  });
}

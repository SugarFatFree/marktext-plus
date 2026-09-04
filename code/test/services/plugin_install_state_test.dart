import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/models/plugin_catalog_entry.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';

/// What the discover list should say about a plugin the reader already has.
///
/// It offered a download button for every result, installed or not: the list
/// that had just installed something showed no sign of it, and the only way
/// to find out was to press download again.
void main() {
  // The two ids are not the same kind of thing, and never match. A catalogue
  // entry is identified by the repository it was found in — `github.owner.repo`
  // — and an installed plugin by whatever its manifest calls itself. Testing
  // both sides with one id was testing a world that does not exist: every
  // discovered plugin looked uninstalled, however many times it had been.
  PluginCatalogEntry result(
    String repo,
    String version, {
    bool prerelease = false,
  }) => PluginCatalogEntry(
    id: 'github.example.$repo',
    name: 'Demo',
    version: version,
    downloadUrl: Uri.parse('https://example.test/$repo-$version.zip'),
    sha256: 'a' * 64,
    repositoryUrl: Uri.parse('https://github.com/example/$repo'),
    isPrerelease: prerelease,
  );

  PluginManifest installed(String repo, String version) => PluginManifest(
    id: 'com.example.demo',
    name: 'Demo',
    version: version,
    entrypoint: 'plugin.lua',
    runtime: PluginRuntime.lua,
    repository: 'https://github.com/example/$repo',
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

  test('a plugin that names no repository is nobody', () {
    // Not a match with everything else that also names none.
    const anonymous = PluginManifest(
      id: 'com.example.demo',
      name: 'Demo',
      version: '1.0.0',
      entrypoint: 'plugin.lua',
      runtime: PluginRuntime.lua,
    );
    expect(
      PluginInstallState.of(result('a', '1.0.0'), const [anonymous]),
      PluginInstallState.installable,
    );
  });

  test('a trailing slash, a .git, or different case is one repository', () {
    final entry = result('a', '1.0.0');
    for (final written in [
      'https://github.com/example/a/',
      'https://github.com/example/a.git',
      'https://github.com/Example/A',
    ]) {
      expect(
        PluginInstallState.of(entry, [
          PluginManifest(
            id: 'com.example.demo',
            name: 'Demo',
            version: '1.0.0',
            entrypoint: 'plugin.lua',
            runtime: PluginRuntime.lua,
            repository: written,
          ),
        ]),
        PluginInstallState.installed,
        reason: '$written 指的是同一个仓库',
      );
    }
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

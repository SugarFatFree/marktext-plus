import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/models/plugin_catalog_entry.dart';
import 'package:marktext_plus/providers/mcp_provider.dart';

/// Which plugin `install_plugin` decides to install.
///
/// The action reaches the network twice — once for the listing, once for the
/// archive — and neither of those is what can go wrong here. What can is the
/// step between them: a name, a listing, and the decision about which entry
/// the name meant. Installing the wrong plugin is the failure worth spending
/// a test on, and it is the one no download check would catch, because the
/// archive that arrives is genuine and its digest matches.
void main() {
  PluginCatalogEntry entry(String owner, String repo) => PluginCatalogEntry(
        id: 'github.$owner.$repo',
        name: repo,
        version: 'v1.0.0',
        downloadUrl: Uri.https('example.invalid', '/$repo.zip'),
        sha256: 'x',
        repositoryUrl: Uri.https('github.com', '/$owner/$repo'),
      );

  final assistant = entry('example-plugins', 'ai-assistant');
  final other = entry('someone', 'other-plugin');

  test('a name that fits exactly one entry chooses it', () {
    final chosen =
        McpController.chooseForInstall('someone/other-plugin', [assistant, other]);
    expect(chosen.refusal, isNull);
    expect(chosen.entry, same(other));
  });

  test('an installed plugin is reached through the repository it declares', () {
    final chosen = McpController.chooseForInstall(
      'com.marktext.ai-assistant',
      [assistant, other],
      repository: 'https://github.com/example-plugins/ai-assistant.git',
    );
    expect(chosen.entry, same(assistant));
  });

  test('a name nothing answers to is refused, and says what was there', () {
    final chosen =
        McpController.chooseForInstall('nobody/nothing', [assistant, other]);
    expect(chosen.entry, isNull);
    // Not merely "no such plugin": the same sentence has to tell a typo apart
    // from a listing that came back short, and only the listing can do that.
    expect(chosen.refusal, contains('nobody/nothing'));
    expect(chosen.refusal, contains('github.example-plugins.ai-assistant'));
    expect(chosen.refusal, contains('github.someone.other-plugin'));
  });

  test('an empty catalogue says so rather than listing nothing', () {
    final chosen = McpController.chooseForInstall('anything', []);
    expect(chosen.refusal, contains('came back empty'));
    // "the catalogue has 0: " with an empty list after it reads as a bug in
    // the message, and sends the reader looking in the wrong place.
    expect(chosen.refusal, isNot(contains('has 0')));
  });

  test('a name that fits two entries is refused, not guessed', () {
    // Both are reachable as `ai-assistant` would be if two owners published
    // under it; the catalogue id differs, the short name does not.
    final twin = entry('example-plugins', 'ai-assistant');
    final chosen = McpController.chooseForInstall(
      'com.marktext.ai-assistant',
      [assistant, twin],
      repository: 'https://github.com/example-plugins/ai-assistant',
    );
    expect(chosen.entry, isNull, reason: '两个都答应这个名字时不能挑一个装');
    expect(chosen.refusal, contains('names 2 plugins'));
  });

  test('no name at all is refused before anything is read', () {
    for (final nothing in ['', '   ']) {
      final chosen = McpController.chooseForInstall(nothing, [assistant]);
      expect(chosen.entry, isNull, reason: '空名字不能装到「第一个」上');
      expect(chosen.refusal, 'no pluginId given');
    }
  });
}

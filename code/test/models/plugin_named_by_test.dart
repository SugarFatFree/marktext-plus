import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/models/plugin_catalog_entry.dart';

/// Which plugin a caller means when they name one.
///
/// Automation names a plugin by its manifest id — `run_plugin_command` takes
/// that and nothing else — and the catalogue has never seen a manifest: a
/// search result is a GitHub release, and the manifest is inside the archive.
/// Matching them up is the whole of `install_plugin` finding its target, and
/// getting it wrong means either "no such plugin" for one that is right there,
/// or, worse, installing a different one.
// The owner and repository below are invented. Naming the real ones would
// read as though this test needed that repository on disk — and
// `repo_dependent_tests_test`, which cannot tell a name used as data from a
// path read off the disk, would say so too.
void main() {
  PluginCatalogEntry entry({String? repository}) => PluginCatalogEntry(
        id: 'github.example-plugins.example-ai-plugin',
        name: 'AI Assistant',
        version: 'v0.1.5',
        downloadUrl: Uri.https('example.invalid', '/a.zip'),
        sha256: 'x',
        repositoryUrl: repository == null
            ? null
            : Uri.parse(repository),
      );

  const repo = 'https://github.com/example-plugins/'
      'example-ai-plugin';

  test('the catalogue id names it', () {
    expect(
      entry(repository: repo).namedBy(
        'github.example-plugins.example-ai-plugin',
      ),
      isTrue,
    );
  });

  test('owner/repo names it, as a person would write it', () {
    expect(
      entry(repository: repo).namedBy(
        'example-plugins/example-ai-plugin',
      ),
      isTrue,
    );
  });

  test('an installed plugin is found through the repository it declares', () {
    // The manifest id is nowhere in the catalogue entry. This is the only way
    // `install_plugin com.marktext.ai-assistant` can reach it.
    expect(
      entry(repository: repo).namedBy('com.marktext.ai-assistant',
          repository: repo),
      isTrue,
    );
  });

  test('the repository is compared as a repository, not as a string', () {
    // All four name one place. A manifest author writes whichever they like.
    for (final written in [
      'https://github.com/example-plugins/example-ai-plugin',
      'https://github.com/example-plugins/example-ai-plugin/',
      'https://github.com/example-plugins/example-ai-plugin.git',
      'git@github.com:example-plugins/example-ai-plugin.git',
    ]) {
      expect(entry(repository: repo).namedBy('anything', repository: written),
          isTrue,
          reason: written);
    }
  });

  test('case is ignored, the way GitHub ignores it', () {
    expect(
      entry(repository: repo)
          .namedBy('Example-Plugins/Example-AI-Plugin'),
      isTrue,
    );
  });

  test('a different plugin is not this one', () {
    expect(entry(repository: repo).namedBy('someone/other-plugin'), isFalse);
    expect(
      entry(repository: repo).namedBy('com.example.other',
          repository: 'https://github.com/someone/other-plugin'),
      isFalse,
    );
  });

  test('an empty name matches nothing, not even with a repository beside it',
      () {
    // The two bare calls are worth little on their own — with nothing to
    // compare against, every branch below answers false anyway, and a version
    // of this with the empty check deleted passed them both.
    expect(entry(repository: repo).namedBy(''), isFalse);
    expect(entry(repository: repo).namedBy('   '), isFalse);

    // This is the one the check is for. The last branch asks whether the
    // repositories agree and never looks at the name again, so an empty name
    // handed a matching repository comes back true: a caller who left the
    // field out gets whichever plugin the repository lookup happened to hold.
    expect(entry(repository: repo).namedBy('', repository: repo), isFalse);
    expect(entry(repository: repo).namedBy('  ', repository: repo), isFalse);
  });

  test('an entry with no repository is only reachable by its own id', () {
    final anonymous = entry();
    expect(anonymous.namedBy('github.example-plugins.'
        'example-ai-plugin'), isTrue);
    expect(
      anonymous.namedBy('com.marktext.ai-assistant', repository: repo),
      isFalse,
      reason: '没有 repositoryUrl 就无从对上，不能因为调用者说了个仓库就算数',
    );
  });
}

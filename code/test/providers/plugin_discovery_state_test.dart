import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/providers/plugin_provider.dart';
import 'package:marktext_plus/services/plugin_catalog_service.dart';

/// A community search survives leaving the plugin panel.
///
/// The results lived in the panel widget's own State, and the side bar
/// destroys the panel when another tab is chosen. Going to Files and back
/// therefore threw away a search that had just cost a network round trip, with
/// nothing to say why the list had emptied.
void main() {
  test('discovered plugins are remembered outside the panel', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(pluginDiscoveryProvider).results, isNull,
        reason: '还没搜索过，和"搜过但没结果"是两回事');

    container.read(pluginDiscoveryProvider.notifier).succeeded([
      PluginCatalogEntry(
        id: 'com.example.demo',
        name: 'Demo',
        version: '1.0.0',
        downloadUrl: Uri.https('example.com', '/p.zip'),
        sha256: 'abc',
      ),
    ]);

    // What the panel does when it is built again: read, not search.
    expect(container.read(pluginDiscoveryProvider).results, hasLength(1));
    expect(container.read(pluginDiscoveryProvider).searching, isFalse);
  });

  test('a search that found nothing is not the same as no search', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(pluginDiscoveryProvider.notifier).succeeded(const []);

    expect(container.read(pluginDiscoveryProvider).results, isEmpty);
    expect(container.read(pluginDiscoveryProvider).results, isNotNull,
        reason: '搜过但没结果要能和"没搜过"区分，否则界面无话可说');
  });

  test('a failed search keeps its reason', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(pluginDiscoveryProvider.notifier).failed('no network');

    expect(container.read(pluginDiscoveryProvider).error, 'no network');
    expect(container.read(pluginDiscoveryProvider).searching, isFalse);
  });
}

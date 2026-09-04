import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/providers/plugin_provider.dart';

/// Searching for community plugins the first time the panel is opened.
///
/// Once per launch, not once per visit: the side bar destroys the panel every
/// time another tab is chosen, so "on open" would be a network request each
/// time the reader glanced at Files and came back.
void main() {
  test('the first look asks for a search', () {
    final discovery = PluginDiscoveryNotifier();
    expect(discovery.shouldSearchOnOpen, isTrue);
  });

  test('and having searched, it does not ask again', () {
    final discovery = PluginDiscoveryNotifier();
    discovery.started();
    expect(
      discovery.shouldSearchOnOpen,
      isFalse,
      reason: '已经在搜了，再发一次就是白费一次网络往返',
    );
    discovery.succeeded(const []);
    expect(discovery.shouldSearchOnOpen, isFalse);
  });

  test('a search that failed is not retried on its own', () {
    // The reader has a button. Retrying by itself every time they look at the
    // panel turns one broken network into a request per glance.
    final discovery = PluginDiscoveryNotifier();
    discovery.started();
    discovery.failed('no network');
    expect(discovery.shouldSearchOnOpen, isFalse);
  });

  test('results that came back are still there on the next visit', () {
    final discovery = PluginDiscoveryNotifier();
    discovery.started();
    discovery.succeeded(const []);
    expect(discovery.state.results, isNotNull);
    expect(discovery.shouldSearchOnOpen, isFalse);
  });
}

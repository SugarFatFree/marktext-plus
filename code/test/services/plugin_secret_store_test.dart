import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_secret_store.dart';

void main() {
  test('secret bridge reads only the requested reference', () async {
    final store = MemorySecretStore({'openai': 'secret'});
    final bridge = PluginSecretBridge(store);

    expect(await bridge.resolve('openai'), 'secret');
    expect(await bridge.resolve('missing'), isNull);
  });

  test('memory adapter supports replacement and deletion for tests', () async {
    final store = MemorySecretStore();
    await store.write('key', 'value');
    expect(await store.read('key'), 'value');
    await store.delete('key');
    expect(await store.read('key'), isNull);
  });
}

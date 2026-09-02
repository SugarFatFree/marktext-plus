import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';

void main() {
  test('manifest rejects missing identity and keeps capabilities immutable', () {
    expect(
      () => PluginManifest.fromJson({'name': 'broken'}),
      throwsFormatException,
    );

    final manifest = PluginManifest.fromJson({
      'id': 'com.example.theme',
      'name': 'Example Theme',
      'version': '1.0.0',
      'entrypoint': 'bin/plugin.exe',
      'capabilities': ['theme', 'command'],
    });

    expect(manifest.id, 'com.example.theme');
    expect(manifest.capabilities, containsAll(['theme', 'command']));
    expect(() => manifest.capabilities.add('network'), throwsUnsupportedError);
  });
}

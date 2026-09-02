import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_catalog_service.dart';

void main() {
  test('catalog entries require HTTPS and a digest', () {
    final entry = PluginCatalogEntry.fromJson({
      'id': 'com.example.demo',
      'name': 'Demo',
      'version': '1.0.0',
      'downloadUrl': 'https://example.com/demo.zip',
      'sha256': 'ABC123',
      'repository': 'https://github.com/example/demo',
    });
    expect(entry.downloadUrl.scheme, 'https');
    expect(entry.sha256, 'abc123');
    expect(entry.repositoryUrl.toString(), 'https://github.com/example/demo');
    expect(
      () => PluginCatalogEntry.fromJson({
        'id': 'bad',
        'name': 'Bad',
        'version': '1.0.0',
        'downloadUrl': 'http://example.com/bad.zip',
        'sha256': 'abc',
      }),
      throwsFormatException,
    );
  });
}

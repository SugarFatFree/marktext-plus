import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';

/// What the plugin list shows about a plugin, and in whose language.
///
/// The list showed a bare name and nothing else. A reader deciding whether to
/// keep a plugin has the same question as one deciding whether to install it —
/// what does it do — and the installed list was the one place that could not
/// answer it.
void main() {
  PluginManifest parse(Map<String, dynamic> json) =>
      PluginManifest.fromJson(json);

  const base = {
    'id': 'com.example.demo',
    'name': 'Demo',
    'version': '1.0.0',
    'entrypoint': 'plugin.lua',
    'runtime': 'lua',
  };

  test('a manifest carries a description', () {
    final manifest = parse({...base, 'description': 'Does a thing.'});
    expect(manifest.description, 'Does a thing.');
  });

  test('a manifest without one has an empty description, not a crash', () {
    expect(parse(base).description, isEmpty);
  });

  test('the description survives a round trip', () {
    final manifest = parse({...base, 'description': 'Does a thing.'});
    expect(
      PluginManifest.fromJson(manifest.toJson()).description,
      'Does a thing.',
    );
  });

  test('a manifest with no description does not write an empty one', () {
    expect(parse(base).toJson().containsKey('description'), isFalse);
  });

  group('the plugin\'s own languages', () {
    final manifest = parse({
      ...base,
      'name': 'plugin.name',
      'description': 'plugin.description',
      'defaultLocale': 'en',
      'locales': {
        'en': {
          'plugin.name': 'Demo Plugin',
          'plugin.description': 'Does a thing.',
        },
        'zh': {'plugin.name': '演示插件'},
      },
    });

    test('the name and description are looked up like any other string', () {
      final strings = manifest.stringsFor('en');
      expect(strings[manifest.name], 'Demo Plugin');
      expect(strings[manifest.description], 'Does a thing.');
    });

    test('a language that translated only some keys keeps the rest', () {
      // The Chinese map has the name and not the description. Returning that
      // map alone left the description showing its own key — the reader saw
      // the literal `plugin.description` where a sentence belonged.
      final strings = manifest.stringsFor('zh_CN');
      expect(
        strings['plugin.name'],
        '演示插件',
        reason: 'the translated key must win over the default language',
      );
      expect(
        strings['plugin.description'],
        'Does a thing.',
        reason: 'an untranslated key must fall back, not disappear',
      );
    });

    test('a language with no map at all falls back whole', () {
      expect(manifest.stringsFor('ko')['plugin.name'], 'Demo Plugin');
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manager.dart';

/// A plugin that is installed and cannot be read.
///
/// `loadInstalled` ignores it, which is right — one broken plugin must not
/// stop the editor from starting, and it does not. But it was ignored in
/// silence: the plugin simply did not appear in the list, and the reader had
/// installed something that was not there, with nothing to say why.
///
/// The reasons were written and never delivered. `PluginManifest.fromJson`
/// refuses a manifest with a sentence naming the key and what was expected —
/// "unknown operating system in "entrypoints": windwos. Expected one of
/// windows, macos, linux" — and that sentence reached nobody at all.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('problems_'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  void install(String directory, Object manifest) {
    Directory('${root.path}/$directory').createSync(recursive: true);
    File(
      '${root.path}/$directory/manifest.json',
    ).writeAsStringSync(manifest is String ? manifest : jsonEncode(manifest));
  }

  const good = {
    'id': 'com.example.good',
    'name': 'Good',
    'version': '1.0.0',
    'runtime': 'lua',
    'entrypoint': 'plugin.lua',
  };

  test('a plugin that reads is not a problem', () async {
    install('good', good);
    final manager = PluginManager(root.path);

    expect((await manager.loadInstalled()).single.id, 'com.example.good');
    expect(await manager.problems(), isEmpty);
  });

  test(
    'a broken manifest is reported with the reason it was refused',
    () async {
      install('good', good);
      install('broken', {
        ...good,
        'id': 'com.example.broken',
        'runtime': 'perl',
      });
      final manager = PluginManager(root.path);

      // The good one still loads: a broken neighbour cannot take it down.
      expect((await manager.loadInstalled()).single.id, 'com.example.good');

      final problems = await manager.problems();
      expect(problems, hasLength(1));
      expect(problems.single.directory, 'broken');
      expect(
        problems.single.problem,
        contains('perl'),
        reason: '这句话本来就写好了，只是从来没人看见',
      );
    },
  );

  test('a manifest that is not JSON at all is reported too', () async {
    install('rubbish', '{ not json');
    final problems = await PluginManager(root.path).problems();

    expect(problems.single.directory, 'rubbish');
    expect(problems.single.problem, isNotEmpty);
  });

  test(
    'a directory with no manifest is not a plugin, and not a problem',
    () async {
      Directory('${root.path}/notaplugin').createSync(recursive: true);
      expect(
        await PluginManager(root.path).problems(),
        isEmpty,
        reason: '插件目录里放个普通文件夹，不该被说成坏插件',
      );
    },
  );

  test('nothing installed at all is not a problem', () async {
    expect(await PluginManager('${root.path}/missing').problems(), isEmpty);
  });
}

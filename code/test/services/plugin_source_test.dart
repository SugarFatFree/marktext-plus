import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manager.dart';

/// Where a plugin came from, remembered at install time.
///
/// The list can say what a plugin is and what version it is, but not whether
/// the reader took a pre-release — the manifest does not carry that, and the
/// release it came from is not on disk. Guessing from "0.x" would be a guess:
/// plenty of finished software is 0.x, and a 1.0.0 pre-release is possible.
void main() {
  late Directory root;
  late PluginManager manager;

  setUp(() {
    root = Directory.systemTemp.createTempSync('sources_');
    manager = PluginManager(root.path);
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('a plugin nobody recorded has no source', () async {
    expect(await manager.sourceOf('com.example.demo'), isNull);
  });

  test('what was recorded comes back', () async {
    await manager.recordSource(
      'com.example.demo',
      const PluginSource(prerelease: true, tag: 'v0.1.3'),
    );
    final source = await manager.sourceOf('com.example.demo');
    expect(source?.prerelease, isTrue);
    expect(source?.tag, 'v0.1.3');
  });

  test('a second plugin does not overwrite the first', () async {
    await manager.recordSource(
      'com.example.one',
      const PluginSource(prerelease: true, tag: 'v0.1.3'),
    );
    await manager.recordSource(
      'com.example.two',
      const PluginSource(prerelease: false, tag: 'v2.0.0'),
    );
    expect((await manager.sourceOf('com.example.one'))?.prerelease, isTrue);
    expect((await manager.sourceOf('com.example.two'))?.prerelease, isFalse);
  });

  test('reinstalling replaces what was recorded', () async {
    await manager.recordSource(
      'com.example.demo',
      const PluginSource(prerelease: true, tag: 'v0.1.3'),
    );
    await manager.recordSource(
      'com.example.demo',
      const PluginSource(prerelease: false, tag: 'v1.0.0'),
    );
    final source = await manager.sourceOf('com.example.demo');
    expect(source?.prerelease, isFalse, reason: '装了正式版之后，列表不该还说这是预发布');
    expect(source?.tag, 'v1.0.0');
  });

  test('uninstalling forgets where it came from', () async {
    await manager.recordSource(
      'com.example.demo',
      const PluginSource(prerelease: true, tag: 'v0.1.3'),
    );
    await manager.forgetSource('com.example.demo');
    expect(await manager.sourceOf('com.example.demo'), isNull);
  });

  test('a corrupt file is no sources, not a crash', () async {
    File('${root.path}/sources.json').writeAsStringSync('not json at all');
    expect(await manager.sourceOf('com.example.demo'), isNull);
    // And it can be written to again.
    await manager.recordSource(
      'com.example.demo',
      const PluginSource(prerelease: true, tag: 'v0.1.3'),
    );
    expect((await manager.sourceOf('com.example.demo'))?.tag, 'v0.1.3');
  });
}

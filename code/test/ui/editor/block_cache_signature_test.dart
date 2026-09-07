import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Everything the cached blocks are drawn from has to reach the signature.
///
/// The preview keeps each block widget it has built and reuses it until a
/// signature changes. The signature is a hand-written tuple, and a setting
/// missing from it is a setting the reader can change with no effect: the
/// blocks come back from the cache, the code that would have read the new
/// value never runs, and even a `ref.watch` inside that code is never
/// re-registered.
///
/// It has drifted twice. `imageRevision` was absent, so "reload images" did
/// nothing at all — the key it built still said `image:0:` afterwards. Then
/// the code font settings were absent, so changing the code font size left
/// the preview at the old size.
///
/// A list written by hand beside the values it is supposed to track is the
/// thing this repository keeps getting wrong, so it is reconciled here rather
/// than watched.
void main() {
  /// Settings read while drawing, that the signature does not need.
  ///
  /// Each one has to be read somewhere the block cache cannot hold it — the
  /// outer tree, rebuilt whole on every build. Adding a name here without
  /// that being true puts the drift back.
  const exempt = <String, String>{
    'editorMaxWidth':
        '外层 ConstrainedBox，不在被缓存的块里，每次 build 都重新应用',
  };

  test('every setting the preview draws from is in the block signature', () {
    final source =
        File('lib/ui/editor/markdown_renderer.dart').readAsStringSync();

    // The signature tuple, from `final signature = (` to its closing line.
    final start = source.indexOf('final signature = (');
    expect(start, greaterThan(0), reason: '找不到签名，这条守卫已失效');
    final end = source.indexOf(');', start);
    final signature = source.substring(start, end);

    Set<String> settingsIn(String text) => {
          for (final line in text.split('\n'))
            if (!line.trimLeft().startsWith('import'))
              ...RegExp(
                r'\bconfig\.(\w+)|ref\.(?:read|watch)\(settingsProvider\)\.(\w+)',
              ).allMatches(line).map((m) => m.group(1) ?? m.group(2)!),
        };

    final drawn = settingsIn(source);
    final tracked = settingsIn(signature);
    expect(drawn, isNotEmpty, reason: '一个设置都没扫到，这条守卫已失效');
    expect(tracked, isNotEmpty, reason: '签名里一个设置都没扫到');

    final missing = drawn.difference(tracked).difference(exempt.keys.toSet());
    expect(
      missing,
      isEmpty,
      reason: '这些设置画进了块里却不在签名中，改了它们预览不会更新：$missing\n'
          '确实不需要的，加进 exempt 并写明为什么',
    );
  });
}

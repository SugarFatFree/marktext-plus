import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What the release workflow promises to publish.
///
/// `softprops/action-gh-release` skips a file it cannot find and still
/// succeeds, so a name in the list that no job ever produces costs nothing at
/// build time and everything at download time: the release page simply has no
/// such asset, and the workflow reports success. Two macOS x64 files were
/// listed that way through several releases.
void main() {
  late String workflow;

  /// The workflow with its expression syntax flattened.
  ///
  /// `${{ matrix.arch }}` contains spaces, which makes a filename impossible
  /// to pick out of a shell line by scanning to the next space. Collapsing
  /// every placeholder to a single token first is what makes the names
  /// tokenisable at all.
  late String flat;

  setUp(() {
    workflow = File('../.github/workflows/release.yml').readAsStringSync();
    flat = workflow
        .replaceAll(RegExp(r'\$\{\{ github\.ref_name \}\}'), 'TAG')
        .replaceAllMapped(
          RegExp(r'\$\{\{ matrix\.(\w+) \}\}'),
          (m) => '<${m.group(1)}>',
        );
  });

  Set<String> assetsIn(String block) => RegExp(r'marktext-plus-TAG-([\w.<>-]+)')
      .allMatches(block)
      .map((m) => m.group(1)!)
      .toSet();

  /// Every value the build matrix declares, by key.
  Map<String, Set<String>> matrixValues() {
    final block = flat.substring(
      flat.indexOf('matrix:'),
      flat.indexOf('runs-on: <runner>'),
    );
    final values = <String, Set<String>>{};
    for (final line
        in RegExp(r'^\s+-?\s*(\w+): ([\w.-]+)$', multiLine: true)
            .allMatches(block)) {
      values.putIfAbsent(line.group(1)!, () => {}).add(line.group(2)!);
    }
    return values;
  }

  Set<String> expand(Set<String> names, Map<String, Set<String>> matrix) {
    final out = <String>{};
    for (final name in names) {
      final key = RegExp(r'<(\w+)>').firstMatch(name);
      if (key == null) {
        out.add(name);
        continue;
      }
      for (final value in matrix[key.group(1)!] ?? const <String>{}) {
        out.add(name.replaceAll('<${key.group(1)}>', value));
      }
    }
    return out;
  }

  String publishBlock() {
    final start = flat.indexOf('name: Create Release');
    expect(start, greaterThan(0), reason: '找不到发布步骤');
    return flat.substring(start);
  }

  test('every published asset is one some job actually builds', () {
    final promised = assetsIn(publishBlock());
    final produced = expand(
      assetsIn(flat.substring(0, flat.indexOf('name: Create Release'))),
      matrixValues(),
    );

    expect(promised, isNotEmpty, reason: '一个产物都没解析出来，说明解析写错了');
    expect(promised.difference(produced), isEmpty,
        reason: '发布清单里有没人产出的文件——该资产不会出现在发行版页面上，'
            '而工作流照样报成功');
  });

  test('every platform this project supports is published', () {
    final promised = assetsIn(publishBlock()).join(' ');
    for (final platform in ['windows', 'macos', 'linux']) {
      expect(promised, contains(platform), reason: '$platform 没有产物');
    }
  });

  test('the macOS asset is not named after one architecture', () {
    // The Release configuration does not set ONLY_ACTIVE_ARCH, so the app
    // Xcode produces carries both x86_64 and arm64 — checked against the
    // published v1.5.0 zip, whose Mach-O header is a two-architecture fat
    // binary. Calling it `arm64` told every Intel Mac owner there was no
    // build for them.
    final macos = assetsIn(publishBlock()).where((a) => a.contains('macos'));
    expect(macos, isNotEmpty);
    for (final asset in macos) {
      expect(asset, contains('universal'),
          reason: '$asset 用架构名命名了一个通用二进制');
    }
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/self_update_service.dart';

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

  /// The workflow split into its jobs, keyed by job name.
  ///
  /// Per job, not per file. This used to read the first `matrix:` in the whole
  /// workflow and stop at the first `runs-on:` after it — fine while exactly
  /// one job had a matrix. Adding a second one above build-linux meant its
  /// deb and rpm architectures were never collected, and four assets that are
  /// built every release looked as though nobody built them.
  Map<String, String> jobs() {
    final starts = RegExp(r'^  (\w[\w-]*):$', multiLine: true)
        .allMatches(flat)
        .toList();
    return {
      for (var i = 0; i < starts.length; i++)
        starts[i].group(1)!: flat.substring(
          starts[i].start,
          i + 1 < starts.length ? starts[i + 1].start : flat.length,
        ),
    };
  }

  /// Every value the matrix of one job declares, by key.
  Map<String, Set<String>> matrixValues(String job) {
    final at = job.indexOf('matrix:');
    if (at == -1) return const {};
    final runsOn = job.indexOf('runs-on:', at);
    final block = job.substring(at, runsOn == -1 ? job.length : runsOn);
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
    // Each job's names are expanded with that job's own matrix. Pooling every
    // matrix in the file would let one job's architectures vouch for another's
    // filenames.
    final produced = <String>{
      for (final entry in jobs().entries)
        if (entry.key != 'release')
          ...expand(assetsIn(entry.value), matrixValues(entry.value)),
    };

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

  test('the name update_app looks for is a name the release publishes', () {
    // Two lists that nothing compared: the assets this workflow uploads, and
    // the suffixes `SelfUpdateService.chooseReleaseAsset` searches for when
    // the editor is replacing itself. Rename one here — `-setup.exe` to
    // `-installer.exe`, say — and the update stops finding anything, with a
    // sentence blaming the release for having nothing for this platform.
    // Neither side would have changed in a way its own tests could see.
    final published = assetsIn(flat)
        .map((tail) => 'marktext-plus-v9.9.9-$tail')
        .toList();
    expect(published.length, greaterThan(6),
        reason: '从 release.yml 读不出几个产物名，取法要跟着改');

    final assets = [
      for (final name in published)
        {'name': name, 'browser_download_url': 'https://example.invalid/$name',
          'digest': 'sha256:${'a' * 64}', 'size': 1},
    ];

    // Every machine this editor can be running on while it updates itself.
    for (final (os, arch) in const [
      ('windows', 'x64'),
      ('windows', 'arm64'),
      ('linux', 'x64'),
      ('linux', 'arm64'),
      ('macos', 'x64'),
      ('macos', 'arm64'),
    ]) {
      final chosen =
          SelfUpdateService.chooseReleaseAsset(assets, os: os, arch: arch);
      expect(chosen, isNotNull,
          reason: '$os $arch 在发布的产物里找不到对应的包：$published');
      expect(chosen!['name'], contains(os == 'macos' ? 'macos' : '$os-$arch'),
          reason: '$os $arch 选中的是 ${chosen['name']}');
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

  test('the macOS zip keeps the bundle a bundle', () {
    // A `.app` is full of symlinks — `Versions/Current`, and the framework
    // binary and Resources beside it — and `zip -r` without `-y` follows them
    // and stores what they point at. Every framework binary then goes in
    // twice, which is why the published zip is 76 MB beside a 25 MB dmg of the
    // same application, and why what comes out of it is a bundle with real
    // files where its symlinks should be.
    //
    // `ditto -c -k --keepParent` is what Apple's own tooling uses and keeps
    // both. `zip -ry` would keep the links too; ditto also keeps the metadata.
    final workflow = File('../.github/workflows/release.yml').readAsStringSync();
    expect(workflow, isNotEmpty, reason: '读不到 release.yml，这条检查会变成空话');

    // The command block around the archive's own name. Not "the line naming
    // it": the command wraps, so the name and the command that makes it are on
    // different lines. Not "the step called Package zip" either — every
    // platform has one of those.
    final at = workflow.indexOf('macos-universal.zip');
    expect(at, isNot(-1), reason: 'release.yml 里找不到 macOS 的 zip，取法要跟着改');
    final from = workflow.lastIndexOf('- name:', at);
    final to = workflow.indexOf('- name:', at);
    final body = workflow.substring(
      from == -1 ? 0 : from,
      to == -1 ? workflow.length : to,
    );

    // Commands only. The comment above the command names both tools to explain
    // the choice, so a check that reads the whole block passes on the strength
    // of the comment even after the command underneath it changes back — which
    // is what the first version of this did.
    final commands = body
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .join('\n');

    expect(
      commands,
      anyOf(contains('ditto'), matches(RegExp(r'zip\s+-\w*y'))),
      reason: '这样打出来的 zip 会把符号链接展开成重复文件，'
          '包大三倍，解开还是个结构坏掉的 bundle',
    );
  });
}

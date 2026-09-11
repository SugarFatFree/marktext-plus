import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/providers/mcp_provider.dart';
import 'package:marktext_plus/services/self_update_service.dart';

/// Which build `update_app` would replace this editor with.
///
/// Everything this decides happens before a byte is fetched, and none of it
/// can be noticed afterwards: every asset in a release is genuine and its
/// digest matches, so handing the arm64 installer to an x64 machine, or an
/// older release to a newer build, produces a download that verifies
/// perfectly and an editor that is wrong.
void main() {
  Map<String, dynamic> asset(String name) => {
        'name': name,
        'browser_download_url': 'https://example.invalid/$name',
        'digest': 'sha256:${'a' * 64}',
        'size': 1,
      };

  final release = [
    asset('marktext-plus-v1.6.2-windows-x64-setup.exe'),
    asset('marktext-plus-v1.6.2-windows-arm64-setup.exe'),
    asset('marktext-plus-v1.6.2-windows-x64.zip'),
    asset('marktext-plus-v1.6.2-linux-x64.tar.gz'),
    asset('marktext-plus-v1.6.2-linux-arm64.tar.gz'),
    asset('marktext-plus-v1.6.2-macos-universal.dmg'),
  ];

  group('choosing the asset for this machine', () {
    test('Windows takes the installer for its own architecture', () {
      expect(
        SelfUpdateService.chooseReleaseAsset(release, os: 'windows', arch: 'x64')?['name'],
        'marktext-plus-v1.6.2-windows-x64-setup.exe',
      );
      expect(
        SelfUpdateService.chooseReleaseAsset(release, os: 'windows', arch: 'arm64')?['name'],
        'marktext-plus-v1.6.2-windows-arm64-setup.exe',
      );
    });

    test('the x64 installer is not what an arm64 machine gets', () {
      // The names differ by four characters and both end in `-setup.exe`. A
      // match on the suffix alone picks whichever came first in the release.
      final chosen = SelfUpdateService.chooseReleaseAsset(
        release,
        os: 'windows',
        arch: 'arm64',
      );
      expect(chosen?['name'], isNot(contains('-x64-')));
    });

    test('the installer is chosen over the portable zip', () {
      // Both are Windows x64 builds of the same version. Only one of them can
      // replace a running program without this code learning how.
      expect(
        SelfUpdateService.chooseReleaseAsset(release, os: 'windows', arch: 'x64')?['name'],
        endsWith('-setup.exe'),
      );
    });

    test('Linux and macOS take their own', () {
      expect(
        SelfUpdateService.chooseReleaseAsset(release, os: 'linux', arch: 'arm64')?['name'],
        'marktext-plus-v1.6.2-linux-arm64.tar.gz',
      );
      expect(
        SelfUpdateService.chooseReleaseAsset(release, os: 'macos', arch: 'x64')?['name'],
        'marktext-plus-v1.6.2-macos-universal.dmg',
      );
    });

    test('an operating system with nothing published gets nothing', () {
      expect(
        SelfUpdateService.chooseReleaseAsset(release, os: 'fuchsia', arch: 'x64'),
        isNull,
      );
      expect(
        SelfUpdateService.chooseReleaseAsset([], os: 'windows', arch: 'x64'),
        isNull,
      );
    });
  });

  group('reading the machine', () {
    test('the ABI decides the architecture, both ways', () {
      expect(SelfUpdateService.archName('windows_arm64'), 'arm64');
      expect(SelfUpdateService.archName('linux_aarch64'), 'arm64');
      expect(SelfUpdateService.archName('windows_x64'), 'x64');
      // Not arm: an x64 build running on an arm64 host is the build that has
      // to be replaced, and it reports x64.
      expect(SelfUpdateService.archName('macos_x64'), 'x64');
    });

    test('the artifact is named after the commit, the way CI names it', () {
      expect(
        SelfUpdateService.artifactFor('abc1234', platform: 'windows-x64'),
        'windows-x64-setup-abc1234',
      );
    });
  });

  group('nothing runs without a checksum', () {
    test('a digest GitHub published is read', () {
      expect(SelfUpdateService.digestOf('sha256:${'A' * 64}'), 'a' * 64);
    });

    test('a build with no digest is refused, not fetched anyway', () {
      // What is being fetched is a program that will be executed. Without a
      // published checksum there is nothing to compare the bytes against, and
      // "it came from GitHub over HTTPS" is a statement about the connection,
      // not about the file.
      for (final missing in [null, '', 'deadbeef', 'md5:${'a' * 32}', 42]) {
        expect(
          () => SelfUpdateService.digestOf(missing),
          throwsA(isA<FormatException>()),
          reason: '$missing',
        );
      }
    });
  });

  group('refusing to go backwards', () {
    test('a newer version is newer', () {
      expect(McpController.isNewerBuild('1.6.3', '1.6.2'), isTrue);
      expect(McpController.isNewerBuild('1.7.0', '1.6.9'), isTrue);
      expect(McpController.isNewerBuild('2.0.0', '1.9.9'), isTrue);
      expect(McpController.isNewerBuild('v1.6.3', '1.6.2'), isTrue);
    });

    test('the same version is not newer, so a reinstall is refused', () {
      expect(McpController.isNewerBuild('1.6.2', '1.6.2'), isFalse);
    });

    test('an older one is refused, including where text would say otherwise',
        () {
      expect(McpController.isNewerBuild('1.6.1', '1.6.2'), isFalse);
      // The comparison that bit this project before: as text, "1.10.0" sorts
      // before "1.9.0".
      expect(McpController.isNewerBuild('1.9.0', '1.10.0'), isFalse);
      expect(McpController.isNewerBuild('1.10.0', '1.9.0'), isTrue);
    });

    test('anything that is not three numbers is not newer', () {
      // Erring towards refusing: this decides whether to replace the program.
      for (final odd in ['', 'latest', '1.6', '1.6.2.3', '1.6.x', 'v1.6.2-beta']) {
        expect(McpController.isNewerBuild(odd, '1.0.0'), isFalse, reason: odd);
      }
    });
  });
}

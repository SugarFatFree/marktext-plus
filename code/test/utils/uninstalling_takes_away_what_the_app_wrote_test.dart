import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Uninstalling leaves nothing of the program behind.
///
/// The program writes diagnostics beside its own executable while it runs —
/// the startup trace, and the account of how the last run ended. The installer
/// did not put those there, so the uninstaller does not know about them, and
/// one unknown file is enough for Inno to leave the installation folder
/// standing after somebody has uninstalled the program. Somebody who removes
/// an editor and finds its folder still there is entitled to wonder what else
/// it left.
///
/// The names are read out of the source that writes them rather than repeated
/// here: renaming one of those files would otherwise leave this passing while
/// the uninstaller looked for a name nothing writes. Both directions are
/// checked, because they fail differently — a file written and never cleaned
/// up leaves the folder behind, and a name cleaned up that nothing writes is a
/// rename somebody only did half of.
///
/// What this does not catch: a third diagnostic file, written beside the
/// executable by some file these assertions do not read. Enumerating those
/// automatically was tried and is wrong — `self_update_service.dart` mentions
/// the executable's directory and names a log, but writes that one into the
/// configuration directory, so "every log named near a mention of the
/// executable" asks the installer to clean up a file that was never there.
void main() {
  /// Repo-root relative, since the workflows live above `code/`.
  String read(String path) {
    for (var directory = Directory.current, level = 0;
        level < 4;
        directory = directory.parent, level++) {
      final candidate = File('${directory.path}/$path');
      if (candidate.existsSync()) return candidate.readAsStringSync();
    }
    fail('$path not found from ${Directory.current.path}');
  }

  String? onlyMatch(String source, RegExp pattern) {
    final found = pattern
        .allMatches(source)
        .map((m) => m.group(1)!)
        .toSet();
    return found.length == 1 ? found.single : null;
  }

  test('every file the program writes beside itself is uninstalled', () {
    // Written by Dart, next to Platform.resolvedExecutable.
    final trace = onlyMatch(read('code/lib/core/diagnostics/startup_trace.dart'),
        RegExp(r'pathSeparator\}([\w.-]+\.log)'));
    // Written by the runner, next to GetModuleFileNameW.
    final lastExit = onlyMatch(read('code/windows/runner/main.cpp'),
        RegExp(r'L"([\w.-]+\.log)"'));
    expect(trace, isNotNull, reason: 'cannot tell what the trace is called');
    expect(lastExit, isNotNull, reason: 'cannot tell what the exit is called');

    // Both workflows: the one nobody installs and the one people run. A guard
    // on this installer that read only the first of the two has already let a
    // defect through once.
    for (final workflow in ['.github/workflows/ci.yml',
                            '.github/workflows/release.yml']) {
      final source = read(workflow);
      expect(source, contains('[UninstallDelete]'),
          reason: '$workflow builds an installer that leaves its folder behind');
      for (final name in [trace!, lastExit!]) {
        expect(source, contains('Name: "{app}\\$name"'),
            reason: '$workflow does not take $name away on uninstall');
      }
      // And nothing else: a name the uninstaller removes that nothing writes
      // is half of a rename, and the other half is a file left behind.
      final cleaned = RegExp(r'Name: "\{app\}\\([\w.-]+\.log)"')
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toSet();
      expect(cleaned, {trace, lastExit},
          reason: '$workflow cleans up '
              '${cleaned.difference({trace, lastExit})}, which nothing writes');
    }
  });
}

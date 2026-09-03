import 'dart:io';

import 'package:path/path.dart' as p;

/// Shows a file or a folder in the reader's own file manager.
///
/// The command differs per platform and per intent, and getting it wrong is
/// quiet: the wrong form opens the parent folder and looks like it worked.
/// Every caller in the editor goes through here so there is one copy to be
/// right.
abstract final class FileReveal {
  /// Opens the file manager with [path] itself highlighted.
  static List<String> selectCommand(String path, {String? os}) =>
      switch (os ?? Platform.operatingSystem) {
        // Explorer returns exit code 1 even when it worked, so the result is
        // not worth inspecting.
        'windows' => ['explorer.exe', '/select,', path],
        'macos' => ['open', '-R', path],
        // xdg-open cannot highlight anything, so the containing folder is the
        // closest honest equivalent.
        _ => ['xdg-open', p.dirname(path)],
      };

  /// Opens [path], which is a folder, in the file manager.
  static List<String> openCommand(String path, {String? os}) =>
      switch (os ?? Platform.operatingSystem) {
        'windows' => ['explorer.exe', path],
        'macos' => ['open', path],
        _ => ['xdg-open', path],
      };

  /// Shows [path] highlighted in the file manager.
  static Future<void> selectFile(String path) => _run(selectCommand(path));

  /// Opens the folder [path] in the file manager.
  static Future<void> openDirectory(String path) => _run(openCommand(path));

  static Future<void> _run(List<String> command) async {
    await Process.run(command.first, command.sublist(1));
  }
}

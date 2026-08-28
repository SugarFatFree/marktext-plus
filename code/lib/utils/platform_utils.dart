import 'dart:io';

class PlatformUtils {
  PlatformUtils._();

  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isLinux => Platform.isLinux;

  static String get modifierKey => isMacOS ? '⌘' : 'Ctrl';
  static String get altKey => isMacOS ? '⌥' : 'Alt';

  /// Starts another copy of the app, optionally opening [filePath].
  ///
  /// macOS needs `open -n` to get a second instance of a bundled app; running
  /// the executable directly there just activates the one already running.
  static Future<void> launchNewWindow({String? filePath}) async {
    final executable = Platform.resolvedExecutable;
    try {
      if (isMacOS) {
        await Process.start('open', [
          '-n',
          '-a',
          executable,
          if (filePath != null) ...['--args', filePath],
        ]);
      } else {
        await Process.start(
          executable,
          [if (filePath != null) filePath],
          mode: ProcessStartMode.detached,
        );
      }
    } catch (_) {
      // Nothing useful to do if the platform refuses; the caller falls back to
      // opening in this window.
    }
  }
}

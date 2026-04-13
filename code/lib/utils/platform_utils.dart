import 'dart:io';

class PlatformUtils {
  PlatformUtils._();

  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isLinux => Platform.isLinux;

  static String get modifierKey => isMacOS ? '⌘' : 'Ctrl';
  static String get altKey => isMacOS ? '⌥' : 'Alt';
}

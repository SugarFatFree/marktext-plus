import 'dart:convert';
import 'dart:io';

/// Reading and writing one small JSON file that the reader must not lose.
///
/// Two of these exist — the settings and the keybindings — and they behaved
/// differently for no reason anyone chose. The settings file was written
/// through a temporary file and renamed into place, and an unreadable one was
/// set aside so it could be recovered; the keybindings file was written in
/// place and, when it failed to parse, silently replaced by the defaults, so
/// every shortcut the reader had customised disappeared without a word and
/// the file that held them was overwritten on the next save.
///
/// One implementation rather than two: whichever of them the next fix lands
/// on, the other gets it too.
class JsonStore {
  /// Creates a store over the file at [path].
  const JsonStore(this.path);

  /// Where the JSON lives.
  final String path;

  /// Where an unreadable file is moved so it can still be recovered.
  String get quarantinePath => '$path.corrupt';

  /// Reads the file, or null when there is nothing usable to read.
  ///
  /// A file that cannot be parsed is moved to [quarantinePath] first: falling
  /// back to defaults *and* leaving the file in place means the next save
  /// overwrites the only copy of what the reader had.
  Future<Map<String, dynamic>?> read() async {
    final file = File(path);
    try {
      if (!await file.exists()) return null;
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      await _setAside(file);
      return null;
    }
  }

  /// Writes [json], atomically.
  ///
  /// Writing in place leaves a truncated file if the process dies mid-write,
  /// and a truncated file does not parse. A rename is atomic, so what is on
  /// disk is always either the whole of the old content or the whole of the
  /// new.
  Future<void> write(Map<String, dynamic> json) async {
    final file = File(path);
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final temporary = File('$path.tmp');
    await temporary.writeAsString(
      const JsonEncoder.withIndent('  ').convert(json),
      flush: true,
    );
    await temporary.rename(path);
  }

  Future<void> _setAside(File file) async {
    try {
      if (await file.exists()) await file.rename(quarantinePath);
    } catch (_) {
      // Nothing more to try; the caller still gets defaults.
    }
  }
}

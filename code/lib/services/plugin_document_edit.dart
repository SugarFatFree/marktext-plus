import 'plugin_manifest.dart';

/// One change a plugin asked to make to the open document.
///
/// A plugin that rewrites a paragraph is what AI writing and AI proofreading
/// are for. Doing it means being exact about what gets replaced — the
/// selection if there is one, the whole document if there is not — and
/// carrying what was there before, so the reader can take it back.
class PluginDocumentEdit {
  const PluginDocumentEdit({required this.before, required this.after});

  /// The document as it was, for undo.
  final String before;

  /// The document as the plugin wants it.
  final String after;

  /// What [plugin] asked for, or null when nothing should happen.
  ///
  /// Null rather than an edit that changes nothing: a plugin without
  /// `document.write`, a selection that is no longer in the document because
  /// it moved while the model was thinking, or a replacement identical to what
  /// is already there. Each of those is a reason to leave the document alone,
  /// and an empty edit on the undo stack is a keystroke the reader has to
  /// press twice.
  static PluginDocumentEdit? of(
    PluginManifest plugin, {
    required String document,
    required String selection,
    required String replacement,
  }) {
    if (!plugin.hasPermission(PluginPermission.documentWrite)) return null;

    if (selection.isEmpty) {
      if (replacement == document) return null;
      return PluginDocumentEdit(before: document, after: replacement);
    }

    // The first occurrence, not every one: a proofreader fixing one "teh"
    // must not change every "teh" in the file.
    final at = document.indexOf(selection);
    if (at < 0) return null;
    if (selection == replacement) return null;

    final after = document.replaceRange(at, at + selection.length, replacement);
    return PluginDocumentEdit(before: document, after: after);
  }
}

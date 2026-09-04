import '../core/config/app_config.dart';
import 'file_encoding.dart';
import 'plugin_catalog_entry.dart';
import 'line_ending.dart';

class TabInfo {
  final String id;
  final String? filePath;
  String fileName;
  String content;
  bool isModified;
  bool isLoading;
  int cursorPosition;
  // Deprecated: use per-mode scroll offsets instead
  @Deprecated(
    'Use sourceScrollOffset, previewScrollOffset, or splitScrollOffset',
  )
  double scrollOffset;
  // Per-mode scroll offsets
  double sourceScrollOffset;
  double previewScrollOffset;
  double splitScrollOffset;
  double splitSourceScrollOffset;
  EditMode editMode;

  /// What this document used on disk, so saving puts the same thing back.
  LineEnding lineEnding;

  /// The byte encoding this document was read in.
  ///
  /// Held for the same reason as [lineEnding]: writing a legacy file back as
  /// UTF-8 corrupts it, and dropping a byte order mark rewrites a file that
  /// was never edited.
  FileEncoding encoding;

  /// Bumped whenever [content] was replaced by something other than the
  /// editor showing it — a reload after the file changed on disk.
  ///
  /// The editors cannot tell that from their own typing by comparing text:
  /// the owner's copy lags the controller by a keystroke while typing, and
  /// adopting it then would eat the character just typed.
  int externalRevision;

  TabInfo({
    required this.id,
    this.filePath,
    this.fileName = 'Untitled',
    this.content = '',
    this.isModified = false,
    this.isLoading = false,
    this.cursorPosition = 0,
    this.scrollOffset = 0,
    this.sourceScrollOffset = 0,
    this.previewScrollOffset = 0,
    this.splitScrollOffset = 0,
    this.splitSourceScrollOffset = 0,
    this.editMode = EditMode.preview,
    this.lineEnding = LineEnding.lf,
    this.encoding = FileEncoding.utf8Encoding,
    this.externalRevision = 0,
    this.diskStamp,
    this.diskConflict = false,
    this.pluginDetail,
  });

  /// A tab showing a plugin's page rather than a document.
  ///
  /// No file path: session persistence, the opened-files list and auto-save
  /// all key off one, and a page is not a file.
  factory TabInfo.pluginDetail(PluginCatalogEntry plugin) => TabInfo(
        id: 'plugin:${plugin.id}',
        fileName: plugin.name,
        pluginDetail: plugin,
      );

  /// The plugin whose page this tab shows, or null for a document.
  final PluginCatalogEntry? pluginDetail;

  /// Whether this tab shows a plugin page instead of a document.
  bool get isPluginDetail => pluginDetail != null;

  /// What the file looked like when it was last read or written.
  ///
  /// Compared before each save so a document rewritten underneath the editor
  /// is not silently overwritten. Null for a document that has never been on
  /// disk.
  final ({DateTime modified, int size})? diskStamp;

  /// Set when a save was refused because the file had changed underneath.
  ///
  /// Auto-save stops for this tab while it is set: retrying every few seconds
  /// would either keep failing or, worse, succeed once the stamp happened to
  /// match again.
  final bool diskConflict;

  TabInfo copyWith({
    String? filePath,
    String? fileName,
    String? content,
    bool? isModified,
    bool? isLoading,
    int? cursorPosition,
    double? scrollOffset,
    double? sourceScrollOffset,
    double? previewScrollOffset,
    double? splitScrollOffset,
    double? splitSourceScrollOffset,
    EditMode? editMode,
    LineEnding? lineEnding,
    FileEncoding? encoding,
    int? externalRevision,
    ({DateTime modified, int size})? diskStamp,
    bool? diskConflict,
    bool clearDiskStamp = false,
    PluginCatalogEntry? pluginDetail,
  }) {
    return TabInfo(
      id: id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      content: content ?? this.content,
      isModified: isModified ?? this.isModified,
      isLoading: isLoading ?? this.isLoading,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      sourceScrollOffset: sourceScrollOffset ?? this.sourceScrollOffset,
      previewScrollOffset: previewScrollOffset ?? this.previewScrollOffset,
      splitScrollOffset: splitScrollOffset ?? this.splitScrollOffset,
      splitSourceScrollOffset:
          splitSourceScrollOffset ?? this.splitSourceScrollOffset,
      editMode: editMode ?? this.editMode,
      lineEnding: lineEnding ?? this.lineEnding,
      encoding: encoding ?? this.encoding,
      externalRevision: externalRevision ?? this.externalRevision,
      diskStamp: clearDiskStamp ? null : (diskStamp ?? this.diskStamp),
      diskConflict: diskConflict ?? this.diskConflict,
      pluginDetail: pluginDetail ?? this.pluginDetail,
    );
  }
}

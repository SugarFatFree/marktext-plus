import '../theme/app_theme.dart';

enum EditMode { source, preview, split }

enum FileOpenBehavior { newWindow, existingWindow, notSet }

class AppConfig {
  bool sideBarVisible;
  bool tabBarVisible;
  EditMode editMode;
  double splitRatio;
  String fontFamily;
  double fontSize;
  double lineHeight;
  bool autoSave;
  int autoSaveDelay;
  String themeName;

  /// Whether the theme follows the operating system's light/dark setting.
  ///
  /// Off by default: turning it on for an existing reader would change the
  /// look of their editor on the next launch without them asking.
  bool followSystemTheme;

  /// The theme used while the system is light, when [followSystemTheme] is on.
  String lightModeTheme;

  /// The theme used while the system is dark, when [followSystemTheme] is on.
  String darkModeTheme;
  String locale;
  String bulletListMarker;
  int tabSize;
  bool enableHtml;

  /// Whether a long line inside a code block wraps, or the block scrolls.
  ///
  /// Wrapping is the default, as it is upstream. Turning it off matters for
  /// code: a wrapped line loses its indentation and breaks in the middle of a
  /// name, which is the opposite of what reading code needs. Until now there
  /// was no way to turn it off.
  bool wrapCodeBlocks;

  /// Auto-closing of `(`, `[` and `{`.
  bool autoPairBracket;

  /// Auto-closing of `"` and `'`.
  bool autoPairQuote;

  /// Auto-closing of the markdown pairs `` ` ``, `*` and `~`.
  ///
  /// Split from the other two because it is the one people disagree about:
  /// typing `*` to start emphasis and being handed `**` with the caret in the
  /// middle interrupts the sentence for some and helps others. Upstream
  /// MarkText offers all three separately; this app offered no way to turn any
  /// of them off.
  bool autoPairMarkdownSyntax;
  double windowWidth;
  double windowHeight;
  double windowX;
  double windowY;
  bool isMaximized;
  List<String> recentFiles;
  bool focusMode;
  bool typewriterMode;
  String codeFontFamily;
  int editorMaxWidth;
  String textDirection;
  String imageStorageMode;
  String imageFolder;
  FileOpenBehavior fileOpenBehavior;
  String lastUpdateCheck;
  String skipVersion;
  String sideBarDirectory;
  List<String> sideBarOpenedFiles;

  AppConfig({
    this.sideBarVisible = true,
    this.tabBarVisible = true,
    this.editMode = EditMode.preview,
    this.splitRatio = 0.5,
    this.fontFamily = 'monospace',
    this.fontSize = 16.0,
    this.lineHeight = 1.6,
    this.autoSave = true,
    this.autoSaveDelay = 5000,
    this.themeName = 'redGraphite',
    this.followSystemTheme = false,
    this.lightModeTheme = 'redGraphite',
    this.darkModeTheme = 'darkGraphite',
    this.locale = '',
    this.bulletListMarker = '-',
    this.tabSize = 4,
    this.enableHtml = false,
    this.wrapCodeBlocks = true,
    this.autoPairBracket = true,
    this.autoPairQuote = true,
    this.autoPairMarkdownSyntax = true,
    this.windowWidth = 1200,
    this.windowHeight = 800,
    this.windowX = 0,
    this.windowY = 0,
    this.isMaximized = false,
    this.recentFiles = const [],
    this.focusMode = false,
    this.typewriterMode = false,
    this.codeFontFamily = 'Courier New',
    this.editorMaxWidth = 800,
    this.textDirection = 'ltr',
    this.imageStorageMode = 'copy',
    this.imageFolder = 'assets/images',
    this.fileOpenBehavior = FileOpenBehavior.notSet,
    this.lastUpdateCheck = '',
    this.skipVersion = '',
    this.sideBarDirectory = '',
    this.sideBarOpenedFiles = const [],
  });

  Map<String, dynamic> toJson() => {
    'sideBarVisible': sideBarVisible,
    'tabBarVisible': tabBarVisible,
    'editMode': editMode.name,
    'splitRatio': splitRatio,
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'lineHeight': lineHeight,
    'autoSave': autoSave,
    'autoSaveDelay': autoSaveDelay,
    'themeName': themeName,
    'followSystemTheme': followSystemTheme,
    'lightModeTheme': lightModeTheme,
    'darkModeTheme': darkModeTheme,
    'locale': locale,
    'bulletListMarker': bulletListMarker,
    'tabSize': tabSize,
    'enableHtml': enableHtml,
    'wrapCodeBlocks': wrapCodeBlocks,
    'autoPairBracket': autoPairBracket,
    'autoPairQuote': autoPairQuote,
    'autoPairMarkdownSyntax': autoPairMarkdownSyntax,
    'windowWidth': windowWidth,
    'windowHeight': windowHeight,
    'windowX': windowX,
    'windowY': windowY,
    'isMaximized': isMaximized,
    'recentFiles': recentFiles,
    'focusMode': focusMode,
    'typewriterMode': typewriterMode,
    'codeFontFamily': codeFontFamily,
    'editorMaxWidth': editorMaxWidth,
    'textDirection': textDirection,
    'imageStorageMode': imageStorageMode,
    'imageFolder': imageFolder,
    'fileOpenBehavior': fileOpenBehavior.name,
    'lastUpdateCheck': lastUpdateCheck,
    'skipVersion': skipVersion,
    'sideBarDirectory': sideBarDirectory,
    'sideBarOpenedFiles': sideBarOpenedFiles,
  };

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      sideBarVisible: json['sideBarVisible'] as bool? ?? true,
      tabBarVisible: json['tabBarVisible'] as bool? ?? true,
      editMode: _parseEditMode(json['editMode']),
      splitRatio: _parseDouble(json['splitRatio'], 0.5),
      fontFamily: json['fontFamily'] as String? ?? 'monospace',
      fontSize: _parseDouble(json['fontSize'], 16.0),
      lineHeight: _parseDouble(json['lineHeight'], 1.6),
      autoSave: json['autoSave'] as bool? ?? true,
      autoSaveDelay: json['autoSaveDelay'] as int? ?? 5000,
      themeName: AppTheme.migrateName(json['themeName'] as String? ?? 'redGraphite'),
      followSystemTheme: json['followSystemTheme'] as bool? ?? false,
      lightModeTheme: AppTheme.migrateName(
          json['lightModeTheme'] as String? ?? 'redGraphite'),
      darkModeTheme: AppTheme.migrateName(
          json['darkModeTheme'] as String? ?? 'darkGraphite'),
      locale: json['locale'] as String? ?? '',
      bulletListMarker: json['bulletListMarker'] as String? ?? '-',
      tabSize: json['tabSize'] as int? ?? 4,
      enableHtml: json['enableHtml'] as bool? ?? false,
      wrapCodeBlocks: json['wrapCodeBlocks'] as bool? ?? true,
      autoPairBracket: json['autoPairBracket'] as bool? ?? true,
      autoPairQuote: json['autoPairQuote'] as bool? ?? true,
      autoPairMarkdownSyntax:
          json['autoPairMarkdownSyntax'] as bool? ?? true,
      windowWidth: _parseDouble(json['windowWidth'], 1200),
      windowHeight: _parseDouble(json['windowHeight'], 800),
      windowX: _parseDouble(json['windowX'], 0),
      windowY: _parseDouble(json['windowY'], 0),
      isMaximized: json['isMaximized'] as bool? ?? false,
      recentFiles: (json['recentFiles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      focusMode: json['focusMode'] as bool? ?? false,
      typewriterMode: json['typewriterMode'] as bool? ?? false,
      codeFontFamily: json['codeFontFamily'] as String? ?? 'Courier New',
      editorMaxWidth: json['editorMaxWidth'] as int? ?? 800,
      textDirection: json['textDirection'] as String? ?? 'ltr',
      imageStorageMode: json['imageStorageMode'] as String? ?? 'copy',
      imageFolder: json['imageFolder'] as String? ?? 'assets/images',
      fileOpenBehavior: _parseFileOpenBehavior(json['fileOpenBehavior']),
      lastUpdateCheck: json['lastUpdateCheck'] as String? ?? '',
      skipVersion: json['skipVersion'] as String? ?? '',
      sideBarDirectory: json['sideBarDirectory'] as String? ?? '',
      sideBarOpenedFiles: (json['sideBarOpenedFiles'] as List?)?.cast<String>() ?? const [],
    );
  }

  static EditMode _parseEditMode(dynamic value) {
    if (value is String) {
      return EditMode.values.where((e) => e.name == value).firstOrNull ?? EditMode.preview;
    }
    return EditMode.preview;
  }

  static double _parseDouble(dynamic value, double defaultValue) {
    if (value is num) return value.toDouble();
    return defaultValue;
  }

  static FileOpenBehavior _parseFileOpenBehavior(dynamic value) {
    if (value is String) {
      return FileOpenBehavior.values
          .where((e) => e.name == value)
          .firstOrNull ?? FileOpenBehavior.notSet;
    }
    return FileOpenBehavior.notSet;
  }

  AppConfig copyWith({
    bool? sideBarVisible,
    bool? tabBarVisible,
    EditMode? editMode,
    double? splitRatio,
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    bool? autoSave,
    int? autoSaveDelay,
    String? themeName,
    bool? followSystemTheme,
    String? lightModeTheme,
    String? darkModeTheme,
    String? locale,
    String? bulletListMarker,
    int? tabSize,
    bool? enableHtml,
    bool? wrapCodeBlocks,
    bool? autoPairBracket,
    bool? autoPairQuote,
    bool? autoPairMarkdownSyntax,
    double? windowWidth,
    double? windowHeight,
    double? windowX,
    double? windowY,
    bool? isMaximized,
    List<String>? recentFiles,
    bool? focusMode,
    bool? typewriterMode,
    String? codeFontFamily,
    int? editorMaxWidth,
    String? textDirection,
    String? imageStorageMode,
    String? imageFolder,
    FileOpenBehavior? fileOpenBehavior,
    String? lastUpdateCheck,
    String? skipVersion,
    String? sideBarDirectory,
    List<String>? sideBarOpenedFiles,
  }) {
    return AppConfig(
      sideBarVisible: sideBarVisible ?? this.sideBarVisible,
      tabBarVisible: tabBarVisible ?? this.tabBarVisible,
      editMode: editMode ?? this.editMode,
      splitRatio: splitRatio ?? this.splitRatio,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      autoSave: autoSave ?? this.autoSave,
      autoSaveDelay: autoSaveDelay ?? this.autoSaveDelay,
      themeName: themeName ?? this.themeName,
      followSystemTheme: followSystemTheme ?? this.followSystemTheme,
      lightModeTheme: lightModeTheme ?? this.lightModeTheme,
      darkModeTheme: darkModeTheme ?? this.darkModeTheme,
      locale: locale ?? this.locale,
      bulletListMarker: bulletListMarker ?? this.bulletListMarker,
      tabSize: tabSize ?? this.tabSize,
      enableHtml: enableHtml ?? this.enableHtml,
      wrapCodeBlocks: wrapCodeBlocks ?? this.wrapCodeBlocks,
      autoPairBracket: autoPairBracket ?? this.autoPairBracket,
      autoPairQuote: autoPairQuote ?? this.autoPairQuote,
      autoPairMarkdownSyntax:
          autoPairMarkdownSyntax ?? this.autoPairMarkdownSyntax,
      windowWidth: windowWidth ?? this.windowWidth,
      windowHeight: windowHeight ?? this.windowHeight,
      windowX: windowX ?? this.windowX,
      windowY: windowY ?? this.windowY,
      isMaximized: isMaximized ?? this.isMaximized,
      recentFiles: recentFiles ?? this.recentFiles,
      focusMode: focusMode ?? this.focusMode,
      typewriterMode: typewriterMode ?? this.typewriterMode,
      codeFontFamily: codeFontFamily ?? this.codeFontFamily,
      editorMaxWidth: editorMaxWidth ?? this.editorMaxWidth,
      textDirection: textDirection ?? this.textDirection,
      imageStorageMode: imageStorageMode ?? this.imageStorageMode,
      imageFolder: imageFolder ?? this.imageFolder,
      fileOpenBehavior: fileOpenBehavior ?? this.fileOpenBehavior,
      lastUpdateCheck: lastUpdateCheck ?? this.lastUpdateCheck,
      skipVersion: skipVersion ?? this.skipVersion,
      sideBarDirectory: sideBarDirectory ?? this.sideBarDirectory,
      sideBarOpenedFiles: sideBarOpenedFiles ?? this.sideBarOpenedFiles,
    );
  }
}

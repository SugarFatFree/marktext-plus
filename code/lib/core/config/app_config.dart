import '../theme/app_theme.dart';

enum EditMode { source, preview, split }

enum FileOpenBehavior { newWindow, existingWindow, notSet }

enum AiProvider { openai, anthropic }

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

  /// Whether a fenced code block is drawn with a gutter of line numbers.
  ///
  /// On, as it is upstream: a snippet someone is talking about is talked
  /// about by line.
  bool codeBlockLineNumbers;

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

  /// The size code is drawn at, independent of the body font size.
  ///
  /// Separate because raising the reading size of prose and raising the size
  /// of code are different wishes: code was fixed at 14 whatever the body was
  /// set to, so anyone who enlarged the text got large prose and small code.
  /// Upstream keeps the two apart for the same reason.
  double codeFontSize;
  int editorMaxWidth;
  String textDirection;
  String imageStorageMode;
  String imageFolder;
  FileOpenBehavior fileOpenBehavior;
  String lastUpdateCheck;
  String skipVersion;
  String sideBarDirectory;
  List<String> sideBarOpenedFiles;

  /// The documents that were open as tabs when the application last closed,
  /// and which of them was in front.
  ///
  /// Distinct from [sideBarOpenedFiles], which is a list the reader curates in
  /// the sidebar and which nothing removes from when a tab is closed. This one
  /// is the session: what was on screen.
  List<String> sessionTabs;
  String sessionActiveTab;

  /// AI settings used by plugins. The key is intentionally visible in the
  /// settings UI because the user asked for a single straightforward field.
  bool aiEnabled;
  String aiApiKey;
  AiProvider aiProvider;
  String aiEndpoint;

  /// Whether the editor answers to an agent over MCP.
  ///
  /// Off unless the reader turns it on: it is a port on their machine that
  /// lets whatever reaches it read their documents and drive their editor.
  bool mcpEnabled;

  /// The port asked for first. The editor walks upward if it is taken.
  int mcpPort;

  /// The token an agent has to present. Generated when MCP is first switched
  /// on, and kept, so a configuration written once keeps working.
  String mcpToken;
  String aiModel;

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
    this.codeBlockLineNumbers = true,
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
    this.codeFontSize = 14.0,
    this.editorMaxWidth = 800,
    this.textDirection = 'ltr',
    this.imageStorageMode = 'copy',
    this.imageFolder = 'assets/images',
    this.fileOpenBehavior = FileOpenBehavior.notSet,
    this.lastUpdateCheck = '',
    this.skipVersion = '',
    this.sideBarDirectory = '',
    this.sideBarOpenedFiles = const [],
    this.sessionTabs = const [],
    this.sessionActiveTab = '',
    this.aiEnabled = false,
    this.aiApiKey = '',
    this.aiProvider = AiProvider.openai,
    this.aiEndpoint = '',
    this.mcpEnabled = false,
    this.mcpPort = 10100,
    this.mcpToken = '',
    this.aiModel = '',
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
    'codeBlockLineNumbers': codeBlockLineNumbers,
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
    'codeFontSize': codeFontSize,
    'editorMaxWidth': editorMaxWidth,
    'textDirection': textDirection,
    'imageStorageMode': imageStorageMode,
    'imageFolder': imageFolder,
    'fileOpenBehavior': fileOpenBehavior.name,
    'lastUpdateCheck': lastUpdateCheck,
    'skipVersion': skipVersion,
    'sideBarDirectory': sideBarDirectory,
    'sideBarOpenedFiles': sideBarOpenedFiles,
    'sessionTabs': sessionTabs,
    'sessionActiveTab': sessionActiveTab,
    'aiEnabled': aiEnabled,
    'aiApiKey': aiApiKey,
    'aiProvider': aiProvider.name,
    'aiEndpoint': aiEndpoint,
    'mcpEnabled': mcpEnabled,
    'mcpPort': mcpPort,
    'mcpToken': mcpToken,
    'aiModel': aiModel,
  };

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      sideBarVisible: _parseBool(json['sideBarVisible'], true),
      tabBarVisible: _parseBool(json['tabBarVisible'], true),
      editMode: _parseEditMode(json['editMode']),
      splitRatio: _parseDouble(json['splitRatio'], 0.5),
      fontFamily: _parseString(json['fontFamily'], 'monospace'),
      fontSize: _parseDouble(json['fontSize'], 16.0),
      lineHeight: _parseDouble(json['lineHeight'], 1.6),
      autoSave: _parseBool(json['autoSave'], true),
      autoSaveDelay: _parseInt(json['autoSaveDelay'], 5000),
      themeName: AppTheme.migrateName(
        _parseString(json['themeName'], 'redGraphite'),
      ),
      followSystemTheme: _parseBool(json['followSystemTheme'], false),
      lightModeTheme: AppTheme.migrateName(
        _parseString(json['lightModeTheme'], 'redGraphite'),
      ),
      darkModeTheme: AppTheme.migrateName(
        _parseString(json['darkModeTheme'], 'darkGraphite'),
      ),
      locale: _parseString(json['locale'], ''),
      bulletListMarker: _parseString(json['bulletListMarker'], '-'),
      tabSize: _parseInt(json['tabSize'], 4),
      enableHtml: _parseBool(json['enableHtml'], false),
      wrapCodeBlocks: _parseBool(json['wrapCodeBlocks'], true),
      codeBlockLineNumbers: _parseBool(json['codeBlockLineNumbers'], true),
      autoPairBracket: _parseBool(json['autoPairBracket'], true),
      autoPairQuote: _parseBool(json['autoPairQuote'], true),
      autoPairMarkdownSyntax: _parseBool(json['autoPairMarkdownSyntax'], true),
      windowWidth: _parseDouble(json['windowWidth'], 1200),
      windowHeight: _parseDouble(json['windowHeight'], 800),
      windowX: _parseDouble(json['windowX'], 0),
      windowY: _parseDouble(json['windowY'], 0),
      isMaximized: _parseBool(json['isMaximized'], false),
      recentFiles: _parseStringList(json['recentFiles']),
      focusMode: _parseBool(json['focusMode'], false),
      typewriterMode: _parseBool(json['typewriterMode'], false),
      codeFontFamily: _parseString(json['codeFontFamily'], 'Courier New'),
      codeFontSize: _parseDouble(json['codeFontSize'], 14.0),
      editorMaxWidth: _parseInt(json['editorMaxWidth'], 800),
      textDirection: _parseString(json['textDirection'], 'ltr'),
      imageStorageMode: _parseString(json['imageStorageMode'], 'copy'),
      imageFolder: _parseString(json['imageFolder'], 'assets/images'),
      fileOpenBehavior: _parseFileOpenBehavior(json['fileOpenBehavior']),
      lastUpdateCheck: _parseString(json['lastUpdateCheck'], ''),
      skipVersion: _parseString(json['skipVersion'], ''),
      sideBarDirectory: _parseString(json['sideBarDirectory'], ''),
      sideBarOpenedFiles:
          _parseStringList(json['sideBarOpenedFiles']),
      sessionTabs: _parseStringList(json['sessionTabs']),
      sessionActiveTab: _parseString(json['sessionActiveTab'], ''),
      aiEnabled: _parseBool(json['aiEnabled'], false),
      aiApiKey: _parseString(json['aiApiKey'], ''),
      aiProvider: _parseAiProvider(json['aiProvider']),
      aiEndpoint: _parseString(json['aiEndpoint'], ''),
      mcpEnabled: _parseBool(json['mcpEnabled'], false),
      mcpPort: _parseInt(json['mcpPort'], 10100),
      mcpToken: _parseString(json['mcpToken'], ''),
      aiModel: _parseString(json['aiModel'], ''),
    );
  }

  static EditMode _parseEditMode(dynamic value) {
    if (value is String) {
      return EditMode.values.where((e) => e.name == value).firstOrNull ??
          EditMode.preview;
    }
    return EditMode.preview;
  }

  static double _parseDouble(dynamic value, double defaultValue) {
    if (value is num) return value.toDouble();
    return defaultValue;
  }

  // The rest of the fields, read the same way. `as bool?` and its kind throw
  // on the wrong type rather than answering null, and ConfigService catches
  // that by starting from a default configuration — so one mistyped value in
  // a file the reader can open reset every setting they had, without saying
  // so. A wrong field now costs that field and nothing else.
  static bool _parseBool(dynamic value, bool defaultValue) =>
      value is bool ? value : defaultValue;

  /// JSON has one number type, so a whole number saved as 5000 can come back
  /// as 5000.0.
  static int _parseInt(dynamic value, int defaultValue) => switch (value) {
        int i => i,
        num n => n.round(),
        _ => defaultValue,
      };

  static String _parseString(dynamic value, String defaultValue) =>
      value is String ? value : defaultValue;

  /// The strings out of a saved list, skipping anything that is not one.
  ///
  /// `cast<String>()` is the trap here rather than a plain `as`: it is lazy,
  /// so a list holding one number is accepted by `fromJson` and throws later,
  /// somewhere with no connection to the file that caused it.
  static List<String> _parseStringList(dynamic value) => switch (value) {
        List list => [
            for (final entry in list)
              if (entry is String) entry,
          ],
        _ => const <String>[],
      };

  static AiProvider _parseAiProvider(dynamic value) {
    if (value is String) {
      return AiProvider.values
              .where((provider) => provider.name == value)
              .firstOrNull ??
          AiProvider.openai;
    }
    return AiProvider.openai;
  }

  static FileOpenBehavior _parseFileOpenBehavior(dynamic value) {
    if (value is String) {
      return FileOpenBehavior.values
              .where((e) => e.name == value)
              .firstOrNull ??
          FileOpenBehavior.notSet;
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
    bool? codeBlockLineNumbers,
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
    double? codeFontSize,
    int? editorMaxWidth,
    String? textDirection,
    String? imageStorageMode,
    String? imageFolder,
    FileOpenBehavior? fileOpenBehavior,
    String? lastUpdateCheck,
    String? skipVersion,
    String? sideBarDirectory,
    List<String>? sideBarOpenedFiles,
    List<String>? sessionTabs,
    String? sessionActiveTab,
    bool? aiEnabled,
    String? aiApiKey,
    AiProvider? aiProvider,
    String? aiEndpoint,
    String? aiModel,
    bool? mcpEnabled,
    int? mcpPort,
    String? mcpToken,
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
      codeBlockLineNumbers: codeBlockLineNumbers ?? this.codeBlockLineNumbers,
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
      codeFontSize: codeFontSize ?? this.codeFontSize,
      editorMaxWidth: editorMaxWidth ?? this.editorMaxWidth,
      textDirection: textDirection ?? this.textDirection,
      imageStorageMode: imageStorageMode ?? this.imageStorageMode,
      imageFolder: imageFolder ?? this.imageFolder,
      fileOpenBehavior: fileOpenBehavior ?? this.fileOpenBehavior,
      lastUpdateCheck: lastUpdateCheck ?? this.lastUpdateCheck,
      skipVersion: skipVersion ?? this.skipVersion,
      sideBarDirectory: sideBarDirectory ?? this.sideBarDirectory,
      sideBarOpenedFiles: sideBarOpenedFiles ?? this.sideBarOpenedFiles,
      sessionTabs: sessionTabs ?? this.sessionTabs,
      sessionActiveTab: sessionActiveTab ?? this.sessionActiveTab,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      aiApiKey: aiApiKey ?? this.aiApiKey,
      aiProvider: aiProvider ?? this.aiProvider,
      aiEndpoint: aiEndpoint ?? this.aiEndpoint,
      mcpEnabled: mcpEnabled ?? this.mcpEnabled,
      mcpPort: mcpPort ?? this.mcpPort,
      mcpToken: mcpToken ?? this.mcpToken,
      aiModel: aiModel ?? this.aiModel,
    );
  }
}

enum EditMode { source, preview, split }

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
  bool darkMode;
  String locale;
  String bulletListMarker;
  int tabSize;
  bool enableHtml;
  double windowWidth;
  double windowHeight;
  double windowX;
  double windowY;
  bool isMaximized;
  List<String> recentFiles;
  bool focusMode;
  bool typewriterMode;

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
    this.themeName = 'cadmiumLight',
    this.darkMode = false,
    this.locale = '',
    this.bulletListMarker = '-',
    this.tabSize = 4,
    this.enableHtml = false,
    this.windowWidth = 1200,
    this.windowHeight = 800,
    this.windowX = 0,
    this.windowY = 0,
    this.isMaximized = false,
    this.recentFiles = const [],
    this.focusMode = false,
    this.typewriterMode = false,
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
    'darkMode': darkMode,
    'locale': locale,
    'bulletListMarker': bulletListMarker,
    'tabSize': tabSize,
    'enableHtml': enableHtml,
    'windowWidth': windowWidth,
    'windowHeight': windowHeight,
    'windowX': windowX,
    'windowY': windowY,
    'isMaximized': isMaximized,
    'recentFiles': recentFiles,
    'focusMode': focusMode,
    'typewriterMode': typewriterMode,
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
      themeName: json['themeName'] as String? ?? 'cadmiumLight',
      darkMode: json['darkMode'] as bool? ?? false,
      locale: json['locale'] as String? ?? '',
      bulletListMarker: json['bulletListMarker'] as String? ?? '-',
      tabSize: json['tabSize'] as int? ?? 4,
      enableHtml: json['enableHtml'] as bool? ?? false,
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
    bool? darkMode,
    String? locale,
    String? bulletListMarker,
    int? tabSize,
    bool? enableHtml,
    double? windowWidth,
    double? windowHeight,
    double? windowX,
    double? windowY,
    bool? isMaximized,
    List<String>? recentFiles,
    bool? focusMode,
    bool? typewriterMode,
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
      darkMode: darkMode ?? this.darkMode,
      locale: locale ?? this.locale,
      bulletListMarker: bulletListMarker ?? this.bulletListMarker,
      tabSize: tabSize ?? this.tabSize,
      enableHtml: enableHtml ?? this.enableHtml,
      windowWidth: windowWidth ?? this.windowWidth,
      windowHeight: windowHeight ?? this.windowHeight,
      windowX: windowX ?? this.windowX,
      windowY: windowY ?? this.windowY,
      isMaximized: isMaximized ?? this.isMaximized,
      recentFiles: recentFiles ?? this.recentFiles,
      focusMode: focusMode ?? this.focusMode,
      typewriterMode: typewriterMode ?? this.typewriterMode,
    );
  }
}

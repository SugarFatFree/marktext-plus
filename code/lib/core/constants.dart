class AppConstants {
  AppConstants._();

  static const String appName = 'MarkText Plus';
  /// The version shown in About, and the one the update check compares
  /// against.
  ///
  /// Must match `version:` in pubspec.yaml, and a test enforces that. It had
  /// drifted to 1.3.0 while the app shipped 1.5.0, which meant About named a
  /// version nobody could match to a release (#1) and — worse — the update
  /// check measured every release against 1.3.0, so anyone on a current build
  /// was told forever that an update was waiting.
  static const String appVersion = '1.6.1';
  static const String configFileName = 'config.json';
  static const String configDirName = 'marktext-plus';

  static const double defaultFontSize = 16.0;
  static const double defaultLineHeight = 1.6;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 32.0;
  static const double defaultSplitRatio = 0.5;
  static const double minSplitRatio = 0.2;
  static const double maxSplitRatio = 0.8;

  static const int autoSaveDelay = 5000;
  static const int debounceDelay = 300;
  /// How many documents the Open Recent menu keeps.
  ///
  /// Ten, because ten is what it has always been: this constant said twenty
  /// and was read by nothing — the trimming happened against a hard-coded ten
  /// in `SettingsNotifier.addRecentFile`. Of the two numbers, the one nobody
  /// had ever seen take effect is the one that changed.
  ///
  /// There is a limit at all because the list goes into the configuration
  /// file, which is read on every launch.
  static const int maxRecentFiles = 10;

  static const double defaultWindowWidth = 1200;
  static const double defaultWindowHeight = 800;
  static const double minWindowWidth = 800;
  static const double minWindowHeight = 600;
}

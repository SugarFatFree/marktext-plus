class AppConstants {
  AppConstants._();

  static const String appName = 'MarkText Plus';
  static const String appVersion = '1.0.1';
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
  static const int maxRecentFiles = 20;

  static const double defaultWindowWidth = 1200;
  static const double defaultWindowHeight = 800;
  static const double minWindowWidth = 800;
  static const double minWindowHeight = 600;
}

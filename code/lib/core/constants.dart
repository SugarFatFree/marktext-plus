/// Values that more than one place needs to agree on.
///
/// The rule for this file: **a value belongs here only when at least two
/// places read it from here.** Fourteen of the eighteen constants that used to
/// live here were read by nobody — and one of them had quietly stopped being
/// true (`minWindowWidth` said 800 while the window would go to 480), which is
/// what a constant nobody reads eventually does.
///
/// A default that only `AppConfig` uses belongs in `AppConfig`; a minimum only
/// `WindowPlacement` enforces belongs there. Duplicating them here made a
/// second place to change and no place that had to be changed.
class AppConstants {
  AppConstants._();

  /// The window title and the application name, in the two places that show
  /// them.
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

  /// The range the Increase/Decrease Font Size actions stay inside.
  static const double minFontSize = 12.0;
  static const double maxFontSize = 32.0;
  /// How far the split view's divider may travel, so neither pane vanishes.
  static const double minSplitRatio = 0.2;
  static const double maxSplitRatio = 0.8;

  /// How long typing has to stop before work that follows it begins:
  /// re-rendering the preview, re-reading a file that changed, saving what was
  /// typed into a settings field.
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

}

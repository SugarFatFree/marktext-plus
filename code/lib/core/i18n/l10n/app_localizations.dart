import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MarkText Plus'**
  String get appTitle;

  /// No description provided for @menuFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get menuFile;

  /// No description provided for @menuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get menuEdit;

  /// No description provided for @menuView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get menuView;

  /// No description provided for @menuFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get menuFormat;

  /// No description provided for @menuWindow.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get menuWindow;

  /// No description provided for @menuHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get menuHelp;

  /// No description provided for @fileNew.
  ///
  /// In en, this message translates to:
  /// **'New File'**
  String get fileNew;

  /// No description provided for @fileNewWindow.
  ///
  /// In en, this message translates to:
  /// **'New Window'**
  String get fileNewWindow;

  /// No description provided for @fileOpen.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get fileOpen;

  /// No description provided for @fileOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get fileOpenFolder;

  /// No description provided for @fileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get fileSave;

  /// No description provided for @fileSaveAs.
  ///
  /// In en, this message translates to:
  /// **'Save As'**
  String get fileSaveAs;

  /// No description provided for @fileRecentFiles.
  ///
  /// In en, this message translates to:
  /// **'Recent Files'**
  String get fileRecentFiles;

  /// No description provided for @fileNoRecentFiles.
  ///
  /// In en, this message translates to:
  /// **'No Recent Files'**
  String get fileNoRecentFiles;

  /// No description provided for @fileExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get fileExport;

  /// No description provided for @fileExportHtml.
  ///
  /// In en, this message translates to:
  /// **'HTML'**
  String get fileExportHtml;

  /// No description provided for @fileExportPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get fileExportPdf;

  /// No description provided for @fileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get fileSettings;

  /// No description provided for @fileQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get fileQuit;

  /// No description provided for @editUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get editUndo;

  /// No description provided for @editRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get editRedo;

  /// No description provided for @editCut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get editCut;

  /// No description provided for @editCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get editCopy;

  /// No description provided for @editPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get editPaste;

  /// No description provided for @editFind.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get editFind;

  /// No description provided for @editReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get editReplace;

  /// No description provided for @editFindInFiles.
  ///
  /// In en, this message translates to:
  /// **'Find in Files'**
  String get editFindInFiles;

  /// No description provided for @viewEditMode.
  ///
  /// In en, this message translates to:
  /// **'Edit Mode'**
  String get viewEditMode;

  /// No description provided for @viewSourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source Code'**
  String get viewSourceCode;

  /// No description provided for @viewPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get viewPreview;

  /// No description provided for @viewSplitView.
  ///
  /// In en, this message translates to:
  /// **'Split View'**
  String get viewSplitView;

  /// No description provided for @viewShowSidebar.
  ///
  /// In en, this message translates to:
  /// **'Show Sidebar'**
  String get viewShowSidebar;

  /// No description provided for @viewHideSidebar.
  ///
  /// In en, this message translates to:
  /// **'Hide Sidebar'**
  String get viewHideSidebar;

  /// No description provided for @viewShowTabBar.
  ///
  /// In en, this message translates to:
  /// **'Show Tab Bar'**
  String get viewShowTabBar;

  /// No description provided for @viewHideTabBar.
  ///
  /// In en, this message translates to:
  /// **'Hide Tab Bar'**
  String get viewHideTabBar;

  /// No description provided for @viewFocusMode.
  ///
  /// In en, this message translates to:
  /// **'Focus Mode'**
  String get viewFocusMode;

  /// No description provided for @viewTypewriterMode.
  ///
  /// In en, this message translates to:
  /// **'Typewriter Mode'**
  String get viewTypewriterMode;

  /// No description provided for @viewZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom In'**
  String get viewZoomIn;

  /// No description provided for @viewZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom Out'**
  String get viewZoomOut;

  /// No description provided for @viewResetZoom.
  ///
  /// In en, this message translates to:
  /// **'Reset Zoom'**
  String get viewResetZoom;

  /// No description provided for @formatBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get formatBold;

  /// No description provided for @formatItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get formatItalic;

  /// No description provided for @formatStrikethrough.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get formatStrikethrough;

  /// No description provided for @formatHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading {level}'**
  String formatHeading(int level);

  /// No description provided for @formatOrderedList.
  ///
  /// In en, this message translates to:
  /// **'Ordered List'**
  String get formatOrderedList;

  /// No description provided for @formatUnorderedList.
  ///
  /// In en, this message translates to:
  /// **'Unordered List'**
  String get formatUnorderedList;

  /// No description provided for @formatTaskList.
  ///
  /// In en, this message translates to:
  /// **'Task List'**
  String get formatTaskList;

  /// No description provided for @formatCodeBlock.
  ///
  /// In en, this message translates to:
  /// **'Code Block'**
  String get formatCodeBlock;

  /// No description provided for @formatQuoteBlock.
  ///
  /// In en, this message translates to:
  /// **'Quote Block'**
  String get formatQuoteBlock;

  /// No description provided for @formatMathBlock.
  ///
  /// In en, this message translates to:
  /// **'Math Block'**
  String get formatMathBlock;

  /// No description provided for @formatTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get formatTable;

  /// No description provided for @formatLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get formatLink;

  /// No description provided for @formatImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get formatImage;

  /// No description provided for @formatHorizontalRule.
  ///
  /// In en, this message translates to:
  /// **'Horizontal Rule'**
  String get formatHorizontalRule;

  /// No description provided for @windowMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get windowMinimize;

  /// No description provided for @windowFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Toggle Full Screen'**
  String get windowFullScreen;

  /// No description provided for @windowAlwaysOnTop.
  ///
  /// In en, this message translates to:
  /// **'Always on Top'**
  String get windowAlwaysOnTop;

  /// No description provided for @helpAbout.
  ///
  /// In en, this message translates to:
  /// **'About MarkText Plus'**
  String get helpAbout;

  /// No description provided for @helpCheckUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get helpCheckUpdates;

  /// No description provided for @helpChangelog.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get helpChangelog;

  /// No description provided for @helpReportBug.
  ///
  /// In en, this message translates to:
  /// **'Report Bug'**
  String get helpReportBug;

  /// No description provided for @helpRequestFeature.
  ///
  /// In en, this message translates to:
  /// **'Request Feature'**
  String get helpRequestFeature;

  /// No description provided for @helpGitHub.
  ///
  /// In en, this message translates to:
  /// **'GitHub Repository'**
  String get helpGitHub;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get settingsEditor;

  /// No description provided for @settingsMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Markdown'**
  String get settingsMarkdown;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsKeybindings.
  ///
  /// In en, this message translates to:
  /// **'Keybindings'**
  String get settingsKeybindings;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsAutoSave.
  ///
  /// In en, this message translates to:
  /// **'Auto Save'**
  String get settingsAutoSave;

  /// No description provided for @settingsAutoSaveDelay.
  ///
  /// In en, this message translates to:
  /// **'Auto Save Delay (ms)'**
  String get settingsAutoSaveDelay;

  /// No description provided for @settingsFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get settingsFontSize;

  /// No description provided for @settingsLineHeight.
  ///
  /// In en, this message translates to:
  /// **'Line Height'**
  String get settingsLineHeight;

  /// No description provided for @settingsTabSize.
  ///
  /// In en, this message translates to:
  /// **'Tab Size'**
  String get settingsTabSize;

  /// No description provided for @settingsEnableHtml.
  ///
  /// In en, this message translates to:
  /// **'Enable HTML'**
  String get settingsEnableHtml;

  /// No description provided for @settingsResetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get settingsResetDefaults;

  /// No description provided for @statusLine.
  ///
  /// In en, this message translates to:
  /// **'Ln {line}, Col {col}'**
  String statusLine(int line, int col);

  /// No description provided for @statusEncoding.
  ///
  /// In en, this message translates to:
  /// **'UTF-8'**
  String get statusEncoding;

  /// No description provided for @statusMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Markdown'**
  String get statusMarkdown;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to save changes before closing?'**
  String get unsavedChangesMessage;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @dontSave.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Save'**
  String get dontSave;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @openRecentFiles.
  ///
  /// In en, this message translates to:
  /// **'Open Recent Files'**
  String get openRecentFiles;

  /// No description provided for @noRecentFiles.
  ///
  /// In en, this message translates to:
  /// **'No Recent Files'**
  String get noRecentFiles;

  /// No description provided for @sidebarFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get sidebarFiles;

  /// No description provided for @sidebarSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get sidebarSearch;

  /// No description provided for @sidebarToc.
  ///
  /// In en, this message translates to:
  /// **'Table of Contents'**
  String get sidebarToc;

  /// No description provided for @sidebarSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get sidebarSettings;

  /// No description provided for @formatHeadingSubmenu.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get formatHeadingSubmenu;

  /// No description provided for @settingsBulletListMarker.
  ///
  /// In en, this message translates to:
  /// **'Bullet List Marker'**
  String get settingsBulletListMarker;

  /// No description provided for @settingsLightThemes.
  ///
  /// In en, this message translates to:
  /// **'Light Themes'**
  String get settingsLightThemes;

  /// No description provided for @settingsDarkThemes.
  ///
  /// In en, this message translates to:
  /// **'Dark Themes'**
  String get settingsDarkThemes;

  /// No description provided for @confirmResetMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all settings to defaults?'**
  String get confirmResetMessage;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @noFiles.
  ///
  /// In en, this message translates to:
  /// **'No files'**
  String get noFiles;

  /// No description provided for @noOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Open a folder to browse files'**
  String get noOpenFolder;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search in files...'**
  String get searchPlaceholder;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get searchNoResults;

  /// No description provided for @searchResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results found'**
  String searchResultCount(int count);

  /// No description provided for @tocEmpty.
  ///
  /// In en, this message translates to:
  /// **'No headings found'**
  String get tocEmpty;

  /// No description provided for @editFindNext.
  ///
  /// In en, this message translates to:
  /// **'Find Next'**
  String get editFindNext;

  /// No description provided for @editFindPrevious.
  ///
  /// In en, this message translates to:
  /// **'Find Previous'**
  String get editFindPrevious;

  /// No description provided for @editReplaceAll.
  ///
  /// In en, this message translates to:
  /// **'Replace All'**
  String get editReplaceAll;

  /// No description provided for @editCaseSensitive.
  ///
  /// In en, this message translates to:
  /// **'Case Sensitive'**
  String get editCaseSensitive;

  /// No description provided for @editWholeWord.
  ///
  /// In en, this message translates to:
  /// **'Whole Word'**
  String get editWholeWord;

  /// No description provided for @editRegex.
  ///
  /// In en, this message translates to:
  /// **'Regular Expression'**
  String get editRegex;

  /// No description provided for @editCopyAsMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Copy as Markdown'**
  String get editCopyAsMarkdown;

  /// No description provided for @editCopyAsHtml.
  ///
  /// In en, this message translates to:
  /// **'Copy as HTML'**
  String get editCopyAsHtml;

  /// No description provided for @editSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get editSelectAll;

  /// No description provided for @editDuplicateLine.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Line'**
  String get editDuplicateLine;

  /// No description provided for @formatUnderline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get formatUnderline;

  /// No description provided for @formatSuperscript.
  ///
  /// In en, this message translates to:
  /// **'Superscript'**
  String get formatSuperscript;

  /// No description provided for @formatSubscript.
  ///
  /// In en, this message translates to:
  /// **'Subscript'**
  String get formatSubscript;

  /// No description provided for @formatHighlight.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get formatHighlight;

  /// No description provided for @formatInlineCode.
  ///
  /// In en, this message translates to:
  /// **'Inline Code'**
  String get formatInlineCode;

  /// No description provided for @formatInlineMath.
  ///
  /// In en, this message translates to:
  /// **'Inline Math'**
  String get formatInlineMath;

  /// No description provided for @formatClearFormatting.
  ///
  /// In en, this message translates to:
  /// **'Clear Formatting'**
  String get formatClearFormatting;

  /// No description provided for @settingsCodeFontFamily.
  ///
  /// In en, this message translates to:
  /// **'Code Font Family'**
  String get settingsCodeFontFamily;

  /// No description provided for @settingsEditorMaxWidth.
  ///
  /// In en, this message translates to:
  /// **'Editor Max Width'**
  String get settingsEditorMaxWidth;

  /// No description provided for @settingsTextDirection.
  ///
  /// In en, this message translates to:
  /// **'Text Direction'**
  String get settingsTextDirection;

  /// No description provided for @keybindingsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Keybinding'**
  String get keybindingsEdit;

  /// No description provided for @keybindingsPressKeys.
  ///
  /// In en, this message translates to:
  /// **'Press key combination...'**
  String get keybindingsPressKeys;

  /// No description provided for @keybindingsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get keybindingsReset;

  /// No description provided for @statusWords.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get statusWords;

  /// No description provided for @statusChars.
  ///
  /// In en, this message translates to:
  /// **'Chars'**
  String get statusChars;

  /// No description provided for @statusParagraphs.
  ///
  /// In en, this message translates to:
  /// **'Paragraphs'**
  String get statusParagraphs;

  /// No description provided for @themeCadmiumLight.
  ///
  /// In en, this message translates to:
  /// **'Cadmium Light'**
  String get themeCadmiumLight;

  /// No description provided for @themeOneDark.
  ///
  /// In en, this message translates to:
  /// **'One Dark'**
  String get themeOneDark;

  /// No description provided for @themeMaterialDark.
  ///
  /// In en, this message translates to:
  /// **'Material Dark'**
  String get themeMaterialDark;

  /// No description provided for @themeGraphiteLight.
  ///
  /// In en, this message translates to:
  /// **'Graphite Light'**
  String get themeGraphiteLight;

  /// No description provided for @themeUlyssesLight.
  ///
  /// In en, this message translates to:
  /// **'Ulysses Light'**
  String get themeUlyssesLight;

  /// No description provided for @themeRedGraphite.
  ///
  /// In en, this message translates to:
  /// **'Red Graphite'**
  String get themeRedGraphite;

  /// No description provided for @themeShibuya.
  ///
  /// In en, this message translates to:
  /// **'Shibuya'**
  String get themeShibuya;

  /// No description provided for @themeDarkGraphite.
  ///
  /// In en, this message translates to:
  /// **'Dark Graphite'**
  String get themeDarkGraphite;

  /// No description provided for @themeDieciOLED.
  ///
  /// In en, this message translates to:
  /// **'Dieci OLED'**
  String get themeDieciOLED;

  /// No description provided for @themeNord.
  ///
  /// In en, this message translates to:
  /// **'Nord'**
  String get themeNord;

  /// No description provided for @keybindingBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get keybindingBold;

  /// No description provided for @keybindingItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get keybindingItalic;

  /// No description provided for @keybindingUnderline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get keybindingUnderline;

  /// No description provided for @keybindingStrikethrough.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get keybindingStrikethrough;

  /// No description provided for @keybindingHeading1.
  ///
  /// In en, this message translates to:
  /// **'Heading 1'**
  String get keybindingHeading1;

  /// No description provided for @keybindingHeading2.
  ///
  /// In en, this message translates to:
  /// **'Heading 2'**
  String get keybindingHeading2;

  /// No description provided for @keybindingHeading3.
  ///
  /// In en, this message translates to:
  /// **'Heading 3'**
  String get keybindingHeading3;

  /// No description provided for @keybindingHeading4.
  ///
  /// In en, this message translates to:
  /// **'Heading 4'**
  String get keybindingHeading4;

  /// No description provided for @keybindingHeading5.
  ///
  /// In en, this message translates to:
  /// **'Heading 5'**
  String get keybindingHeading5;

  /// No description provided for @keybindingHeading6.
  ///
  /// In en, this message translates to:
  /// **'Heading 6'**
  String get keybindingHeading6;

  /// No description provided for @keybindingOrderedList.
  ///
  /// In en, this message translates to:
  /// **'Ordered List'**
  String get keybindingOrderedList;

  /// No description provided for @keybindingUnorderedList.
  ///
  /// In en, this message translates to:
  /// **'Unordered List'**
  String get keybindingUnorderedList;

  /// No description provided for @keybindingTaskList.
  ///
  /// In en, this message translates to:
  /// **'Task List'**
  String get keybindingTaskList;

  /// No description provided for @keybindingCodeBlock.
  ///
  /// In en, this message translates to:
  /// **'Code Block'**
  String get keybindingCodeBlock;

  /// No description provided for @keybindingQuoteBlock.
  ///
  /// In en, this message translates to:
  /// **'Quote Block'**
  String get keybindingQuoteBlock;

  /// No description provided for @keybindingTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get keybindingTable;

  /// No description provided for @keybindingLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get keybindingLink;

  /// No description provided for @keybindingImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get keybindingImage;

  /// No description provided for @keybindingInlineCode.
  ///
  /// In en, this message translates to:
  /// **'Inline Code'**
  String get keybindingInlineCode;

  /// No description provided for @keybindingInlineMath.
  ///
  /// In en, this message translates to:
  /// **'Inline Math'**
  String get keybindingInlineMath;

  /// No description provided for @keybindingMathBlock.
  ///
  /// In en, this message translates to:
  /// **'Math Block'**
  String get keybindingMathBlock;

  /// No description provided for @keybindingFind.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get keybindingFind;

  /// No description provided for @keybindingReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get keybindingReplace;

  /// No description provided for @keybindingSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get keybindingSave;

  /// No description provided for @keybindingOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get keybindingOpen;

  /// No description provided for @keybindingUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get keybindingUndo;

  /// No description provided for @keybindingRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get keybindingRedo;

  /// No description provided for @keybindingSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get keybindingSelectAll;

  /// No description provided for @keybindingDuplicateLine.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Line'**
  String get keybindingDuplicateLine;

  /// No description provided for @keybindingHighlight.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get keybindingHighlight;

  /// No description provided for @closeFile.
  ///
  /// In en, this message translates to:
  /// **'Close File'**
  String get closeFile;

  /// No description provided for @copyFileName.
  ///
  /// In en, this message translates to:
  /// **'Copy File Name'**
  String get copyFileName;

  /// No description provided for @copyFilePath.
  ///
  /// In en, this message translates to:
  /// **'Copy File Path'**
  String get copyFilePath;

  /// No description provided for @deleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete File'**
  String get deleteFile;

  /// No description provided for @confirmDeleteFile.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{fileName}\"?'**
  String confirmDeleteFile(String fileName);

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New Folder'**
  String get newFolder;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @fileNameHint.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get fileNameHint;

  /// No description provided for @folderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderNameHint;

  /// No description provided for @newNameHint.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get newNameHint;

  /// No description provided for @closeOtherTabs.
  ///
  /// In en, this message translates to:
  /// **'Close Other Tabs'**
  String get closeOtherTabs;

  /// No description provided for @closeTabsToRight.
  ///
  /// In en, this message translates to:
  /// **'Close Tabs to the Right'**
  String get closeTabsToRight;

  /// No description provided for @closeAllTabs.
  ///
  /// In en, this message translates to:
  /// **'Close All Tabs'**
  String get closeAllTabs;

  /// No description provided for @revealInExplorer.
  ///
  /// In en, this message translates to:
  /// **'Reveal in File Explorer'**
  String get revealInExplorer;

  /// No description provided for @formatTextSubmenu.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get formatTextSubmenu;

  /// No description provided for @formatBlocksSubmenu.
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get formatBlocksSubmenu;

  /// No description provided for @formatCodeSubmenu.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get formatCodeSubmenu;

  /// No description provided for @formatInsertSubmenu.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get formatInsertSubmenu;

  /// No description provided for @fileRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get fileRename;

  /// No description provided for @newTab.
  ///
  /// In en, this message translates to:
  /// **'New Tab'**
  String get newTab;

  /// No description provided for @newNameHintDialog.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get newNameHintDialog;

  /// No description provided for @commandPaletteHint.
  ///
  /// In en, this message translates to:
  /// **'Type a command...'**
  String get commandPaletteHint;

  /// No description provided for @commandPaletteNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching commands'**
  String get commandPaletteNoResults;

  /// No description provided for @statusLineFeed.
  ///
  /// In en, this message translates to:
  /// **'LF'**
  String get statusLineFeed;

  /// No description provided for @settingsTextDirectionLtr.
  ///
  /// In en, this message translates to:
  /// **'LTR'**
  String get settingsTextDirectionLtr;

  /// No description provided for @settingsTextDirectionRtl.
  ///
  /// In en, this message translates to:
  /// **'RTL'**
  String get settingsTextDirectionRtl;

  /// No description provided for @commandFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Format: {action}'**
  String commandFormatLabel(String action);

  /// No description provided for @commandFormatDesc.
  ///
  /// In en, this message translates to:
  /// **'Apply {action} formatting'**
  String commandFormatDesc(String action);

  /// No description provided for @commandNewFile.
  ///
  /// In en, this message translates to:
  /// **'New File'**
  String get commandNewFile;

  /// No description provided for @commandNewFileDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a new untitled file'**
  String get commandNewFileDesc;

  /// No description provided for @commandSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commandSave;

  /// No description provided for @commandSaveDesc.
  ///
  /// In en, this message translates to:
  /// **'Save the current file'**
  String get commandSaveDesc;

  /// No description provided for @commandSourceMode.
  ///
  /// In en, this message translates to:
  /// **'Source Mode'**
  String get commandSourceMode;

  /// No description provided for @commandSourceModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Switch to source code editing mode'**
  String get commandSourceModeDesc;

  /// No description provided for @commandPreviewMode.
  ///
  /// In en, this message translates to:
  /// **'Preview Mode'**
  String get commandPreviewMode;

  /// No description provided for @commandPreviewModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Switch to preview mode'**
  String get commandPreviewModeDesc;

  /// No description provided for @commandSplitMode.
  ///
  /// In en, this message translates to:
  /// **'Split Mode'**
  String get commandSplitMode;

  /// No description provided for @commandSplitModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Switch to split editing mode'**
  String get commandSplitModeDesc;

  /// No description provided for @commandToggleFocusMode.
  ///
  /// In en, this message translates to:
  /// **'Toggle Focus Mode'**
  String get commandToggleFocusMode;

  /// No description provided for @commandToggleFocusModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Toggle distraction-free focus mode'**
  String get commandToggleFocusModeDesc;

  /// No description provided for @commandToggleTypewriterMode.
  ///
  /// In en, this message translates to:
  /// **'Toggle Typewriter Mode'**
  String get commandToggleTypewriterMode;

  /// No description provided for @commandToggleTypewriterModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Toggle typewriter scrolling mode'**
  String get commandToggleTypewriterModeDesc;

  /// No description provided for @commandToggleSidebar.
  ///
  /// In en, this message translates to:
  /// **'Toggle Sidebar'**
  String get commandToggleSidebar;

  /// No description provided for @commandToggleSidebarDesc.
  ///
  /// In en, this message translates to:
  /// **'Show or hide the sidebar'**
  String get commandToggleSidebarDesc;

  /// No description provided for @commandToggleTabBar.
  ///
  /// In en, this message translates to:
  /// **'Toggle Tab Bar'**
  String get commandToggleTabBar;

  /// No description provided for @commandToggleTabBarDesc.
  ///
  /// In en, this message translates to:
  /// **'Show or hide the tab bar'**
  String get commandToggleTabBarDesc;

  /// No description provided for @welcomeNewFile.
  ///
  /// In en, this message translates to:
  /// **'New File'**
  String get welcomeNewFile;

  /// No description provided for @welcomeOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get welcomeOpenFile;

  /// No description provided for @welcomeDragHint.
  ///
  /// In en, this message translates to:
  /// **'Drop files here to open'**
  String get welcomeDragHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'ko',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

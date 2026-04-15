// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MarkText Plus';

  @override
  String get menuFile => 'File';

  @override
  String get menuEdit => 'Edit';

  @override
  String get menuView => 'View';

  @override
  String get menuFormat => 'Format';

  @override
  String get menuWindow => 'Window';

  @override
  String get menuHelp => 'Help';

  @override
  String get fileNew => 'New File';

  @override
  String get fileNewWindow => 'New Window';

  @override
  String get fileOpen => 'Open File';

  @override
  String get fileOpenFolder => 'Open Folder';

  @override
  String get fileSave => 'Save';

  @override
  String get fileSaveAs => 'Save As';

  @override
  String get fileRecentFiles => 'Recent Files';

  @override
  String get fileNoRecentFiles => 'No Recent Files';

  @override
  String get fileExport => 'Export';

  @override
  String get fileExportHtml => 'HTML';

  @override
  String get fileExportPdf => 'PDF';

  @override
  String get fileSettings => 'Settings';

  @override
  String get fileQuit => 'Quit';

  @override
  String get editUndo => 'Undo';

  @override
  String get editRedo => 'Redo';

  @override
  String get editCut => 'Cut';

  @override
  String get editCopy => 'Copy';

  @override
  String get editPaste => 'Paste';

  @override
  String get editFind => 'Find';

  @override
  String get editReplace => 'Replace';

  @override
  String get editFindInFiles => 'Find in Files';

  @override
  String get viewEditMode => 'Edit Mode';

  @override
  String get viewSourceCode => 'Source Code';

  @override
  String get viewPreview => 'Preview';

  @override
  String get viewSplitView => 'Split View';

  @override
  String get viewShowSidebar => 'Show Sidebar';

  @override
  String get viewHideSidebar => 'Hide Sidebar';

  @override
  String get viewShowTabBar => 'Show Tab Bar';

  @override
  String get viewHideTabBar => 'Hide Tab Bar';

  @override
  String get viewFocusMode => 'Focus Mode';

  @override
  String get viewTypewriterMode => 'Typewriter Mode';

  @override
  String get viewZoomIn => 'Zoom In';

  @override
  String get viewZoomOut => 'Zoom Out';

  @override
  String get viewResetZoom => 'Reset Zoom';

  @override
  String get formatBold => 'Bold';

  @override
  String get formatItalic => 'Italic';

  @override
  String get formatStrikethrough => 'Strikethrough';

  @override
  String formatHeading(int level) {
    return 'Heading $level';
  }

  @override
  String get formatOrderedList => 'Ordered List';

  @override
  String get formatUnorderedList => 'Unordered List';

  @override
  String get formatTaskList => 'Task List';

  @override
  String get formatCodeBlock => 'Code Block';

  @override
  String get formatQuoteBlock => 'Quote Block';

  @override
  String get formatMathBlock => 'Math Block';

  @override
  String get formatTable => 'Table';

  @override
  String get formatLink => 'Link';

  @override
  String get formatImage => 'Image';

  @override
  String get formatHorizontalRule => 'Horizontal Rule';

  @override
  String get windowMinimize => 'Minimize';

  @override
  String get windowFullScreen => 'Toggle Full Screen';

  @override
  String get windowAlwaysOnTop => 'Always on Top';

  @override
  String get helpAbout => 'About MarkText Plus';

  @override
  String get helpCheckUpdates => 'Check for Updates';

  @override
  String get helpChangelog => 'Changelog';

  @override
  String get helpReportBug => 'Report Bug';

  @override
  String get helpRequestFeature => 'Request Feature';

  @override
  String get helpGitHub => 'GitHub Repository';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsEditor => 'Editor';

  @override
  String get settingsMarkdown => 'Markdown';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsKeybindings => 'Keybindings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAutoSave => 'Auto Save';

  @override
  String get settingsAutoSaveDelay => 'Auto Save Delay (ms)';

  @override
  String get settingsFontSize => 'Font Size';

  @override
  String get settingsLineHeight => 'Line Height';

  @override
  String get settingsTabSize => 'Tab Size';

  @override
  String get settingsEnableHtml => 'Enable HTML';

  @override
  String get settingsResetDefaults => 'Reset to Defaults';

  @override
  String statusLine(int line, int col) {
    return 'Ln $line, Col $col';
  }

  @override
  String get statusEncoding => 'UTF-8';

  @override
  String get statusMarkdown => 'Markdown';

  @override
  String get unsavedChanges => 'Unsaved Changes';

  @override
  String get unsavedChangesMessage =>
      'Do you want to save changes before closing?';

  @override
  String get save => 'Save';

  @override
  String get dontSave => 'Don\'t Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get untitled => 'Untitled';

  @override
  String get openRecentFiles => 'Open Recent Files';

  @override
  String get noRecentFiles => 'No Recent Files';

  @override
  String get sidebarFiles => 'Files';

  @override
  String get sidebarSearch => 'Search';

  @override
  String get sidebarToc => 'Table of Contents';

  @override
  String get sidebarSettings => 'Settings';

  @override
  String get formatHeadingSubmenu => 'Heading';

  @override
  String get settingsBulletListMarker => 'Bullet List Marker';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get confirmResetMessage =>
      'Are you sure you want to reset all settings to defaults?';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get noFiles => 'No files';

  @override
  String get noOpenFolder => 'Open a folder to browse files';

  @override
  String get searchPlaceholder => 'Search in files...';

  @override
  String get searchNoResults => 'No results found';

  @override
  String searchResultCount(int count) {
    return '$count results found';
  }

  @override
  String get tocEmpty => 'No headings found';

  @override
  String get editFindNext => 'Find Next';

  @override
  String get editFindPrevious => 'Find Previous';

  @override
  String get editReplaceAll => 'Replace All';

  @override
  String get editCaseSensitive => 'Case Sensitive';

  @override
  String get editWholeWord => 'Whole Word';

  @override
  String get editRegex => 'Regular Expression';

  @override
  String get editCopyAsMarkdown => 'Copy as Markdown';

  @override
  String get editCopyAsHtml => 'Copy as HTML';

  @override
  String get editSelectAll => 'Select All';

  @override
  String get editDuplicateLine => 'Duplicate Line';

  @override
  String get formatUnderline => 'Underline';

  @override
  String get formatSuperscript => 'Superscript';

  @override
  String get formatSubscript => 'Subscript';

  @override
  String get formatHighlight => 'Highlight';

  @override
  String get formatInlineCode => 'Inline Code';

  @override
  String get formatInlineMath => 'Inline Math';

  @override
  String get formatClearFormatting => 'Clear Formatting';

  @override
  String get settingsCodeFontFamily => 'Code Font Family';

  @override
  String get settingsEditorMaxWidth => 'Editor Max Width';

  @override
  String get settingsTextDirection => 'Text Direction';

  @override
  String get keybindingsEdit => 'Edit Keybinding';

  @override
  String get keybindingsPressKeys => 'Press key combination...';

  @override
  String get keybindingsReset => 'Reset to Default';

  @override
  String get statusWords => 'Words';

  @override
  String get statusChars => 'Chars';

  @override
  String get statusParagraphs => 'Paragraphs';

  @override
  String get themeCadmiumLight => 'Cadmium Light';

  @override
  String get themeOneDark => 'One Dark';

  @override
  String get themeMaterialDark => 'Material Dark';

  @override
  String get themeGraphiteLight => 'Graphite Light';

  @override
  String get themeUlyssesLight => 'Ulysses Light';

  @override
  String get keybindingBold => 'Bold';

  @override
  String get keybindingItalic => 'Italic';

  @override
  String get keybindingUnderline => 'Underline';

  @override
  String get keybindingStrikethrough => 'Strikethrough';

  @override
  String get keybindingHeading1 => 'Heading 1';

  @override
  String get keybindingHeading2 => 'Heading 2';

  @override
  String get keybindingHeading3 => 'Heading 3';

  @override
  String get keybindingHeading4 => 'Heading 4';

  @override
  String get keybindingHeading5 => 'Heading 5';

  @override
  String get keybindingHeading6 => 'Heading 6';

  @override
  String get keybindingOrderedList => 'Ordered List';

  @override
  String get keybindingUnorderedList => 'Unordered List';

  @override
  String get keybindingTaskList => 'Task List';

  @override
  String get keybindingCodeBlock => 'Code Block';

  @override
  String get keybindingQuoteBlock => 'Quote Block';

  @override
  String get keybindingTable => 'Table';

  @override
  String get keybindingLink => 'Link';

  @override
  String get keybindingImage => 'Image';

  @override
  String get keybindingInlineCode => 'Inline Code';

  @override
  String get keybindingInlineMath => 'Inline Math';

  @override
  String get keybindingMathBlock => 'Math Block';

  @override
  String get keybindingFind => 'Find';

  @override
  String get keybindingReplace => 'Replace';

  @override
  String get keybindingSave => 'Save';

  @override
  String get keybindingOpen => 'Open';

  @override
  String get keybindingUndo => 'Undo';

  @override
  String get keybindingRedo => 'Redo';

  @override
  String get keybindingSelectAll => 'Select All';

  @override
  String get keybindingDuplicateLine => 'Duplicate Line';

  @override
  String get keybindingHighlight => 'Highlight';

  @override
  String get closeFile => 'Close File';

  @override
  String get copyFileName => 'Copy File Name';

  @override
  String get copyFilePath => 'Copy File Path';

  @override
  String get deleteFile => 'Delete File';

  @override
  String confirmDeleteFile(String fileName) {
    return 'Are you sure you want to delete \"$fileName\"?';
  }
}

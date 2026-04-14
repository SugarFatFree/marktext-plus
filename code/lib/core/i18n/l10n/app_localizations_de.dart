// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'MarkText Plus';

  @override
  String get menuFile => 'Datei';

  @override
  String get menuEdit => 'Bearbeiten';

  @override
  String get menuView => 'Ansicht';

  @override
  String get menuFormat => 'Format';

  @override
  String get menuWindow => 'Fenster';

  @override
  String get menuHelp => 'Hilfe';

  @override
  String get fileNew => 'Neue Datei';

  @override
  String get fileNewWindow => 'Neues Fenster';

  @override
  String get fileOpen => 'Datei öffnen';

  @override
  String get fileOpenFolder => 'Ordner öffnen';

  @override
  String get fileSave => 'Speichern';

  @override
  String get fileSaveAs => 'Speichern unter';

  @override
  String get fileRecentFiles => 'Recent Files';

  @override
  String get fileNoRecentFiles => 'No Recent Files';

  @override
  String get fileExport => 'Exportieren';

  @override
  String get fileExportHtml => 'HTML';

  @override
  String get fileExportPdf => 'PDF';

  @override
  String get fileSettings => 'Einstellungen';

  @override
  String get fileQuit => 'Beenden';

  @override
  String get editUndo => 'Rückgängig';

  @override
  String get editRedo => 'Wiederholen';

  @override
  String get editCut => 'Ausschneiden';

  @override
  String get editCopy => 'Kopieren';

  @override
  String get editPaste => 'Einfügen';

  @override
  String get editFind => 'Suchen';

  @override
  String get editReplace => 'Ersetzen';

  @override
  String get editFindInFiles => 'In Dateien suchen';

  @override
  String get viewEditMode => 'Bearbeitungsmodus';

  @override
  String get viewSourceCode => 'Quellcode';

  @override
  String get viewPreview => 'Vorschau';

  @override
  String get viewSplitView => 'Geteilte Ansicht';

  @override
  String get viewShowSidebar => 'Seitenleiste anzeigen';

  @override
  String get viewHideSidebar => 'Seitenleiste ausblenden';

  @override
  String get viewShowTabBar => 'Tab-Leiste anzeigen';

  @override
  String get viewHideTabBar => 'Tab-Leiste ausblenden';

  @override
  String get viewFocusMode => 'Fokusmodus';

  @override
  String get viewTypewriterMode => 'Schreibmaschinenmodus';

  @override
  String get viewZoomIn => 'Vergrößern';

  @override
  String get viewZoomOut => 'Verkleinern';

  @override
  String get viewResetZoom => 'Zoom zurücksetzen';

  @override
  String get formatBold => 'Fett';

  @override
  String get formatItalic => 'Kursiv';

  @override
  String get formatStrikethrough => 'Durchgestrichen';

  @override
  String formatHeading(int level) {
    return 'Überschrift $level';
  }

  @override
  String get formatOrderedList => 'Nummerierte Liste';

  @override
  String get formatUnorderedList => 'Aufzählungsliste';

  @override
  String get formatTaskList => 'Aufgabenliste';

  @override
  String get formatCodeBlock => 'Codeblock';

  @override
  String get formatQuoteBlock => 'Zitatblock';

  @override
  String get formatMathBlock => 'Mathematikblock';

  @override
  String get formatTable => 'Tabelle';

  @override
  String get formatLink => 'Link';

  @override
  String get formatImage => 'Bild';

  @override
  String get formatHorizontalRule => 'Horizontale Linie';

  @override
  String get windowMinimize => 'Minimieren';

  @override
  String get windowFullScreen => 'Vollbild umschalten';

  @override
  String get windowAlwaysOnTop => 'Immer im Vordergrund';

  @override
  String get helpAbout => 'Über MarkText Plus';

  @override
  String get helpCheckUpdates => 'Nach Updates suchen';

  @override
  String get helpChangelog => 'Änderungsprotokoll';

  @override
  String get helpReportBug => 'Fehler melden';

  @override
  String get helpRequestFeature => 'Funktion vorschlagen';

  @override
  String get helpGitHub => 'GitHub-Repository';

  @override
  String get settingsGeneral => 'Allgemein';

  @override
  String get settingsEditor => 'Editor';

  @override
  String get settingsMarkdown => 'Markdown';

  @override
  String get settingsTheme => 'Design';

  @override
  String get settingsKeybindings => 'Tastenkürzel';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsAutoSave => 'Automatisch speichern';

  @override
  String get settingsAutoSaveDelay => 'Automatische Speicherverzögerung (ms)';

  @override
  String get settingsFontSize => 'Schriftgröße';

  @override
  String get settingsLineHeight => 'Zeilenhöhe';

  @override
  String get settingsTabSize => 'Tab-Größe';

  @override
  String get settingsEnableHtml => 'HTML aktivieren';

  @override
  String get settingsResetDefaults => 'Auf Standard zurücksetzen';

  @override
  String statusLine(int line, int col) {
    return 'Zeile $line, Spalte $col';
  }

  @override
  String get statusEncoding => 'UTF-8';

  @override
  String get statusMarkdown => 'Markdown';

  @override
  String get unsavedChanges => 'Nicht gespeicherte Änderungen';

  @override
  String get unsavedChangesMessage =>
      'Möchten Sie die Änderungen vor dem Schließen speichern?';

  @override
  String get save => 'Speichern';

  @override
  String get dontSave => 'Nicht speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get ok => 'OK';

  @override
  String get untitled => 'Unbenannt';

  @override
  String get openRecentFiles => 'Zuletzt geöffnete Dateien';

  @override
  String get noRecentFiles => 'Keine zuletzt geöffneten Dateien';

  @override
  String get sidebarFiles => 'Dateien';

  @override
  String get sidebarSearch => 'Suche';

  @override
  String get sidebarToc => 'Inhaltsverzeichnis';

  @override
  String get sidebarSettings => 'Einstellungen';

  @override
  String get formatHeadingSubmenu => 'Überschrift';

  @override
  String get settingsBulletListMarker => 'Aufzählungszeichen';

  @override
  String get settingsDarkMode => 'Dunkelmodus';

  @override
  String get confirmResetMessage =>
      'Möchten Sie alle Einstellungen auf die Standardwerte zurücksetzen?';

  @override
  String get comingSoon => 'Demnächst';

  @override
  String get noFiles => 'Keine Dateien';

  @override
  String get noOpenFolder => 'Ordner öffnen um Dateien zu durchsuchen';

  @override
  String get searchPlaceholder => 'In Dateien suchen...';

  @override
  String get searchNoResults => 'Keine Ergebnisse gefunden';

  @override
  String searchResultCount(int count) {
    return '$count Ergebnisse gefunden';
  }

  @override
  String get tocEmpty => 'Keine Überschriften gefunden';

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
}

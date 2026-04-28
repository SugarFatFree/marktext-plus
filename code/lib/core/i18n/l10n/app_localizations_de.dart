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
  String get settingsLightThemes => 'Helle Themen';

  @override
  String get settingsDarkThemes => 'Dunkle Themen';

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
  String get editFindNext => 'Weitersuchen';

  @override
  String get editFindPrevious => 'Vorheriges suchen';

  @override
  String get editReplaceAll => 'Alle ersetzen';

  @override
  String get editCaseSensitive => 'Groß-/Kleinschreibung';

  @override
  String get editWholeWord => 'Ganzes Wort';

  @override
  String get editRegex => 'Regulärer Ausdruck';

  @override
  String get editCopyAsMarkdown => 'Als Markdown kopieren';

  @override
  String get editCopyAsHtml => 'Als HTML kopieren';

  @override
  String get editSelectAll => 'Alles auswählen';

  @override
  String get editDuplicateLine => 'Zeile duplizieren';

  @override
  String get formatUnderline => 'Unterstrichen';

  @override
  String get formatSuperscript => 'Hochgestellt';

  @override
  String get formatSubscript => 'Tiefgestellt';

  @override
  String get formatHighlight => 'Hervorheben';

  @override
  String get formatInlineCode => 'Inline-Code';

  @override
  String get formatInlineMath => 'Inline-Formel';

  @override
  String get formatClearFormatting => 'Formatierung löschen';

  @override
  String get settingsCodeFontFamily => 'Code-Schriftart';

  @override
  String get settingsEditorMaxWidth => 'Maximale Editorbreite';

  @override
  String get settingsTextDirection => 'Textrichtung';

  @override
  String get keybindingsEdit => 'Tastenkürzel bearbeiten';

  @override
  String get keybindingsPressKeys => 'Tastenkombination drücken...';

  @override
  String get keybindingsReset => 'Auf Standard zurücksetzen';

  @override
  String get statusWords => 'Wörter';

  @override
  String get statusChars => 'Zeichen';

  @override
  String get statusParagraphs => 'Absätze';

  @override
  String get themeCadmiumLight => 'Cadmium Hell';

  @override
  String get themeOneDark => 'One Dark';

  @override
  String get themeMaterialDark => 'Material Dunkel';

  @override
  String get themeGraphiteLight => 'Graphit Hell';

  @override
  String get themeUlyssesLight => 'Ulysses Hell';

  @override
  String get themeRedGraphite => 'Rot Graphit';

  @override
  String get themeShibuya => 'Shibuya';

  @override
  String get themePinkBlossom => 'Rosa Blüte';

  @override
  String get themeSkyBlue => 'Himmelblau';

  @override
  String get themeDarkGraphite => 'Dunkel Graphit';

  @override
  String get themeDieciOLED => 'Dieci OLED';

  @override
  String get themeNord => 'Nord';

  @override
  String get themeMidnight => 'Mitternacht';

  @override
  String get keybindingBold => 'Fett';

  @override
  String get keybindingItalic => 'Kursiv';

  @override
  String get keybindingUnderline => 'Unterstrichen';

  @override
  String get keybindingStrikethrough => 'Durchgestrichen';

  @override
  String get keybindingHeading1 => 'Überschrift 1';

  @override
  String get keybindingHeading2 => 'Überschrift 2';

  @override
  String get keybindingHeading3 => 'Überschrift 3';

  @override
  String get keybindingHeading4 => 'Überschrift 4';

  @override
  String get keybindingHeading5 => 'Überschrift 5';

  @override
  String get keybindingHeading6 => 'Überschrift 6';

  @override
  String get keybindingOrderedList => 'Nummerierte Liste';

  @override
  String get keybindingUnorderedList => 'Aufzählungsliste';

  @override
  String get keybindingTaskList => 'Aufgabenliste';

  @override
  String get keybindingCodeBlock => 'Codeblock';

  @override
  String get keybindingQuoteBlock => 'Zitatblock';

  @override
  String get keybindingTable => 'Tabelle';

  @override
  String get keybindingLink => 'Link';

  @override
  String get keybindingImage => 'Bild';

  @override
  String get keybindingInlineCode => 'Inline-Code';

  @override
  String get keybindingInlineMath => 'Inline-Formel';

  @override
  String get keybindingMathBlock => 'Mathematikblock';

  @override
  String get keybindingFind => 'Suchen';

  @override
  String get keybindingReplace => 'Ersetzen';

  @override
  String get keybindingSave => 'Speichern';

  @override
  String get keybindingOpen => 'Öffnen';

  @override
  String get keybindingUndo => 'Rückgängig';

  @override
  String get keybindingRedo => 'Wiederholen';

  @override
  String get keybindingSelectAll => 'Alles auswählen';

  @override
  String get keybindingDuplicateLine => 'Zeile duplizieren';

  @override
  String get keybindingHighlight => 'Hervorheben';

  @override
  String get closeFile => 'Datei schließen';

  @override
  String get copyFileName => 'Dateinamen kopieren';

  @override
  String get copyFilePath => 'Dateipfad kopieren';

  @override
  String get deleteFile => 'Datei löschen';

  @override
  String confirmDeleteFile(String fileName) {
    return 'Sind Sie sicher, dass Sie \"$fileName\" löschen möchten?';
  }

  @override
  String get newFolder => 'Neuer Ordner';

  @override
  String get rename => 'Umbenennen';

  @override
  String get delete => 'Löschen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get fileNameHint => 'Dateiname';

  @override
  String get folderNameHint => 'Ordnername';

  @override
  String get newNameHint => 'Neuer Name';

  @override
  String get closeOtherTabs => 'Andere Tabs schließen';

  @override
  String get closeTabsToRight => 'Tabs rechts schließen';

  @override
  String get closeAllTabs => 'Alle Tabs schließen';

  @override
  String get revealInExplorer => 'Im Datei-Explorer anzeigen';

  @override
  String get formatTextSubmenu => 'Text';

  @override
  String get formatBlocksSubmenu => 'Blöcke';

  @override
  String get formatCodeSubmenu => 'Code';

  @override
  String get formatInsertSubmenu => 'Einfügen';

  @override
  String get fileRename => 'Umbenennen';

  @override
  String get newTab => 'Neuer Tab';

  @override
  String get newNameHintDialog => 'Neuer Name';

  @override
  String get commandPaletteHint => 'Befehl eingeben...';

  @override
  String get commandPaletteNoResults => 'Keine passenden Befehle';

  @override
  String get statusLineFeed => 'LF';

  @override
  String get settingsTextDirectionLtr => 'Links nach rechts';

  @override
  String get settingsTextDirectionRtl => 'Rechts nach links';

  @override
  String commandFormatLabel(String action) {
    return 'Format: $action';
  }

  @override
  String commandFormatDesc(String action) {
    return '$action-Formatierung anwenden';
  }

  @override
  String get commandNewFile => 'Neue Datei';

  @override
  String get commandNewFileDesc => 'Neue unbenannte Datei erstellen';

  @override
  String get commandSave => 'Speichern';

  @override
  String get commandSaveDesc => 'Aktuelle Datei speichern';

  @override
  String get commandSourceMode => 'Quellcode-Modus';

  @override
  String get commandSourceModeDesc =>
      'Zum Quellcode-Bearbeitungsmodus wechseln';

  @override
  String get commandPreviewMode => 'Vorschau-Modus';

  @override
  String get commandPreviewModeDesc => 'Zum Vorschau-Modus wechseln';

  @override
  String get commandSplitMode => 'Geteilter Modus';

  @override
  String get commandSplitModeDesc => 'Zum geteilten Bearbeitungsmodus wechseln';

  @override
  String get commandToggleFocusMode => 'Fokusmodus umschalten';

  @override
  String get commandToggleFocusModeDesc =>
      'Ablenkungsfreien Fokusmodus umschalten';

  @override
  String get commandToggleTypewriterMode => 'Schreibmaschinenmodus umschalten';

  @override
  String get commandToggleTypewriterModeDesc =>
      'Schreibmaschinen-Scrollmodus umschalten';

  @override
  String get commandToggleSidebar => 'Seitenleiste umschalten';

  @override
  String get commandToggleSidebarDesc => 'Seitenleiste ein-/ausblenden';

  @override
  String get commandToggleTabBar => 'Tab-Leiste umschalten';

  @override
  String get commandToggleTabBarDesc => 'Tab-Leiste ein-/ausblenden';

  @override
  String get welcomeNewFile => 'Neue Datei';

  @override
  String get welcomeOpenFile => 'Datei öffnen';

  @override
  String get welcomeDragHint => 'Dateien hierher ziehen zum Öffnen';

  @override
  String get fileOpenBehavior => 'File Opening Behavior';

  @override
  String get fileOpenBehaviorTitle => 'How to Open Files?';

  @override
  String get fileOpenBehaviorMessage =>
      'When you double-click a file while the app is already running:';

  @override
  String get fileOpenBehaviorNewWindow => 'Open in New Window';

  @override
  String get fileOpenBehaviorNewWindowDesc => 'Allow multiple app instances';

  @override
  String get fileOpenBehaviorExistingWindow => 'Open in Current Window';

  @override
  String get fileOpenBehaviorExistingWindowDesc =>
      'Add to existing tabs (single instance)';

  @override
  String get fileOpenBehaviorNotSet => 'Not configured';
}

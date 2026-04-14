// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'MarkText Plus';

  @override
  String get menuFile => 'File';

  @override
  String get menuEdit => 'Modifica';

  @override
  String get menuView => 'Visualizza';

  @override
  String get menuFormat => 'Formato';

  @override
  String get menuWindow => 'Finestra';

  @override
  String get menuHelp => 'Aiuto';

  @override
  String get fileNew => 'Nuovo file';

  @override
  String get fileNewWindow => 'Nuova finestra';

  @override
  String get fileOpen => 'Apri file';

  @override
  String get fileOpenFolder => 'Apri cartella';

  @override
  String get fileSave => 'Salva';

  @override
  String get fileSaveAs => 'Salva con nome';

  @override
  String get fileRecentFiles => 'Recent Files';

  @override
  String get fileNoRecentFiles => 'No Recent Files';

  @override
  String get fileExport => 'Esporta';

  @override
  String get fileExportHtml => 'HTML';

  @override
  String get fileExportPdf => 'PDF';

  @override
  String get fileSettings => 'Impostazioni';

  @override
  String get fileQuit => 'Esci';

  @override
  String get editUndo => 'Annulla';

  @override
  String get editRedo => 'Ripeti';

  @override
  String get editCut => 'Taglia';

  @override
  String get editCopy => 'Copia';

  @override
  String get editPaste => 'Incolla';

  @override
  String get editFind => 'Cerca';

  @override
  String get editReplace => 'Sostituisci';

  @override
  String get editFindInFiles => 'Cerca nei file';

  @override
  String get viewEditMode => 'Modalità modifica';

  @override
  String get viewSourceCode => 'Codice sorgente';

  @override
  String get viewPreview => 'Anteprima';

  @override
  String get viewSplitView => 'Vista divisa';

  @override
  String get viewShowSidebar => 'Mostra barra laterale';

  @override
  String get viewHideSidebar => 'Nascondi barra laterale';

  @override
  String get viewShowTabBar => 'Mostra barra schede';

  @override
  String get viewHideTabBar => 'Nascondi barra schede';

  @override
  String get viewFocusMode => 'Modalità concentrazione';

  @override
  String get viewTypewriterMode => 'Modalità macchina da scrivere';

  @override
  String get viewZoomIn => 'Ingrandisci';

  @override
  String get viewZoomOut => 'Riduci';

  @override
  String get viewResetZoom => 'Reimposta zoom';

  @override
  String get formatBold => 'Grassetto';

  @override
  String get formatItalic => 'Corsivo';

  @override
  String get formatStrikethrough => 'Barrato';

  @override
  String formatHeading(int level) {
    return 'Intestazione $level';
  }

  @override
  String get formatOrderedList => 'Elenco ordinato';

  @override
  String get formatUnorderedList => 'Elenco non ordinato';

  @override
  String get formatTaskList => 'Elenco attività';

  @override
  String get formatCodeBlock => 'Blocco di codice';

  @override
  String get formatQuoteBlock => 'Blocco citazione';

  @override
  String get formatMathBlock => 'Blocco matematico';

  @override
  String get formatTable => 'Tabella';

  @override
  String get formatLink => 'Collegamento';

  @override
  String get formatImage => 'Immagine';

  @override
  String get formatHorizontalRule => 'Linea orizzontale';

  @override
  String get windowMinimize => 'Riduci a icona';

  @override
  String get windowFullScreen => 'Schermo intero';

  @override
  String get windowAlwaysOnTop => 'Sempre in primo piano';

  @override
  String get helpAbout => 'Informazioni su MarkText Plus';

  @override
  String get helpCheckUpdates => 'Controlla aggiornamenti';

  @override
  String get helpChangelog => 'Registro modifiche';

  @override
  String get helpReportBug => 'Segnala un bug';

  @override
  String get helpRequestFeature => 'Richiedi funzionalità';

  @override
  String get helpGitHub => 'Repository GitHub';

  @override
  String get settingsGeneral => 'Generale';

  @override
  String get settingsEditor => 'Editor';

  @override
  String get settingsMarkdown => 'Markdown';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsKeybindings => 'Scorciatoie da tastiera';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsAutoSave => 'Salvataggio automatico';

  @override
  String get settingsAutoSaveDelay => 'Ritardo salvataggio automatico (ms)';

  @override
  String get settingsFontSize => 'Dimensione carattere';

  @override
  String get settingsLineHeight => 'Altezza riga';

  @override
  String get settingsTabSize => 'Dimensione tabulazione';

  @override
  String get settingsEnableHtml => 'Abilita HTML';

  @override
  String get settingsResetDefaults => 'Ripristina impostazioni predefinite';

  @override
  String statusLine(int line, int col) {
    return 'Riga $line, Col $col';
  }

  @override
  String get statusEncoding => 'UTF-8';

  @override
  String get statusMarkdown => 'Markdown';

  @override
  String get unsavedChanges => 'Modifiche non salvate';

  @override
  String get unsavedChangesMessage => 'Salvare le modifiche prima di chiudere?';

  @override
  String get save => 'Salva';

  @override
  String get dontSave => 'Non salvare';

  @override
  String get cancel => 'Annulla';

  @override
  String get ok => 'OK';

  @override
  String get untitled => 'Senza titolo';

  @override
  String get openRecentFiles => 'File recenti';

  @override
  String get noRecentFiles => 'Nessun file recente';

  @override
  String get sidebarFiles => 'File';

  @override
  String get sidebarSearch => 'Cerca';

  @override
  String get sidebarToc => 'Indice';

  @override
  String get sidebarSettings => 'Impostazioni';

  @override
  String get formatHeadingSubmenu => 'Intestazione';

  @override
  String get settingsBulletListMarker => 'Marcatore elenco';

  @override
  String get settingsDarkMode => 'Modalità scura';

  @override
  String get confirmResetMessage =>
      'Ripristinare tutte le impostazioni ai valori predefiniti?';

  @override
  String get comingSoon => 'Prossimamente';

  @override
  String get noFiles => 'Nessun file';

  @override
  String get noOpenFolder => 'Apri una cartella per sfogliare i file';

  @override
  String get searchPlaceholder => 'Cerca nei file...';

  @override
  String get searchNoResults => 'Nessun risultato';

  @override
  String searchResultCount(int count) {
    return '$count risultati trovati';
  }

  @override
  String get tocEmpty => 'Nessuna intestazione trovata';

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
}

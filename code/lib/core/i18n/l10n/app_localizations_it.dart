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
  String get settingsLightThemes => 'Temi chiari';

  @override
  String get settingsDarkThemes => 'Temi scuri';

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
  String get editFindNext => 'Trova successivo';

  @override
  String get editFindPrevious => 'Trova precedente';

  @override
  String get editReplaceAll => 'Sostituisci tutto';

  @override
  String get editCaseSensitive => 'Maiuscole/minuscole';

  @override
  String get editWholeWord => 'Parola intera';

  @override
  String get editRegex => 'Espressione regolare';

  @override
  String get editCopyAsMarkdown => 'Copia come Markdown';

  @override
  String get editCopyAsHtml => 'Copia come HTML';

  @override
  String get editSelectAll => 'Seleziona tutto';

  @override
  String get editDuplicateLine => 'Duplica riga';

  @override
  String get formatUnderline => 'Sottolineato';

  @override
  String get formatSuperscript => 'Apice';

  @override
  String get formatSubscript => 'Pedice';

  @override
  String get formatHighlight => 'Evidenzia';

  @override
  String get formatInlineCode => 'Codice in linea';

  @override
  String get formatInlineMath => 'Formula in linea';

  @override
  String get formatClearFormatting => 'Cancella formattazione';

  @override
  String get settingsCodeFontFamily => 'Font del codice';

  @override
  String get settingsEditorMaxWidth => 'Larghezza massima editor';

  @override
  String get settingsTextDirection => 'Direzione del testo';

  @override
  String get keybindingsEdit => 'Modifica scorciatoia';

  @override
  String get keybindingsPressKeys => 'Premi combinazione di tasti...';

  @override
  String get keybindingsReset => 'Ripristina predefinito';

  @override
  String get statusWords => 'Parole';

  @override
  String get statusChars => 'Caratteri';

  @override
  String get statusParagraphs => 'Paragrafi';

  @override
  String get themeCadmiumLight => 'Cadmium Chiaro';

  @override
  String get themeOneDark => 'One Dark';

  @override
  String get themeMaterialDark => 'Material Scuro';

  @override
  String get themeGraphiteLight => 'Grafite Chiaro';

  @override
  String get themeUlyssesLight => 'Ulysses Chiaro';

  @override
  String get themeRedGraphite => 'Grafite Rosso';

  @override
  String get themeShibuya => 'Shibuya';

  @override
  String get themePinkBlossom => 'Fiore Rosa';

  @override
  String get themeSkyBlue => 'Azzurro Cielo';

  @override
  String get themeDarkGraphite => 'Grafite Scuro';

  @override
  String get themeDieciOLED => 'Dieci OLED';

  @override
  String get themeNord => 'Nord';

  @override
  String get themeMidnight => 'Mezzanotte';

  @override
  String get keybindingBold => 'Grassetto';

  @override
  String get keybindingItalic => 'Corsivo';

  @override
  String get keybindingUnderline => 'Sottolineato';

  @override
  String get keybindingStrikethrough => 'Barrato';

  @override
  String get keybindingHeading1 => 'Intestazione 1';

  @override
  String get keybindingHeading2 => 'Intestazione 2';

  @override
  String get keybindingHeading3 => 'Intestazione 3';

  @override
  String get keybindingHeading4 => 'Intestazione 4';

  @override
  String get keybindingHeading5 => 'Intestazione 5';

  @override
  String get keybindingHeading6 => 'Intestazione 6';

  @override
  String get keybindingOrderedList => 'Elenco ordinato';

  @override
  String get keybindingUnorderedList => 'Elenco non ordinato';

  @override
  String get keybindingTaskList => 'Elenco attività';

  @override
  String get keybindingCodeBlock => 'Blocco di codice';

  @override
  String get keybindingQuoteBlock => 'Blocco citazione';

  @override
  String get keybindingTable => 'Tabella';

  @override
  String get keybindingLink => 'Collegamento';

  @override
  String get keybindingImage => 'Immagine';

  @override
  String get keybindingInlineCode => 'Codice in linea';

  @override
  String get keybindingInlineMath => 'Formula in linea';

  @override
  String get keybindingMathBlock => 'Blocco matematico';

  @override
  String get keybindingFind => 'Cerca';

  @override
  String get keybindingReplace => 'Sostituisci';

  @override
  String get keybindingSave => 'Salva';

  @override
  String get keybindingOpen => 'Apri';

  @override
  String get keybindingUndo => 'Annulla';

  @override
  String get keybindingRedo => 'Ripeti';

  @override
  String get keybindingSelectAll => 'Seleziona tutto';

  @override
  String get keybindingDuplicateLine => 'Duplica riga';

  @override
  String get keybindingHighlight => 'Evidenzia';

  @override
  String get closeFile => 'Chiudi file';

  @override
  String get copyFileName => 'Copia nome file';

  @override
  String get copyFilePath => 'Copia percorso file';

  @override
  String get deleteFile => 'Elimina file';

  @override
  String confirmDeleteFile(String fileName) {
    return 'Sei sicuro di voler eliminare \"$fileName\"?';
  }

  @override
  String get newFolder => 'Nuova cartella';

  @override
  String get rename => 'Rinomina';

  @override
  String get delete => 'Elimina';

  @override
  String get confirm => 'Conferma';

  @override
  String get fileNameHint => 'Nome del file';

  @override
  String get folderNameHint => 'Nome della cartella';

  @override
  String get newNameHint => 'Nuovo nome';

  @override
  String get closeOtherTabs => 'Chiudi le altre schede';

  @override
  String get closeTabsToRight => 'Chiudi le schede a destra';

  @override
  String get closeAllTabs => 'Chiudi tutte le schede';

  @override
  String get revealInExplorer => 'Mostra nel file manager';

  @override
  String get formatTextSubmenu => 'Testo';

  @override
  String get formatBlocksSubmenu => 'Blocchi';

  @override
  String get formatCodeSubmenu => 'Codice';

  @override
  String get formatInsertSubmenu => 'Inserisci';

  @override
  String get fileRename => 'Rinomina';

  @override
  String get newTab => 'Nuova scheda';

  @override
  String get newNameHintDialog => 'Nuovo nome';

  @override
  String get commandPaletteHint => 'Digita un comando...';

  @override
  String get commandPaletteNoResults => 'Nessun comando corrispondente';

  @override
  String get statusLineFeed => 'LF';

  @override
  String get settingsTextDirectionLtr => 'Da sinistra a destra';

  @override
  String get settingsTextDirectionRtl => 'Da destra a sinistra';

  @override
  String commandFormatLabel(String action) {
    return 'Formato: $action';
  }

  @override
  String commandFormatDesc(String action) {
    return 'Applica formattazione $action';
  }

  @override
  String get commandNewFile => 'Nuovo file';

  @override
  String get commandNewFileDesc => 'Crea un nuovo file senza titolo';

  @override
  String get commandSave => 'Salva';

  @override
  String get commandSaveDesc => 'Salva il file corrente';

  @override
  String get commandSourceMode => 'Modalità sorgente';

  @override
  String get commandSourceModeDesc =>
      'Passa alla modalità di modifica del codice sorgente';

  @override
  String get commandPreviewMode => 'Modalità anteprima';

  @override
  String get commandPreviewModeDesc => 'Passa alla modalità anteprima';

  @override
  String get commandSplitMode => 'Modalità divisa';

  @override
  String get commandSplitModeDesc => 'Passa alla modalità di modifica divisa';

  @override
  String get commandToggleFocusMode => 'Attiva/disattiva modalità focus';

  @override
  String get commandToggleFocusModeDesc =>
      'Attiva/disattiva la modalità focus senza distrazioni';

  @override
  String get commandToggleTypewriterMode =>
      'Attiva/disattiva modalità macchina da scrivere';

  @override
  String get commandToggleTypewriterModeDesc =>
      'Attiva/disattiva lo scorrimento macchina da scrivere';

  @override
  String get commandToggleSidebar => 'Attiva/disattiva barra laterale';

  @override
  String get commandToggleSidebarDesc => 'Mostra o nascondi la barra laterale';

  @override
  String get commandToggleTabBar => 'Attiva/disattiva barra schede';

  @override
  String get commandToggleTabBarDesc =>
      'Mostra o nascondi la barra delle schede';

  @override
  String get welcomeNewFile => 'Nuovo file';

  @override
  String get welcomeOpenFile => 'Apri file';

  @override
  String get welcomeDragHint => 'Trascina i file qui per aprirli';

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

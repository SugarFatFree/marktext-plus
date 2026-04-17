// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MarkText Plus';

  @override
  String get menuFile => 'Fichier';

  @override
  String get menuEdit => 'Édition';

  @override
  String get menuView => 'Affichage';

  @override
  String get menuFormat => 'Format';

  @override
  String get menuWindow => 'Fenêtre';

  @override
  String get menuHelp => 'Aide';

  @override
  String get fileNew => 'Nouveau fichier';

  @override
  String get fileNewWindow => 'Nouvelle fenêtre';

  @override
  String get fileOpen => 'Ouvrir un fichier';

  @override
  String get fileOpenFolder => 'Ouvrir un dossier';

  @override
  String get fileSave => 'Enregistrer';

  @override
  String get fileSaveAs => 'Enregistrer sous';

  @override
  String get fileRecentFiles => 'Recent Files';

  @override
  String get fileNoRecentFiles => 'No Recent Files';

  @override
  String get fileExport => 'Exporter';

  @override
  String get fileExportHtml => 'HTML';

  @override
  String get fileExportPdf => 'PDF';

  @override
  String get fileSettings => 'Paramètres';

  @override
  String get fileQuit => 'Quitter';

  @override
  String get editUndo => 'Annuler';

  @override
  String get editRedo => 'Rétablir';

  @override
  String get editCut => 'Couper';

  @override
  String get editCopy => 'Copier';

  @override
  String get editPaste => 'Coller';

  @override
  String get editFind => 'Rechercher';

  @override
  String get editReplace => 'Remplacer';

  @override
  String get editFindInFiles => 'Rechercher dans les fichiers';

  @override
  String get viewEditMode => 'Mode édition';

  @override
  String get viewSourceCode => 'Code source';

  @override
  String get viewPreview => 'Aperçu';

  @override
  String get viewSplitView => 'Vue partagée';

  @override
  String get viewShowSidebar => 'Afficher la barre latérale';

  @override
  String get viewHideSidebar => 'Masquer la barre latérale';

  @override
  String get viewShowTabBar => 'Afficher la barre d\'onglets';

  @override
  String get viewHideTabBar => 'Masquer la barre d\'onglets';

  @override
  String get viewFocusMode => 'Mode concentration';

  @override
  String get viewTypewriterMode => 'Mode machine à écrire';

  @override
  String get viewZoomIn => 'Zoom avant';

  @override
  String get viewZoomOut => 'Zoom arrière';

  @override
  String get viewResetZoom => 'Réinitialiser le zoom';

  @override
  String get formatBold => 'Gras';

  @override
  String get formatItalic => 'Italique';

  @override
  String get formatStrikethrough => 'Barré';

  @override
  String formatHeading(int level) {
    return 'Titre $level';
  }

  @override
  String get formatOrderedList => 'Liste ordonnée';

  @override
  String get formatUnorderedList => 'Liste non ordonnée';

  @override
  String get formatTaskList => 'Liste de tâches';

  @override
  String get formatCodeBlock => 'Bloc de code';

  @override
  String get formatQuoteBlock => 'Bloc de citation';

  @override
  String get formatMathBlock => 'Bloc mathématique';

  @override
  String get formatTable => 'Tableau';

  @override
  String get formatLink => 'Lien';

  @override
  String get formatImage => 'Image';

  @override
  String get formatHorizontalRule => 'Ligne horizontale';

  @override
  String get windowMinimize => 'Réduire';

  @override
  String get windowFullScreen => 'Basculer en plein écran';

  @override
  String get windowAlwaysOnTop => 'Toujours au premier plan';

  @override
  String get helpAbout => 'À propos de MarkText Plus';

  @override
  String get helpCheckUpdates => 'Vérifier les mises à jour';

  @override
  String get helpChangelog => 'Journal des modifications';

  @override
  String get helpReportBug => 'Signaler un bug';

  @override
  String get helpRequestFeature => 'Demander une fonctionnalité';

  @override
  String get helpGitHub => 'Dépôt GitHub';

  @override
  String get settingsGeneral => 'Général';

  @override
  String get settingsEditor => 'Éditeur';

  @override
  String get settingsMarkdown => 'Markdown';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsKeybindings => 'Raccourcis clavier';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsAutoSave => 'Sauvegarde automatique';

  @override
  String get settingsAutoSaveDelay => 'Délai de sauvegarde automatique (ms)';

  @override
  String get settingsFontSize => 'Taille de police';

  @override
  String get settingsLineHeight => 'Hauteur de ligne';

  @override
  String get settingsTabSize => 'Taille de tabulation';

  @override
  String get settingsEnableHtml => 'Activer HTML';

  @override
  String get settingsResetDefaults => 'Réinitialiser les paramètres';

  @override
  String statusLine(int line, int col) {
    return 'Ln $line, Col $col';
  }

  @override
  String get statusEncoding => 'UTF-8';

  @override
  String get statusMarkdown => 'Markdown';

  @override
  String get unsavedChanges => 'Modifications non enregistrées';

  @override
  String get unsavedChangesMessage =>
      'Voulez-vous enregistrer les modifications avant de fermer ?';

  @override
  String get save => 'Enregistrer';

  @override
  String get dontSave => 'Ne pas enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get ok => 'OK';

  @override
  String get untitled => 'Sans titre';

  @override
  String get openRecentFiles => 'Fichiers récents';

  @override
  String get noRecentFiles => 'Aucun fichier récent';

  @override
  String get sidebarFiles => 'Fichiers';

  @override
  String get sidebarSearch => 'Recherche';

  @override
  String get sidebarToc => 'Table des matières';

  @override
  String get sidebarSettings => 'Paramètres';

  @override
  String get formatHeadingSubmenu => 'Titre';

  @override
  String get settingsBulletListMarker => 'Marqueur de liste';

  @override
  String get settingsLightThemes => 'Thèmes clairs';

  @override
  String get settingsDarkThemes => 'Thèmes sombres';

  @override
  String get confirmResetMessage =>
      'Voulez-vous vraiment réinitialiser tous les paramètres ?';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get noFiles => 'Aucun fichier';

  @override
  String get noOpenFolder => 'Ouvrir un dossier pour parcourir les fichiers';

  @override
  String get searchPlaceholder => 'Rechercher dans les fichiers...';

  @override
  String get searchNoResults => 'Aucun résultat';

  @override
  String searchResultCount(int count) {
    return '$count résultats trouvés';
  }

  @override
  String get tocEmpty => 'Aucun titre trouvé';

  @override
  String get editFindNext => 'Suivant';

  @override
  String get editFindPrevious => 'Précédent';

  @override
  String get editReplaceAll => 'Tout remplacer';

  @override
  String get editCaseSensitive => 'Respecter la casse';

  @override
  String get editWholeWord => 'Mot entier';

  @override
  String get editRegex => 'Expression régulière';

  @override
  String get editCopyAsMarkdown => 'Copier en Markdown';

  @override
  String get editCopyAsHtml => 'Copier en HTML';

  @override
  String get editSelectAll => 'Tout sélectionner';

  @override
  String get editDuplicateLine => 'Dupliquer la ligne';

  @override
  String get formatUnderline => 'Souligné';

  @override
  String get formatSuperscript => 'Exposant';

  @override
  String get formatSubscript => 'Indice';

  @override
  String get formatHighlight => 'Surligner';

  @override
  String get formatInlineCode => 'Code en ligne';

  @override
  String get formatInlineMath => 'Formule en ligne';

  @override
  String get formatClearFormatting => 'Effacer le formatage';

  @override
  String get settingsCodeFontFamily => 'Police de code';

  @override
  String get settingsEditorMaxWidth => 'Largeur maximale de l\'éditeur';

  @override
  String get settingsTextDirection => 'Direction du texte';

  @override
  String get keybindingsEdit => 'Modifier le raccourci';

  @override
  String get keybindingsPressKeys =>
      'Appuyez sur une combinaison de touches...';

  @override
  String get keybindingsReset => 'Réinitialiser par défaut';

  @override
  String get statusWords => 'Mots';

  @override
  String get statusChars => 'Caractères';

  @override
  String get statusParagraphs => 'Paragraphes';

  @override
  String get themeCadmiumLight => 'Cadmium Clair';

  @override
  String get themeOneDark => 'One Dark';

  @override
  String get themeMaterialDark => 'Material Sombre';

  @override
  String get themeGraphiteLight => 'Graphite Clair';

  @override
  String get themeUlyssesLight => 'Ulysses Clair';

  @override
  String get themeRedGraphite => 'Graphite Rouge';

  @override
  String get themeShibuya => 'Shibuya';

  @override
  String get themePinkBlossom => 'Fleur Rose';

  @override
  String get themeSkyBlue => 'Bleu Ciel';

  @override
  String get themeDarkGraphite => 'Graphite Sombre';

  @override
  String get themeDieciOLED => 'Dieci OLED';

  @override
  String get themeNord => 'Nord';

  @override
  String get themeMidnight => 'Minuit';

  @override
  String get keybindingBold => 'Gras';

  @override
  String get keybindingItalic => 'Italique';

  @override
  String get keybindingUnderline => 'Souligné';

  @override
  String get keybindingStrikethrough => 'Barré';

  @override
  String get keybindingHeading1 => 'Titre 1';

  @override
  String get keybindingHeading2 => 'Titre 2';

  @override
  String get keybindingHeading3 => 'Titre 3';

  @override
  String get keybindingHeading4 => 'Titre 4';

  @override
  String get keybindingHeading5 => 'Titre 5';

  @override
  String get keybindingHeading6 => 'Titre 6';

  @override
  String get keybindingOrderedList => 'Liste ordonnée';

  @override
  String get keybindingUnorderedList => 'Liste non ordonnée';

  @override
  String get keybindingTaskList => 'Liste de tâches';

  @override
  String get keybindingCodeBlock => 'Bloc de code';

  @override
  String get keybindingQuoteBlock => 'Bloc de citation';

  @override
  String get keybindingTable => 'Tableau';

  @override
  String get keybindingLink => 'Lien';

  @override
  String get keybindingImage => 'Image';

  @override
  String get keybindingInlineCode => 'Code en ligne';

  @override
  String get keybindingInlineMath => 'Formule en ligne';

  @override
  String get keybindingMathBlock => 'Bloc mathématique';

  @override
  String get keybindingFind => 'Rechercher';

  @override
  String get keybindingReplace => 'Remplacer';

  @override
  String get keybindingSave => 'Enregistrer';

  @override
  String get keybindingOpen => 'Ouvrir';

  @override
  String get keybindingUndo => 'Annuler';

  @override
  String get keybindingRedo => 'Rétablir';

  @override
  String get keybindingSelectAll => 'Tout sélectionner';

  @override
  String get keybindingDuplicateLine => 'Dupliquer la ligne';

  @override
  String get keybindingHighlight => 'Surligner';

  @override
  String get closeFile => 'Fermer le fichier';

  @override
  String get copyFileName => 'Copier le nom du fichier';

  @override
  String get copyFilePath => 'Copier le chemin du fichier';

  @override
  String get deleteFile => 'Supprimer le fichier';

  @override
  String confirmDeleteFile(String fileName) {
    return 'Êtes-vous sûr de vouloir supprimer \"$fileName\" ?';
  }

  @override
  String get newFolder => 'Nouveau dossier';

  @override
  String get rename => 'Renommer';

  @override
  String get delete => 'Supprimer';

  @override
  String get confirm => 'Confirmer';

  @override
  String get fileNameHint => 'Nom du fichier';

  @override
  String get folderNameHint => 'Nom du dossier';

  @override
  String get newNameHint => 'Nouveau nom';

  @override
  String get closeOtherTabs => 'Fermer les autres onglets';

  @override
  String get closeTabsToRight => 'Fermer les onglets à droite';

  @override
  String get closeAllTabs => 'Fermer tous les onglets';

  @override
  String get revealInExplorer => 'Afficher dans l\'explorateur';

  @override
  String get formatTextSubmenu => 'Texte';

  @override
  String get formatBlocksSubmenu => 'Blocs';

  @override
  String get formatCodeSubmenu => 'Code';

  @override
  String get formatInsertSubmenu => 'Insérer';

  @override
  String get fileRename => 'Renommer';

  @override
  String get newTab => 'Nouvel onglet';

  @override
  String get newNameHintDialog => 'Nouveau nom';

  @override
  String get commandPaletteHint => 'Saisir une commande...';

  @override
  String get commandPaletteNoResults => 'Aucune commande correspondante';

  @override
  String get statusLineFeed => 'LF';

  @override
  String get settingsTextDirectionLtr => 'Gauche à droite';

  @override
  String get settingsTextDirectionRtl => 'Droite à gauche';

  @override
  String commandFormatLabel(String action) {
    return 'Format : $action';
  }

  @override
  String commandFormatDesc(String action) {
    return 'Appliquer le formatage $action';
  }

  @override
  String get commandNewFile => 'Nouveau fichier';

  @override
  String get commandNewFileDesc => 'Créer un nouveau fichier sans titre';

  @override
  String get commandSave => 'Enregistrer';

  @override
  String get commandSaveDesc => 'Enregistrer le fichier actuel';

  @override
  String get commandSourceMode => 'Mode source';

  @override
  String get commandSourceModeDesc => 'Passer en mode édition du code source';

  @override
  String get commandPreviewMode => 'Mode aperçu';

  @override
  String get commandPreviewModeDesc => 'Passer en mode aperçu';

  @override
  String get commandSplitMode => 'Mode divisé';

  @override
  String get commandSplitModeDesc => 'Passer en mode édition divisée';

  @override
  String get commandToggleFocusMode => 'Basculer le mode focus';

  @override
  String get commandToggleFocusModeDesc =>
      'Basculer le mode focus sans distraction';

  @override
  String get commandToggleTypewriterMode => 'Basculer le mode machine à écrire';

  @override
  String get commandToggleTypewriterModeDesc =>
      'Basculer le mode défilement machine à écrire';

  @override
  String get commandToggleSidebar => 'Basculer la barre latérale';

  @override
  String get commandToggleSidebarDesc =>
      'Afficher ou masquer la barre latérale';

  @override
  String get commandToggleTabBar => 'Basculer la barre d\'onglets';

  @override
  String get commandToggleTabBarDesc =>
      'Afficher ou masquer la barre d\'onglets';

  @override
  String get welcomeNewFile => 'Nouveau fichier';

  @override
  String get welcomeOpenFile => 'Ouvrir un fichier';

  @override
  String get welcomeDragHint => 'Déposez des fichiers ici pour les ouvrir';
}

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
}

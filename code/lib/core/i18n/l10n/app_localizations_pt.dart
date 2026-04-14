// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'MarkText Plus';

  @override
  String get menuFile => 'Ficheiro';

  @override
  String get menuEdit => 'Editar';

  @override
  String get menuView => 'Ver';

  @override
  String get menuFormat => 'Formato';

  @override
  String get menuWindow => 'Janela';

  @override
  String get menuHelp => 'Ajuda';

  @override
  String get fileNew => 'Novo ficheiro';

  @override
  String get fileNewWindow => 'Nova janela';

  @override
  String get fileOpen => 'Abrir ficheiro';

  @override
  String get fileOpenFolder => 'Abrir pasta';

  @override
  String get fileSave => 'Guardar';

  @override
  String get fileSaveAs => 'Guardar como';

  @override
  String get fileRecentFiles => 'Recent Files';

  @override
  String get fileNoRecentFiles => 'No Recent Files';

  @override
  String get fileExport => 'Exportar';

  @override
  String get fileExportHtml => 'HTML';

  @override
  String get fileExportPdf => 'PDF';

  @override
  String get fileSettings => 'Definições';

  @override
  String get fileQuit => 'Sair';

  @override
  String get editUndo => 'Desfazer';

  @override
  String get editRedo => 'Refazer';

  @override
  String get editCut => 'Cortar';

  @override
  String get editCopy => 'Copiar';

  @override
  String get editPaste => 'Colar';

  @override
  String get editFind => 'Localizar';

  @override
  String get editReplace => 'Substituir';

  @override
  String get editFindInFiles => 'Localizar em ficheiros';

  @override
  String get viewEditMode => 'Modo de edição';

  @override
  String get viewSourceCode => 'Código fonte';

  @override
  String get viewPreview => 'Pré-visualização';

  @override
  String get viewSplitView => 'Vista dividida';

  @override
  String get viewShowSidebar => 'Mostrar barra lateral';

  @override
  String get viewHideSidebar => 'Ocultar barra lateral';

  @override
  String get viewShowTabBar => 'Mostrar barra de separadores';

  @override
  String get viewHideTabBar => 'Ocultar barra de separadores';

  @override
  String get viewFocusMode => 'Modo de foco';

  @override
  String get viewTypewriterMode => 'Modo máquina de escrever';

  @override
  String get viewZoomIn => 'Ampliar';

  @override
  String get viewZoomOut => 'Reduzir';

  @override
  String get viewResetZoom => 'Repor zoom';

  @override
  String get formatBold => 'Negrito';

  @override
  String get formatItalic => 'Itálico';

  @override
  String get formatStrikethrough => 'Rasurado';

  @override
  String formatHeading(int level) {
    return 'Cabeçalho $level';
  }

  @override
  String get formatOrderedList => 'Lista ordenada';

  @override
  String get formatUnorderedList => 'Lista não ordenada';

  @override
  String get formatTaskList => 'Lista de tarefas';

  @override
  String get formatCodeBlock => 'Bloco de código';

  @override
  String get formatQuoteBlock => 'Bloco de citação';

  @override
  String get formatMathBlock => 'Bloco matemático';

  @override
  String get formatTable => 'Tabela';

  @override
  String get formatLink => 'Ligação';

  @override
  String get formatImage => 'Imagem';

  @override
  String get formatHorizontalRule => 'Linha horizontal';

  @override
  String get windowMinimize => 'Minimizar';

  @override
  String get windowFullScreen => 'Ecrã completo';

  @override
  String get windowAlwaysOnTop => 'Sempre visível';

  @override
  String get helpAbout => 'Acerca do MarkText Plus';

  @override
  String get helpCheckUpdates => 'Verificar atualizações';

  @override
  String get helpChangelog => 'Registo de alterações';

  @override
  String get helpReportBug => 'Reportar erro';

  @override
  String get helpRequestFeature => 'Solicitar funcionalidade';

  @override
  String get helpGitHub => 'Repositório GitHub';

  @override
  String get settingsGeneral => 'Geral';

  @override
  String get settingsEditor => 'Editor';

  @override
  String get settingsMarkdown => 'Markdown';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsKeybindings => 'Atalhos de teclado';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsAutoSave => 'Guardar automaticamente';

  @override
  String get settingsAutoSaveDelay => 'Atraso de gravação automática (ms)';

  @override
  String get settingsFontSize => 'Tamanho da fonte';

  @override
  String get settingsLineHeight => 'Altura da linha';

  @override
  String get settingsTabSize => 'Tamanho da tabulação';

  @override
  String get settingsEnableHtml => 'Ativar HTML';

  @override
  String get settingsResetDefaults => 'Repor predefinições';

  @override
  String statusLine(int line, int col) {
    return 'Ln $line, Col $col';
  }

  @override
  String get statusEncoding => 'UTF-8';

  @override
  String get statusMarkdown => 'Markdown';

  @override
  String get unsavedChanges => 'Alterações não guardadas';

  @override
  String get unsavedChangesMessage =>
      'Deseja guardar as alterações antes de fechar?';

  @override
  String get save => 'Guardar';

  @override
  String get dontSave => 'Não guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'OK';

  @override
  String get untitled => 'Sem título';

  @override
  String get openRecentFiles => 'Ficheiros recentes';

  @override
  String get noRecentFiles => 'Sem ficheiros recentes';

  @override
  String get sidebarFiles => 'Ficheiros';

  @override
  String get sidebarSearch => 'Pesquisar';

  @override
  String get sidebarToc => 'Índice';

  @override
  String get sidebarSettings => 'Definições';

  @override
  String get formatHeadingSubmenu => 'Título';

  @override
  String get settingsBulletListMarker => 'Marcador de lista';

  @override
  String get settingsDarkMode => 'Modo escuro';

  @override
  String get confirmResetMessage =>
      'Tem a certeza de que pretende repor todas as definições?';

  @override
  String get comingSoon => 'Em breve';

  @override
  String get noFiles => 'Sem ficheiros';

  @override
  String get noOpenFolder => 'Abra uma pasta para explorar ficheiros';

  @override
  String get searchPlaceholder => 'Pesquisar em ficheiros...';

  @override
  String get searchNoResults => 'Sem resultados';

  @override
  String searchResultCount(int count) {
    return '$count resultados encontrados';
  }

  @override
  String get tocEmpty => 'Nenhum título encontrado';

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

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appTitle => 'MarkText Plus';

  @override
  String get menuFile => 'Arquivo';

  @override
  String get menuEdit => 'Editar';

  @override
  String get menuView => 'Exibir';

  @override
  String get menuFormat => 'Formatar';

  @override
  String get menuWindow => 'Janela';

  @override
  String get menuHelp => 'Ajuda';

  @override
  String get fileNew => 'Novo arquivo';

  @override
  String get fileNewWindow => 'Nova janela';

  @override
  String get fileOpen => 'Abrir arquivo';

  @override
  String get fileOpenFolder => 'Abrir pasta';

  @override
  String get fileSave => 'Salvar';

  @override
  String get fileSaveAs => 'Salvar como';

  @override
  String get fileRecentFiles => 'Recent Files';

  @override
  String get fileNoRecentFiles => 'No Recent Files';

  @override
  String get fileExport => 'Exportar';

  @override
  String get fileExportHtml => 'HTML';

  @override
  String get fileExportPdf => 'PDF';

  @override
  String get fileSettings => 'Configurações';

  @override
  String get fileQuit => 'Sair';

  @override
  String get editUndo => 'Desfazer';

  @override
  String get editRedo => 'Refazer';

  @override
  String get editCut => 'Recortar';

  @override
  String get editCopy => 'Copiar';

  @override
  String get editPaste => 'Colar';

  @override
  String get editFind => 'Localizar';

  @override
  String get editReplace => 'Substituir';

  @override
  String get editFindInFiles => 'Localizar em arquivos';

  @override
  String get viewEditMode => 'Modo de edição';

  @override
  String get viewSourceCode => 'Código fonte';

  @override
  String get viewPreview => 'Pré-visualização';

  @override
  String get viewSplitView => 'Visualização dividida';

  @override
  String get viewShowSidebar => 'Mostrar barra lateral';

  @override
  String get viewHideSidebar => 'Ocultar barra lateral';

  @override
  String get viewShowTabBar => 'Mostrar barra de abas';

  @override
  String get viewHideTabBar => 'Ocultar barra de abas';

  @override
  String get viewFocusMode => 'Modo de foco';

  @override
  String get viewTypewriterMode => 'Modo máquina de escrever';

  @override
  String get viewZoomIn => 'Aumentar zoom';

  @override
  String get viewZoomOut => 'Diminuir zoom';

  @override
  String get viewResetZoom => 'Redefinir zoom';

  @override
  String get formatBold => 'Negrito';

  @override
  String get formatItalic => 'Itálico';

  @override
  String get formatStrikethrough => 'Tachado';

  @override
  String formatHeading(int level) {
    return 'Título $level';
  }

  @override
  String get formatOrderedList => 'Lista ordenada';

  @override
  String get formatUnorderedList => 'Lista não ordenada';

  @override
  String get formatTaskList => 'Lista de tarefas';

  @override
  String get formatCodeBlock => 'Bloco de código';

  @override
  String get formatQuoteBlock => 'Bloco de citação';

  @override
  String get formatMathBlock => 'Bloco matemático';

  @override
  String get formatTable => 'Tabela';

  @override
  String get formatLink => 'Link';

  @override
  String get formatImage => 'Imagem';

  @override
  String get formatHorizontalRule => 'Linha horizontal';

  @override
  String get windowMinimize => 'Minimizar';

  @override
  String get windowFullScreen => 'Tela cheia';

  @override
  String get windowAlwaysOnTop => 'Sempre no topo';

  @override
  String get helpAbout => 'Sobre o MarkText Plus';

  @override
  String get helpCheckUpdates => 'Verificar atualizações';

  @override
  String get helpChangelog => 'Registro de alterações';

  @override
  String get helpReportBug => 'Reportar bug';

  @override
  String get helpRequestFeature => 'Solicitar recurso';

  @override
  String get helpGitHub => 'Repositório GitHub';

  @override
  String get settingsGeneral => 'Geral';

  @override
  String get settingsEditor => 'Editor';

  @override
  String get settingsMarkdown => 'Markdown';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsKeybindings => 'Atalhos de teclado';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsAutoSave => 'Salvamento automático';

  @override
  String get settingsAutoSaveDelay => 'Atraso do salvamento automático (ms)';

  @override
  String get settingsFontSize => 'Tamanho da fonte';

  @override
  String get settingsLineHeight => 'Altura da linha';

  @override
  String get settingsTabSize => 'Tamanho da tabulação';

  @override
  String get settingsEnableHtml => 'Habilitar HTML';

  @override
  String get settingsResetDefaults => 'Restaurar padrões';

  @override
  String statusLine(int line, int col) {
    return 'Ln $line, Col $col';
  }

  @override
  String get statusEncoding => 'UTF-8';

  @override
  String get statusMarkdown => 'Markdown';

  @override
  String get unsavedChanges => 'Alterações não salvas';

  @override
  String get unsavedChangesMessage =>
      'Deseja salvar as alterações antes de fechar?';

  @override
  String get save => 'Salvar';

  @override
  String get dontSave => 'Não salvar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'OK';

  @override
  String get untitled => 'Sem título';

  @override
  String get openRecentFiles => 'Arquivos recentes';

  @override
  String get noRecentFiles => 'Nenhum arquivo recente';

  @override
  String get sidebarFiles => 'Arquivos';

  @override
  String get sidebarSearch => 'Pesquisar';

  @override
  String get sidebarToc => 'Índice';

  @override
  String get sidebarSettings => 'Configurações';

  @override
  String get formatHeadingSubmenu => 'Título';

  @override
  String get settingsBulletListMarker => 'Marcador de lista';

  @override
  String get settingsDarkMode => 'Modo escuro';

  @override
  String get confirmResetMessage =>
      'Tem certeza de que deseja redefinir todas as configurações?';

  @override
  String get comingSoon => 'Em breve';

  @override
  String get noFiles => 'Sem arquivos';

  @override
  String get noOpenFolder => 'Abra uma pasta para explorar arquivos';

  @override
  String get searchPlaceholder => 'Pesquisar em arquivos...';

  @override
  String get searchNoResults => 'Sem resultados';

  @override
  String searchResultCount(int count) {
    return '$count resultados encontrados';
  }

  @override
  String get tocEmpty => 'Nenhum título encontrado';
}

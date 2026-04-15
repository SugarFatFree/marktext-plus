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
  String get editFindNext => 'Localizar seguinte';

  @override
  String get editFindPrevious => 'Localizar anterior';

  @override
  String get editReplaceAll => 'Substituir tudo';

  @override
  String get editCaseSensitive => 'Maiúsculas/minúsculas';

  @override
  String get editWholeWord => 'Palavra inteira';

  @override
  String get editRegex => 'Expressão regular';

  @override
  String get editCopyAsMarkdown => 'Copiar como Markdown';

  @override
  String get editCopyAsHtml => 'Copiar como HTML';

  @override
  String get editSelectAll => 'Selecionar tudo';

  @override
  String get editDuplicateLine => 'Duplicar linha';

  @override
  String get formatUnderline => 'Sublinhado';

  @override
  String get formatSuperscript => 'Sobrescrito';

  @override
  String get formatSubscript => 'Subscrito';

  @override
  String get formatHighlight => 'Realçar';

  @override
  String get formatInlineCode => 'Código em linha';

  @override
  String get formatInlineMath => 'Fórmula em linha';

  @override
  String get formatClearFormatting => 'Limpar formatação';

  @override
  String get settingsCodeFontFamily => 'Fonte de código';

  @override
  String get settingsEditorMaxWidth => 'Largura máxima do editor';

  @override
  String get settingsTextDirection => 'Direção do texto';

  @override
  String get keybindingsEdit => 'Editar atalho';

  @override
  String get keybindingsPressKeys => 'Pressione combinação de teclas...';

  @override
  String get keybindingsReset => 'Repor predefinição';

  @override
  String get statusWords => 'Palavras';

  @override
  String get statusChars => 'Caracteres';

  @override
  String get statusParagraphs => 'Parágrafos';

  @override
  String get themeCadmiumLight => 'Cádmio Claro';

  @override
  String get themeOneDark => 'One Dark';

  @override
  String get themeMaterialDark => 'Material Escuro';

  @override
  String get themeGraphiteLight => 'Grafite Claro';

  @override
  String get themeUlyssesLight => 'Ulysses Claro';

  @override
  String get keybindingBold => 'Negrito';

  @override
  String get keybindingItalic => 'Itálico';

  @override
  String get keybindingUnderline => 'Sublinhado';

  @override
  String get keybindingStrikethrough => 'Rasurado';

  @override
  String get keybindingHeading1 => 'Cabeçalho 1';

  @override
  String get keybindingHeading2 => 'Cabeçalho 2';

  @override
  String get keybindingHeading3 => 'Cabeçalho 3';

  @override
  String get keybindingHeading4 => 'Cabeçalho 4';

  @override
  String get keybindingHeading5 => 'Cabeçalho 5';

  @override
  String get keybindingHeading6 => 'Cabeçalho 6';

  @override
  String get keybindingOrderedList => 'Lista ordenada';

  @override
  String get keybindingUnorderedList => 'Lista não ordenada';

  @override
  String get keybindingTaskList => 'Lista de tarefas';

  @override
  String get keybindingCodeBlock => 'Bloco de código';

  @override
  String get keybindingQuoteBlock => 'Bloco de citação';

  @override
  String get keybindingTable => 'Tabela';

  @override
  String get keybindingLink => 'Ligação';

  @override
  String get keybindingImage => 'Imagem';

  @override
  String get keybindingInlineCode => 'Código em linha';

  @override
  String get keybindingInlineMath => 'Fórmula em linha';

  @override
  String get keybindingMathBlock => 'Bloco matemático';

  @override
  String get keybindingFind => 'Localizar';

  @override
  String get keybindingReplace => 'Substituir';

  @override
  String get keybindingSave => 'Guardar';

  @override
  String get keybindingOpen => 'Abrir';

  @override
  String get keybindingUndo => 'Desfazer';

  @override
  String get keybindingRedo => 'Refazer';

  @override
  String get keybindingSelectAll => 'Selecionar tudo';

  @override
  String get keybindingDuplicateLine => 'Duplicar linha';

  @override
  String get keybindingHighlight => 'Realçar';

  @override
  String get closeFile => 'Fechar ficheiro';

  @override
  String get copyFileName => 'Copiar nome do ficheiro';

  @override
  String get copyFilePath => 'Copiar caminho do ficheiro';

  @override
  String get deleteFile => 'Eliminar ficheiro';

  @override
  String confirmDeleteFile(String fileName) {
    return 'Tem a certeza de que deseja eliminar \"$fileName\"?';
  }
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

  @override
  String get editFindNext => 'Localizar próximo';

  @override
  String get editFindPrevious => 'Localizar anterior';

  @override
  String get editReplaceAll => 'Substituir tudo';

  @override
  String get editCaseSensitive => 'Diferenciar maiúsculas';

  @override
  String get editWholeWord => 'Palavra inteira';

  @override
  String get editRegex => 'Expressão regular';

  @override
  String get editCopyAsMarkdown => 'Copiar como Markdown';

  @override
  String get editCopyAsHtml => 'Copiar como HTML';

  @override
  String get editSelectAll => 'Selecionar tudo';

  @override
  String get editDuplicateLine => 'Duplicar linha';

  @override
  String get formatUnderline => 'Sublinhado';

  @override
  String get formatSuperscript => 'Sobrescrito';

  @override
  String get formatSubscript => 'Subscrito';

  @override
  String get formatHighlight => 'Realçar';

  @override
  String get formatInlineCode => 'Código em linha';

  @override
  String get formatInlineMath => 'Fórmula em linha';

  @override
  String get formatClearFormatting => 'Limpar formatação';

  @override
  String get settingsCodeFontFamily => 'Fonte de código';

  @override
  String get settingsEditorMaxWidth => 'Largura máxima do editor';

  @override
  String get settingsTextDirection => 'Direção do texto';

  @override
  String get keybindingsEdit => 'Editar atalho';

  @override
  String get keybindingsPressKeys => 'Pressione combinação de teclas...';

  @override
  String get keybindingsReset => 'Restaurar padrão';

  @override
  String get statusWords => 'Palavras';

  @override
  String get statusChars => 'Caracteres';

  @override
  String get statusParagraphs => 'Parágrafos';

  @override
  String get themeCadmiumLight => 'Cádmio Claro';

  @override
  String get themeOneDark => 'One Dark';

  @override
  String get themeMaterialDark => 'Material Escuro';

  @override
  String get themeGraphiteLight => 'Grafite Claro';

  @override
  String get themeUlyssesLight => 'Ulysses Claro';

  @override
  String get keybindingBold => 'Negrito';

  @override
  String get keybindingItalic => 'Itálico';

  @override
  String get keybindingUnderline => 'Sublinhado';

  @override
  String get keybindingStrikethrough => 'Tachado';

  @override
  String get keybindingHeading1 => 'Título 1';

  @override
  String get keybindingHeading2 => 'Título 2';

  @override
  String get keybindingHeading3 => 'Título 3';

  @override
  String get keybindingHeading4 => 'Título 4';

  @override
  String get keybindingHeading5 => 'Título 5';

  @override
  String get keybindingHeading6 => 'Título 6';

  @override
  String get keybindingOrderedList => 'Lista ordenada';

  @override
  String get keybindingUnorderedList => 'Lista não ordenada';

  @override
  String get keybindingTaskList => 'Lista de tarefas';

  @override
  String get keybindingCodeBlock => 'Bloco de código';

  @override
  String get keybindingQuoteBlock => 'Bloco de citação';

  @override
  String get keybindingTable => 'Tabela';

  @override
  String get keybindingLink => 'Link';

  @override
  String get keybindingImage => 'Imagem';

  @override
  String get keybindingInlineCode => 'Código em linha';

  @override
  String get keybindingInlineMath => 'Fórmula em linha';

  @override
  String get keybindingMathBlock => 'Bloco matemático';

  @override
  String get keybindingFind => 'Localizar';

  @override
  String get keybindingReplace => 'Substituir';

  @override
  String get keybindingSave => 'Salvar';

  @override
  String get keybindingOpen => 'Abrir';

  @override
  String get keybindingUndo => 'Desfazer';

  @override
  String get keybindingRedo => 'Refazer';

  @override
  String get keybindingSelectAll => 'Selecionar tudo';

  @override
  String get keybindingDuplicateLine => 'Duplicar linha';

  @override
  String get keybindingHighlight => 'Realçar';

  @override
  String get closeFile => 'Fechar arquivo';

  @override
  String get copyFileName => 'Copiar nome do arquivo';

  @override
  String get copyFilePath => 'Copiar caminho do arquivo';

  @override
  String get deleteFile => 'Excluir arquivo';

  @override
  String confirmDeleteFile(String fileName) {
    return 'Tem certeza de que deseja excluir \"$fileName\"?';
  }
}

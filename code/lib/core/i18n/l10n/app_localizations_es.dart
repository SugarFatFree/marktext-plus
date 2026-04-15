// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MarkText Plus';

  @override
  String get menuFile => 'Archivo';

  @override
  String get menuEdit => 'Editar';

  @override
  String get menuView => 'Ver';

  @override
  String get menuFormat => 'Formato';

  @override
  String get menuWindow => 'Ventana';

  @override
  String get menuHelp => 'Ayuda';

  @override
  String get fileNew => 'Nuevo archivo';

  @override
  String get fileNewWindow => 'Nueva ventana';

  @override
  String get fileOpen => 'Abrir archivo';

  @override
  String get fileOpenFolder => 'Abrir carpeta';

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
  String get fileSettings => 'Configuración';

  @override
  String get fileQuit => 'Salir';

  @override
  String get editUndo => 'Deshacer';

  @override
  String get editRedo => 'Rehacer';

  @override
  String get editCut => 'Cortar';

  @override
  String get editCopy => 'Copiar';

  @override
  String get editPaste => 'Pegar';

  @override
  String get editFind => 'Buscar';

  @override
  String get editReplace => 'Reemplazar';

  @override
  String get editFindInFiles => 'Buscar en archivos';

  @override
  String get viewEditMode => 'Modo de edición';

  @override
  String get viewSourceCode => 'Código fuente';

  @override
  String get viewPreview => 'Vista previa';

  @override
  String get viewSplitView => 'Vista dividida';

  @override
  String get viewShowSidebar => 'Mostrar barra lateral';

  @override
  String get viewHideSidebar => 'Ocultar barra lateral';

  @override
  String get viewShowTabBar => 'Mostrar barra de pestañas';

  @override
  String get viewHideTabBar => 'Ocultar barra de pestañas';

  @override
  String get viewFocusMode => 'Modo de concentración';

  @override
  String get viewTypewriterMode => 'Modo máquina de escribir';

  @override
  String get viewZoomIn => 'Acercar';

  @override
  String get viewZoomOut => 'Alejar';

  @override
  String get viewResetZoom => 'Restablecer zoom';

  @override
  String get formatBold => 'Negrita';

  @override
  String get formatItalic => 'Cursiva';

  @override
  String get formatStrikethrough => 'Tachado';

  @override
  String formatHeading(int level) {
    return 'Encabezado $level';
  }

  @override
  String get formatOrderedList => 'Lista ordenada';

  @override
  String get formatUnorderedList => 'Lista desordenada';

  @override
  String get formatTaskList => 'Lista de tareas';

  @override
  String get formatCodeBlock => 'Bloque de código';

  @override
  String get formatQuoteBlock => 'Bloque de cita';

  @override
  String get formatMathBlock => 'Bloque matemático';

  @override
  String get formatTable => 'Tabla';

  @override
  String get formatLink => 'Enlace';

  @override
  String get formatImage => 'Imagen';

  @override
  String get formatHorizontalRule => 'Línea horizontal';

  @override
  String get windowMinimize => 'Minimizar';

  @override
  String get windowFullScreen => 'Pantalla completa';

  @override
  String get windowAlwaysOnTop => 'Siempre visible';

  @override
  String get helpAbout => 'Acerca de MarkText Plus';

  @override
  String get helpCheckUpdates => 'Buscar actualizaciones';

  @override
  String get helpChangelog => 'Registro de cambios';

  @override
  String get helpReportBug => 'Informar error';

  @override
  String get helpRequestFeature => 'Solicitar función';

  @override
  String get helpGitHub => 'Repositorio GitHub';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsEditor => 'Editor';

  @override
  String get settingsMarkdown => 'Markdown';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsKeybindings => 'Atajos de teclado';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsAutoSave => 'Guardado automático';

  @override
  String get settingsAutoSaveDelay => 'Retraso de guardado automático (ms)';

  @override
  String get settingsFontSize => 'Tamaño de fuente';

  @override
  String get settingsLineHeight => 'Altura de línea';

  @override
  String get settingsTabSize => 'Tamaño de tabulación';

  @override
  String get settingsEnableHtml => 'Habilitar HTML';

  @override
  String get settingsResetDefaults => 'Restablecer valores predeterminados';

  @override
  String statusLine(int line, int col) {
    return 'Ln $line, Col $col';
  }

  @override
  String get statusEncoding => 'UTF-8';

  @override
  String get statusMarkdown => 'Markdown';

  @override
  String get unsavedChanges => 'Cambios sin guardar';

  @override
  String get unsavedChangesMessage =>
      '¿Desea guardar los cambios antes de cerrar?';

  @override
  String get save => 'Guardar';

  @override
  String get dontSave => 'No guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'Aceptar';

  @override
  String get untitled => 'Sin título';

  @override
  String get openRecentFiles => 'Archivos recientes';

  @override
  String get noRecentFiles => 'No hay archivos recientes';

  @override
  String get sidebarFiles => 'Archivos';

  @override
  String get sidebarSearch => 'Buscar';

  @override
  String get sidebarToc => 'Índice';

  @override
  String get sidebarSettings => 'Configuración';

  @override
  String get formatHeadingSubmenu => 'Encabezado';

  @override
  String get settingsBulletListMarker => 'Marcador de lista';

  @override
  String get settingsDarkMode => 'Modo oscuro';

  @override
  String get confirmResetMessage =>
      '¿Está seguro de que desea restablecer toda la configuración?';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get noFiles => 'Sin archivos';

  @override
  String get noOpenFolder => 'Abra una carpeta para explorar archivos';

  @override
  String get searchPlaceholder => 'Buscar en archivos...';

  @override
  String get searchNoResults => 'Sin resultados';

  @override
  String searchResultCount(int count) {
    return '$count resultados encontrados';
  }

  @override
  String get tocEmpty => 'No se encontraron encabezados';

  @override
  String get editFindNext => 'Buscar siguiente';

  @override
  String get editFindPrevious => 'Buscar anterior';

  @override
  String get editReplaceAll => 'Reemplazar todo';

  @override
  String get editCaseSensitive => 'Distinguir mayúsculas';

  @override
  String get editWholeWord => 'Palabra completa';

  @override
  String get editRegex => 'Expresión regular';

  @override
  String get editCopyAsMarkdown => 'Copiar como Markdown';

  @override
  String get editCopyAsHtml => 'Copiar como HTML';

  @override
  String get editSelectAll => 'Seleccionar todo';

  @override
  String get editDuplicateLine => 'Duplicar línea';

  @override
  String get formatUnderline => 'Subrayado';

  @override
  String get formatSuperscript => 'Superíndice';

  @override
  String get formatSubscript => 'Subíndice';

  @override
  String get formatHighlight => 'Resaltar';

  @override
  String get formatInlineCode => 'Código en línea';

  @override
  String get formatInlineMath => 'Fórmula en línea';

  @override
  String get formatClearFormatting => 'Borrar formato';

  @override
  String get settingsCodeFontFamily => 'Fuente de código';

  @override
  String get settingsEditorMaxWidth => 'Ancho máximo del editor';

  @override
  String get settingsTextDirection => 'Dirección del texto';

  @override
  String get keybindingsEdit => 'Editar atajo';

  @override
  String get keybindingsPressKeys => 'Presione combinación de teclas...';

  @override
  String get keybindingsReset => 'Restablecer por defecto';

  @override
  String get statusWords => 'Palabras';

  @override
  String get statusChars => 'Caracteres';

  @override
  String get statusParagraphs => 'Párrafos';

  @override
  String get themeCadmiumLight => 'Cadmio Claro';

  @override
  String get themeOneDark => 'One Dark';

  @override
  String get themeMaterialDark => 'Material Oscuro';

  @override
  String get themeGraphiteLight => 'Grafito Claro';

  @override
  String get themeUlyssesLight => 'Ulysses Claro';

  @override
  String get keybindingBold => 'Negrita';

  @override
  String get keybindingItalic => 'Cursiva';

  @override
  String get keybindingUnderline => 'Subrayado';

  @override
  String get keybindingStrikethrough => 'Tachado';

  @override
  String get keybindingHeading1 => 'Encabezado 1';

  @override
  String get keybindingHeading2 => 'Encabezado 2';

  @override
  String get keybindingHeading3 => 'Encabezado 3';

  @override
  String get keybindingHeading4 => 'Encabezado 4';

  @override
  String get keybindingHeading5 => 'Encabezado 5';

  @override
  String get keybindingHeading6 => 'Encabezado 6';

  @override
  String get keybindingOrderedList => 'Lista ordenada';

  @override
  String get keybindingUnorderedList => 'Lista desordenada';

  @override
  String get keybindingTaskList => 'Lista de tareas';

  @override
  String get keybindingCodeBlock => 'Bloque de código';

  @override
  String get keybindingQuoteBlock => 'Bloque de cita';

  @override
  String get keybindingTable => 'Tabla';

  @override
  String get keybindingLink => 'Enlace';

  @override
  String get keybindingImage => 'Imagen';

  @override
  String get keybindingInlineCode => 'Código en línea';

  @override
  String get keybindingInlineMath => 'Fórmula en línea';

  @override
  String get keybindingMathBlock => 'Bloque matemático';

  @override
  String get keybindingFind => 'Buscar';

  @override
  String get keybindingReplace => 'Reemplazar';

  @override
  String get keybindingSave => 'Guardar';

  @override
  String get keybindingOpen => 'Abrir';

  @override
  String get keybindingUndo => 'Deshacer';

  @override
  String get keybindingRedo => 'Rehacer';

  @override
  String get keybindingSelectAll => 'Seleccionar todo';

  @override
  String get keybindingDuplicateLine => 'Duplicar línea';

  @override
  String get keybindingHighlight => 'Resaltar';

  @override
  String get closeFile => 'Cerrar archivo';

  @override
  String get copyFileName => 'Copiar nombre de archivo';

  @override
  String get copyFilePath => 'Copiar ruta de archivo';

  @override
  String get deleteFile => 'Eliminar archivo';

  @override
  String confirmDeleteFile(String fileName) {
    return '¿Está seguro de que desea eliminar \"$fileName\"?';
  }
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get settingsWrapCodeBlocks =>
      'Ajustar las líneas largas en los bloques de código';

  @override
  String get settingsCodeBlockLineNumbers =>
      'Números de línea en bloques de código';

  @override
  String settingsSaveFailed(String message) {
    return 'No se pudo guardar la configuración: $message';
  }

  @override
  String get settingsFollowSystemTheme =>
      'Seguir el modo claro/oscuro del sistema';

  @override
  String get settingsFollowSystemThemeHint =>
      'Elija un tema claro y uno oscuro; el sistema decide cuál se muestra.';

  @override
  String get settingsAutoPairBracket => 'Cerrar corchetes automáticamente';

  @override
  String get settingsAutoPairQuote => 'Cerrar comillas automáticamente';

  @override
  String get settingsAutoPairMarkdown =>
      'Cerrar la sintaxis de Markdown automáticamente (`, *, ~)';

  @override
  String get helpOpenDiagnosticLog => 'Abrir el registro de diagnóstico';

  @override
  String get diagnosticLogMissing =>
      'Todavía no se ha escrito ningún registro de diagnóstico';

  @override
  String get mermaidCaptureFailed => 'No se pudo capturar el diagrama';

  @override
  String get mermaidErrorEmpty => 'El diagrama está vacío.';

  @override
  String mermaidErrorUnknownType(String type) {
    return 'Tipo de diagrama no reconocido: «$type».';
  }

  @override
  String get mermaidErrorHeaderOnly =>
      'Este diagrama tiene encabezado pero no contenido.';

  @override
  String get mermaidErrorBadBody =>
      'El encabezado se reconoce; revise la sintaxis debajo.';

  @override
  String mermaidSupportedTypes(String list) {
    return 'Tipos admitidos: $list';
  }

  @override
  String get mermaidParseError => 'Error de análisis de Mermaid';

  @override
  String imageSavedTo(String path) {
    return 'Guardado en $path';
  }

  @override
  String imageSaveFailed(String message) {
    return 'No se pudo guardar la imagen: $message';
  }

  @override
  String saveFailed(String message) {
    return 'No se pudo guardar el archivo: $message';
  }

  @override
  String fileOperationFailed(String message) {
    return 'Error en la operación de archivo: $message';
  }

  @override
  String get fileNameTaken =>
      'Ya existe un archivo o una carpeta con ese nombre';

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
  String get fileRecentFiles => 'Archivos recientes';

  @override
  String get fileNoRecentFiles => 'No hay archivos recientes';

  @override
  String get fileExport => 'Exportar';

  @override
  String get fileExportHtml => 'HTML';

  @override
  String get fileExportPdf => 'PDF';

  @override
  String get filePrint => 'Imprimir';

  @override
  String get fileExportWord => 'Word (.docx)';

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
  String get formatTableSubmenu => 'Editar tabla';

  @override
  String get formatTableInsertRowAbove => 'Insertar fila arriba';

  @override
  String get formatTableInsertRowBelow => 'Insertar fila abajo';

  @override
  String get formatTableDeleteRow => 'Eliminar fila';

  @override
  String get formatTableInsertColumnLeft => 'Insertar columna a la izquierda';

  @override
  String get formatTableInsertColumnRight => 'Insertar columna a la derecha';

  @override
  String get formatTableDeleteColumn => 'Eliminar columna';

  @override
  String get formatTableAlignLeft => 'Alinear columna a la izquierda';

  @override
  String get formatTableAlignCenter => 'Centrar columna';

  @override
  String get formatTableAlignRight => 'Alinear columna a la derecha';

  @override
  String get formatTableAlignNone => 'Quitar alineación de la columna';

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
  String get settingsLightThemes => 'Temas claros';

  @override
  String get settingsDarkThemes => 'Temas oscuros';

  @override
  String get confirmResetMessage =>
      '¿Está seguro de que desea restablecer toda la configuración?';

  @override
  String get noFiles => 'Sin archivos';

  @override
  String get noOpenFolder => 'Abra una carpeta para explorar archivos';

  @override
  String get searchPlaceholder => 'Buscar en archivos...';

  @override
  String searchTooLarge(int count) {
    return '$count archivo(s) demasiado grandes para buscar';
  }

  @override
  String dropNotMarkdown(int count) {
    return '$count archivo(s) soltados no se abrieron: no son documentos markdown';
  }

  @override
  String get previewStartWriting => 'Empieza a escribir…';

  @override
  String get linkOpenHint => 'Ctrl/Cmd + clic para abrir';

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
  String get editCreateParagraph => 'Crear párrafo debajo';

  @override
  String get editDeleteParagraph => 'Eliminar párrafo';

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
  String get settingsCodeFontSize => 'Tamaño de fuente de código';

  @override
  String get settingsEditorFontFamily => 'Fuente del editor';

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
  String get themeRedGraphite => 'Grafito Rojo';

  @override
  String get themeShibuya => 'Shibuya';

  @override
  String get themePinkBlossom => 'Flor Rosa';

  @override
  String get themeSkyBlue => 'Azul Cielo';

  @override
  String get themeDarkGraphite => 'Grafito Oscuro';

  @override
  String get themeDieciOLED => 'Dieci OLED';

  @override
  String get themeNord => 'Nord';

  @override
  String get themeMidnight => 'Medianoche';

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

  @override
  String get newFolder => 'Nueva carpeta';

  @override
  String get rename => 'Renombrar';

  @override
  String get delete => 'Eliminar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get fileNameHint => 'Nombre del archivo';

  @override
  String get folderNameHint => 'Nombre de la carpeta';

  @override
  String get newNameHint => 'Nuevo nombre';

  @override
  String get closeOtherTabs => 'Cerrar otras pestañas';

  @override
  String get closeTabsToRight => 'Cerrar pestañas a la derecha';

  @override
  String get closeAllTabs => 'Cerrar todas las pestañas';

  @override
  String get revealInExplorer => 'Mostrar en el explorador';

  @override
  String get formatTextSubmenu => 'Texto';

  @override
  String get formatBlocksSubmenu => 'Bloques';

  @override
  String get formatCodeSubmenu => 'Código';

  @override
  String get formatInsertSubmenu => 'Insertar';

  @override
  String get fileRename => 'Renombrar';

  @override
  String get fileMove => 'Mover a…';

  @override
  String get newTab => 'Nueva pestaña';

  @override
  String get newNameHintDialog => 'Nuevo nombre';

  @override
  String get commandPaletteHint => 'Escribir un comando...';

  @override
  String get commandPaletteNoResults => 'No se encontraron comandos';

  @override
  String get statusLineFeed => 'LF';

  @override
  String get settingsTextDirectionLtr => 'Izquierda a derecha';

  @override
  String get settingsTextDirectionRtl => 'Derecha a izquierda';

  @override
  String commandFormatLabel(String action) {
    return 'Formato: $action';
  }

  @override
  String commandFormatDesc(String action) {
    return 'Aplicar formato $action';
  }

  @override
  String get commandNewFile => 'Nuevo archivo';

  @override
  String get commandNewFileDesc => 'Crear un nuevo archivo sin título';

  @override
  String get commandSave => 'Guardar';

  @override
  String get commandSaveDesc => 'Guardar el archivo actual';

  @override
  String get commandSourceMode => 'Modo código fuente';

  @override
  String get commandSourceModeDesc =>
      'Cambiar al modo de edición de código fuente';

  @override
  String get commandPreviewMode => 'Modo vista previa';

  @override
  String get commandPreviewModeDesc => 'Cambiar al modo de vista previa';

  @override
  String get commandSplitMode => 'Modo dividido';

  @override
  String get commandSplitModeDesc => 'Cambiar al modo de edición dividida';

  @override
  String get commandToggleFocusMode => 'Alternar modo enfoque';

  @override
  String get commandToggleFocusModeDesc =>
      'Alternar modo de enfoque sin distracciones';

  @override
  String get commandToggleTypewriterMode => 'Alternar modo máquina de escribir';

  @override
  String get commandToggleTypewriterModeDesc =>
      'Alternar modo de desplazamiento máquina de escribir';

  @override
  String get commandToggleSidebar => 'Alternar barra lateral';

  @override
  String get commandToggleSidebarDesc => 'Mostrar u ocultar la barra lateral';

  @override
  String get commandToggleTabBar => 'Alternar barra de pestañas';

  @override
  String get commandToggleTabBarDesc =>
      'Mostrar u ocultar la barra de pestañas';

  @override
  String get welcomeNewFile => 'Nuevo archivo';

  @override
  String get welcomeOpenFile => 'Abrir archivo';

  @override
  String get welcomeDragHint => 'Arrastra archivos aquí para abrirlos';

  @override
  String get fileOpenBehavior => 'Comportamiento al abrir archivos';

  @override
  String get fileOpenBehaviorNewWindow => 'Abrir en una ventana nueva';

  @override
  String get fileOpenBehaviorExistingWindow => 'Abrir en la ventana actual';

  @override
  String get fileOpenBehaviorNotSet => 'Sin configurar';

  @override
  String get updateAvailable => 'Nueva versión disponible';

  @override
  String get updateDismiss => 'Descartar';

  @override
  String get mermaidFullscreen => 'Pantalla completa';

  @override
  String get mermaidSaveAs => 'Guardar como';

  @override
  String get mermaidCopySource => 'Copiar código fuente';

  @override
  String get mermaidEditSource => 'Editar código fuente';

  @override
  String get mermaidFullscreenHint =>
      'Toca dos veces el diagrama para verlo en pantalla completa';

  @override
  String get mermaidSaveAsHint => 'Guardar el diagrama como PNG';

  @override
  String get menuParagraph => 'Párrafo';

  @override
  String get paragraphPromoteHeading => 'Subir nivel de título';

  @override
  String get paragraphDemoteHeading => 'Bajar nivel de título';

  @override
  String get paragraphToParagraph => 'Convertir en párrafo';

  @override
  String get paragraphLooseList => 'Elemento de lista espaciado';

  @override
  String get close => 'Cerrar';

  @override
  String get mermaidViewerTitle => 'Visor de diagramas Mermaid';

  @override
  String get mermaidViewerHint =>
      'Ctrl+Rueda para ampliar    Arrastrar para desplazar    Esc para cerrar';

  @override
  String get statusHighlightOff =>
      'Resaltado de sintaxis desactivado (archivo grande)';

  @override
  String get settingsImageStorage => 'Dónde guardar las imágenes arrastradas';

  @override
  String get settingsImageStorageCopy => 'Junto al documento';

  @override
  String get settingsImageStorageFolder => 'En una carpeta compartida';

  @override
  String get settingsImageStorageLink => 'Enlazar donde están';

  @override
  String get settingsImageFolder => 'Carpeta de imágenes';

  @override
  String get fileCloseTab => 'Cerrar pestaña';

  @override
  String get fileClearRecentFiles => 'Borrar archivos recientes';

  @override
  String get viewCommandPalette => 'Paleta de comandos';

  @override
  String get viewReloadImages => 'Recargar imágenes';

  @override
  String get formatFrontMatter => 'Front matter';

  @override
  String get formatHtmlBlock => 'Bloque HTML';

  @override
  String get updateUpToDate => 'Está usando la última versión';

  @override
  String get updateCheckFailed => 'No se pudo buscar actualizaciones';

  @override
  String get linkOpenFailed => 'No se pudo abrir el enlace';

  @override
  String get recentFileMissing =>
      'Ese archivo ya no existe; se ha quitado de la lista';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'MarkText Plus';

  @override
  String get menuFile => 'Файл';

  @override
  String get menuEdit => 'Правка';

  @override
  String get menuView => 'Вид';

  @override
  String get menuFormat => 'Формат';

  @override
  String get menuWindow => 'Окно';

  @override
  String get menuHelp => 'Справка';

  @override
  String get fileNew => 'Новый файл';

  @override
  String get fileNewWindow => 'Новое окно';

  @override
  String get fileOpen => 'Открыть файл';

  @override
  String get fileOpenFolder => 'Открыть папку';

  @override
  String get fileSave => 'Сохранить';

  @override
  String get fileSaveAs => 'Сохранить как';

  @override
  String get fileRecentFiles => 'Recent Files';

  @override
  String get fileNoRecentFiles => 'No Recent Files';

  @override
  String get fileExport => 'Экспорт';

  @override
  String get fileExportHtml => 'HTML';

  @override
  String get fileExportPdf => 'PDF';

  @override
  String get fileSettings => 'Настройки';

  @override
  String get fileQuit => 'Выход';

  @override
  String get editUndo => 'Отменить';

  @override
  String get editRedo => 'Повторить';

  @override
  String get editCut => 'Вырезать';

  @override
  String get editCopy => 'Копировать';

  @override
  String get editPaste => 'Вставить';

  @override
  String get editFind => 'Найти';

  @override
  String get editReplace => 'Заменить';

  @override
  String get editFindInFiles => 'Найти в файлах';

  @override
  String get viewEditMode => 'Режим редактирования';

  @override
  String get viewSourceCode => 'Исходный код';

  @override
  String get viewPreview => 'Предпросмотр';

  @override
  String get viewSplitView => 'Разделенный вид';

  @override
  String get viewShowSidebar => 'Показать боковую панель';

  @override
  String get viewHideSidebar => 'Скрыть боковую панель';

  @override
  String get viewShowTabBar => 'Показать панель вкладок';

  @override
  String get viewHideTabBar => 'Скрыть панель вкладок';

  @override
  String get viewFocusMode => 'Режим фокусировки';

  @override
  String get viewTypewriterMode => 'Режим печатной машинки';

  @override
  String get viewZoomIn => 'Увеличить';

  @override
  String get viewZoomOut => 'Уменьшить';

  @override
  String get viewResetZoom => 'Сбросить масштаб';

  @override
  String get formatBold => 'Жирный';

  @override
  String get formatItalic => 'Курсив';

  @override
  String get formatStrikethrough => 'Зачеркнутый';

  @override
  String formatHeading(int level) {
    return 'Заголовок $level';
  }

  @override
  String get formatOrderedList => 'Нумерованный список';

  @override
  String get formatUnorderedList => 'Маркированный список';

  @override
  String get formatTaskList => 'Список задач';

  @override
  String get formatCodeBlock => 'Блок кода';

  @override
  String get formatQuoteBlock => 'Блок цитаты';

  @override
  String get formatMathBlock => 'Математический блок';

  @override
  String get formatTable => 'Таблица';

  @override
  String get formatLink => 'Ссылка';

  @override
  String get formatImage => 'Изображение';

  @override
  String get formatHorizontalRule => 'Горизонтальная линия';

  @override
  String get windowMinimize => 'Свернуть';

  @override
  String get windowFullScreen => 'Полноэкранный режим';

  @override
  String get windowAlwaysOnTop => 'Поверх всех окон';

  @override
  String get helpAbout => 'О программе MarkText Plus';

  @override
  String get helpCheckUpdates => 'Проверить обновления';

  @override
  String get helpChangelog => 'История изменений';

  @override
  String get helpReportBug => 'Сообщить об ошибке';

  @override
  String get helpRequestFeature => 'Запросить функцию';

  @override
  String get helpGitHub => 'Репозиторий GitHub';

  @override
  String get settingsGeneral => 'Общие';

  @override
  String get settingsEditor => 'Редактор';

  @override
  String get settingsMarkdown => 'Markdown';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsKeybindings => 'Горячие клавиши';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsAutoSave => 'Автосохранение';

  @override
  String get settingsAutoSaveDelay => 'Задержка автосохранения (мс)';

  @override
  String get settingsFontSize => 'Размер шрифта';

  @override
  String get settingsLineHeight => 'Высота строки';

  @override
  String get settingsTabSize => 'Размер табуляции';

  @override
  String get settingsEnableHtml => 'Включить HTML';

  @override
  String get settingsResetDefaults => 'Сбросить настройки';

  @override
  String statusLine(int line, int col) {
    return 'Стр $line, Кол $col';
  }

  @override
  String get statusEncoding => 'UTF-8';

  @override
  String get statusMarkdown => 'Markdown';

  @override
  String get unsavedChanges => 'Несохраненные изменения';

  @override
  String get unsavedChangesMessage => 'Сохранить изменения перед закрытием?';

  @override
  String get save => 'Сохранить';

  @override
  String get dontSave => 'Не сохранять';

  @override
  String get cancel => 'Отмена';

  @override
  String get ok => 'ОК';

  @override
  String get untitled => 'Без названия';

  @override
  String get openRecentFiles => 'Недавние файлы';

  @override
  String get noRecentFiles => 'Нет недавних файлов';

  @override
  String get sidebarFiles => 'Файлы';

  @override
  String get sidebarSearch => 'Поиск';

  @override
  String get sidebarToc => 'Содержание';

  @override
  String get sidebarSettings => 'Настройки';

  @override
  String get formatHeadingSubmenu => 'Заголовок';

  @override
  String get settingsBulletListMarker => 'Маркер списка';

  @override
  String get settingsLightThemes => 'Светлые темы';

  @override
  String get settingsDarkThemes => 'Тёмные темы';

  @override
  String get confirmResetMessage =>
      'Вы уверены, что хотите сбросить все настройки?';

  @override
  String get comingSoon => 'Скоро';

  @override
  String get noFiles => 'Нет файлов';

  @override
  String get noOpenFolder => 'Откройте папку для просмотра файлов';

  @override
  String get searchPlaceholder => 'Поиск в файлах...';

  @override
  String get searchNoResults => 'Результатов не найдено';

  @override
  String searchResultCount(int count) {
    return 'Найдено результатов: $count';
  }

  @override
  String get tocEmpty => 'Заголовки не найдены';

  @override
  String get editFindNext => 'Найти далее';

  @override
  String get editFindPrevious => 'Найти предыдущее';

  @override
  String get editReplaceAll => 'Заменить все';

  @override
  String get editCaseSensitive => 'С учётом регистра';

  @override
  String get editWholeWord => 'Слово целиком';

  @override
  String get editRegex => 'Регулярное выражение';

  @override
  String get editCopyAsMarkdown => 'Копировать как Markdown';

  @override
  String get editCopyAsHtml => 'Копировать как HTML';

  @override
  String get editSelectAll => 'Выделить всё';

  @override
  String get editDuplicateLine => 'Дублировать строку';

  @override
  String get formatUnderline => 'Подчёркнутый';

  @override
  String get formatSuperscript => 'Надстрочный';

  @override
  String get formatSubscript => 'Подстрочный';

  @override
  String get formatHighlight => 'Выделение';

  @override
  String get formatInlineCode => 'Встроенный код';

  @override
  String get formatInlineMath => 'Встроенная формула';

  @override
  String get formatClearFormatting => 'Очистить форматирование';

  @override
  String get settingsCodeFontFamily => 'Шрифт кода';

  @override
  String get settingsEditorMaxWidth => 'Максимальная ширина редактора';

  @override
  String get settingsTextDirection => 'Направление текста';

  @override
  String get keybindingsEdit => 'Изменить сочетание';

  @override
  String get keybindingsPressKeys => 'Нажмите сочетание клавиш...';

  @override
  String get keybindingsReset => 'Сбросить по умолчанию';

  @override
  String get statusWords => 'Слова';

  @override
  String get statusChars => 'Символы';

  @override
  String get statusParagraphs => 'Абзацы';

  @override
  String get themeCadmiumLight => 'Кадмий светлый';

  @override
  String get themeOneDark => 'One Dark';

  @override
  String get themeMaterialDark => 'Material тёмный';

  @override
  String get themeGraphiteLight => 'Графит светлый';

  @override
  String get themeUlyssesLight => 'Ulysses светлый';

  @override
  String get themeRedGraphite => 'Красный графит';

  @override
  String get themeShibuya => 'Сибуя';

  @override
  String get themePinkBlossom => 'Розовый цветок';

  @override
  String get themeSkyBlue => 'Небесно-голубой';

  @override
  String get themeDarkGraphite => 'Тёмный графит';

  @override
  String get themeDieciOLED => 'Dieci OLED';

  @override
  String get themeNord => 'Nord';

  @override
  String get themeMidnight => 'Полночь';

  @override
  String get keybindingBold => 'Жирный';

  @override
  String get keybindingItalic => 'Курсив';

  @override
  String get keybindingUnderline => 'Подчёркнутый';

  @override
  String get keybindingStrikethrough => 'Зачёркнутый';

  @override
  String get keybindingHeading1 => 'Заголовок 1';

  @override
  String get keybindingHeading2 => 'Заголовок 2';

  @override
  String get keybindingHeading3 => 'Заголовок 3';

  @override
  String get keybindingHeading4 => 'Заголовок 4';

  @override
  String get keybindingHeading5 => 'Заголовок 5';

  @override
  String get keybindingHeading6 => 'Заголовок 6';

  @override
  String get keybindingOrderedList => 'Нумерованный список';

  @override
  String get keybindingUnorderedList => 'Маркированный список';

  @override
  String get keybindingTaskList => 'Список задач';

  @override
  String get keybindingCodeBlock => 'Блок кода';

  @override
  String get keybindingQuoteBlock => 'Блок цитаты';

  @override
  String get keybindingTable => 'Таблица';

  @override
  String get keybindingLink => 'Ссылка';

  @override
  String get keybindingImage => 'Изображение';

  @override
  String get keybindingInlineCode => 'Встроенный код';

  @override
  String get keybindingInlineMath => 'Встроенная формула';

  @override
  String get keybindingMathBlock => 'Математический блок';

  @override
  String get keybindingFind => 'Найти';

  @override
  String get keybindingReplace => 'Заменить';

  @override
  String get keybindingSave => 'Сохранить';

  @override
  String get keybindingOpen => 'Открыть';

  @override
  String get keybindingUndo => 'Отменить';

  @override
  String get keybindingRedo => 'Повторить';

  @override
  String get keybindingSelectAll => 'Выделить всё';

  @override
  String get keybindingDuplicateLine => 'Дублировать строку';

  @override
  String get keybindingHighlight => 'Выделение';

  @override
  String get closeFile => 'Закрыть файл';

  @override
  String get copyFileName => 'Копировать имя файла';

  @override
  String get copyFilePath => 'Копировать путь к файлу';

  @override
  String get deleteFile => 'Удалить файл';

  @override
  String confirmDeleteFile(String fileName) {
    return 'Вы уверены, что хотите удалить \"$fileName\"?';
  }

  @override
  String get newFolder => 'Новая папка';

  @override
  String get rename => 'Переименовать';

  @override
  String get delete => 'Удалить';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get fileNameHint => 'Имя файла';

  @override
  String get folderNameHint => 'Имя папки';

  @override
  String get newNameHint => 'Новое имя';

  @override
  String get closeOtherTabs => 'Закрыть другие вкладки';

  @override
  String get closeTabsToRight => 'Закрыть вкладки справа';

  @override
  String get closeAllTabs => 'Закрыть все вкладки';

  @override
  String get revealInExplorer => 'Показать в проводнике';

  @override
  String get formatTextSubmenu => 'Текст';

  @override
  String get formatBlocksSubmenu => 'Блоки';

  @override
  String get formatCodeSubmenu => 'Код';

  @override
  String get formatInsertSubmenu => 'Вставка';

  @override
  String get fileRename => 'Переименовать';

  @override
  String get newTab => 'Новая вкладка';

  @override
  String get newNameHintDialog => 'Новое имя';

  @override
  String get commandPaletteHint => 'Введите команду...';

  @override
  String get commandPaletteNoResults => 'Команды не найдены';

  @override
  String get statusLineFeed => 'LF';

  @override
  String get settingsTextDirectionLtr => 'Слева направо';

  @override
  String get settingsTextDirectionRtl => 'Справа налево';

  @override
  String commandFormatLabel(String action) {
    return 'Формат: $action';
  }

  @override
  String commandFormatDesc(String action) {
    return 'Применить форматирование $action';
  }

  @override
  String get commandNewFile => 'Новый файл';

  @override
  String get commandNewFileDesc => 'Создать новый файл без названия';

  @override
  String get commandSave => 'Сохранить';

  @override
  String get commandSaveDesc => 'Сохранить текущий файл';

  @override
  String get commandSourceMode => 'Режим исходного кода';

  @override
  String get commandSourceModeDesc =>
      'Переключиться в режим редактирования кода';

  @override
  String get commandPreviewMode => 'Режим предпросмотра';

  @override
  String get commandPreviewModeDesc => 'Переключиться в режим предпросмотра';

  @override
  String get commandSplitMode => 'Режим разделения';

  @override
  String get commandSplitModeDesc =>
      'Переключиться в режим разделённого редактирования';

  @override
  String get commandToggleFocusMode => 'Режим фокусировки';

  @override
  String get commandToggleFocusModeDesc => 'Переключить режим фокусировки';

  @override
  String get commandToggleTypewriterMode => 'Режим печатной машинки';

  @override
  String get commandToggleTypewriterModeDesc =>
      'Переключить режим печатной машинки';

  @override
  String get commandToggleSidebar => 'Боковая панель';

  @override
  String get commandToggleSidebarDesc => 'Показать или скрыть боковую панель';

  @override
  String get commandToggleTabBar => 'Панель вкладок';

  @override
  String get commandToggleTabBarDesc => 'Показать или скрыть панель вкладок';

  @override
  String get welcomeNewFile => 'Новый файл';

  @override
  String get welcomeOpenFile => 'Открыть файл';

  @override
  String get welcomeDragHint => 'Перетащите файлы сюда для открытия';
}

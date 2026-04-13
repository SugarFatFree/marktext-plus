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
}

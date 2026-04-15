// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'MarkText Plus';

  @override
  String get menuFile => 'ملف';

  @override
  String get menuEdit => 'تحرير';

  @override
  String get menuView => 'عرض';

  @override
  String get menuFormat => 'تنسيق';

  @override
  String get menuWindow => 'نافذة';

  @override
  String get menuHelp => 'مساعدة';

  @override
  String get fileNew => 'ملف جديد';

  @override
  String get fileNewWindow => 'نافذة جديدة';

  @override
  String get fileOpen => 'فتح ملف';

  @override
  String get fileOpenFolder => 'فتح مجلد';

  @override
  String get fileSave => 'حفظ';

  @override
  String get fileSaveAs => 'حفظ باسم';

  @override
  String get fileRecentFiles => 'Recent Files';

  @override
  String get fileNoRecentFiles => 'No Recent Files';

  @override
  String get fileExport => 'تصدير';

  @override
  String get fileExportHtml => 'HTML';

  @override
  String get fileExportPdf => 'PDF';

  @override
  String get fileSettings => 'الإعدادات';

  @override
  String get fileQuit => 'إنهاء';

  @override
  String get editUndo => 'تراجع';

  @override
  String get editRedo => 'إعادة';

  @override
  String get editCut => 'قص';

  @override
  String get editCopy => 'نسخ';

  @override
  String get editPaste => 'لصق';

  @override
  String get editFind => 'بحث';

  @override
  String get editReplace => 'استبدال';

  @override
  String get editFindInFiles => 'البحث في الملفات';

  @override
  String get viewEditMode => 'وضع التحرير';

  @override
  String get viewSourceCode => 'الشفرة المصدرية';

  @override
  String get viewPreview => 'معاينة';

  @override
  String get viewSplitView => 'عرض مقسم';

  @override
  String get viewShowSidebar => 'إظهار الشريط الجانبي';

  @override
  String get viewHideSidebar => 'إخفاء الشريط الجانبي';

  @override
  String get viewShowTabBar => 'إظهار شريط التبويب';

  @override
  String get viewHideTabBar => 'إخفاء شريط التبويب';

  @override
  String get viewFocusMode => 'وضع التركيز';

  @override
  String get viewTypewriterMode => 'وضع الآلة الكاتبة';

  @override
  String get viewZoomIn => 'تكبير';

  @override
  String get viewZoomOut => 'تصغير';

  @override
  String get viewResetZoom => 'إعادة تعيين التكبير';

  @override
  String get formatBold => 'غامق';

  @override
  String get formatItalic => 'مائل';

  @override
  String get formatStrikethrough => 'يتوسطه خط';

  @override
  String formatHeading(int level) {
    return 'عنوان $level';
  }

  @override
  String get formatOrderedList => 'قائمة مرقمة';

  @override
  String get formatUnorderedList => 'قائمة نقطية';

  @override
  String get formatTaskList => 'قائمة مهام';

  @override
  String get formatCodeBlock => 'كتلة برمجية';

  @override
  String get formatQuoteBlock => 'كتلة اقتباس';

  @override
  String get formatMathBlock => 'كتلة رياضية';

  @override
  String get formatTable => 'جدول';

  @override
  String get formatLink => 'رابط';

  @override
  String get formatImage => 'صورة';

  @override
  String get formatHorizontalRule => 'خط أفقي';

  @override
  String get windowMinimize => 'تصغير';

  @override
  String get windowFullScreen => 'ملء الشاشة';

  @override
  String get windowAlwaysOnTop => 'دائماً في المقدمة';

  @override
  String get helpAbout => 'حول MarkText Plus';

  @override
  String get helpCheckUpdates => 'التحقق من التحديثات';

  @override
  String get helpChangelog => 'سجل التغييرات';

  @override
  String get helpReportBug => 'الإبلاغ عن خطأ';

  @override
  String get helpRequestFeature => 'طلب ميزة';

  @override
  String get helpGitHub => 'مستودع GitHub';

  @override
  String get settingsGeneral => 'عام';

  @override
  String get settingsEditor => 'المحرر';

  @override
  String get settingsMarkdown => 'Markdown';

  @override
  String get settingsTheme => 'السمة';

  @override
  String get settingsKeybindings => 'اختصارات لوحة المفاتيح';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsAutoSave => 'حفظ تلقائي';

  @override
  String get settingsAutoSaveDelay => 'تأخير الحفظ التلقائي (مللي ثانية)';

  @override
  String get settingsFontSize => 'حجم الخط';

  @override
  String get settingsLineHeight => 'ارتفاع السطر';

  @override
  String get settingsTabSize => 'حجم علامة التبويب';

  @override
  String get settingsEnableHtml => 'تفعيل HTML';

  @override
  String get settingsResetDefaults => 'إعادة تعيين الإعدادات الافتراضية';

  @override
  String statusLine(int line, int col) {
    return 'سطر $line، عمود $col';
  }

  @override
  String get statusEncoding => 'UTF-8';

  @override
  String get statusMarkdown => 'Markdown';

  @override
  String get unsavedChanges => 'تغييرات غير محفوظة';

  @override
  String get unsavedChangesMessage => 'هل تريد حفظ التغييرات قبل الإغلاق؟';

  @override
  String get save => 'حفظ';

  @override
  String get dontSave => 'عدم الحفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get ok => 'موافق';

  @override
  String get untitled => 'بدون عنوان';

  @override
  String get openRecentFiles => 'الملفات الأخيرة';

  @override
  String get noRecentFiles => 'لا توجد ملفات حديثة';

  @override
  String get sidebarFiles => 'الملفات';

  @override
  String get sidebarSearch => 'بحث';

  @override
  String get sidebarToc => 'جدول المحتويات';

  @override
  String get sidebarSettings => 'الإعدادات';

  @override
  String get formatHeadingSubmenu => 'عنوان';

  @override
  String get settingsBulletListMarker => 'علامة القائمة';

  @override
  String get settingsDarkMode => 'الوضع الداكن';

  @override
  String get confirmResetMessage =>
      'هل أنت متأكد من إعادة تعيين جميع الإعدادات؟';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get noFiles => 'لا توجد ملفات';

  @override
  String get noOpenFolder => 'افتح مجلداً لتصفح الملفات';

  @override
  String get searchPlaceholder => 'البحث في الملفات...';

  @override
  String get searchNoResults => 'لم يتم العثور على نتائج';

  @override
  String searchResultCount(int count) {
    return 'تم العثور على $count نتيجة';
  }

  @override
  String get tocEmpty => 'لم يتم العثور على عناوين';

  @override
  String get editFindNext => 'البحث عن التالي';

  @override
  String get editFindPrevious => 'البحث عن السابق';

  @override
  String get editReplaceAll => 'استبدال الكل';

  @override
  String get editCaseSensitive => 'مطابقة حالة الأحرف';

  @override
  String get editWholeWord => 'كلمة كاملة';

  @override
  String get editRegex => 'تعبير نمطي';

  @override
  String get editCopyAsMarkdown => 'نسخ كـ Markdown';

  @override
  String get editCopyAsHtml => 'نسخ كـ HTML';

  @override
  String get editSelectAll => 'تحديد الكل';

  @override
  String get editDuplicateLine => 'تكرار السطر';

  @override
  String get formatUnderline => 'تسطير';

  @override
  String get formatSuperscript => 'نص مرتفع';

  @override
  String get formatSubscript => 'نص منخفض';

  @override
  String get formatHighlight => 'تمييز';

  @override
  String get formatInlineCode => 'كود مضمّن';

  @override
  String get formatInlineMath => 'صيغة مضمّنة';

  @override
  String get formatClearFormatting => 'مسح التنسيق';

  @override
  String get settingsCodeFontFamily => 'خط الكود';

  @override
  String get settingsEditorMaxWidth => 'أقصى عرض للمحرر';

  @override
  String get settingsTextDirection => 'اتجاه النص';

  @override
  String get keybindingsEdit => 'تحرير الاختصار';

  @override
  String get keybindingsPressKeys => 'اضغط مجموعة المفاتيح...';

  @override
  String get keybindingsReset => 'إعادة تعيين الافتراضي';

  @override
  String get statusWords => 'كلمات';

  @override
  String get statusChars => 'أحرف';

  @override
  String get statusParagraphs => 'فقرات';

  @override
  String get themeCadmiumLight => 'كادميوم فاتح';

  @override
  String get themeOneDark => 'One Dark';

  @override
  String get themeMaterialDark => 'Material داكن';

  @override
  String get themeGraphiteLight => 'جرافيت فاتح';

  @override
  String get themeUlyssesLight => 'Ulysses فاتح';

  @override
  String get keybindingBold => 'غامق';

  @override
  String get keybindingItalic => 'مائل';

  @override
  String get keybindingUnderline => 'تسطير';

  @override
  String get keybindingStrikethrough => 'يتوسطه خط';

  @override
  String get keybindingHeading1 => 'عنوان 1';

  @override
  String get keybindingHeading2 => 'عنوان 2';

  @override
  String get keybindingHeading3 => 'عنوان 3';

  @override
  String get keybindingHeading4 => 'عنوان 4';

  @override
  String get keybindingHeading5 => 'عنوان 5';

  @override
  String get keybindingHeading6 => 'عنوان 6';

  @override
  String get keybindingOrderedList => 'قائمة مرقمة';

  @override
  String get keybindingUnorderedList => 'قائمة نقطية';

  @override
  String get keybindingTaskList => 'قائمة مهام';

  @override
  String get keybindingCodeBlock => 'كتلة برمجية';

  @override
  String get keybindingQuoteBlock => 'كتلة اقتباس';

  @override
  String get keybindingTable => 'جدول';

  @override
  String get keybindingLink => 'رابط';

  @override
  String get keybindingImage => 'صورة';

  @override
  String get keybindingInlineCode => 'كود مضمّن';

  @override
  String get keybindingInlineMath => 'صيغة مضمّنة';

  @override
  String get keybindingMathBlock => 'كتلة رياضية';

  @override
  String get keybindingFind => 'بحث';

  @override
  String get keybindingReplace => 'استبدال';

  @override
  String get keybindingSave => 'حفظ';

  @override
  String get keybindingOpen => 'فتح';

  @override
  String get keybindingUndo => 'تراجع';

  @override
  String get keybindingRedo => 'إعادة';

  @override
  String get keybindingSelectAll => 'تحديد الكل';

  @override
  String get keybindingDuplicateLine => 'تكرار السطر';

  @override
  String get keybindingHighlight => 'تمييز';

  @override
  String get closeFile => 'إغلاق الملف';

  @override
  String get copyFileName => 'نسخ اسم الملف';

  @override
  String get copyFilePath => 'نسخ مسار الملف';

  @override
  String get deleteFile => 'حذف الملف';

  @override
  String confirmDeleteFile(String fileName) {
    return 'هل أنت متأكد من حذف \"$fileName\"؟';
  }
}

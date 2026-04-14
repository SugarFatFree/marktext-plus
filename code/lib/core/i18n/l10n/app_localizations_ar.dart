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
}

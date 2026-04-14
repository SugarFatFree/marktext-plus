// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'MarkText Plus';

  @override
  String get menuFile => '文件';

  @override
  String get menuEdit => '编辑';

  @override
  String get menuView => '视图';

  @override
  String get menuFormat => '格式';

  @override
  String get menuWindow => '窗口';

  @override
  String get menuHelp => '帮助';

  @override
  String get fileNew => '新建文件';

  @override
  String get fileNewWindow => '新建窗口';

  @override
  String get fileOpen => '打开文件';

  @override
  String get fileOpenFolder => '打开文件夹';

  @override
  String get fileSave => '保存';

  @override
  String get fileSaveAs => '另存为';

  @override
  String get fileRecentFiles => '最近文件';

  @override
  String get fileNoRecentFiles => '无最近文件';

  @override
  String get fileExport => '导出';

  @override
  String get fileExportHtml => 'HTML';

  @override
  String get fileExportPdf => 'PDF';

  @override
  String get fileSettings => '设置';

  @override
  String get fileQuit => '退出';

  @override
  String get editUndo => '撤销';

  @override
  String get editRedo => '重做';

  @override
  String get editCut => '剪切';

  @override
  String get editCopy => '复制';

  @override
  String get editPaste => '粘贴';

  @override
  String get editFind => '查找';

  @override
  String get editReplace => '替换';

  @override
  String get editFindInFiles => '在文件中查找';

  @override
  String get viewEditMode => '编辑模式';

  @override
  String get viewSourceCode => '源代码';

  @override
  String get viewPreview => '预览';

  @override
  String get viewSplitView => '双栏视图';

  @override
  String get viewShowSidebar => '显示侧边栏';

  @override
  String get viewHideSidebar => '隐藏侧边栏';

  @override
  String get viewShowTabBar => '显示标签栏';

  @override
  String get viewHideTabBar => '隐藏标签栏';

  @override
  String get viewFocusMode => '专注模式';

  @override
  String get viewTypewriterMode => '打字机模式';

  @override
  String get viewZoomIn => '放大';

  @override
  String get viewZoomOut => '缩小';

  @override
  String get viewResetZoom => '重置缩放';

  @override
  String get formatBold => '粗体';

  @override
  String get formatItalic => '斜体';

  @override
  String get formatStrikethrough => '删除线';

  @override
  String formatHeading(int level) {
    return '$level 级标题';
  }

  @override
  String get formatOrderedList => '有序列表';

  @override
  String get formatUnorderedList => '无序列表';

  @override
  String get formatTaskList => '任务列表';

  @override
  String get formatCodeBlock => '代码块';

  @override
  String get formatQuoteBlock => '引用块';

  @override
  String get formatMathBlock => '数学公式';

  @override
  String get formatTable => '表格';

  @override
  String get formatLink => '链接';

  @override
  String get formatImage => '图片';

  @override
  String get formatHorizontalRule => '分隔线';

  @override
  String get windowMinimize => '最小化';

  @override
  String get windowFullScreen => '切换全屏';

  @override
  String get windowAlwaysOnTop => '置顶';

  @override
  String get helpAbout => '关于 MarkText Plus';

  @override
  String get helpCheckUpdates => '检查更新';

  @override
  String get helpChangelog => '更新日志';

  @override
  String get helpReportBug => '报告问题';

  @override
  String get helpRequestFeature => '功能建议';

  @override
  String get helpGitHub => 'GitHub 仓库';

  @override
  String get settingsGeneral => '通用';

  @override
  String get settingsEditor => '编辑器';

  @override
  String get settingsMarkdown => 'Markdown';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsKeybindings => '快捷键';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsAutoSave => '自动保存';

  @override
  String get settingsAutoSaveDelay => '自动保存延迟（毫秒）';

  @override
  String get settingsFontSize => '字体大小';

  @override
  String get settingsLineHeight => '行高';

  @override
  String get settingsTabSize => 'Tab 大小';

  @override
  String get settingsEnableHtml => '启用 HTML';

  @override
  String get settingsResetDefaults => '恢复默认设置';

  @override
  String statusLine(int line, int col) {
    return '行 $line, 列 $col';
  }

  @override
  String get statusEncoding => 'UTF-8';

  @override
  String get statusMarkdown => 'Markdown';

  @override
  String get unsavedChanges => '未保存的更改';

  @override
  String get unsavedChangesMessage => '关闭前是否保存更改？';

  @override
  String get save => '保存';

  @override
  String get dontSave => '不保存';

  @override
  String get cancel => '取消';

  @override
  String get ok => '确定';

  @override
  String get untitled => '未命名';

  @override
  String get openRecentFiles => '最近打开的文件';

  @override
  String get noRecentFiles => '没有最近的文件';

  @override
  String get sidebarFiles => '文件';

  @override
  String get sidebarSearch => '搜索';

  @override
  String get sidebarToc => '目录';

  @override
  String get sidebarSettings => '设置';

  @override
  String get formatHeadingSubmenu => '标题';

  @override
  String get settingsBulletListMarker => '无序列表标记';

  @override
  String get settingsDarkMode => '深色模式';

  @override
  String get confirmResetMessage => '确定要恢复所有设置为默认值吗？';

  @override
  String get comingSoon => '即将推出';

  @override
  String get noFiles => '没有文件';

  @override
  String get noOpenFolder => '打开文件夹以浏览文件';

  @override
  String get searchPlaceholder => '在文件中搜索...';

  @override
  String get searchNoResults => '未找到结果';

  @override
  String searchResultCount(int count) {
    return '找到 $count 个结果';
  }

  @override
  String get tocEmpty => '未找到标题';

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

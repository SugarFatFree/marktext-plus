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
  String get settingsLightThemes => '浅色主题';

  @override
  String get settingsDarkThemes => '深色主题';

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
  String get editFindNext => '查找下一个';

  @override
  String get editFindPrevious => '查找上一个';

  @override
  String get editReplaceAll => '全部替换';

  @override
  String get editCaseSensitive => '区分大小写';

  @override
  String get editWholeWord => '全字匹配';

  @override
  String get editRegex => '正则表达式';

  @override
  String get editCopyAsMarkdown => '复制为 Markdown';

  @override
  String get editCopyAsHtml => '复制为 HTML';

  @override
  String get editSelectAll => '全选';

  @override
  String get editDuplicateLine => '复制行';

  @override
  String get formatUnderline => '下划线';

  @override
  String get formatSuperscript => '上标';

  @override
  String get formatSubscript => '下标';

  @override
  String get formatHighlight => '高亮';

  @override
  String get formatInlineCode => '行内代码';

  @override
  String get formatInlineMath => '行内公式';

  @override
  String get formatClearFormatting => '清除格式';

  @override
  String get settingsCodeFontFamily => '代码字体';

  @override
  String get settingsEditorMaxWidth => '编辑器最大宽度';

  @override
  String get settingsTextDirection => '文本方向';

  @override
  String get keybindingsEdit => '编辑快捷键';

  @override
  String get keybindingsPressKeys => '按下组合键...';

  @override
  String get keybindingsReset => '恢复默认';

  @override
  String get statusWords => '单词';

  @override
  String get statusChars => '字符';

  @override
  String get statusParagraphs => '段落';

  @override
  String get themeCadmiumLight => '镉黄浅色';

  @override
  String get themeOneDark => 'One Dark';

  @override
  String get themeMaterialDark => 'Material 深色';

  @override
  String get themeGraphiteLight => '石墨浅色';

  @override
  String get themeUlyssesLight => 'Ulysses 浅色';

  @override
  String get themeRedGraphite => '红石墨';

  @override
  String get themeShibuya => '涩谷';

  @override
  String get themePinkBlossom => '粉樱';

  @override
  String get themeSkyBlue => '天蓝';

  @override
  String get themeDarkGraphite => '深色石墨';

  @override
  String get themeDieciOLED => 'Dieci 纯黑';

  @override
  String get themeNord => 'Nord 极光';

  @override
  String get themeMidnight => '午夜蓝';

  @override
  String get keybindingBold => '粗体';

  @override
  String get keybindingItalic => '斜体';

  @override
  String get keybindingUnderline => '下划线';

  @override
  String get keybindingStrikethrough => '删除线';

  @override
  String get keybindingHeading1 => '一级标题';

  @override
  String get keybindingHeading2 => '二级标题';

  @override
  String get keybindingHeading3 => '三级标题';

  @override
  String get keybindingHeading4 => '四级标题';

  @override
  String get keybindingHeading5 => '五级标题';

  @override
  String get keybindingHeading6 => '六级标题';

  @override
  String get keybindingOrderedList => '有序列表';

  @override
  String get keybindingUnorderedList => '无序列表';

  @override
  String get keybindingTaskList => '任务列表';

  @override
  String get keybindingCodeBlock => '代码块';

  @override
  String get keybindingQuoteBlock => '引用块';

  @override
  String get keybindingTable => '表格';

  @override
  String get keybindingLink => '链接';

  @override
  String get keybindingImage => '图片';

  @override
  String get keybindingInlineCode => '行内代码';

  @override
  String get keybindingInlineMath => '行内公式';

  @override
  String get keybindingMathBlock => '数学公式块';

  @override
  String get keybindingFind => '查找';

  @override
  String get keybindingReplace => '替换';

  @override
  String get keybindingSave => '保存';

  @override
  String get keybindingOpen => '打开';

  @override
  String get keybindingUndo => '撤销';

  @override
  String get keybindingRedo => '重做';

  @override
  String get keybindingSelectAll => '全选';

  @override
  String get keybindingDuplicateLine => '复制行';

  @override
  String get keybindingHighlight => '高亮';

  @override
  String get closeFile => '关闭文件';

  @override
  String get copyFileName => '复制文件名';

  @override
  String get copyFilePath => '复制文件路径';

  @override
  String get deleteFile => '删除文件';

  @override
  String confirmDeleteFile(String fileName) {
    return '确定要删除 \"$fileName\" 吗？';
  }

  @override
  String get newFolder => '新建文件夹';

  @override
  String get rename => '重命名';

  @override
  String get delete => '删除';

  @override
  String get confirm => '确认';

  @override
  String get fileNameHint => '文件名';

  @override
  String get folderNameHint => '文件夹名';

  @override
  String get newNameHint => '新名称';

  @override
  String get closeOtherTabs => '关闭其他标签页';

  @override
  String get closeTabsToRight => '关闭右侧标签页';

  @override
  String get closeAllTabs => '关闭所有标签页';

  @override
  String get revealInExplorer => '在文件管理器中显示';

  @override
  String get formatTextSubmenu => '文本';

  @override
  String get formatBlocksSubmenu => '块元素';

  @override
  String get formatCodeSubmenu => '代码';

  @override
  String get formatInsertSubmenu => '插入';

  @override
  String get fileRename => '重命名';

  @override
  String get newTab => '新建标签页';

  @override
  String get newNameHintDialog => '新名称';

  @override
  String get commandPaletteHint => '输入命令...';

  @override
  String get commandPaletteNoResults => '没有匹配的命令';

  @override
  String get statusLineFeed => 'LF';

  @override
  String get settingsTextDirectionLtr => '从左到右';

  @override
  String get settingsTextDirectionRtl => '从右到左';

  @override
  String commandFormatLabel(String action) {
    return '格式：$action';
  }

  @override
  String commandFormatDesc(String action) {
    return '应用$action格式';
  }

  @override
  String get commandNewFile => '新建文件';

  @override
  String get commandNewFileDesc => '创建一个新的无标题文件';

  @override
  String get commandSave => '保存';

  @override
  String get commandSaveDesc => '保存当前文件';

  @override
  String get commandSourceMode => '源码模式';

  @override
  String get commandSourceModeDesc => '切换到源码编辑模式';

  @override
  String get commandPreviewMode => '预览模式';

  @override
  String get commandPreviewModeDesc => '切换到预览模式';

  @override
  String get commandSplitMode => '分屏模式';

  @override
  String get commandSplitModeDesc => '切换到分屏编辑模式';

  @override
  String get commandToggleFocusMode => '切换专注模式';

  @override
  String get commandToggleFocusModeDesc => '切换无干扰专注模式';

  @override
  String get commandToggleTypewriterMode => '切换打字机模式';

  @override
  String get commandToggleTypewriterModeDesc => '切换打字机滚动模式';

  @override
  String get commandToggleSidebar => '切换侧边栏';

  @override
  String get commandToggleSidebarDesc => '显示或隐藏侧边栏';

  @override
  String get commandToggleTabBar => '切换标签栏';

  @override
  String get commandToggleTabBarDesc => '显示或隐藏标签栏';

  @override
  String get welcomeNewFile => '新建文件';

  @override
  String get welcomeOpenFile => '打开文件';

  @override
  String get welcomeDragHint => '拖拽文件到此处打开';
}

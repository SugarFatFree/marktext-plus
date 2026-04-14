// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'MarkText Plus';

  @override
  String get menuFile => 'ファイル';

  @override
  String get menuEdit => '編集';

  @override
  String get menuView => '表示';

  @override
  String get menuFormat => '書式';

  @override
  String get menuWindow => 'ウィンドウ';

  @override
  String get menuHelp => 'ヘルプ';

  @override
  String get fileNew => '新規ファイル';

  @override
  String get fileNewWindow => '新規ウィンドウ';

  @override
  String get fileOpen => 'ファイルを開く';

  @override
  String get fileOpenFolder => 'フォルダを開く';

  @override
  String get fileSave => '保存';

  @override
  String get fileSaveAs => '名前を付けて保存';

  @override
  String get fileRecentFiles => 'Recent Files';

  @override
  String get fileNoRecentFiles => 'No Recent Files';

  @override
  String get fileExport => 'エクスポート';

  @override
  String get fileExportHtml => 'HTML';

  @override
  String get fileExportPdf => 'PDF';

  @override
  String get fileSettings => '設定';

  @override
  String get fileQuit => '終了';

  @override
  String get editUndo => '元に戻す';

  @override
  String get editRedo => 'やり直し';

  @override
  String get editCut => '切り取り';

  @override
  String get editCopy => 'コピー';

  @override
  String get editPaste => '貼り付け';

  @override
  String get editFind => '検索';

  @override
  String get editReplace => '置換';

  @override
  String get editFindInFiles => 'ファイル内検索';

  @override
  String get viewEditMode => '編集モード';

  @override
  String get viewSourceCode => 'ソースコード';

  @override
  String get viewPreview => 'プレビュー';

  @override
  String get viewSplitView => '分割ビュー';

  @override
  String get viewShowSidebar => 'サイドバーを表示';

  @override
  String get viewHideSidebar => 'サイドバーを非表示';

  @override
  String get viewShowTabBar => 'タブバーを表示';

  @override
  String get viewHideTabBar => 'タブバーを非表示';

  @override
  String get viewFocusMode => '集中モード';

  @override
  String get viewTypewriterMode => 'タイプライターモード';

  @override
  String get viewZoomIn => '拡大';

  @override
  String get viewZoomOut => '縮小';

  @override
  String get viewResetZoom => 'ズームをリセット';

  @override
  String get formatBold => '太字';

  @override
  String get formatItalic => '斜体';

  @override
  String get formatStrikethrough => '取り消し線';

  @override
  String formatHeading(int level) {
    return '見出し $level';
  }

  @override
  String get formatOrderedList => '番号付きリスト';

  @override
  String get formatUnorderedList => '箇条書きリスト';

  @override
  String get formatTaskList => 'タスクリスト';

  @override
  String get formatCodeBlock => 'コードブロック';

  @override
  String get formatQuoteBlock => '引用ブロック';

  @override
  String get formatMathBlock => '数式ブロック';

  @override
  String get formatTable => 'テーブル';

  @override
  String get formatLink => 'リンク';

  @override
  String get formatImage => '画像';

  @override
  String get formatHorizontalRule => '水平線';

  @override
  String get windowMinimize => '最小化';

  @override
  String get windowFullScreen => 'フルスクリーン切替';

  @override
  String get windowAlwaysOnTop => '常に最前面';

  @override
  String get helpAbout => 'MarkText Plus について';

  @override
  String get helpCheckUpdates => 'アップデートを確認';

  @override
  String get helpChangelog => '変更履歴';

  @override
  String get helpReportBug => 'バグを報告';

  @override
  String get helpRequestFeature => '機能をリクエスト';

  @override
  String get helpGitHub => 'GitHub リポジトリ';

  @override
  String get settingsGeneral => '一般';

  @override
  String get settingsEditor => 'エディタ';

  @override
  String get settingsMarkdown => 'Markdown';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsKeybindings => 'キーバインド';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsAutoSave => '自動保存';

  @override
  String get settingsAutoSaveDelay => '自動保存の遅延（ミリ秒）';

  @override
  String get settingsFontSize => 'フォントサイズ';

  @override
  String get settingsLineHeight => '行の高さ';

  @override
  String get settingsTabSize => 'タブサイズ';

  @override
  String get settingsEnableHtml => 'HTML を有効化';

  @override
  String get settingsResetDefaults => 'デフォルトに戻す';

  @override
  String statusLine(int line, int col) {
    return '$line 行, $col 列';
  }

  @override
  String get statusEncoding => 'UTF-8';

  @override
  String get statusMarkdown => 'Markdown';

  @override
  String get unsavedChanges => '未保存の変更';

  @override
  String get unsavedChangesMessage => '閉じる前に変更を保存しますか？';

  @override
  String get save => '保存';

  @override
  String get dontSave => '保存しない';

  @override
  String get cancel => 'キャンセル';

  @override
  String get ok => 'OK';

  @override
  String get untitled => '無題';

  @override
  String get openRecentFiles => '最近開いたファイル';

  @override
  String get noRecentFiles => '最近のファイルはありません';

  @override
  String get sidebarFiles => 'ファイル';

  @override
  String get sidebarSearch => '検索';

  @override
  String get sidebarToc => '目次';

  @override
  String get sidebarSettings => '設定';

  @override
  String get formatHeadingSubmenu => '見出し';

  @override
  String get settingsBulletListMarker => '箇条書きマーカー';

  @override
  String get settingsDarkMode => 'ダークモード';

  @override
  String get confirmResetMessage => 'すべての設定をデフォルトに戻しますか？';

  @override
  String get comingSoon => '近日公開';

  @override
  String get noFiles => 'ファイルなし';

  @override
  String get noOpenFolder => 'フォルダを開いてファイルを参照';

  @override
  String get searchPlaceholder => 'ファイル内を検索...';

  @override
  String get searchNoResults => '結果が見つかりません';

  @override
  String searchResultCount(int count) {
    return '$count 件の結果';
  }

  @override
  String get tocEmpty => '見出しが見つかりません';

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

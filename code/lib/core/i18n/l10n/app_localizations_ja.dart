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
  String get settingsLightThemes => 'ライトテーマ';

  @override
  String get settingsDarkThemes => 'ダークテーマ';

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
  String get editFindNext => '次を検索';

  @override
  String get editFindPrevious => '前を検索';

  @override
  String get editReplaceAll => 'すべて置換';

  @override
  String get editCaseSensitive => '大文字と小文字を区別';

  @override
  String get editWholeWord => '単語全体';

  @override
  String get editRegex => '正規表現';

  @override
  String get editCopyAsMarkdown => 'Markdownとしてコピー';

  @override
  String get editCopyAsHtml => 'HTMLとしてコピー';

  @override
  String get editSelectAll => 'すべて選択';

  @override
  String get editDuplicateLine => '行を複製';

  @override
  String get formatUnderline => '下線';

  @override
  String get formatSuperscript => '上付き文字';

  @override
  String get formatSubscript => '下付き文字';

  @override
  String get formatHighlight => 'ハイライト';

  @override
  String get formatInlineCode => 'インラインコード';

  @override
  String get formatInlineMath => 'インライン数式';

  @override
  String get formatClearFormatting => '書式をクリア';

  @override
  String get settingsCodeFontFamily => 'コードフォント';

  @override
  String get settingsEditorMaxWidth => 'エディタの最大幅';

  @override
  String get settingsTextDirection => 'テキスト方向';

  @override
  String get keybindingsEdit => 'キーバインドを編集';

  @override
  String get keybindingsPressKeys => 'キーの組み合わせを押してください...';

  @override
  String get keybindingsReset => 'デフォルトに戻す';

  @override
  String get statusWords => '単語';

  @override
  String get statusChars => '文字';

  @override
  String get statusParagraphs => '段落';

  @override
  String get themeCadmiumLight => 'カドミウムライト';

  @override
  String get themeOneDark => 'One Dark';

  @override
  String get themeMaterialDark => 'Material ダーク';

  @override
  String get themeGraphiteLight => 'グラファイトライト';

  @override
  String get themeUlyssesLight => 'Ulysses ライト';

  @override
  String get themeRedGraphite => 'レッドグラファイト';

  @override
  String get themeShibuya => '渋谷';

  @override
  String get themePinkBlossom => 'ピンクブロッサム';

  @override
  String get themeSkyBlue => 'スカイブルー';

  @override
  String get themeDarkGraphite => 'ダークグラファイト';

  @override
  String get themeDieciOLED => 'Dieci OLED';

  @override
  String get themeNord => 'Nord';

  @override
  String get themeMidnight => 'ミッドナイト';

  @override
  String get keybindingBold => '太字';

  @override
  String get keybindingItalic => '斜体';

  @override
  String get keybindingUnderline => '下線';

  @override
  String get keybindingStrikethrough => '取り消し線';

  @override
  String get keybindingHeading1 => '見出し 1';

  @override
  String get keybindingHeading2 => '見出し 2';

  @override
  String get keybindingHeading3 => '見出し 3';

  @override
  String get keybindingHeading4 => '見出し 4';

  @override
  String get keybindingHeading5 => '見出し 5';

  @override
  String get keybindingHeading6 => '見出し 6';

  @override
  String get keybindingOrderedList => '番号付きリスト';

  @override
  String get keybindingUnorderedList => '箇条書きリスト';

  @override
  String get keybindingTaskList => 'タスクリスト';

  @override
  String get keybindingCodeBlock => 'コードブロック';

  @override
  String get keybindingQuoteBlock => '引用ブロック';

  @override
  String get keybindingTable => 'テーブル';

  @override
  String get keybindingLink => 'リンク';

  @override
  String get keybindingImage => '画像';

  @override
  String get keybindingInlineCode => 'インラインコード';

  @override
  String get keybindingInlineMath => 'インライン数式';

  @override
  String get keybindingMathBlock => '数式ブロック';

  @override
  String get keybindingFind => '検索';

  @override
  String get keybindingReplace => '置換';

  @override
  String get keybindingSave => '保存';

  @override
  String get keybindingOpen => '開く';

  @override
  String get keybindingUndo => '元に戻す';

  @override
  String get keybindingRedo => 'やり直し';

  @override
  String get keybindingSelectAll => 'すべて選択';

  @override
  String get keybindingDuplicateLine => '行を複製';

  @override
  String get keybindingHighlight => 'ハイライト';

  @override
  String get closeFile => 'ファイルを閉じる';

  @override
  String get copyFileName => 'ファイル名をコピー';

  @override
  String get copyFilePath => 'ファイルパスをコピー';

  @override
  String get deleteFile => 'ファイルを削除';

  @override
  String confirmDeleteFile(String fileName) {
    return '\"$fileName\" を削除してもよろしいですか？';
  }

  @override
  String get newFolder => '新しいフォルダ';

  @override
  String get rename => '名前を変更';

  @override
  String get delete => '削除';

  @override
  String get confirm => '確認';

  @override
  String get fileNameHint => 'ファイル名';

  @override
  String get folderNameHint => 'フォルダ名';

  @override
  String get newNameHint => '新しい名前';

  @override
  String get closeOtherTabs => '他のタブを閉じる';

  @override
  String get closeTabsToRight => '右側のタブを閉じる';

  @override
  String get closeAllTabs => 'すべてのタブを閉じる';

  @override
  String get revealInExplorer => 'ファイルマネージャーで表示';

  @override
  String get formatTextSubmenu => 'テキスト';

  @override
  String get formatBlocksSubmenu => 'ブロック';

  @override
  String get formatCodeSubmenu => 'コード';

  @override
  String get formatInsertSubmenu => '挿入';

  @override
  String get fileRename => '名前を変更';

  @override
  String get newTab => '新しいタブ';

  @override
  String get newNameHintDialog => '新しい名前';

  @override
  String get commandPaletteHint => 'コマンドを入力...';

  @override
  String get commandPaletteNoResults => '一致するコマンドがありません';

  @override
  String get statusLineFeed => 'LF';

  @override
  String get settingsTextDirectionLtr => '左から右';

  @override
  String get settingsTextDirectionRtl => '右から左';

  @override
  String commandFormatLabel(String action) {
    return '書式：$action';
  }

  @override
  String commandFormatDesc(String action) {
    return '$action書式を適用';
  }

  @override
  String get commandNewFile => '新規ファイル';

  @override
  String get commandNewFileDesc => '新しい無題ファイルを作成';

  @override
  String get commandSave => '保存';

  @override
  String get commandSaveDesc => '現在のファイルを保存';

  @override
  String get commandSourceMode => 'ソースモード';

  @override
  String get commandSourceModeDesc => 'ソースコード編集モードに切り替え';

  @override
  String get commandPreviewMode => 'プレビューモード';

  @override
  String get commandPreviewModeDesc => 'プレビューモードに切り替え';

  @override
  String get commandSplitMode => '分割モード';

  @override
  String get commandSplitModeDesc => '分割編集モードに切り替え';

  @override
  String get commandToggleFocusMode => 'フォーカスモード切替';

  @override
  String get commandToggleFocusModeDesc => '集中フォーカスモードを切り替え';

  @override
  String get commandToggleTypewriterMode => 'タイプライターモード切替';

  @override
  String get commandToggleTypewriterModeDesc => 'タイプライタースクロールモードを切り替え';

  @override
  String get commandToggleSidebar => 'サイドバー切替';

  @override
  String get commandToggleSidebarDesc => 'サイドバーの表示/非表示を切り替え';

  @override
  String get commandToggleTabBar => 'タブバー切替';

  @override
  String get commandToggleTabBarDesc => 'タブバーの表示/非表示を切り替え';

  @override
  String get welcomeNewFile => '新規ファイル';

  @override
  String get welcomeOpenFile => 'ファイルを開く';

  @override
  String get welcomeDragHint => 'ファイルをここにドロップして開く';

  @override
  String get fileOpenBehavior => 'File Opening Behavior';

  @override
  String get fileOpenBehaviorTitle => 'How to Open Files?';

  @override
  String get fileOpenBehaviorMessage =>
      'When you double-click a file while the app is already running:';

  @override
  String get fileOpenBehaviorNewWindow => 'Open in New Window';

  @override
  String get fileOpenBehaviorNewWindowDesc => 'Allow multiple app instances';

  @override
  String get fileOpenBehaviorExistingWindow => 'Open in Current Window';

  @override
  String get fileOpenBehaviorExistingWindowDesc =>
      'Add to existing tabs (single instance)';

  @override
  String get fileOpenBehaviorNotSet => 'Not configured';
}

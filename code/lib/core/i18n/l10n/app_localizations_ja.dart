// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get settingsWrapCodeBlocks => 'コードブロック内の長い行を折り返す';

  @override
  String get settingsCodeBlockLineNumbers => 'コードブロックの行番号';

  @override
  String settingsSaveFailed(String message) {
    return '設定を保存できませんでした: $message';
  }

  @override
  String get settingsFollowSystemTheme => 'システムのライト/ダーク設定に従う';

  @override
  String get settingsFollowSystemThemeHint =>
      'ライトとダークのテーマをそれぞれ選ぶと、どちらを表示するかはシステムが決めます。';

  @override
  String get settingsAutoPairBracket => '括弧を自動で閉じる';

  @override
  String get settingsAutoPairQuote => '引用符を自動で閉じる';

  @override
  String get settingsAutoPairMarkdown => 'Markdown 記法を自動で閉じる（`、*、~）';

  @override
  String get helpOpenDiagnosticLog => '診断ログを開く';

  @override
  String get diagnosticLogMissing => '診断ログはまだ書き出されていません';

  @override
  String get mermaidCaptureFailed => '図をキャプチャできませんでした';

  @override
  String get mermaidErrorEmpty => '図が空です。';

  @override
  String mermaidErrorUnknownType(String type) {
    return '認識できない図の種類: 「$type」。';
  }

  @override
  String get mermaidErrorHeaderOnly => 'この図にはヘッダーだけがあり、内容がありません。';

  @override
  String get mermaidErrorBadBody => 'ヘッダーは認識できています。その下の構文を確認してください。';

  @override
  String mermaidSupportedTypes(String list) {
    return '対応している種類: $list';
  }

  @override
  String get mermaidParseError => 'Mermaid の解析エラー';

  @override
  String imageSavedTo(String path) {
    return '$path に保存しました';
  }

  @override
  String imageSaveFailed(String message) {
    return '画像を保存できませんでした: $message';
  }

  @override
  String saveFailed(String message) {
    return 'ファイルを保存できませんでした: $message';
  }

  @override
  String fileOperationFailed(String message) {
    return 'ファイル操作に失敗しました: $message';
  }

  @override
  String get fileNameTaken => '同じ名前のファイルまたはフォルダーが既にあります';

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
  String get fileRecentFiles => '最近使用したファイル';

  @override
  String get fileNoRecentFiles => '最近使用したファイルはありません';

  @override
  String get fileExport => 'エクスポート';

  @override
  String get fileExportHtml => 'HTML';

  @override
  String get fileExportPdf => 'PDF';

  @override
  String get filePrint => '印刷';

  @override
  String get fileExportWord => 'Word (.docx)';

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
  String get noFiles => 'ファイルなし';

  @override
  String get noOpenFolder => 'フォルダを開いてファイルを参照';

  @override
  String get searchPlaceholder => 'ファイル内を検索...';

  @override
  String searchTooLarge(int count) {
    return '$count 個のファイルは大きすぎるため検索しませんでした';
  }

  @override
  String dropNotMarkdown(int count) {
    return '$count 個のファイルは開きませんでした：markdown 文書ではありません';
  }

  @override
  String get previewStartWriting => '書き始めましょう…';

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
  String get editCreateParagraph => '下に段落を作成';

  @override
  String get editDeleteParagraph => '段落を削除';

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
  String get settingsCodeFontSize => 'コードフォントサイズ';

  @override
  String get settingsEditorFontFamily => '本文フォント';

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
  String get fileMove => '移動…';

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
  String get fileOpenBehavior => 'ファイルを開くときの動作';

  @override
  String get fileOpenBehaviorNewWindow => '新しいウィンドウで開く';

  @override
  String get fileOpenBehaviorExistingWindow => '現在のウィンドウで開く';

  @override
  String get fileOpenBehaviorNotSet => '未設定';

  @override
  String get updateAvailable => '新しいバージョンがあります';

  @override
  String get updateDismiss => '閉じる';

  @override
  String get mermaidFullscreen => '全画面';

  @override
  String get mermaidSaveAs => '名前を付けて保存';

  @override
  String get mermaidCopySource => 'ソースをコピー';

  @override
  String get mermaidEditSource => 'ソースを編集';

  @override
  String get mermaidFullscreenHint => '図をダブルタップで全画面表示';

  @override
  String get mermaidSaveAsHint => '図を PNG として保存';

  @override
  String get menuParagraph => '段落';

  @override
  String get paragraphPromoteHeading => '見出しレベルを上げる';

  @override
  String get paragraphDemoteHeading => '見出しレベルを下げる';

  @override
  String get paragraphToParagraph => '段落に変換';

  @override
  String get paragraphLooseList => 'ゆるいリスト項目';

  @override
  String get close => '閉じる';

  @override
  String get mermaidViewerTitle => 'Mermaid ダイアグラムビューア';

  @override
  String get mermaidViewerHint => 'Ctrl+スクロールで拡大縮小    ドラッグで移動    Esc で閉じる';

  @override
  String get statusHighlightOff => '大きなファイルのため構文ハイライトは無効';

  @override
  String get settingsImageStorage => 'ドロップした画像の保存先';

  @override
  String get settingsImageStorageCopy => '文書のとなりにコピー';

  @override
  String get settingsImageStorageFolder => '共通のフォルダーにまとめる';

  @override
  String get settingsImageStorageLink => '元の場所を参照する';

  @override
  String get settingsImageFolder => '画像フォルダー';

  @override
  String get fileCloseTab => 'タブを閉じる';

  @override
  String get fileClearRecentFiles => '最近のファイルを消去';

  @override
  String get viewCommandPalette => 'コマンドパレット';

  @override
  String get viewReloadImages => '画像を再読み込み';

  @override
  String get formatFrontMatter => 'フロントマター';

  @override
  String get formatHtmlBlock => 'HTML ブロック';

  @override
  String get updateUpToDate => '最新バージョンです';

  @override
  String get updateCheckFailed => '更新を確認できませんでした';

  @override
  String get linkOpenFailed => 'リンクを開けませんでした';

  @override
  String get recentFileMissing => 'そのファイルは存在しません。一覧から削除しました';
}

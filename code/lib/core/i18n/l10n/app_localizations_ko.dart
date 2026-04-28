// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'MarkText Plus';

  @override
  String get menuFile => '파일';

  @override
  String get menuEdit => '편집';

  @override
  String get menuView => '보기';

  @override
  String get menuFormat => '서식';

  @override
  String get menuWindow => '창';

  @override
  String get menuHelp => '도움말';

  @override
  String get fileNew => '새 파일';

  @override
  String get fileNewWindow => '새 창';

  @override
  String get fileOpen => '파일 열기';

  @override
  String get fileOpenFolder => '폴더 열기';

  @override
  String get fileSave => '저장';

  @override
  String get fileSaveAs => '다른 이름으로 저장';

  @override
  String get fileRecentFiles => 'Recent Files';

  @override
  String get fileNoRecentFiles => 'No Recent Files';

  @override
  String get fileExport => '내보내기';

  @override
  String get fileExportHtml => 'HTML';

  @override
  String get fileExportPdf => 'PDF';

  @override
  String get fileSettings => '설정';

  @override
  String get fileQuit => '종료';

  @override
  String get editUndo => '실행 취소';

  @override
  String get editRedo => '다시 실행';

  @override
  String get editCut => '잘라내기';

  @override
  String get editCopy => '복사';

  @override
  String get editPaste => '붙여넣기';

  @override
  String get editFind => '찾기';

  @override
  String get editReplace => '바꾸기';

  @override
  String get editFindInFiles => '파일에서 찾기';

  @override
  String get viewEditMode => '편집 모드';

  @override
  String get viewSourceCode => '소스 코드';

  @override
  String get viewPreview => '미리보기';

  @override
  String get viewSplitView => '분할 보기';

  @override
  String get viewShowSidebar => '사이드바 표시';

  @override
  String get viewHideSidebar => '사이드바 숨기기';

  @override
  String get viewShowTabBar => '탭 바 표시';

  @override
  String get viewHideTabBar => '탭 바 숨기기';

  @override
  String get viewFocusMode => '집중 모드';

  @override
  String get viewTypewriterMode => '타자기 모드';

  @override
  String get viewZoomIn => '확대';

  @override
  String get viewZoomOut => '축소';

  @override
  String get viewResetZoom => '확대/축소 초기화';

  @override
  String get formatBold => '굵게';

  @override
  String get formatItalic => '기울임꼴';

  @override
  String get formatStrikethrough => '취소선';

  @override
  String formatHeading(int level) {
    return '제목 $level';
  }

  @override
  String get formatOrderedList => '순서 있는 목록';

  @override
  String get formatUnorderedList => '순서 없는 목록';

  @override
  String get formatTaskList => '작업 목록';

  @override
  String get formatCodeBlock => '코드 블록';

  @override
  String get formatQuoteBlock => '인용 블록';

  @override
  String get formatMathBlock => '수식 블록';

  @override
  String get formatTable => '표';

  @override
  String get formatLink => '링크';

  @override
  String get formatImage => '이미지';

  @override
  String get formatHorizontalRule => '수평선';

  @override
  String get windowMinimize => '최소화';

  @override
  String get windowFullScreen => '전체 화면 전환';

  @override
  String get windowAlwaysOnTop => '항상 위에';

  @override
  String get helpAbout => 'MarkText Plus 정보';

  @override
  String get helpCheckUpdates => '업데이트 확인';

  @override
  String get helpChangelog => '변경 로그';

  @override
  String get helpReportBug => '버그 신고';

  @override
  String get helpRequestFeature => '기능 요청';

  @override
  String get helpGitHub => 'GitHub 저장소';

  @override
  String get settingsGeneral => '일반';

  @override
  String get settingsEditor => '편집기';

  @override
  String get settingsMarkdown => 'Markdown';

  @override
  String get settingsTheme => '테마';

  @override
  String get settingsKeybindings => '키 바인딩';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsAutoSave => '자동 저장';

  @override
  String get settingsAutoSaveDelay => '자동 저장 지연 (ms)';

  @override
  String get settingsFontSize => '글꼴 크기';

  @override
  String get settingsLineHeight => '줄 높이';

  @override
  String get settingsTabSize => '탭 크기';

  @override
  String get settingsEnableHtml => 'HTML 활성화';

  @override
  String get settingsResetDefaults => '기본값으로 재설정';

  @override
  String statusLine(int line, int col) {
    return '$line행, $col열';
  }

  @override
  String get statusEncoding => 'UTF-8';

  @override
  String get statusMarkdown => 'Markdown';

  @override
  String get unsavedChanges => '저장되지 않은 변경 사항';

  @override
  String get unsavedChangesMessage => '닫기 전에 변경 사항을 저장하시겠습니까?';

  @override
  String get save => '저장';

  @override
  String get dontSave => '저장 안 함';

  @override
  String get cancel => '취소';

  @override
  String get ok => '확인';

  @override
  String get untitled => '제목 없음';

  @override
  String get openRecentFiles => '최근 파일 열기';

  @override
  String get noRecentFiles => '최근 파일 없음';

  @override
  String get sidebarFiles => '파일';

  @override
  String get sidebarSearch => '검색';

  @override
  String get sidebarToc => '목차';

  @override
  String get sidebarSettings => '설정';

  @override
  String get formatHeadingSubmenu => '제목';

  @override
  String get settingsBulletListMarker => '글머리 기호';

  @override
  String get settingsLightThemes => '라이트 테마';

  @override
  String get settingsDarkThemes => '다크 테마';

  @override
  String get confirmResetMessage => '모든 설정을 기본값으로 되돌리시겠습니까?';

  @override
  String get comingSoon => '곧 출시';

  @override
  String get noFiles => '파일 없음';

  @override
  String get noOpenFolder => '폴더를 열어 파일 탐색';

  @override
  String get searchPlaceholder => '파일에서 검색...';

  @override
  String get searchNoResults => '결과 없음';

  @override
  String searchResultCount(int count) {
    return '$count개 결과';
  }

  @override
  String get tocEmpty => '제목을 찾을 수 없습니다';

  @override
  String get editFindNext => '다음 찾기';

  @override
  String get editFindPrevious => '이전 찾기';

  @override
  String get editReplaceAll => '모두 바꾸기';

  @override
  String get editCaseSensitive => '대소문자 구분';

  @override
  String get editWholeWord => '단어 단위';

  @override
  String get editRegex => '정규식';

  @override
  String get editCopyAsMarkdown => 'Markdown으로 복사';

  @override
  String get editCopyAsHtml => 'HTML로 복사';

  @override
  String get editSelectAll => '모두 선택';

  @override
  String get editDuplicateLine => '줄 복제';

  @override
  String get formatUnderline => '밑줄';

  @override
  String get formatSuperscript => '위 첨자';

  @override
  String get formatSubscript => '아래 첨자';

  @override
  String get formatHighlight => '강조';

  @override
  String get formatInlineCode => '인라인 코드';

  @override
  String get formatInlineMath => '인라인 수식';

  @override
  String get formatClearFormatting => '서식 지우기';

  @override
  String get settingsCodeFontFamily => '코드 글꼴';

  @override
  String get settingsEditorMaxWidth => '편집기 최대 너비';

  @override
  String get settingsTextDirection => '텍스트 방향';

  @override
  String get keybindingsEdit => '키 바인딩 편집';

  @override
  String get keybindingsPressKeys => '키 조합을 누르세요...';

  @override
  String get keybindingsReset => '기본값으로 재설정';

  @override
  String get statusWords => '단어';

  @override
  String get statusChars => '문자';

  @override
  String get statusParagraphs => '단락';

  @override
  String get themeCadmiumLight => '카드뮴 라이트';

  @override
  String get themeOneDark => 'One Dark';

  @override
  String get themeMaterialDark => 'Material 다크';

  @override
  String get themeGraphiteLight => '그래파이트 라이트';

  @override
  String get themeUlyssesLight => 'Ulysses 라이트';

  @override
  String get themeRedGraphite => '레드 그래파이트';

  @override
  String get themeShibuya => '시부야';

  @override
  String get themePinkBlossom => '핑크 블로썸';

  @override
  String get themeSkyBlue => '스카이 블루';

  @override
  String get themeDarkGraphite => '다크 그래파이트';

  @override
  String get themeDieciOLED => 'Dieci OLED';

  @override
  String get themeNord => 'Nord';

  @override
  String get themeMidnight => '미드나잇';

  @override
  String get keybindingBold => '굵게';

  @override
  String get keybindingItalic => '기울임꼴';

  @override
  String get keybindingUnderline => '밑줄';

  @override
  String get keybindingStrikethrough => '취소선';

  @override
  String get keybindingHeading1 => '제목 1';

  @override
  String get keybindingHeading2 => '제목 2';

  @override
  String get keybindingHeading3 => '제목 3';

  @override
  String get keybindingHeading4 => '제목 4';

  @override
  String get keybindingHeading5 => '제목 5';

  @override
  String get keybindingHeading6 => '제목 6';

  @override
  String get keybindingOrderedList => '순서 있는 목록';

  @override
  String get keybindingUnorderedList => '순서 없는 목록';

  @override
  String get keybindingTaskList => '작업 목록';

  @override
  String get keybindingCodeBlock => '코드 블록';

  @override
  String get keybindingQuoteBlock => '인용 블록';

  @override
  String get keybindingTable => '표';

  @override
  String get keybindingLink => '링크';

  @override
  String get keybindingImage => '이미지';

  @override
  String get keybindingInlineCode => '인라인 코드';

  @override
  String get keybindingInlineMath => '인라인 수식';

  @override
  String get keybindingMathBlock => '수식 블록';

  @override
  String get keybindingFind => '찾기';

  @override
  String get keybindingReplace => '바꾸기';

  @override
  String get keybindingSave => '저장';

  @override
  String get keybindingOpen => '열기';

  @override
  String get keybindingUndo => '실행 취소';

  @override
  String get keybindingRedo => '다시 실행';

  @override
  String get keybindingSelectAll => '모두 선택';

  @override
  String get keybindingDuplicateLine => '줄 복제';

  @override
  String get keybindingHighlight => '강조';

  @override
  String get closeFile => '파일 닫기';

  @override
  String get copyFileName => '파일 이름 복사';

  @override
  String get copyFilePath => '파일 경로 복사';

  @override
  String get deleteFile => '파일 삭제';

  @override
  String confirmDeleteFile(String fileName) {
    return '\"$fileName\"을(를) 삭제하시겠습니까?';
  }

  @override
  String get newFolder => '새 폴더';

  @override
  String get rename => '이름 변경';

  @override
  String get delete => '삭제';

  @override
  String get confirm => '확인';

  @override
  String get fileNameHint => '파일 이름';

  @override
  String get folderNameHint => '폴더 이름';

  @override
  String get newNameHint => '새 이름';

  @override
  String get closeOtherTabs => '다른 탭 닫기';

  @override
  String get closeTabsToRight => '오른쪽 탭 닫기';

  @override
  String get closeAllTabs => '모든 탭 닫기';

  @override
  String get revealInExplorer => '파일 탐색기에서 표시';

  @override
  String get formatTextSubmenu => '텍스트';

  @override
  String get formatBlocksSubmenu => '블록';

  @override
  String get formatCodeSubmenu => '코드';

  @override
  String get formatInsertSubmenu => '삽입';

  @override
  String get fileRename => '이름 바꾸기';

  @override
  String get newTab => '새 탭';

  @override
  String get newNameHintDialog => '새 이름';

  @override
  String get commandPaletteHint => '명령어 입력...';

  @override
  String get commandPaletteNoResults => '일치하는 명령어 없음';

  @override
  String get statusLineFeed => 'LF';

  @override
  String get settingsTextDirectionLtr => '왼쪽에서 오른쪽';

  @override
  String get settingsTextDirectionRtl => '오른쪽에서 왼쪽';

  @override
  String commandFormatLabel(String action) {
    return '서식: $action';
  }

  @override
  String commandFormatDesc(String action) {
    return '$action 서식 적용';
  }

  @override
  String get commandNewFile => '새 파일';

  @override
  String get commandNewFileDesc => '새 제목 없는 파일 만들기';

  @override
  String get commandSave => '저장';

  @override
  String get commandSaveDesc => '현재 파일 저장';

  @override
  String get commandSourceMode => '소스 모드';

  @override
  String get commandSourceModeDesc => '소스 코드 편집 모드로 전환';

  @override
  String get commandPreviewMode => '미리보기 모드';

  @override
  String get commandPreviewModeDesc => '미리보기 모드로 전환';

  @override
  String get commandSplitMode => '분할 모드';

  @override
  String get commandSplitModeDesc => '분할 편집 모드로 전환';

  @override
  String get commandToggleFocusMode => '집중 모드 전환';

  @override
  String get commandToggleFocusModeDesc => '방해 없는 집중 모드 전환';

  @override
  String get commandToggleTypewriterMode => '타자기 모드 전환';

  @override
  String get commandToggleTypewriterModeDesc => '타자기 스크롤 모드 전환';

  @override
  String get commandToggleSidebar => '사이드바 전환';

  @override
  String get commandToggleSidebarDesc => '사이드바 표시/숨기기';

  @override
  String get commandToggleTabBar => '탭 바 전환';

  @override
  String get commandToggleTabBarDesc => '탭 바 표시/숨기기';

  @override
  String get welcomeNewFile => '새 파일';

  @override
  String get welcomeOpenFile => '파일 열기';

  @override
  String get welcomeDragHint => '파일을 여기에 드롭하여 열기';

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

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
  String get settingsDarkMode => '다크 모드';

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

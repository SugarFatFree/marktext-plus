import '../../core/i18n/l10n/app_localizations.dart';

/// The reader-facing name of a bindable action, in their language.
///
/// One map, because there are three places that need it: the keybinding list
/// in Settings, the command palette, and any future list of what the editor
/// can do. It used to live inside the settings screen as a private method,
/// which is why the palette wrote its own labels for the handful of commands
/// it offered — and why it offered only a handful.
String actionLabel(String action, AppLocalizations l10n) {
  return switch (action) {
  'bold' => l10n.keybindingBold,
  'italic' => l10n.keybindingItalic,
  'underline' => l10n.keybindingUnderline,
  'strikethrough' => l10n.keybindingStrikethrough,
  'heading1' => l10n.keybindingHeading1,
  'heading2' => l10n.keybindingHeading2,
  'heading3' => l10n.keybindingHeading3,
  'heading4' => l10n.keybindingHeading4,
  'heading5' => l10n.keybindingHeading5,
  'heading6' => l10n.keybindingHeading6,
  'orderedList' => l10n.keybindingOrderedList,
  'unorderedList' => l10n.keybindingUnorderedList,
  'taskList' => l10n.keybindingTaskList,
  'codeBlock' => l10n.keybindingCodeBlock,
  'quoteBlock' => l10n.keybindingQuoteBlock,
  'table' => l10n.keybindingTable,
  'link' => l10n.keybindingLink,
  'image' => l10n.keybindingImage,
  'inlineCode' => l10n.keybindingInlineCode,
  'inlineMath' => l10n.keybindingInlineMath,
  'mathBlock' => l10n.keybindingMathBlock,
  'find' => l10n.keybindingFind,
  'replace' => l10n.keybindingReplace,
  'save' => l10n.keybindingSave,
  'open' => l10n.keybindingOpen,
  'undo' => l10n.keybindingUndo,
  'redo' => l10n.keybindingRedo,
  'selectAll' => l10n.keybindingSelectAll,
  'duplicateLine' => l10n.keybindingDuplicateLine,
  'highlight' => l10n.keybindingHighlight,
  'closeTab' => l10n.fileCloseTab,
  'findNext' => l10n.editFindNext,
  'findPrevious' => l10n.editFindPrevious,
  // These two had been in the map since it gained promote and demote
  // heading, but never here, so the settings list showed their raw action
  // names next to every other row's translated one.
  'promoteHeading' => l10n.paragraphPromoteHeading,
  'demoteHeading' => l10n.paragraphDemoteHeading,
  // The twenty-four that used to be hard-coded on their menu items or had
  // no shortcut at all. They reuse the menu's own labels, so the settings
  // list names them the same way the menu does.
  'sourceMode' => l10n.viewSourceCode,
  'previewMode' => l10n.viewPreview,
  'splitMode' => l10n.viewSplitView,
  'toggleSidebar' => l10n.viewHideSidebar,
  'toggleTabBar' => l10n.viewHideTabBar,
  'commandPalette' => l10n.viewCommandPalette,
  'focusMode' => l10n.viewFocusMode,
  'typewriterMode' => l10n.viewTypewriterMode,
  'zoomIn' => l10n.viewZoomIn,
  'zoomOut' => l10n.viewZoomOut,
  'resetZoom' => l10n.viewResetZoom,
  'newWindow' => l10n.fileNewWindow,
  'settings' => l10n.fileSettings,
  'quit' => l10n.fileQuit,
  'print' => l10n.filePrint,
  'exportPdf' => l10n.fileExportPdf,
  'reloadImages' => l10n.viewReloadImages,
  'fullScreen' => l10n.windowFullScreen,
  'clearFormatting' => l10n.formatClearFormatting,
  'createParagraph' => l10n.editCreateParagraph,
  'deleteParagraph' => l10n.editDeleteParagraph,
  'toParagraph' => l10n.paragraphToParagraph,
  'looseList' => l10n.paragraphLooseList,
  'moveBlockUp' => l10n.paragraphMoveBlockUp,
  'moveBlockDown' => l10n.paragraphMoveBlockDown,
  'frontMatter' => l10n.formatFrontMatter,
  'htmlBlock' => l10n.formatHtmlBlock,
    _ => action,
  };
}

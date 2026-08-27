# Changelog

All notable changes to MarkText Plus will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.4.0] - 2026-08-28

### Added
- Sequence diagrams honour `box … end` participant groupings and `autonumber`
- Mermaid `block-beta` diagrams render: a wrapping grid of shaped blocks with arrows between them
- Mermaid C4 diagrams render (`C4Context` and its four siblings), completing every diagram type the upstream editor draws
- State diagrams read described states, choice nodes, composite states, `direction`, and the concurrency separator, instead of dropping every line that is not a transition
- A Gantt chart written without any `section` line draws instead of coming out blank, several status keywords on one task are all read, and a task named in a non-Latin script keeps a usable id
- A timeline period written with several colon-separated events draws one box each, as mermaid does
- A kanban task written with an `@{ … }` metadata block appears on the board instead of vanishing
- Email addresses are linked, both `<foo@example.com>` and bare ones in prose
- An open document reloads when the file changes on disk, as long as it has no unsaved edits
- "Save as" rebinds the tab to the file it wrote, so the title updates and the next save no longer asks again
- A failed write leaves the document marked as modified instead of claiming it was saved
- Link and image text may contain a bracketed run, as in `[see [1] here](url)`

### Fixed
- Clicking a folder-search result now scrolls to the line that matched, instead of opening the file at the top
- Disposing a source editor no longer throws, so it hands its controller registration back as it was always meant to
- A line starting with an inline HTML tag, such as `<kbd>Ctrl</kbd>`, is a paragraph again instead of a grey code box
- An HTML block ends at the first blank line, so a distant closing tag no longer swallows the headings and prose in between — and markdown inside a `<details>` renders as markdown
- An ordered list written from `3.` is numbered from three, in the preview and in all three export formats
- A fenced code block indented under a list item no longer carries that indentation into every line of the snippet

## [v1.3.0] - 2026-08-27

### Added
- Edit blocks directly in preview mode: double-tap a block to swap it for its markdown source, click away to commit, Esc to cancel
- Mermaid `classDiagram` rendering — three compartments, `<<stereotype>>` annotations, all eight relationship kinds, cardinality labels
- AST nodes carry their source line range, with `sourceOfBlock` / `replaceBlock` helpers that preserve line endings, BOM, and trailing newline
- CI workflow running analyze, test, and a Linux release build on every push and pull request
- `scripts/install-linux-desktop.sh` to register the app as the Markdown handler for a locally built binary

### Fixed
- Sequence diagram activation bars, notes and loop/alt/opt/par frames are drawn instead of being dropped
- A Sankey diagram (`sankey-beta`) renders instead of falling back to showing its source
- A kanban column written with a Chinese id no longer breaks the whole board
- The closing `##` of an ATX heading is no longer shown as part of the heading text
- The "how to open files" dialog no longer appears on launch; opening behaviour is a Settings preference, as it is upstream
- deb packages now ship a postinst that refreshes the desktop and MIME databases, without which a freshly installed app never became a registered handler
- deb and rpm packages now ship a shared-mime-info definition, without which `.md` never resolved to `text/markdown` on systems whose database lacked the glob
- `AppConstants.appVersion` was stuck at 1.2.2 while the app shipped as 1.2.3, so the update check offered users the version they already had
- Mermaid flowcharts written as `graph TD;`, a bare `graph`, or `flowchart-elk LR` rendered nothing
- The app widget test hung CI for over 20 minutes by calling `pumpAndSettle()` on a screen with an indeterminate progress indicator

### Changed
- Cleared the analyzer baseline: `withOpacity` → `withValues`, dangling library doc comments, `Matrix4.scale`, `Radio.groupValue`, `ReorderableListView.onReorder`

## [v1.2.3] - 2026-06-02

### Added
- Mermaid diagram export as PNG image (toolbar "另存为" button, 2x resolution capture via RepaintBoundary)
- Progressive rendering for large files (initial 50 nodes, recursively schedules more via postFrameCallback)
- File loading uses isolate (compute) for background reading, no longer blocks UI thread
- Loading skeleton screens during editor mode switches
- Per-mode scroll offset fields in TabInfo (foundation for future split-mode scroll sync)

### Fixed
- File-open behavior dialog repeatedly appearing (default to existingWindow when dismissed)
- Indented code blocks not rendering (regex now allows leading whitespace)
- Large files (>900 lines) freezing preview window (progressive rendering + isolate-based file read)
- Blockquote text overlapping inside multi-line quotes (removed forceStrutHeight)
- Table last column overflowing border (FlexColumnWidth in preview mode)
- Split-mode tables not horizontally scrollable (mode-aware scroll wrapper)
- Mode switching loses scroll position (IndexedStack keeps all editor states alive)
- Mode switching causing severe lag for large files (deferred build with skeleton screen)
- File loading animation appearing static (forced frame render before isolate work begins)
- Mermaid stateDiagram parallel edges overlapping each other and their labels (perpendicular line offset + label follows its line)
- Mermaid edge labels covered by nodes (draw order: edges → nodes → labels)
- Mermaid layout cramped (Dagre dynamic spacing based on max label size + parallel-edge count)

### Changed
- Mermaid edge label max wrap width tightened to 120px (better vertical layout)
- Mermaid base node spacing reduced to 60px (DagreLayout now adds dynamic extra spacing)
- Editor mode switching duration reduced to 150ms with smoother easing

## [v1.2.2] - 2026-05-22

### Added
- Sidebar directory persistence across app restarts (without auto-opening tabs)
- Sidebar opened-files list also persists (individual files appear after restart)
- Mermaid stateDiagram-v2 syntax support (with Dagre layout, stadium-shape states)
- Mermaid viewer dialog (double-click or button), zoom/pan/Esc to close, dialog sized to ~80% of screen
- Mermaid inline auto-fit (scales down when wider than container)

### Fixed
- Preview mode Ctrl+C copying entire document instead of selected text
- Markdown files with Windows line endings (\r\n) failing to parse
- Large file parsing slow due to repeated CRLF replaceAll (now uses LineSplitter)
- Mermaid diagrams clipped when wider than container
- stateDiagram-v2 layout chaos (now reuses Dagre flowchart layout)
- stateDiagram showing multiple end nodes (now unified) + long edge labels overlapping (dynamic spacing based on label length)
- First file open blocking UI thread due to synchronous readAsStringSync (now async)
- Large code blocks (>20KB) causing UI freeze during syntax highlighting (now skipped)
- UTF-8 BOM causing first-line heading to not render in preview mode
- Duplicate GlobalKey crash when opening files with certain heading structures
- Provider modification during widget build causing startup crash (moved to postFrameCallback)

## [v1.2.1] - 2026-04-30

### Added
- Auto-update check via GitHub Releases API (once per day, non-intrusive status bar indicator)
- Mermaid diagram rendering as images in PDF/Word export (using offscreen widget capture)
- Platform-native font system: Windows (Microsoft YaHei UI), macOS (San Francisco), Linux (Noto Sans)
- Multi-language font fallback chain for CJK, Korean, Japanese, Arabic, Cyrillic

### Fixed
- Preview mode font inconsistency — was using Roboto instead of system default font
- Selection highlight height variation in preview mode (StrutStyle + TextLeadingDistribution.even)
- PDF code block Chinese characters garbled (Courier font doesn't support CJK)
- PDF/Word export showing Mermaid source code instead of rendered diagrams

### Changed
- PDF export styling overhaul: GitHub-inspired typography, proper spacing, borders, alternating table rows
- Word export styling overhaul: page margins, paragraph spacing, line height, code block backgrounds
- Unified font rendering across all UI components (menus, settings, dialogs, preview, status bar)

## [v1.2.0] - 2026-04-29

### Added
- Word (.docx) export functionality with full formatting support (headings, lists, tables, inline styles)
- Automatic HTML clipboard format on Ctrl+C in preview mode for rich paste into Word/Outlook

### Fixed
- PDF export crash caused by TrueType Collection (.ttc) font parsing errors
- PDF emoji rendering - now displays emoji correctly using system emoji fonts (Segoe UI Emoji on Windows)
- Preview mode copy-paste losing line breaks when pasting into Word

### Changed
- Removed redundant "Copy as HTML" toolbar button in preview mode (now automatic on Ctrl+C)
- Optimized markdown parsing performance with AST caching - no longer re-parses on every rebuild
- Simplified PDF emoji normalization - only maps problematic variants (✅→☑, ❌→✗), lets fonts handle others
- Removed expensive font pre-validation in PDF export - now uses try-catch fallback for better startup performance

### Performance
- 3x faster preview mode rendering for large documents (AST caching eliminates redundant parsing)
- Eliminated 6+ PDF generation operations during font loading (removed testDoc.save() validation)
- HTML conversion now cached until content changes (faster Ctrl+C in preview)

## [v1.1.4] - 2026-04-28

### Fixed
- Fixed file open behavior dialog showing on every launch due to config loading race condition
- SettingsNotifier now receives pre-loaded config as initial state instead of async loading

## [v1.1.3] - 2026-04-28

### Added
- Mermaid diagram rendering in preview mode using pure Dart/Flutter (no WebView dependency)
- Copy source button on Mermaid diagram blocks
- Single-instance mode: configurable file opening behavior (new window vs existing window)
- First-launch dialog to choose file opening preference
- File opening behavior setting in Settings → General
- Table cells now render inline Markdown syntax (bold, links, code, etc.)

### Fixed
- Windows line endings (`\r\n`) causing all Markdown syntax to fail rendering
- Config directory `.marktext-plus` being created in the file's directory instead of user home
- Mermaid CDN version upgraded from v10 to v11 in HTML export

### Changed
- Config storage moved from `~/.marktext-plus/` to system application support directory
- Mermaid diagram rendering enlarged (font 16px, node spacing 80px)

## [v1.1.2] - 2026-04-17

### Added
- 3 new themes: Pink Blossom (light), Sky Blue (light), Midnight (dark)
- Preview mode link interaction: Ctrl+Click (Windows/Linux) or Cmd+Click (macOS) to open links in browser or new tab
- Theme names now fully localized in all 12 languages (simplified Chinese names for Chinese locale)

### Fixed
- Fixed preview mode text selection highlight issues with mixed CJK/Latin content, inline code, and links
- Fixed tab title font weight inconsistency (all tabs now use normal weight)

### Changed
- README theme section reorganized into light/dark two-column layout showing all 8 themes
- Link rendering in preview mode: removed default underline decoration to fix selection highlight visibility
- Table rendering in preview mode: removed horizontal scroll wrapper to fix selection continuity

## [v1.1.1] - 2026-04-16

### Fixed
- Fixed keyboard shortcuts (Ctrl+F, Ctrl+H) not working when focus is in editor TextField
- Fixed dark mode display issues — removed independent dark mode toggle, themes now auto-determine light/dark mode
- Fixed excessive UI heights for menu bar, submenu items, and tab context menu (48px → 36px)
- Fixed table overflow in preview mode — added horizontal scrolling for wide tables
- Fixed preview content width not expanding when sidebar is hidden — now uses configurable `editorMaxWidth`
- Fixed preview mode font rendering — applied Open Sans font family with 16px size and 1.6 line height
- Fixed source view selection highlight overflow at line endings — newline characters now share TextStyle with preceding text

### Changed
- Settings screen: split themes into "Light Themes" and "Dark Themes" sections with consistent font weight (w600)
- Theme names now fully internationalized in all 12 languages (e.g., "Dieci OLED" → "Dieci 纯黑" in Chinese)
- Removed `darkMode` boolean from AppConfig, replaced with automatic theme mode detection based on selected theme

## [v1.1.0] - 2026-04-16

### Added
- Token-based theme system (`AppThemeTokens`) with 14 color tokens for unified color management
- 5 new themes: Red Graphite, Shibuya, Dark Graphite, Dieci OLED, Nord
- 28 new i18n keys across all 12 languages for menus, commands, and UI labels
- Dynamic line number gutter width calculation based on digit count
- Browser-style tab bar with rounded active tabs and hover effects
- Tab context menu: close others, close to right, close all, copy name/path, reveal in explorer
- Sidebar active indicator with accent-colored left border
- File tree drag-and-drop folder support
- macOS unsigned app warning and workaround instructions in README

### Changed
- Redesigned all UI components with token-based styling (tab bar, sidebar, status bar, editor, settings)
- Status bar: replaced shadow with top border, token-based colors
- Markdown preview: max-width 720px centered layout, improved typography (17px, 1.7 line height)
- Settings screen: card-style layout with animated category navigation
- Editor syntax highlighting colors now follow theme tokens
- Replaced all hardcoded UI strings with l10n calls (command palette, settings, home screen commands)
- Tab bar height increased to 44px with improved spacing and close button hover states

### Removed
- Old theme set (Cadmium Light, One Dark, Material Dark, Graphite Light, Ulysses Light)

## [v1.0.2] - 2026-04-15

### Fixed
- Fixed StateProvider.overrideWithValue method not existing, causing build failures on Linux ARM64 and macOS
- Fixed Windows file association — .md files now appear in "Open with" context menu
- Fixed startup file handling — files selected via "Open with" now load correctly instead of showing blank window
- Fixed CI/CD ARM64 Linux builds by using manual Flutter installation
- Fixed CI/CD macOS builds by removing unsupported x64 architecture
- Fixed GITHUB_PATH environment variable not taking effect in same workflow step

### Added
- Windows Registry entries for .md, .markdown, and .txt file associations via Inno Setup
- Command-line argument parsing for startup files
- Startup file processing on app launch

## [v1.0.1] - 2026-04-14

### Added
- Initial release with cross-platform CI/CD workflow
- GitHub Actions workflow for Windows, macOS, and Linux builds
- Multi-architecture support (x64, ARM64)
- DEB and RPM package generation for Linux
- Inno Setup installer for Windows
- DMG packaging for macOS

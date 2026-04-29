# Changelog

All notable changes to MarkText Plus will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

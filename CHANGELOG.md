# Changelog

All notable changes to MarkText Plus will be documented in this file.

## [v1.0.1] - 2026-04-15

### Features

- Custom Markdown editor with syntax highlighting (headings, bold, code, links, strikethrough, italic)
- Three edit modes: Source, Preview, Split (draggable divider with 300ms debounce sync)
- Markdown renderer with full AST-based widget tree (headings, paragraphs, code blocks, tables, math blocks, blockquotes, lists, task lists, images, horizontal rules, front matter, footnotes, HTML blocks)
- Mermaid diagram rendering support (flowchart, sequence, gantt, class, state, ER, journey, gitgraph, pie, mindmap)
- Sidebar with file tree, full-text search, and table of contents panel
- Multi-tab editing with drag-to-reorder and modified indicator
- Command palette (Ctrl+P) with format, file, and view commands
- Find & Replace bar with regex and case-sensitive options
- Keyboard shortcuts for all format actions (bold, italic, headings, lists, code, etc.)
- Export to HTML and PDF
- Drag-and-drop file opening (markdown files) and image insertion
- Clipboard image paste support (auto-save to project directory)
- Auto-bracket pairing for `()`, `[]`, `{}`, `""`, `''`, `` ` ` ``, `**`, `~~`
- 12 language localizations (English, Chinese, Japanese, Korean, German, French, Italian, Russian, Spanish, Portuguese, Arabic, Brazilian Portuguese)
- RTL support for Arabic
- 5 built-in themes: Cadmium Light, One Dark, Material Dark, Graphite Light, Ulysses Light
- Dark mode toggle
- Focus mode and Typewriter mode
- Configurable font size, line height, tab size, code font family, editor max width, text direction
- Auto-save with configurable delay
- Recent files list
- Customizable keybindings with persistent JSON storage
- File tree context menu (new file, new folder, rename, delete)
- Status bar with cursor position, encoding, file type, line ending, word/character/paragraph count

### Bug Fixes

- BUG-001: Fixed missing system window title bar on Windows caused by `window_manager` intercepting `WM_NCCALCSIZE` — removed `window_manager` entirely
- BUG-002: Fixed theme switching not taking effect when dark mode is enabled — auto-disable dark mode on theme change
- BUG-003: Fixed scroll jank and line numbers disappearing past 100 lines — added `itemExtent` and dynamic gutter width
- BUG-004: Fixed missing keyboard shortcuts in Format and View menus
- BUG-005: Fixed theme transition animation frame drops — disabled `themeAnimationDuration`
- BUG-006: Fixed line number gutter bounce on large scrolls — clamped scroll offset with `ClampingScrollPhysics`
- BUG-007: Fixed markdown link syntax disappearing in source view — show full `[text](url)` with syntax highlighting
- BUG-008: Fixed links not clickable in preview — added tap handler with local `.md` file support

### UI Improvements

- Material 3 enabled across all themes
- Menu bar left-aligned with subtle shadow
- Sidebar icon buttons with hover animation (150ms)
- Sidebar content area with fade transition (200ms)
- Tab bar with hover effects and animated close button
- Status bar with vertical dividers and top shadow
- Sidebar show/hide with slide animation (200ms)
- Tab bar show/hide with animated size transition

# Changelog

All notable changes to MarkText Plus will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - v1.5.0

### Added

### Fixed

## [v1.4.0] - 2026-08-28

### Added
- Sequence diagrams honour `box … end` participant groupings and `autonumber`
- Mermaid `block-beta` diagrams render: a wrapping grid of shaped blocks with arrows between them
- Mermaid C4 diagrams render (`C4Context` and its four siblings), completing every diagram type the upstream editor draws
- State diagrams read described states, choice nodes, composite states, `direction`, and the concurrency separator, instead of dropping every line that is not a transition
- A Gantt chart written without any `section` line draws instead of coming out blank, several status keywords on one task are all read, and a task named in a non-Latin script keeps a usable id
- A timeline period written with several colon-separated events draws one box each, as mermaid does
- A kanban task written with an `@{ … }` metadata block appears on the board instead of vanishing
- Searching the preview for a repeating pattern no longer draws more characters than the document holds, and the preview and the find bar agree on the match count
- The word count keeps an apostrophe or a hyphen inside the word, so `don't` and `well-known` count as one each
- A file that is not UTF-8 opens instead of the tab vanishing, and its encoding — including a UTF-8 byte order mark — is written back on save
- The status bar shows the file's actual encoding, where it used to print the word "UTF-8" whatever the file was
- Clicking the line ending in the status bar switches the document between LF and CRLF
- A list written with blank lines between its items is drawn and exported with the spacing that asks for
- A numbered list followed by a bulleted one is two lists again, so the bullets no longer export inside an `<ol>` and render as numbers
- The "enable HTML" setting does something: inline tags such as `<kbd>`, `<u>` and `<br>` are rendered, in the preview and in every export
- Blockquote lines and single-line HTML comments are coloured in the source editor, using the theme colours that were already defined for them
- Twelve strings that ten of the twelve languages were missing — the file-opening preference among them — are translated instead of falling back to English
- The Save As and Export file dialogs are titled in the app's language
- Email addresses are linked, both `<foo@example.com>` and bare ones in prose
- An open document reloads when the file changes on disk, as long as it has no unsaved edits
- "Save as" rebinds the tab to the file it wrote, so the title updates and the next save no longer asks again
- A failed write leaves the document marked as modified instead of claiming it was saved
- Link and image text may contain a bracketed run, as in `[see [1] here](url)`
- Front matter written as TOML (`+++`) or JSON (`;;;`, `{ … }`) is recognised, not just YAML — a Hugo file no longer shows its metadata as a paragraph of plus signs
- A mermaid timeline groups its periods under `section` bands, drawn above the period titles and coloured per band
- A diagram can be edited from the preview: its toolbar has an "Edit Source" button, since its own double tap opens fullscreen
- The editor's body font can be chosen in Settings; the setting was read all along but had no row of its own
- Paragraph ▸ Loose List Item spaces a list's items apart, or runs them together again — the last entry the upstream paragraph menu had and this one did not
- Edit ▸ Create Paragraph Below and Delete Paragraph, anchored on the outermost block as upstream anchors them
- File ▸ Print, on Ctrl+P, opening the system print dialog with the document laid out by the same code the PDF export uses; the palette moves to Ctrl+Shift+P, which is where upstream and VS Code both put it
- A list item can carry blocks of its own — a code fence beneath a numbered step, a second paragraph, a quote, a table — instead of the list breaking in three around them and the fence landing at the document's left margin
- Pressing Enter in a list carries the list on: the same bullet, the next number, the indentation and spacing that were written, and an unticked box for a task. An item with nothing in it ends the list instead
- The size code is drawn at can be set, independently of the body text; raising the reading size used to enlarge the prose and leave code at a fixed 14
- Edit ▸ Find in Files, which searches every file in the open folder. The search itself was there all along, reachable only by finding the magnifying glass in the sidebar, and the label was already translated into all twelve languages
- A mermaid diagram can be titled with `---\ntitle: …\n---`, which is how mermaid documents it for every type and the only way a flowchart can be titled at all
- A fenced code block is drawn with a gutter of line numbers, as upstream draws one, and can be turned off in Settings. A line that wraps keeps its number level with it, and when the block scrolls sideways the numbers stay put
- A document written in GBK — which is what Chinese notes were written in before UTF-8 — opens as what it says instead of as two wrong characters for every real one, and is written back in the encoding it came in
- The encoding in the status bar can be clicked to read the file again as something else. Detection is a guess, and until now a document that opened as mojibake was a dead end

### Fixed
- Clicking a folder-search result now scrolls to the line that matched, instead of opening the file at the top
- Disposing a source editor no longer throws, so it hands its controller registration back as it was always meant to
- A line starting with an inline HTML tag, such as `<kbd>Ctrl</kbd>`, is a paragraph again instead of a grey code box
- An HTML block ends at the first blank line, so a distant closing tag no longer swallows the headings and prose in between — and markdown inside a `<details>` renders as markdown
- An ordered list written from `3.` is numbered from three, in the preview and in all three export formats
- A fenced code block indented under a list item no longer carries that indentation into every line of the snippet
- A footnote definition whose text has no spaces — `[^1]: 中文脚注`, `[^1]: https://…` — is no longer swallowed by the link-definition rule and dropped from the document
- A document that opens with a thematic break is no longer read as front matter reaching to the next `---`, which hid everything in between
- A kanban board indented with four spaces or with tabs draws instead of failing to render at all
- A pie chart written `pie title …`, the spelling mermaid's own documentation uses, keeps its title
- A timeline `section` line is no longer drawn as text inside whichever event came before it
- A Gantt task written `until <id>` gets a real length instead of a zero-width bar, and `after a1 a2` resolves against both tasks rather than neither
- A settings write that cannot reach the disk no longer surfaces as an unhandled error far from anything the user did
- A link in the preview that cannot be opened — a typo'd address, no handler registered for the scheme — says so instead of failing silently
- Markdown inside a fenced code block is no longer coloured as markdown in the source editor: `**bold**`, `[a](b)`, `# comment` and `> arrow` in a snippet stay code
- A very long single line — minified JSON, a CSV row, a pasted block — no longer freezes the source editor for tens of seconds; the worst case measured went from 45 seconds to 10 milliseconds
- The same kind of line no longer freezes the preview either: parsing 60,000 unmatched brackets went from 51 seconds to 55 milliseconds
- A long line inside a `pie` or `erDiagram` block no longer freezes the preview for fourteen and twenty-seven seconds respectively
- A whole-word search over a large document is twenty times faster
- Moving the caret no longer rebuilds the whole preview: in split view every arrow key used to rebuild every block that had been rendered
- Typing no longer rebuilds the whole file tree in the sidebar
- Dismissing the update badge remembers the version, instead of showing it again on the next launch
- Renaming or deleting a file from the sidebar takes its open tab with it — renaming used to leave the tab on the old path, where the next save wrote the old file back out; a folder does it to every file beneath it
- Saving a new document from the close prompt names the tab after the file it wrote and adds it to the recent files, as Save As from the menu already did
- Closing a file from the sidebar asks about unsaved work, as closing its tab already did — the cross on the row, the context menu, closing a file or a whole folder all used to discard it silently
- Save from the command palette offers Save As for a document that has no file yet, instead of doing nothing; New File from the palette names the tab in the app's language
- Quitting from the File menu asks about unsaved work and records the window's geometry, as closing from the title bar already did; it used to end the process outright
- Closing the window no longer leaves the process lingering: the directory watches are stopped before it goes
- Replace-all with a regular expression writes only the matches it counted and highlighted; a pattern that can match nothing — `x*`, `.*` — used to rewrite the document at every position
- Opening a document no longer starts an isolate to read it unless it is over half a megabyte; the first one in a process has to load the app snapshot, and that was happening while the user waited for their file
- The buttons on a diagram's toolbar answer immediately, where each used to sit dead for a third of a second
- A change another program makes just after the app saves — a formatter running on save, say — is picked up instead of silently dropped and then overwritten
- Typing in a large document is faster than before: a keystroke in a 1.4 MiB file costs 45 ms where it used to cost 57
- Launching is roughly ten times quicker on Windows: creating the engine's view took two to four seconds and now takes a third of one. The cost was Impeller, the renderer that became the Windows default after this program's last release; shipped builds ask for the other one. Everything the program does itself has always added up to about 150 ms
- `<br/>` inside a mermaid label is a line break rather than five characters on screen — in every diagram type, not only the flowchart — and `&amp;` and its siblings are decoded. An edge label written in quotes loses them, as a node label already did
- A mermaid state diagram's start and end are told apart: mermaid draws the end ringed, and both were drawn as the same plain circle
- The two spellings of a nested quote, `>> inner` and `> > inner`, are the same quote inside a quote. One nested and the other sat beside its parent
- A table's column alignment survives being exported: `:--`, `:-:` and `--:` were honoured on screen and dropped by HTML, PDF and Word alike. Word also gets real table cells, so `**bold**` in a cell is bold rather than asterisks
- An exported nested list nests the way HTML requires — the sub-list inside the item it hangs off, rather than beside it. Browsers forgive the old shape; validators, pandoc and anything pasted into Word do not
- The code font is used wherever code is drawn: inline `code`, front matter and html blocks kept the platform's generic face while fenced blocks changed, so one setting produced two fonts on one screen
- A task list's checkbox ticks the line it belongs to. Counting one line per item put it on a continuation line, on the blank line of a loose list, or inside a block carried by the step — where it silently did nothing
- Closing the find bar no longer throws, and the highlight it draws in the preview is cleared as it was meant to be
- The settings page keeps what is being typed into it: its text fields were rebuilt on every rebuild, so flipping any switch discarded whatever had not yet been submitted
- The window can be made narrow without the settings page, the menu bar or the status bar spilling over their right edge. There is no minimum window size, and the striping started at about a thousand pixels
- Renaming a file onto a name already in use no longer destroys the file that had it, and asking for a new file under a name already in use no longer empties it. Both wrote over what was there without a prompt, an undo, or anything on screen to say it had happened
- The sidebar's outline scrolls to the heading it names. It and the preview disagreed about which lines are headings — a `# comment` inside front matter was listed although nothing is drawn for it, and an underlined heading was drawn although nothing was listed — so from the first disagreement on, every entry went to the wrong place
- A diagram written under a numbered step is exported with its picture, and a formula written there is exported as a formula rather than as the dollar signs it was written with. A local picture written there is carried into the file too, instead of being left as a path that breaks anywhere else
- Clicking a recent file that has been moved or deleted says so and takes it off the list, instead of doing nothing at all
- Export and Print are greyed out with no document open, where they used to be offered and then do nothing
- A task list is written with the bullet chosen in Settings, as an ordinary list already was; choosing `*` gave one list written with stars and the next with dashes
- Print answers to Ctrl+P. The palette went on taking that key from a shortcut written into the window itself, so Print had none — and rebinding any of the view shortcuts left the old key working there too
- Closing several tabs at once lets go of what they were holding. Closing one dropped its undo history and cancelled its pending auto-save; closing the others, those to the right, or all of them did neither, and their histories stayed for the rest of the session

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

# MarkText Plus - Development Guide

## Project Overview

A lightweight, cross-platform Markdown editor built with Flutter, reimagined from [MarkText](https://github.com/marktext/marktext).

- **Version**: V1.1.3
- **License**: MIT
- **Platforms**: Windows, macOS, Linux

## Project Structure

```
marktext-plus/
├── code/                      # Flutter application source
│   ├── lib/
│   │   ├── main.dart          # Entry point (window_manager init)
│   │   ├── app.dart           # MaterialApp with theme/locale/i18n binding
│   │   ├── core/
│   │   │   ├── constants.dart
│   │   │   ├── config/        # AppConfig model + ConfigService (JSON persistence)
│   │   │   ├── theme/         # AppTheme with 5 built-in themes
│   │   │   └── i18n/l10n/     # Generated localization code (12 languages)
│   │   ├── models/            # TabInfo, FileNode
│   │   ├── services/          # MarkdownParser, FileService
│   │   ├── providers/         # Riverpod: settings, tab, editor, file, locale
│   │   ├── ui/
│   │   │   ├── editor/        # SourceEditor, MarkdownRenderer, SplitEditor, SyntaxHighlighter
│   │   │   ├── screens/       # HomeScreen, SettingsScreen
│   │   │   └── widgets/       # AppMenuBar, SideBar, EditorTabBar, StatusBar
│   │   └── utils/             # PlatformUtils, FileUtils
│   ├── test/                  # Unit and widget tests
│   └── l10n.yaml              # Localization config
├── docs/
│   ├── vX.Y.Z/                # Version docs (bugfix.md for bugs, PRD_需求文档.md for features)
│   └── i18n/                  # README translations (11 languages)
└── .claude/
    └── CLAUDE.md              # Project instructions
```

## Build & Test Commands

All commands should be run from `code/` directory:

```bash
# Get dependencies
flutter pub get

# Run analysis (must pass with 0 issues)
flutter analyze

# Run all tests
flutter test

# Run specific test file
flutter test test/services/markdown_parser_test.dart

# Build release
flutter build linux    # or windows / macos

# Generate localization files (after modifying .arb files)
flutter gen-l10n
```

## Architecture

Four-layer architecture with Riverpod state management:

- **UI Layer** (`lib/ui/`): Flutter widgets, screens
- **State Layer** (`lib/providers/`): Riverpod StateNotifier providers
- **Service Layer** (`lib/services/`): Markdown parser, file I/O
- **Platform Layer**: Flutter platform channels, window_manager

## Key Design Decisions

- **Custom Markdown Editor**: Self-built parser and renderer (no third-party editor libs)
- **Riverpod**: StateNotifier pattern for all state management
- **JSON Config**: Direct file read/write via ConfigService (no shared_preferences/hive)
- **i18n**: flutter_localizations + intl + .arb files, 12 languages, RTL support for Arabic
- **Three Edit Modes**: Source (TextField + line numbers + syntax highlight), Preview (AST -> Widget tree), Split (draggable divider + 300ms debounce sync)

## Conventions

- All communication in Chinese (中文)
- Code comments and identifiers in English
- ARB key naming: camelCase with section prefix (e.g., `settingsGeneral`, `menuFile`, `editUndo`)
- Provider naming: `xxxProvider` for StateNotifierProvider
- File organization: one widget per file, group by feature not layer
- Tests alongside source in `test/` mirroring `lib/` structure

## Version Documentation

Each version maintains its own directory under `docs/vX.Y.Z/`:

- `bugfix.md` — Bug fixes (summary table + detailed records per bug: 现象、根因、修复方案、涉及文件)
- `PRD_需求文档.md` — New features and requirements

[简体中文](docs/i18n/README_zh-CN.md) | [日本語](docs/i18n/README_ja-JP.md) | [한국어](docs/i18n/README_ko-KR.md) | [Deutsch](docs/i18n/README_de-DE.md) | [Français](docs/i18n/README_fr-FR.md) | [Italiano](docs/i18n/README_it-IT.md) | [Русский](docs/i18n/README_ru-RU.md) | [Español](docs/i18n/README_es-ES.md) | [Português](docs/i18n/README_pt-PT.md) | [العربية](docs/i18n/README_ar-SA.md) | [Português (Brasil)](docs/i18n/README_pt-BR.md)

# MarkText Plus

A lightweight, cross-platform Markdown editor built with Flutter, reimagined from the original [MarkText](https://github.com/marktext/marktext).

## Features

- **Multi-language Support**: 12 languages including English, Chinese, Japanese, Korean, German, French, Italian, Russian, Spanish, Portuguese, Arabic, and Brazilian Portuguese
- **Lightweight & Fast**: Self-built Markdown parser and renderer for optimal performance
- **Persistent Configuration**: JSON-based settings storage with automatic save
- **Dual-pane Editing**: Source code, preview, and split-view modes
- **Cross-platform**: Runs on Windows, macOS, and Linux
- **Modern UI**: Clean interface with 5 built-in themes
- **Syntax Highlighting**: Real-time Markdown syntax highlighting in source mode

## Installation

### Prerequisites

- Flutter 3.x or higher
- Dart 3.x or higher

### Build from Source

```bash
git clone https://github.com/yourusername/marktext-plus.git
cd marktext-plus/code
flutter pub get
flutter run
```

### Release Builds

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

## Development

### Project Structure

```
code/
├── lib/
│   ├── main.dart              # Application entry point
│   ├── app.dart               # MaterialApp configuration
│   ├── core/                  # Core configuration and themes
│   ├── models/                # Data models
│   ├── services/              # Business logic services
│   ├── providers/             # Riverpod state management
│   └── ui/                    # UI components
└── test/                      # Unit and widget tests
```

### Architecture

Four-layer architecture:
- **UI Layer**: Flutter widgets and screens
- **State Layer**: Riverpod providers for state management
- **Service Layer**: Business logic and data processing
- **Platform Layer**: File I/O and system integration

### Running Tests

```bash
flutter test
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](code/LICENSE) file for details.

Based on [MarkText](https://github.com/marktext/marktext) by Luo Ran and contributors.

## Acknowledgments

- Original MarkText project and its contributors
- Flutter and Dart teams
- All open source libraries used in this project

[简体中文](docs/i18n/README_zh-CN.md) | [日本語](docs/i18n/README_ja-JP.md) | [한국어](docs/i18n/README_ko-KR.md) | [Deutsch](docs/i18n/README_de-DE.md) | [Français](docs/i18n/README_fr-FR.md) | [Italiano](docs/i18n/README_it-IT.md) | [Русский](docs/i18n/README_ru-RU.md) | [Español](docs/i18n/README_es-ES.md) | [Português](docs/i18n/README_pt-PT.md) | [العربية](docs/i18n/README_ar-SA.md) | [Português (Brasil)](docs/i18n/README_pt-BR.md)

# MarkText Plus

> A lightweight, cross-platform Markdown editor built with Flutter

[![Release](https://img.shields.io/github/v/release/yourusername/marktext-plus)](https://github.com/yourusername/marktext-plus/releases)
[![License](https://img.shields.io/github/license/yourusername/marktext-plus)](LICENSE)

A modern Markdown editor reimagined from the original [MarkText](https://github.com/marktext/marktext), built with Flutter for true cross-platform support.

## Screenshots

![MarkText Plus Themes](docs/v1.1.1/picture/theme/红石墨.png)

## ✨ Features

- **🌍 Multi-language Support**: 12 languages including English, Chinese, Japanese, Korean, German, French, Italian, Russian, Spanish, Portuguese, Arabic, and Brazilian Portuguese
- **🎨 Beautiful Themes**: 5 built-in themes
  - Light: Red Graphite, Shibuya
  - Dark: Dark Graphite, Dieci OLED, Nord
- **⚡ Lightweight & Fast**: Self-built Markdown parser and renderer for optimal performance
- **💾 Persistent Configuration**: JSON-based settings storage with automatic save
- **📝 Three Edit Modes**: 
  - Source Code Mode: Syntax highlighting with line numbers
  - Preview Mode: Real-time rendered Markdown
  - Split View Mode: Side-by-side editing and preview
- **🖥️ Cross-platform**: Runs on Windows, macOS, and Linux
- **🔍 Find & Replace**: Full-featured search with regex support
- **📂 File Management**: Sidebar with file tree navigation
- **⌨️ Keyboard Shortcuts**: Comprehensive keyboard shortcuts for efficient editing

### 🎨 Themes

<table>
  <tr>
    <th>Light Themes</th>
    <th>Dark Themes</th>
  </tr>
  <tr>
    <td><img src="docs/v1.1.1/picture/theme/红石墨.png" alt="Red Graphite" width="400"/></td>
    <td><img src="docs/v1.1.1/picture/theme/深色石墨.png" alt="Dark Graphite" width="400"/></td>
  </tr>
  <tr>
    <td><img src="docs/v1.1.1/picture/theme/涩谷.png" alt="Shibuya" width="400"/></td>
    <td><img src="docs/v1.1.1/picture/theme/纯黑.png" alt="Dieci OLED" width="400"/></td>
  </tr>
  <tr>
    <td></td>
    <td><img src="docs/v1.1.1/picture/theme/极光.png" alt="Nord" width="400"/></td>
  </tr>
</table>

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

### Note for macOS Users

> **Warning**
> macOS releases will show an "Apple couldn't verify MarkText Plus is free of malware..." warning due to a lack of notarization.
>
> After dragging MarkText Plus into the "Applications" folder, please run:
>
> ```bash
> xattr -cr /Applications/MarkText\ Plus.app
> sudo codesign --force --deep --sign - /Applications/MarkText\ Plus.app
> ```

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

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Based on [MarkText](https://github.com/marktext/marktext) by Luo Ran and contributors.

## Acknowledgments

- Original MarkText project and its contributors
- Flutter and Dart teams
- All open source libraries used in this project

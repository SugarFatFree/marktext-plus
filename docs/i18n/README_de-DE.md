[English](../../README.md) | [简体中文](README_zh-CN.md) | [日本語](README_ja-JP.md) | [한국어](README_ko-KR.md) | [Français](README_fr-FR.md) | [Italiano](README_it-IT.md) | [Русский](README_ru-RU.md) | [Español](README_es-ES.md) | [Português](README_pt-PT.md) | [العربية](README_ar-SA.md) | [Português (Brasil)](README_pt-BR.md)

# MarkText Plus

Ein leichtgewichtiger, plattformuebergreifender Markdown-Editor, erstellt mit Flutter, neu gestaltet nach dem Original [MarkText](https://github.com/marktext/marktext).

## Funktionen

- **Mehrsprachige Unterstuetzung**: 12 Sprachen einschliesslich Englisch, Chinesisch, Japanisch, Koreanisch, Deutsch, Franzoesisch, Italienisch, Russisch, Spanisch, Portugiesisch, Arabisch und Brasilianisches Portugiesisch
- **Leichtgewichtig und schnell**: Eigener Markdown-Parser und Renderer fuer optimale Leistung
- **Persistente Konfiguration**: JSON-basierte Einstellungsspeicherung mit automatischem Speichern
- **Dual-Panel-Bearbeitung**: Quellcode-, Vorschau- und geteilte Ansichtsmodi
- **Plattformuebergreifend**: Laeuft auf Windows, macOS und Linux
- **Moderne Benutzeroberflaeche**: Sauberes Interface mit 5 integrierten Themes
- **Syntaxhervorhebung**: Echtzeit-Markdown-Syntaxhervorhebung im Quellmodus

## Installation

### Voraussetzungen

- Flutter 3.x oder hoeher
- Dart 3.x oder hoeher

### Aus Quellcode erstellen

```bash
git clone https://github.com/yourusername/marktext-plus.git
cd marktext-plus/code
flutter pub get
flutter run
```

### Release-Builds

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

## Entwicklung

### Projektstruktur

```
code/
├── lib/
│   ├── main.dart              # Anwendungseinstiegspunkt
│   ├── app.dart               # MaterialApp-Konfiguration
│   ├── core/                  # Kernkonfiguration und Themes
│   ├── models/                # Datenmodelle
│   ├── services/              # Geschäftslogik-Dienste
│   ├── providers/             # Riverpod-Zustandsverwaltung
│   └── ui/                    # UI-Komponenten
└── test/                      # Unit- und Widget-Tests
```

### Architektur

Vierschichtige Architektur:
- **UI-Schicht**: Flutter-Widgets und Bildschirme
- **Zustandsschicht**: Riverpod-Provider für Zustandsverwaltung
- **Dienst-Schicht**: Geschäftslogik und Datenverarbeitung
- **Plattform-Schicht**: Datei-I/O und Systemintegration

### Tests ausführen

```bash
flutter test
```

## Beitragen

Beitraege sind willkommen! Bitte reichen Sie gerne einen Pull Request ein.

## Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert - siehe die [LICENSE](../../LICENSE) Datei fuer Details.

Basierend auf [MarkText](https://github.com/marktext/marktext) von Luo Ran und Mitwirkenden.

## Danksagungen

- Das originale MarkText-Projekt und seine Mitwirkenden
- Flutter- und Dart-Teams
- Alle in diesem Projekt verwendeten Open-Source-Bibliotheken

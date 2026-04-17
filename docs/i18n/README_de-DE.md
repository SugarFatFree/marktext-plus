<div align="center">

# MarkText Plus

**Ein leichtgewichtiger, plattformübergreifender Markdown-Editor, neu gedacht aus dem ursprünglichen [MarkText](https://github.com/marktext/marktext) und mit Flutter umgesetzt.**

[English](../../README.md) | [简体中文](README_zh-CN.md) | [日本語](README_ja-JP.md) | [한국어](README_ko-KR.md) | [Français](README_fr-FR.md) | [Italiano](README_it-IT.md) | [Русский](README_ru-RU.md) | [Español](README_es-ES.md) | [Português](README_pt-PT.md) | [العربية](README_ar-SA.md) | [Português (Brasil)](README_pt-BR.md)

![MarkText Plus](../../docs/v1.1.2/picture/theme/red-graphite.png)

</div>

---

## 💡 Was ist MarkText Plus?

MarkText Plus ist ein **moderner Markdown-Editor**, neu interpretiert auf Basis des ursprünglichen [MarkText](https://github.com/marktext/marktext) und mit Flutter für echte Plattformunabhängigkeit neu aufgebaut. Er beseitigt typische Schwächen klassischer Markdown-Editoren.

- ❌ Schwergewichtig und langsamer Start → ✅ **Blitzschnell** mit eigenem Parser
- ❌ Wenige Theme-Optionen → ✅ **8 schöne Themes** (hell & dunkel)
- ❌ Schwaches plattformübergreifendes Erlebnis → ✅ **Native Performance** auf Windows, macOS und Linux
- ❌ Komplizierte Einrichtung → ✅ **In 3 Befehlen startklar**

## 🚀 Schnellstart

In weniger als 30 Sekunden startklar.

```bash
git clone https://github.com/yourusername/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

Das ist alles. Der Editor startet mit einem Beispieldokument und ist sofort einsatzbereit.

## ✨ Funktionen

| Feature | Description |
|---------|-------------|
| **📝 Drei Bearbeitungsmodi** | Quellcode mit Syntaxhervorhebung, Live-Vorschau und geteilte Ansicht |
| **🎨 8 schöne Themes** | Red Graphite, Shibuya, Pink Blossom, Sky Blue, Dark Graphite, Dieci OLED, Nord, Midnight |
| **🌍 12 Sprachen** | Englisch, Chinesisch, Japanisch, Koreanisch, Deutsch, Französisch, Italienisch, Russisch, Spanisch, Portugiesisch, Arabisch und Brasilianisches Portugiesisch |
| **⚡ Sehr schnell** | Eigener Markdown-Parser und Renderer ohne schwere Abhängigkeiten |
| **🔍 Suchen & Ersetzen** | Vollständige Suche mit Regex-Unterstützung |
| **📂 Dateibaum** | Seitenleisten-Navigation mit Drag-and-Drop für Ordner |
| **⌨️ Anpassbare Tastenkürzel** | Tastaturbelegungen vollständig konfigurierbar |
| **💾 Automatisches Speichern** | JSON-basierte persistente Konfiguration, damit keine Arbeit verloren geht |

## 🎨 Themes

<table>
  <tr>
    <th align="center">Light Themes</th>
    <th align="center">Dark Themes</th>
  </tr>
  <tr>
    <td align="center"><b>Red Graphite</b><br/><img src="../../docs/v1.1.2/picture/theme/red-graphite.png" alt="Red Graphite" width="400"/></td>
    <td align="center"><b>Dark Graphite</b><br/><img src="../../docs/v1.1.2/picture/theme/dark-graphite.png" alt="Dark Graphite" width="400"/></td>
  </tr>
  <tr>
    <td align="center"><b>Shibuya</b><br/><img src="../../docs/v1.1.2/picture/theme/shibuya.png" alt="Shibuya" width="400"/></td>
    <td align="center"><b>Dieci OLED</b><br/><img src="../../docs/v1.1.2/picture/theme/dieci-oled.png" alt="Dieci OLED" width="400"/></td>
  </tr>
  <tr>
    <td align="center"><b>Pink Blossom</b><br/><img src="../../docs/v1.1.2/picture/theme/pink-blossom.png" alt="Pink Blossom" width="400"/></td>
    <td align="center"><b>Nord</b><br/><img src="../../docs/v1.1.2/picture/theme/nord.png" alt="Nord" width="400"/></td>
  </tr>
  <tr>
    <td align="center"><b>Sky Blue</b><br/><img src="../../docs/v1.1.2/picture/theme/sky-blue.png" alt="Sky Blue" width="400"/></td>
    <td align="center"><b>Midnight</b><br/><img src="../../docs/v1.1.2/picture/theme/midnight.png" alt="Midnight" width="400"/></td>
  </tr>
</table>

## 📦 Installation

### Vorgefertigte Builds herunterladen

Laden Sie die neueste Version für Ihre Plattform von [Releases](https://github.com/yourusername/marktext-plus/releases) herunter.

| Platform | Architecture | Format |
|----------|-------------|--------|
| Windows | x64 | `.exe` installer |
| macOS | ARM64 | `.dmg` |
| Linux | x64 / ARM64 | `.deb` / `.rpm` |

### Aus dem Quellcode bauen

> **Voraussetzungen**: Flutter 3.x+, Dart 3.x+

```bash
git clone https://github.com/yourusername/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

<details>
<summary><b>Release-Build-Befehle</b></summary>

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```
</details>

<details>
<summary><b>macOS: Warnung für unsignierte Apps umgehen</b></summary>

> macOS kann die Warnung "Apple konnte nicht überprüfen, dass MarkText Plus frei von Schadsoftware ist..." anzeigen. Nach dem Verschieben in den Ordner "Programme" führen Sie bitte Folgendes aus.
>
> ```bash
> xattr -cr /Applications/MarkText\ Plus.app
> sudo codesign --force --deep --sign - /Applications/MarkText\ Plus.app
> ```
</details>

## 🏗️ Architektur

```
code/lib/
├── main.dart           # Anwendungseinstiegspunkt
├── app.dart            # MaterialApp mit Theme-, Locale- und i18n-Bindung
├── core/               # Theme-Tokens, Konfiguration, i18n (12 Sprachen)
├── models/             # TabInfo, FileNode
├── services/           # Markdown-Parser, Datei-I/O, Tastenkürzel
├── providers/          # Riverpod-Zustandsverwaltung
└── ui/
    ├── editor/         # Quelleditor, Vorschau-Renderer, geteilte Ansicht
    ├── screens/        # Startseite, Einstellungen
    └── widgets/        # Menüleiste, Seitenleiste, Tab-Leiste, Statusleiste
```

Vier-Schichten-Architektur: **UI** → **Zustand** (Riverpod) → **Service** → **Plattform**

### Tests ausführen

```bash
cd code && flutter test
```

## 🤝 Mitwirken

Beiträge sind willkommen. Reichen Sie gerne einen Pull Request ein.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 Lizenz

MIT-Lizenz - Details finden Sie in [LICENSE](../../LICENSE).

Basiert auf [MarkText](https://github.com/marktext/marktext) von Luo Ran und Mitwirkenden.

## 🙏 Danksagung

- [MarkText](https://github.com/marktext/marktext) — das Originalprojekt, das diesen Editor inspiriert hat
- [Flutter](https://flutter.dev) — das plattformübergreifende Framework
- Alle in diesem Projekt verwendeten Open-Source-Bibliotheken

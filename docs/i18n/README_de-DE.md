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
git clone https://github.com/marktext-plus/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

Das ist alles. Der Editor startet mit einem Beispieldokument und ist sofort einsatzbereit.

## ✨ Funktionen

### Bearbeiten

| Funktion | Beschreibung |
|---------|-------------|
| **📝 Drei Bearbeitungsmodi** | Quelltext mit Syntaxhervorhebung, Live-Vorschau und eine ziehbare geteilte Ansicht |
| **✏️ In der Vorschau bearbeiten** | Doppelklick auf einen Block öffnet Markdown an Ort und Stelle; `Esc` verwirft, Aufgabenboxen reagieren auf einen Klick |
| **⌨️ Befehls-Palette und `/`-Menü** | `Ctrl+Shift+P` führt jeden Befehl aus, `/` fügt einen Block ein |
| **📊 Tabellenbearbeitung** | Zeilen und Spalten einfügen oder löschen und Spalten ausrichten |
| **🔀 Blöcke verschieben** | Absatz, Liste oder Fence mit einem Tastenkürzel nach oben oder unten bewegen |
| **🔍 Suchen und Ersetzen** | Ganze Wörter und reguläre Ausdrücke suchen und im Dokument ersetzen |
| **🔗 Link einfügen** | Wörter markieren und eine Webadresse darüber einfügen, um einen Link zu erzeugen |
| **📐 Tabelle ausrichten** | Pipes neu ausrichten, ohne den Inhalt zu ändern; CJK-Zeichen zählen als zwei Spalten |
| **🖼️ Bilder** | Bild einfügen oder ablegen; es wird neben dem Dokument gespeichert und verknüpft |

### Darstellung

| Funktion | Beschreibung |
|---------|-------------|
| **📈 Mermaid-Diagramme** | **22 Diagrammtypen** in reinem Dart gezeichnet, **ohne WebView** |
| **∑ Mathematik** | Inline- und Block-LaTeX mit KaTeX-kompatibler Darstellung |
| **📋 CommonMark + GFM** | Tabellen, Aufgabenlisten, Durchstreichungen, Autolinks, Fußnoten und `<ruby>`-Annotationen |
| **🎨 8 Themes** | Red Graphite, Shibuya, Pink Blossom, Sky Blue, Dark Graphite, Dieci OLED, Nord, Midnight |
| **🌍 12 Sprachen** | Englisch, Chinesisch, Japanisch, Koreanisch, Deutsch, Französisch, Italienisch, Russisch, Spanisch, Portugiesisch, Arabisch und brasilianisches Portugiesisch; Arabisch mit RTL |

### Dateien und Ausgabe

| Funktion | Beschreibung |
|---------|-------------|
| **📤 Export** | HTML, PDF und Word `.docx`; Diagramme und Code sind im HTML eingebettet, Mathematik nutzt weiterhin KaTeX |
| **🔤 Zeichencodierungen** | UTF-8, UTF-16 und GBK beim Öffnen erkannt, mit oder ohne BOM, und unverändert zurückgeschrieben |
| **📂 Dateibaum** | Seitennavigation mit Drag-and-Drop für Ordner |
| **👀 Externe Änderungen** | Änderungen durch andere Programme werden während des Öffnens erkannt |
| **💾 Sicheres Speichern** | Atomare Schreibvorgänge verhindern halbe Dateien nach einem Abbruch |
| **⌨️ Anpassbare Tastenkürzel** | Tastaturbelegungen vollständig konfigurierbar |

### Leichtgewichtig bleiben

| | |
|---------|-------------|
| **🧩 Open plugins** | Discover public plugins through [GitHub Topic: `marktext-plus-plugin`](https://github.com/topics/marktext-plus-plugin); every plugin is labelled Community/Unverified and runs out of process |
| **⚡ Schneller Start** | Kein eingebetteter Browser, kein Editor-Framework, 22 direkte Abhängigkeiten |
| **📄 Große Dateien** | Parser, Hervorhebung und Suche arbeiten in einem Durchlauf und werden per Tests begrenzt |
| **🧪 Getestet** | 2027 Tests für Parser, Exporte, Provider und Editor-Widgets |

## ⚖️ Im Vergleich

Gegen den Editor, aus dem dieser hervorgegangen ist, und gegen den bekanntesten in diesem Feld. Alles in der MarkText-Spalte wurde aus dessen Quelltext bei `v0.20.0-dev` gelesen; die Typora-Spalte stammt aus dessen veröffentlichter Dokumentation, da es Closed Source ist und sich nicht auf dieselbe Weise prüfen lässt.

Die Startzeiten stammen von einem einzigen Windows-Rechner, alle drei Programme darauf. Die dieses Programms sind instrumentiert — es schreibt ein eigenes `startup-trace.log`, und die Zahlen sind vier Starts —, die beiden anderen wurden von Hand gestoppt; behandeln Sie sie als das gröbere Paar. Der Großteil des Starts hier ist nicht der eigene Code: von den 0,7 s entfallen etwa 0,5 s auf Windows beim Laden der Programmdatei und den Start der Flutter-Engine, und 0,15 s auf alles, was der Editor selbst tut.

| | **MarkText Plus** | **MarkText** (Original) | **Typora** |
|---|---|---|---|
| **Laufzeitumgebung** | Flutter — kompiliert, kein eingebetteter Browser | Electron 42 | Electron |
| **Start** (bis das Dokument steht) | ~0,7 s warm, ~1,4 s kalt | 2–3 s | 2–3 s |
| **Direkte Abhängigkeiten** | 22 | 56 (Desktop-Paket) | Closed Source |
| **Lizenz** | MIT, kostenlos | MIT, kostenlos | Kostenpflichtig, Closed Source |
| **Bearbeiten** | Quelltext, Vorschau und eine geteilte Ansicht, deren Hälften einander folgen; Blöcke werden in der Vorschau an Ort und Stelle bearbeitet | Live-Vorschau (WYSIWYG), dazu ein Quelltextmodus | Live-Vorschau (WYSIWYG), dazu ein Quelltextmodus |
| **Diagramme** | 22 Mermaid-Typen, in Dart gezeichnet, ohne WebView | Mermaid, flowchart.js, Vega-Lite, PlantUML — alle über JavaScript | Mermaid, flowchart.js, js-sequence, PlantUML |
| **Mathematik** | KaTeX-kompatibel | KaTeX | KaTeX |
| **Export** | HTML, PDF, Word — alles eingebaut | HTML, PDF, Markdown; weitere Formate, wenn pandoc installiert ist | Viele Formate, die meisten über pandoc |
| **Themes** | 8 | 32 | Viele, dazu eine große Sammlung aus der Community |
| **Oberflächensprachen** | 12 | 10 | Mehrere |
| **Plattformen** | Windows, macOS, Linux (x64 und arm64) | Windows, macOS, Linux | Windows, macOS, Linux |

### Worin die anderen voraus sind

Das gehört deutlich gesagt, denn ein Vergleich, der nur dem schmeichelt, der ihn schreibt, ist das Lesen nicht wert.

- **Live-Vorschau.** Typora und MarkText bearbeiten beide das gesetzte Dokument unmittelbar, ohne Moduswechsel. Dieser Editor gibt Ihnen drei Ansichten und lässt Sie einen Block an Ort und Stelle öffnen; das ist etwas anderes, und für jemanden, der Typora gewohnt ist, ist es der Unterschied, der zuerst auffällt.
- **Themes.** Zweiunddreißig gegen acht, und hinter Typora stehen Jahre an Community-CSS.
- **Bandbreite der Diagramme.** PlantUML und Vega-Lite sind hier nicht umgesetzt.
- **Jahre.** Typora wird seit einem Jahrzehnt verfeinert. Dies ist ein junges Programm und liest sich stellenweise auch so.

### Worin dieses voraus ist

- **Kein eingebetteter Browser.** Parser, Renderer, Syntaxhervorhebung und Diagramm-Engine sind alle hier geschrieben und einkompiliert. Das ist der ganze Grund für das Projekt, und die Startzeiten oben sind, was es dafür bekommt.
- **Diagramme ohne JavaScript.** Zweiundzwanzig Mermaid-Typen, von einem Dart-Painter gezeichnet, kommen daher als Bilder in die PDF- und Word-Datei statt als Skript, das der Rechner des Lesers ausführen muss.
- **Word-Export ohne pandoc.** Kein zweites Programm zu installieren.
- **Kostenlos und quelloffen**, was Typora nicht ist.

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

Laden Sie die neueste Version für Ihre Plattform von [Releases](https://github.com/marktext-plus/marktext-plus/releases) herunter.

| Platform | Architecture | Format |
|----------|-------------|--------|
| Windows | x64 | `.exe` installer |
| macOS | ARM64 | `.dmg` |
| Linux | x64 / ARM64 | `.deb` / `.rpm` |

### Aus dem Quellcode bauen

> **Voraussetzungen**: Flutter 3.x+, Dart 3.x+

```bash
git clone https://github.com/marktext-plus/marktext-plus.git
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

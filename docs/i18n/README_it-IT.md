<div align="center">

# MarkText Plus

**Un editor Markdown leggero e multipiattaforma ricostruito con Flutter, ripensato a partire dall’originale [MarkText](https://github.com/marktext/marktext).**

[English](../../README.md) | [简体中文](README_zh-CN.md) | [日本語](README_ja-JP.md) | [한국어](README_ko-KR.md) | [Deutsch](README_de-DE.md) | [Français](README_fr-FR.md) | [Русский](README_ru-RU.md) | [Español](README_es-ES.md) | [Português](README_pt-PT.md) | [العربية](README_ar-SA.md) | [Português (Brasil)](README_pt-BR.md)

![MarkText Plus](../../docs/v1.1.2/picture/theme/red-graphite.png)

</div>

---

## 💡 Cos’è MarkText Plus?

MarkText Plus è un **editor Markdown moderno**, ripensato dall’originale [MarkText](https://github.com/marktext/marktext) e ricostruito con Flutter per un vero supporto multipiattaforma. Risolve i principali limiti degli editor Markdown tradizionali.

- ❌ Pesante e lento all’avvio → ✅ **Rapidissimo** con parser sviluppato internamente
- ❌ Poche opzioni di tema → ✅ **8 temi eleganti** (chiari e scuri)
- ❌ Esperienza multipiattaforma debole → ✅ **Prestazioni native** su Windows, macOS e Linux
- ❌ Configurazione complicata → ✅ **Pronto in 3 comandi**

## 🚀 Avvio rapido

Pronto in meno di 30 secondi.

```bash
git clone https://github.com/yourusername/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

Tutto qui. L’editor si avvierà con un documento di esempio pronto per la modifica.

## ✨ Funzionalità

| Feature | Description |
|---------|-------------|
| **📝 Tre modalità di modifica** | Codice sorgente con evidenziazione sintattica, anteprima live e vista divisa |
| **🎨 8 temi eleganti** | Red Graphite, Shibuya, Pink Blossom, Sky Blue, Dark Graphite, Dieci OLED, Nord, Midnight |
| **🌍 12 lingue** | Inglese, cinese, giapponese, coreano, tedesco, francese, italiano, russo, spagnolo, portoghese, arabo e portoghese brasiliano |
| **⚡ Reattività elevata** | Parser e renderer Markdown sviluppati internamente, senza dipendenze pesanti |
| **🔍 Trova e sostituisci** | Ricerca completa con supporto per le espressioni regolari |
| **📂 Albero file** | Navigazione laterale con supporto drag-and-drop delle cartelle |
| **⌨️ Scorciatoie personalizzabili** | Associazioni da tastiera completamente configurabili |
| **💾 Salvataggio automatico** | Configurazione persistente basata su JSON per non perdere mai il lavoro |

## 🎨 Temi

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

## 📦 Installazione

### Scarica i binari precompilati

Scarica l’ultima versione per la tua piattaforma da [Releases](https://github.com/yourusername/marktext-plus/releases).

| Platform | Architecture | Format |
|----------|-------------|--------|
| Windows | x64 | `.exe` installer |
| macOS | ARM64 | `.dmg` |
| Linux | x64 / ARM64 | `.deb` / `.rpm` |

### Compila dal sorgente

> **Prerequisiti**: Flutter 3.x+, Dart 3.x+

```bash
git clone https://github.com/yourusername/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

<details>
<summary><b>Comandi di build release</b></summary>

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
<summary><b>Utenti macOS: aggirare l’avviso app non firmata</b></summary>

> macOS potrebbe mostrare l’avviso "Apple non ha potuto verificare che MarkText Plus non contenga malware...". Dopo aver trascinato l’app nella cartella "Applicazioni", esegui i seguenti comandi.
>
> ```bash
> xattr -cr /Applications/MarkText\ Plus.app
> sudo codesign --force --deep --sign - /Applications/MarkText\ Plus.app
> ```
</details>

## 🏗️ Architettura

```
code/lib/
├── main.dart           # Punto di ingresso dell’applicazione
├── app.dart            # MaterialApp con binding di tema/locale/i18n
├── core/               # Token di tema, configurazione, i18n (12 lingue)
├── models/             # TabInfo, FileNode
├── services/           # Parser Markdown, file I/O, scorciatoie da tastiera
├── providers/          # Gestione dello stato Riverpod
└── ui/
    ├── editor/         # Editor sorgente, renderer anteprima, vista divisa
    ├── screens/        # Home, Impostazioni
    └── widgets/        # Barra menu, sidebar, barra schede, barra di stato
```

Architettura a quattro livelli: **UI** → **Stato** (Riverpod) → **Servizio** → **Piattaforma**

### Esegui i test

```bash
cd code && flutter test
```

## 🤝 Contribuire

I contributi sono benvenuti. Invia pure una Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 Licenza

Licenza MIT - vedi [LICENSE](../../LICENSE) per i dettagli.

Basato su [MarkText](https://github.com/marktext/marktext) di Luo Ran e contributori.

## 🙏 Ringraziamenti

- [MarkText](https://github.com/marktext/marktext) — il progetto originale che ha ispirato questo editor
- [Flutter](https://flutter.dev) — il framework multipiattaforma
- Tutte le librerie open source utilizzate in questo progetto

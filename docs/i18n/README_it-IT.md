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
git clone https://github.com/marktext-plus/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

Tutto qui. L’editor si avvierà con un documento di esempio pronto per la modifica.

## ✨ Funzionalità

### Modifica

| Funzione | Descrizione |
|---------|-------------|
| **📝 Tre modalità di modifica** | Codice sorgente con evidenziazione, anteprima live e vista divisa trascinabile |
| **✏️ Modifica nell’anteprima** | Doppio clic su un blocco per modificare Markdown sul posto; `Esc` annulla e le caselle si spuntano con un clic |
| **⌨️ Tavolozza comandi e menu `/`** | `Ctrl+Shift+P` esegue ogni comando e `/` inserisce un blocco |
| **📊 Modifica tabelle** | Inserisci o elimina righe e colonne e allinea ogni colonna |
| **🔀 Sposta blocchi** | Sposta paragrafi, liste o fence su e giù con una scorciatoia |
| **🔍 Trova e sostituisci** | Cerca parole intere ed espressioni regolari nell’intero documento |
| **🔗 Incolla un link** | Seleziona parole e incolla un indirizzo Web per creare un link |
| **📐 Allinea una tabella** | Riallinea i separatori senza cambiare il contenuto; i caratteri CJK valgono due colonne |
| **🖼️ Immagini** | Incolla o trascina un’immagine per salvarla accanto al documento e collegarla |

### Rendering

| Funzione | Descrizione |
|---------|-------------|
| **📈 Diagrammi Mermaid** | **22 tipi** disegnati in puro Dart, **senza WebView** |
| **∑ Matematica** | Formule LaTeX inline e a blocco con rendering compatibile con KaTeX |
| **📋 CommonMark + GFM** | Tabelle, task list, barrato, autolink, note a piè di pagina e annotazioni `<ruby>` |
| **🎨 8 temi** | Red Graphite, Shibuya, Pink Blossom, Sky Blue, Dark Graphite, Dieci OLED, Nord, Midnight |
| **🌍 12 lingue** | Inglese, cinese, giapponese, coreano, tedesco, francese, italiano, russo, spagnolo, portoghese, arabo e portoghese brasiliano; arabo RTL |

### File e output

| Funzione | Descrizione |
|---------|-------------|
| **📤 Esportazione** | HTML, PDF e Word `.docx`; diagrammi e codice sono incorporati nell’HTML, mentre la matematica usa ancora KaTeX |
| **🔤 Codifiche** | Rileva UTF-8, UTF-16 e GBK all’apertura, con o senza BOM, e riscrive con la codifica trovata |
| **📂 Albero file** | Navigazione laterale con trascinamento delle cartelle |
| **👀 Modifiche esterne** | Rileva modifiche al documento fatte da altri programmi mentre è aperto |
| **💾 Salvataggio sicuro** | Scrittura atomica per evitare file incompleti dopo un’interruzione |
| **⌨️ Scorciatoie personalizzabili** | Associazioni da tastiera completamente configurabili |

### Progettato per restare leggero

| | |
|---------|-------------|
| **🧩 Open plugins** | Discover public plugins through GitHub Topic `marktext-plus-plugin`; every plugin is labelled Community/Unverified and runs out of process |
| **⚡ Avvio rapido** | Nessun browser incorporato o framework di editing, 22 dipendenze dirette |
| **📄 File grandi** | Analisi, evidenziazione e ricerca a passaggio singolo, con budget verificati dai test |
| **🧪 Testato** | 2021 test per parser, esportatori, provider e widget dell’editor |

## ⚖️ A confronto

Rispetto all'editor da cui questo è stato ripensato, e rispetto al più noto del settore. Tutto ciò che compare nella colonna MarkText è stato letto dal suo codice sorgente alla `v0.20.0-dev`; la colonna Typora viene dalla sua documentazione pubblicata, dato che è a sorgente chiuso e non può essere verificato allo stesso modo.

I tempi di avvio provengono da una sola macchina Windows, con tutti e tre i programmi installati. Quelli di questo programma sono strumentati — scrive un proprio `startup-trace.log`, e i numeri sono di quattro avvii — mentre gli altri due sono stati cronometrati a mano: consideratela la coppia più grossolana. La maggior parte dell'avvio qui non è codice proprio: dei 0,7 s, circa 0,5 s spettano a Windows che carica l'eseguibile e al motore Flutter che parte, e 0,15 s a tutto ciò che fa l'editor.

| | **MarkText Plus** | **MarkText** (originale) | **Typora** |
|---|---|---|---|
| **Runtime** | Flutter — compilato, senza browser incorporato | Electron 42 | Electron |
| **Avvio** (fino al documento a schermo) | ~0,7 s a caldo, ~1,4 s a freddo | 2–3 s | 2–3 s |
| **Dipendenze dirette** | 22 | 56 (pacchetto desktop) | sorgente chiuso |
| **Licenza** | MIT, gratuito | MIT, gratuito | A pagamento, sorgente chiuso |
| **Modifica** | Sorgente, anteprima e una vista divisa le cui metà si seguono; i blocchi si modificano sul posto nell'anteprima | Anteprima dal vivo (WYSIWYG), più una modalità sorgente | Anteprima dal vivo (WYSIWYG), più una modalità sorgente |
| **Diagrammi** | 22 tipi Mermaid, disegnati in Dart senza WebView | Mermaid, flowchart.js, Vega-Lite, PlantUML — tutti tramite JavaScript | Mermaid, flowchart.js, js-sequence, PlantUML |
| **Matematica** | Compatibile KaTeX | KaTeX | KaTeX |
| **Esportazione** | HTML, PDF, Word — tutto integrato | HTML, PDF, Markdown; altri formati se pandoc è installato | Molti formati, per lo più tramite pandoc |
| **Temi** | 8 | 32 | Molti, e una vasta raccolta della comunità |
| **Lingue dell'interfaccia** | 12 | 10 | Diverse |
| **Piattaforme** | Windows, macOS, Linux (x64 e arm64) | Windows, macOS, Linux | Windows, macOS, Linux |

### Dove gli altri sono avanti

Vale la pena dirlo chiaramente: un confronto che lusinga solo chi lo scrive non merita di essere letto.

- **Anteprima dal vivo.** Typora e MarkText modificano entrambi il documento già composto, senza modalità da cambiare. Questo editor offre tre riquadri e permette di aprire un blocco sul posto: è un'altra cosa, e per chi viene da Typora è la differenza che si nota per prima.
- **Temi.** Trentadue contro otto, e Typora ha anni di CSS della comunità alle spalle.
- **Ampiezza dei diagrammi.** PlantUML e Vega-Lite non sono implementati qui.
- **Anni.** Typora viene rifinito da un decennio. Questo è un programma giovane e in alcuni punti si vede.

### Dove è avanti questo

- **Nessun browser incorporato.** Parser, renderer, evidenziazione della sintassi e motore dei diagrammi sono tutti scritti qui e compilati. È l'intera ragione del progetto, e i tempi di avvio qui sopra sono ciò che se ne ricava.
- **Diagrammi senza JavaScript.** Ventidue tipi Mermaid disegnati da un pittore Dart, così entrano nel PDF e nel file Word come immagini e non come uno script che la macchina del lettore deve eseguire.
- **Esportazione in Word senza pandoc.** Nessun secondo programma da installare.
- **Gratuito e open source**, cosa che Typora non è.

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

Scarica l’ultima versione per la tua piattaforma da [Releases](https://github.com/marktext-plus/marktext-plus/releases).

| Platform | Architecture | Format |
|----------|-------------|--------|
| Windows | x64 | `.exe` installer |
| macOS | ARM64 | `.dmg` |
| Linux | x64 / ARM64 | `.deb` / `.rpm` |

### Compila dal sorgente

> **Prerequisiti**: Flutter 3.x+, Dart 3.x+

```bash
git clone https://github.com/marktext-plus/marktext-plus.git
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

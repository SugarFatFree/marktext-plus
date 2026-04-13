[English](../../README.md) | [简体中文](README_zh-CN.md) | [日本語](README_ja-JP.md) | [한국어](README_ko-KR.md) | [Deutsch](README_de-DE.md) | [Français](README_fr-FR.md) | [Русский](README_ru-RU.md) | [Español](README_es-ES.md) | [Português](README_pt-PT.md) | [العربية](README_ar-SA.md) | [Português (Brasil)](README_pt-BR.md)

# MarkText Plus

Un editor Markdown leggero e multipiattaforma costruito con Flutter, ripensato dall'originale [MarkText](https://github.com/marktext/marktext).

## Caratteristiche

- **Supporto multilingue**: 12 lingue tra cui inglese, cinese, giapponese, coreano, tedesco, francese, italiano, russo, spagnolo, portoghese, arabo e portoghese brasiliano
- **Leggero e veloce**: Parser e renderer Markdown personalizzati per prestazioni ottimali
- **Configurazione persistente**: Archiviazione delle impostazioni basata su JSON con salvataggio automatico
- **Editing a doppio pannello**: Modalità codice sorgente, anteprima e vista divisa
- **Multipiattaforma**: Funziona su Windows, macOS e Linux
- **Interfaccia moderna**: Interfaccia pulita con 5 temi integrati
- **Evidenziazione della sintassi**: Evidenziazione della sintassi Markdown in tempo reale in modalità sorgente

## Installazione

### Prerequisiti

- Flutter 3.x o superiore
- Dart 3.x o superiore

### Compilazione dal codice sorgente

```bash
git clone https://github.com/yourusername/marktext-plus.git
cd marktext-plus/code
flutter pub get
flutter run
```

### Build di rilascio

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

## Sviluppo

### Struttura del progetto

```
code/
├── lib/
│   ├── main.dart              # Punto di ingresso dell'applicazione
│   ├── app.dart               # Configurazione MaterialApp
│   ├── core/                  # Configurazione e temi principali
│   ├── models/                # Modelli di dati
│   ├── services/              # Servizi di logica aziendale
│   ├── providers/             # Gestione dello stato Riverpod
│   └── ui/                    # Componenti UI
└── test/                      # Test unitari e widget
```

### Architettura

Architettura a quattro livelli:
- **Livello UI**: Widget e schermate Flutter
- **Livello di stato**: Provider Riverpod per la gestione dello stato
- **Livello di servizio**: Logica aziendale ed elaborazione dati
- **Livello piattaforma**: I/O file e integrazione di sistema

### Esecuzione dei test

```bash
flutter test
```

## Contribuire

I contributi sono benvenuti! Sentiti libero di inviare una Pull Request.

## Licenza

Questo progetto è concesso in licenza con la Licenza MIT — vedi il file [LICENSE](../../code/LICENSE) per i dettagli.

Basato sul progetto [MarkText](https://github.com/marktext/marktext) di Luo Ran e contributori.

## Ringraziamenti

- Il progetto MarkText originale e i suoi contributori
- I team Flutter e Dart
- Tutte le librerie open source utilizzate in questo progetto

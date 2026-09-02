<div align="center">

# MarkText Plus

**Лёгкий кроссплатформенный Markdown-редактор на Flutter, переосмысленный на основе оригинального [MarkText](https://github.com/marktext/marktext).**

[English](../../README.md) | [简体中文](README_zh-CN.md) | [日本語](README_ja-JP.md) | [한국어](README_ko-KR.md) | [Deutsch](README_de-DE.md) | [Français](README_fr-FR.md) | [Italiano](README_it-IT.md) | [Español](README_es-ES.md) | [Português](README_pt-PT.md) | [العربية](README_ar-SA.md) | [Português (Brasil)](README_pt-BR.md)

![MarkText Plus](../../docs/v1.1.2/picture/theme/red-graphite.png)

</div>

---

## 💡 Что такое MarkText Plus?

MarkText Plus — это **современный Markdown-редактор**, заново переосмысленный на основе оригинального [MarkText](https://github.com/marktext/marktext) и полностью перестроенный на Flutter для настоящей кроссплатформенности. Он устраняет типичные проблемы традиционных Markdown-редакторов.

- ❌ Тяжёлый и медленный запуск → ✅ **Молниеносная скорость** благодаря собственному парсеру
- ❌ Мало вариантов тем → ✅ **8 красивых тем** (светлые и тёмные)
- ❌ Слабый кроссплатформенный опыт → ✅ **Нативная производительность** на Windows, macOS и Linux
- ❌ Сложная настройка → ✅ **Начало работы в 3 командах**

## 🚀 Быстрый старт

Запуск менее чем за 30 секунд.

```bash
git clone https://github.com/SugarFatFree/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

Вот и всё. Редактор откроется с примером документа, и можно сразу начинать редактирование.

## ✨ Возможности

### Редактирование

| Feature | Description |
|---------|-------------|
| **📝 Three edit modes** | Source with syntax highlighting, live preview and draggable split view |
| **✏️ Edit in preview** | Double-click a block to edit Markdown in place; `Esc` discards and task boxes toggle with one click |
| **⌨️ Command palette and `/` menu** | `Ctrl+Shift+P` runs commands and `/` inserts a block |
| **📊 Table editing** | Insert or delete rows and columns and align each column |
| **🔀 Move blocks** | Move paragraphs, lists or fences up and down with one shortcut |
| **🔍 Find and replace** | Whole-word and regular-expression search across the document |
| **🔗 Paste a link** | Select words and paste a web address to make a link |
| **📐 Tidy tables** | Realign table pipes without changing content; CJK characters count as two columns |
| **🖼️ Images** | Paste or drop a picture to store it beside the document and link it |

### Отображение

| Feature | Description |
|---------|-------------|
| **📈 Mermaid diagrams** | **22 types** drawn in pure Dart, **without WebView** |
| **∑ Math** | Inline and block LaTeX with KaTeX-compatible rendering |
| **📋 CommonMark + GFM** | Tables, task lists, strikethrough, autolinks, footnotes and `<ruby>` annotations |
| **🎨 8 themes** | Red Graphite, Shibuya, Pink Blossom, Sky Blue, Dark Graphite, Dieci OLED, Nord, Midnight |
| **🌍 12 languages** | English, Chinese, Japanese, Korean, German, French, Italian, Russian, Spanish, Portuguese, Arabic and Brazilian Portuguese; Arabic uses RTL |

### Файлы и вывод

| Feature | Description |
|---------|-------------|
| **📤 Export** | HTML, PDF and Word `.docx`; diagrams and highlighted code are embedded in HTML, while maths still uses KaTeX |
| **🔤 Encodings** | UTF-8, UTF-16 and GBK detected on open, with or without BOM, and written back as found |
| **📂 File tree** | Sidebar navigation with folder drag and drop |
| **👀 External changes** | Notices edits made by another program while the document is open |
| **💾 Safe saving** | Atomic writes prevent partial files after interruption |
| **⌨️ Custom shortcuts** | Fully configurable keyboard bindings |

### Создан лёгким

| | |
|---------|-------------|
| **🧩 Open plugins** | Discover public plugins through GitHub Topic `marktext-plus-plugin`; every plugin is labelled Community/Unverified and runs out of process |
| **⚡ Fast start** | No embedded browser or editor framework, 22 direct dependencies |
| **📄 Large files** | Single-pass parsing, highlighting and search with tested budgets |
| **🧪 Tested** | 2019 tests covering parser, exporters, providers and editor widgets |

## ⚖️ Сравнение

С редактором, из которого этот переосмыслен, и с самым известным в этой области. Всё в столбце MarkText прочитано из его исходного кода на `v0.20.0-dev`; столбец Typora взят из его опубликованной документации, поскольку он закрыт и проверить его тем же способом нельзя.

Время запуска снято на одной машине с Windows, все три программы на ней. Показатели этой программы сняты приборно — она пишет собственный `startup-trace.log`, и это четыре запуска, — а две другие засекались вручную: считайте их более грубой парой. Большая часть запуска здесь — не собственный код: из 0,7 с около 0,5 с приходится на загрузку исполняемого файла в Windows и старт движка Flutter, и 0,15 с — на всё, что делает сам редактор.

| | **MarkText Plus** | **MarkText** (оригинал) | **Typora** |
|---|---|---|---|
| **Среда выполнения** | Flutter — компилируемая, без встроенного браузера | Electron 42 | Electron |
| **Запуск** (до появления документа) | ~0,7 с «на горячую», ~1,4 с «на холодную» | 2–3 с | 2–3 с |
| **Прямых зависимостей** | 22 | 56 (пакет desktop) | закрытый код |
| **Лицензия** | MIT, бесплатно | MIT, бесплатно | Платно, закрытый код |
| **Редактирование** | Исходник, предпросмотр и разделённый вид, половины которого следуют друг за другом; блоки правятся на месте в предпросмотре | Живой предпросмотр (WYSIWYG) и режим исходника | Живой предпросмотр (WYSIWYG) и режим исходника |
| **Диаграммы** | 22 типа Mermaid, рисуются на Dart без WebView | Mermaid, flowchart.js, Vega-Lite, PlantUML — все через JavaScript | Mermaid, flowchart.js, js-sequence, PlantUML |
| **Формулы** | Совместимо с KaTeX | KaTeX | KaTeX |
| **Экспорт** | HTML, PDF, Word — всё встроено | HTML, PDF, Markdown; больше форматов, если установлен pandoc | Много форматов, большинство через pandoc |
| **Темы** | 8 | 32 | Много, плюс большая коллекция сообщества |
| **Языки интерфейса** | 12 | 10 | Несколько |
| **Платформы** | Windows, macOS, Linux (x64 и arm64) | Windows, macOS, Linux | Windows, macOS, Linux |

### В чём другие впереди

Об этом стоит сказать прямо: сравнение, которое льстит только тому, кто его пишет, читать незачем.

- **Живой предпросмотр.** И Typora, и MarkText правят уже свёрстанный документ, без переключения режимов. Этот редактор даёт три панели и позволяет открыть блок на месте — это другое, и тот, кто привык к Typora, заметит эту разницу первой.
- **Темы.** Тридцать две против восьми, и за Typora стоят годы CSS от сообщества.
- **Широта диаграмм.** PlantUML и Vega-Lite здесь не реализованы.
- **Годы.** Typora шлифуют десятилетие. Эта программа молода, и местами это заметно.

### В чём впереди эта

- **Нет встроенного браузера.** Разборщик, отрисовка, подсветка синтаксиса и движок диаграмм написаны здесь и скомпилированы. В этом весь смысл проекта, а время запуска выше — то, что он за это получает.
- **Диаграммы без JavaScript.** Двадцать два типа Mermaid рисует Dart, поэтому в PDF и файл Word они попадают картинками, а не сценарием, который должна выполнить машина читателя.
- **Экспорт в Word без pandoc.** Не нужно ставить вторую программу.
- **Бесплатно и с открытым кодом**, чего о Typora сказать нельзя.

## 🎨 Темы

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

## 📦 Установка

### Скачать готовые сборки

Скачайте последнюю версию для вашей платформы из [Releases](https://github.com/SugarFatFree/marktext-plus/releases).

| Platform | Architecture | Format |
|----------|-------------|--------|
| Windows | x64 | `.exe` installer |
| macOS | ARM64 | `.dmg` |
| Linux | x64 / ARM64 | `.deb` / `.rpm` |

### Сборка из исходников

> **Требования**: Flutter 3.x+, Dart 3.x+

```bash
git clone https://github.com/SugarFatFree/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

<details>
<summary><b>Команды релизной сборки</b></summary>

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
<summary><b>Пользователи macOS: обход предупреждения о неподписанном приложении</b></summary>

> macOS может показать предупреждение «Apple не удалось проверить, что MarkText Plus не содержит вредоносного ПО...». После перемещения приложения в папку «Программы» выполните следующие команды.
>
> ```bash
> xattr -cr /Applications/MarkText\ Plus.app
> sudo codesign --force --deep --sign - /Applications/MarkText\ Plus.app
> ```
</details>

## 🏗️ Архитектура

```
code/lib/
├── main.dart           # Точка входа приложения
├── app.dart            # MaterialApp с привязкой темы, локали и i18n
├── core/               # Токены тем, конфигурация, i18n (12 языков)
├── models/             # TabInfo, FileNode
├── services/           # Markdown-парсер, файловый I/O, сочетания клавиш
├── providers/          # Управление состоянием Riverpod
└── ui/
    ├── editor/         # Редактор исходника, предпросмотр, разделённый вид
    ├── screens/        # Главный экран, настройки
    └── widgets/        # Меню, боковая панель, панель вкладок, строка состояния
```

Четырёхслойная архитектура: **UI** → **Состояние** (Riverpod) → **Сервис** → **Платформа**

### Запуск тестов

```bash
cd code && flutter test
```

## 🤝 Вклад

Мы приветствуем вклад. Отправляйте Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 Лицензия

Лицензия MIT — подробности в [LICENSE](../../LICENSE).

Основано на проекте [MarkText](https://github.com/marktext/marktext) Luo Ran и участников.

## 🙏 Благодарности

- [MarkText](https://github.com/marktext/marktext) — оригинальный проект, вдохновивший этот редактор
- [Flutter](https://flutter.dev) — кроссплатформенный фреймворк
- Все библиотеки с открытым исходным кодом, используемые в проекте

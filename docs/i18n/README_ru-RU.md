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

| Feature | Description |
|---------|-------------|
| **📝 Три режима редактирования** | Исходный код с подсветкой синтаксиса, живой предпросмотр и разделённый вид |
| **🎨 8 красивых тем** | Red Graphite, Shibuya, Pink Blossom, Sky Blue, Dark Graphite, Dieci OLED, Nord, Midnight |
| **🌍 12 языков** | Английский, китайский, японский, корейский, немецкий, французский, итальянский, русский, испанский, португальский, арабский и бразильский португальский |
| **⚡ Высокая скорость** | Собственный Markdown-парсер и рендерер без тяжёлых зависимостей |
| **🔍 Поиск и замена** | Полноценный поиск с поддержкой регулярных выражений |
| **📂 Дерево файлов** | Навигация в боковой панели с поддержкой перетаскивания папок |
| **⌨️ Настраиваемые сочетания клавиш** | Полностью конфигурируемые клавиатурные привязки |
| **💾 Автосохранение** | Постоянная JSON-конфигурация, чтобы не потерять работу |

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

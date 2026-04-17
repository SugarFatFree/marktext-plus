<div align="center">

# MarkText Plus

**Flutter で構築された軽量クロスプラットフォーム Markdown エディタ。オリジナルの [MarkText](https://github.com/marktext/marktext) を再設計。**

[English](../../README.md) | [简体中文](README_zh-CN.md) | [한국어](README_ko-KR.md) | [Deutsch](README_de-DE.md) | [Français](README_fr-FR.md) | [Italiano](README_it-IT.md) | [Русский](README_ru-RU.md) | [Español](README_es-ES.md) | [Português](README_pt-PT.md) | [العربية](README_ar-SA.md) | [Português (Brasil)](README_pt-BR.md)

![MarkText Plus](../../docs/v1.1.2/picture/theme/red-graphite.png)

</div>

---

## 💡 MarkText Plus とは？

MarkText Plus は、オリジナルの [MarkText](https://github.com/marktext/marktext) をベースに Flutter で再構築した**モダンな Markdown エディタ**です。真のクロスプラットフォーム体験を実現し、従来の Markdown エディタの課題を解決します。

- ❌ 起動が遅く重い → ✅ **高速起動**、独自開発パーサーを搭載
- ❌ テーマの選択肢が少ない → ✅ **8 つの美しいテーマ**（ライト & ダーク）
- ❌ クロスプラットフォーム体験が弱い → ✅ **ネイティブ性能**、Windows・macOS・Linux をサポート
- ❌ セットアップが複雑 → ✅ **3 コマンドですぐ開始**

## 🚀 クイックスタート

30 秒以内で起動できます。

```bash
git clone https://github.com/yourusername/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

以上です。エディタがサンプルドキュメント付きで起動し、すぐに編集を始められます。

## ✨ 機能

| Feature | Description |
|---------|-------------|
| **📝 3 つの編集モード** | ソースコードのシンタックスハイライト、ライブプレビュー、分割ビュー |
| **🎨 8 つの美しいテーマ** | Red Graphite、Shibuya、Pink Blossom、Sky Blue、Dark Graphite、Dieci OLED、Nord、Midnight |
| **🌍 12 言語対応** | 英語、中国語、日本語、韓国語、ドイツ語、フランス語、イタリア語、ロシア語、スペイン語、ポルトガル語、アラビア語、ブラジルポルトガル語 |
| **⚡ 高速応答** | 独自開発の Markdown パーサーとレンダラーで重い依存関係なし |
| **🔍 検索と置換** | 正規表現対応のフル機能検索 |
| **📂 ファイルツリー** | サイドバーでのナビゲーション、フォルダのドラッグ & ドロップ対応 |
| **⌨️ カスタマイズ可能なショートカット** | キーボードバインドを完全設定可能 |
| **💾 自動保存** | JSON ベースの永続設定で作業を失わない |

## 🎨 テーマ

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

## 📦 インストール

### プレビルド版をダウンロード

[Releases](https://github.com/yourusername/marktext-plus/releases) から、お使いのプラットフォーム向け最新バージョンをダウンロードしてください。

| Platform | Architecture | Format |
|----------|-------------|--------|
| Windows | x64 | `.exe` installer |
| macOS | ARM64 | `.dmg` |
| Linux | x64 / ARM64 | `.deb` / `.rpm` |

### ソースからビルド

> **前提条件**: Flutter 3.x+、Dart 3.x+

```bash
git clone https://github.com/yourusername/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

<details>
<summary><b>リリースビルドコマンド</b></summary>

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
<summary><b>macOS ユーザー: 未署名アプリの警告を回避</b></summary>

> macOS では「Apple は MarkText Plus に悪意のあるソフトウェアが含まれていないことを確認できません...」という警告が表示される場合があります。アプリを「アプリケーション」フォルダへ移動した後、次を実行してください。
>
> ```bash
> xattr -cr /Applications/MarkText\ Plus.app
> sudo codesign --force --deep --sign - /Applications/MarkText\ Plus.app
> ```
</details>

## 🏗️ アーキテクチャ

```
code/lib/
├── main.dart           # アプリのエントリーポイント
├── app.dart            # テーマ・ロケール・i18n を束ねた MaterialApp
├── core/               # テーマトークン、設定、i18n（12 言語）
├── models/             # TabInfo、FileNode
├── services/           # Markdown パーサー、ファイル I/O、キーバインド
├── providers/          # Riverpod 状態管理
└── ui/
    ├── editor/         # ソースエディタ、プレビュー、分割ビュー
    ├── screens/        # ホーム、設定
    └── widgets/        # メニューバー、サイドバー、タブバー、ステータスバー
```

4 層アーキテクチャ: **UI** → **状態層** (Riverpod) → **サービス層** → **プラットフォーム層**

### テストを実行

```bash
cd code && flutter test
```

## 🤝 コントリビューション

コントリビューションを歓迎します。Pull Request を送ってください。

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 ライセンス

MIT ライセンス - 詳細は [LICENSE](../../LICENSE) を参照してください。

[MarkText](https://github.com/marktext/marktext) は Luo Ran とコントリビューターによるプロジェクトです。

## 🙏 謝辞

- [MarkText](https://github.com/marktext/marktext) — このエディタの元になったオリジナルプロジェクト
- [Flutter](https://flutter.dev) — クロスプラットフォームフレームワーク
- このプロジェクトで利用しているすべてのオープンソースライブラリ

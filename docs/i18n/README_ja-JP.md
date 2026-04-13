[English](../../code/README.md) | [简体中文](README_zh-CN.md) | [한국어](README_ko-KR.md) | [Deutsch](README_de-DE.md) | [Français](README_fr-FR.md) | [Italiano](README_it-IT.md) | [Русский](README_ru-RU.md) | [Español](README_es-ES.md) | [Português](README_pt-PT.md) | [العربية](README_ar-SA.md) | [Português (Brasil)](README_pt-BR.md)

# MarkText Plus

Flutter で構築された軽量クロスプラットフォーム Markdown エディタ。オリジナルの [MarkText](https://github.com/marktext/marktext) を再設計。

## 機能

- **多言語サポート**：英語、中国語、日本語、韓国語、ドイツ語、フランス語、イタリア語、ロシア語、スペイン語、ポルトガル語、アラビア語、ブラジルポルトガル語を含む12言語
- **軽量・高速**：自社開発の Markdown パーサーとレンダラーによる最適なパフォーマンス
- **永続的な設定**：JSON ベースの設定保存と自動保存
- **デュアルペイン編集**：ソースコード、プレビュー、分割ビューモード
- **クロスプラットフォーム**：Windows、macOS、Linux で動作
- **モダンな UI**：5つの組み込みテーマを備えたクリーンなインターフェース
- **シンタックスハイライト**：ソースモードでのリアルタイム Markdown シンタックスハイライト

## インストール

### 前提条件

- Flutter 3.x 以上
- Dart 3.x 以上

### ソースからビルド

```bash
git clone https://github.com/yourusername/marktext-plus.git
cd marktext-plus/code
flutter pub get
flutter run
```

### リリースビルド

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

## 開発

### プロジェクト構造

```
code/
├── lib/
│   ├── main.dart              # アプリケーションエントリーポイント
│   ├── app.dart               # MaterialApp 設定
│   ├── core/                  # コア設定とテーマ
│   ├── models/                # データモデル
│   ├── services/              # ビジネスロジックサービス
│   ├── providers/             # Riverpod 状態管理
│   └── ui/                    # UI コンポーネント
└── test/                      # ユニットテストとウィジェットテスト
```

### アーキテクチャ

4層アーキテクチャ：
- **UI 層**：Flutter ウィジェットと画面
- **状態層**：Riverpod による状態管理
- **サービス層**：ビジネスロジックとデータ処理
- **プラットフォーム層**：ファイル I/O とシステム統合

### テストの実行

```bash
flutter test
```

## 貢献

貢献を歓迎します！お気軽にプルリクエストを送信してください。

## ライセンス

このプロジェクトは MIT ライセンスの下でライセンスされています - 詳細は [LICENSE](../../code/LICENSE) ファイルを参照してください。

Luo Ran と貢献者による [MarkText](https://github.com/marktext/marktext) に基づいています。

## 謝辞

- オリジナルの MarkText プロジェクトとその貢献者
- Flutter と Dart チーム
- このプロジェクトで使用されているすべてのオープンソースライブラリ

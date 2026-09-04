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
git clone https://github.com/marktext-plus/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

以上です。エディタがサンプルドキュメント付きで起動し、すぐに編集を始められます。

## ✨ 機能

### 編集

| 機能 | 説明 |
|---------|-------------|
| **📝 3 つの編集モード** | シンタックスハイライト付きソース、ライブプレビュー、ドラッグ可能な分割ビュー |
| **✏️ プレビュー内編集** | ブロックをダブルクリックして Markdown をその場で編集。`Esc` で破棄、タスクボックスはクリックで切り替え |
| **⌨️ コマンドパレットと `/` メニュー** | `Ctrl+Shift+P` でコマンドを実行し、`/` でブロックを挿入 |
| **📊 表の編集** | 行と列の追加・削除、列ごとの配置設定 |
| **🔀 ブロック移動** | ショートカット 1 つで段落、リスト、コードフェンスを上下に移動 |
| **🔍 検索と置換** | 完全一致語と正規表現に対応した文書全体の検索と置換 |
| **🔗 リンクの貼り付け** | 文字を選択して Web アドレスを貼り付けるとリンクに変換 |
| **📐 表の整形** | 内容を変えずにパイプを整列。CJK 文字は 2 列として計算 |
| **🖼️ 画像** | 画像を貼り付けまたはドロップすると文書の隣に保存してリンク |

### レンダリング

| 機能 | 説明 |
|---------|-------------|
| **📈 Mermaid ダイアグラム** | **22 種類**を純粋な Dart で描画し、**WebView 不要** |
| **∑ 数式** | KaTeX 互換の描画によるインラインおよびブロック LaTeX |
| **📋 CommonMark + GFM** | 表、タスクリスト、取り消し線、自動リンク、脚注、`<ruby>` 注釈 |
| **🎨 8 テーマ** | Red Graphite、Shibuya、Pink Blossom、Sky Blue、Dark Graphite、Dieci OLED、Nord、Midnight |
| **🌍 12 言語** | 英語、中国語、日本語、韓国語、ドイツ語、フランス語、イタリア語、ロシア語、スペイン語、ポルトガル語、アラビア語、ブラジルポルトガル語。アラビア語は RTL |

### ファイルと出力

| 機能 | 説明 |
|---------|-------------|
| **📤 エクスポート** | HTML、PDF、Word `.docx`。図とハイライト済みコードを HTML に内蔵し、数式は KaTeX を使用 |
| **🔤 エンコーディング** | BOM の有無を問わず UTF-8、UTF-16、GBK を検出し、検出した形式で保存 |
| **📂 ファイルツリー** | サイドバーのナビゲーションとフォルダーのドラッグ＆ドロップ |
| **👀 外部変更** | 開いている文書を他のプログラムが変更すると検知 |
| **💾 安全な保存** | アトミック書き込みで中断後の不完全なファイルを防止 |
| **⌨️ カスタムショートカット** | キーバインドを完全に設定可能 |

### 軽量さを維持

| | |
|---------|-------------|
| **🧩 開かれたプラグイン** | Lua か JavaScript のファイル一つ。SDK も、ビルドも要りません。サンドボックスで動き、自分が宣言した権限だけを持ちます。[GitHub Topic: `marktext-plus-plugin`](https://github.com/topics/marktext-plus-plugin) から見つけられ、どれもコミュニティ／未検証と表示されます |
| **⚡ 高速起動** | 埋め込みブラウザもエディタフレームワークもなく、直接依存は 23 個 |
| **📄 大きなファイル** | 解析、ハイライト、検索はいずれも一度きりの走査で、遅くなればテストが落ちる予算つき。128 KB を超えるとハイライトを諦めます——一秒ほどで開ける最後の大きさです。編集は変わらずでき、小さくなれば色は戻ります |
| **🧪 テスト** | パーサー、エクスポーター、provider、プラグインランタイム、エディター widget を 2417 のテストで |

### プラグイン

Lua か JavaScript で書きます。ファイル一つとマニフェスト、ビルドなし、同じファイルが三つのプラットフォームで動きます。必要なら複数ファイルにもでき、`require` は自分のディレクトリの中だけに届きます。

| 機能 | 説明 |
|---------|-------------|
| **🔐 権限** | マニフェストに書き、インストール前にあなたに示し、そして**強制します**。VS Code や IntelliJ は一覧を見せて拡張を信用しますが、ここでは誰も審査しないので、エディタが確かめます。`ai.chat` なしにモデルを呼んだプラグインは断られ、呼んだことがあなたに伝わります |
| **🪟 ペイン** | エディタはもともとタブをソースとプレビューに分けています。それを開いたものです。最大四つ、区切りはドラッグでき、誰も埋めていないマスは描かれません |
| **✍️ 書き戻し** | 選択したところをプラグインが書き直せます——ただし先に見せてから。結果には「適用」ボタンが付き、適用はエディタの履歴を通るので、取り消し一回で戻ります |
| **⚙️ 自分の設定** | プラグインが宣言したとおりに、エディタが設定ページを描きます。スイッチにはスイッチ、秘密には伏せ字の入力欄。プラグインが渡すのはデータで、ウィジェットではありません |
| **🌍 自分の言語** | プラグインは作者が望むだけの言語を自分で持ちます。エディタが話す十二とは無関係です |
| **🔑 鍵は決して渡らない** | 資格情報はエディタが持ち、要求もエディタが出します。プラグインはプロンプトを渡し、テキストを受け取ります |

[プラグイン SDK](https://github.com/marktext-plus-plugins/marktext-plus-plugin-sdk) から始めてください——そのまま写せる完全な例が三つと、十一言語のドキュメントがあります。

### AI エージェント向け

任意の MCP サーバーで、**既定では動いていません**。あなたの機械にポートを開き、そこに届いたものがあなたの文書を読み、エディタを操れるようになるので、自分で入れるものであり、作り直せるトークンを持ちます。

| ツール | 説明 |
|---------|-------------|
| **`read_logs`** | エディタとプラグインのログ。プラグイン別、深刻度別に絞れます |
| **`screenshot`** | いまのウィンドウの姿 |
| **`record_gif`** | 最長五秒。動きを見るためのもの |
| **`get_state`** | 開いているタブ、表示モード、入っているプラグイン、埋まっているペイン |
| **`control`** | タブの開閉、表示モードの切り替え、内容の書き込み、ペインを閉じる |
## ⚖️ 他のエディタとの比較

本プロジェクトが作り直した元のエディタと、この分野で最も知られているエディタとの比較です。MarkText の列はすべて `v0.20.0-dev` のソースから読み取りました。Typora はクローズドソースで同じようには確認できないため、公開されているドキュメントに書かれている内容だけを載せています。

起動時間は同じ Windows マシンで、3 つとも測っています。本プロジェクトの数値はプログラム自身が記録したもの（`startup-trace.log` を書き出します。ここでは 4 回分）で、他の 2 つは手で計測したものです。後者 2 つは粗い数値として見てください。本プロジェクトの起動時間の大半は自身のコードではありません。0.7 秒のうち約 0.5 秒は Windows による実行ファイルの読み込みと Flutter エンジンの起動で、エディタ自身の処理は約 0.15 秒です。

| | **MarkText Plus** | **MarkText**（原版） | **Typora** |
|---|---|---|---|
| **ランタイム** | Flutter — コンパイル型、埋め込みブラウザなし | Electron 42 | Electron |
| **起動**（文書が表示されるまで） | ウォーム約 0.7 秒、コールド約 1.4 秒 | 2〜3 秒 | 2〜3 秒 |
| **直接依存の数** | 22 | 56（desktop パッケージ） | クローズドソース |
| **ライセンス** | MIT、無料 | MIT、無料 | 有料、クローズドソース |
| **編集方法** | ソース、プレビュー、そして互いに追従する分割ビュー。プレビュー内でブロックをその場で編集できます | ライブプレビュー（WYSIWYG）とソースモード | ライブプレビュー（WYSIWYG）とソースモード |
| **ダイアグラム** | 22 種類の Mermaid 図を Dart で描画、WebView 不使用 | Mermaid、flowchart.js、Vega-Lite、PlantUML — いずれも JavaScript 経由 | Mermaid、flowchart.js、js-sequence、PlantUML |
| **数式** | KaTeX 互換 | KaTeX | KaTeX |
| **エクスポート** | HTML、PDF、Word — すべて内蔵 | HTML、PDF、Markdown。pandoc があればより多くの形式 | 多数の形式、ほとんどは pandoc 経由 |
| **テーマ** | 8 | 32 | 多数、さらに大きなコミュニティ製のテーマ群 |
| **表示言語** | 12 | 10 | 複数 |
| **対応 OS** | Windows、macOS、Linux（x64 と arm64） | Windows、macOS、Linux | Windows、macOS、Linux |

### 相手が優れている点

はっきり書いておきます。自分を持ち上げるだけの比較表は読む価値がないからです。

- **ライブプレビュー。** Typora も MarkText も、描画された文書を直接編集します。モードの切り替えはありません。本プロジェクトは 3 つのビューと、プレビュー内でブロックを開く方式です。**これは別のものであり**、Typora に慣れた人がまず気づく違いです。
- **テーマ。** 32 対 8。さらに Typora には長年のコミュニティ CSS があります。
- **ダイアグラムの幅。** PlantUML と Vega-Lite は実装していません。
- **年月。** Typora は 10 年磨かれてきました。本プロジェクトは若く、実際そう見える箇所もあります。

### 本プロジェクトが優れている点

- **埋め込みブラウザがない。** パーサ、レンダラ、シンタックスハイライト、ダイアグラムエンジンはすべてここで書かれ、コンパイルされています。それがこのプロジェクトの存在理由であり、上の起動時間はその成果です。
- **JavaScript に依存しないダイアグラム。** 22 種類の Mermaid 図を Dart のペインタが描くため、PDF や Word には読者の環境で実行するスクリプトではなく画像として入ります。
- **pandoc なしの Word 出力。** 別のプログラムを入れる必要がありません。
- **無料でオープンソース**。Typora はそうではありません。

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

[Releases](https://github.com/marktext-plus/marktext-plus/releases) から、お使いのプラットフォーム向け最新バージョンをダウンロードしてください。

| Platform | Architecture | Format |
|----------|-------------|--------|
| Windows | x64 | `.exe` installer |
| macOS | ARM64 | `.dmg` |
| Linux | x64 / ARM64 | `.deb` / `.rpm` |

### ソースからビルド

> **前提条件**: Flutter 3.x+、Dart 3.x+

```bash
git clone https://github.com/marktext-plus/marktext-plus.git
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

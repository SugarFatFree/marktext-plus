<div align="center">

# MarkText Plus

**让写作成为一种享受的轻量级跨平台 Markdown 编辑器**

[![Release](https://img.shields.io/github/v/release/SugarFatFree/marktext-plus?style=flat-square)](https://github.com/SugarFatFree/marktext-plus/releases)
[![License](https://img.shields.io/github/license/SugarFatFree/marktext-plus?style=flat-square)](../../LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey?style=flat-square)](https://github.com/SugarFatFree/marktext-plus)

[English](../../README.md) | [日本語](README_ja-JP.md) | [한국어](README_ko-KR.md) | [Deutsch](README_de-DE.md) | [Français](README_fr-FR.md) | [Italiano](README_it-IT.md) | [Русский](README_ru-RU.md) | [Español](README_es-ES.md) | [Português](README_pt-PT.md) | [العربية](README_ar-SA.md) | [Português (Brasil)](README_pt-BR.md)

![MarkText Plus](../../docs/v1.1.2/picture/theme/red-graphite.png)

</div>

---

## 💡 什么是 MarkText Plus？

MarkText Plus 是一款**现代化的 Markdown 编辑器**，重新设计自原版 [MarkText](https://github.com/marktext/marktext)，使用 Flutter 重构以实现真正的跨平台支持。它解决了传统 Markdown 编辑器的痛点：

- ❌ 启动缓慢、体积庞大 → ✅ **闪电般快速**，自研解析器
- ❌ 主题选择有限 → ✅ **8 款精美主题**（浅色 & 深色）
- ❌ 跨平台体验差 → ✅ **原生性能**，支持 Windows、macOS、Linux
- ❌ 配置复杂 → ✅ **3 条命令即可开始**

## 🚀 快速开始

不到 30 秒即可运行：

```bash
git clone https://github.com/SugarFatFree/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

就这么简单！编辑器将启动并加载示例文档，立即开始编辑。

## ✨ 功能特性

### 编辑

| 功能 | 描述 |
|---------|-------------|
| **📝 三种编辑模式** | 源代码语法高亮、实时预览，以及可拖动的分屏视图 |
| **✏️ 预览内编辑** | 双击块即可原地编辑 Markdown；`Esc` 放弃，任务框单击切换，图表提供编辑按钮 |
| **⌨️ 命令面板与 `/` 菜单** | 使用 `Ctrl+Shift+P` 按名称运行命令，或输入 `/` 插入块 |
| **📊 表格编辑** | 插入、删除行列，并设置每列对齐方式 |
| **🔀 移动块** | 用一个快捷键上下移动段落、列表或代码围栏 |
| **🔍 查找替换** | 支持全词匹配和正则表达式，可全文替换 |
| **🔗 粘贴链接** | 选中文字后粘贴网址，自动变成链接 |
| **📐 整理表格** | 重新对齐表格竖线而不改变内容；中日韩字符按两列计算 |
| **🖼️ 图片** | 粘贴或拖入图片，自动保存到文档旁并建立链接 |

### 渲染

| 功能 | 描述 |
|---------|-------------|
| **📈 Mermaid 图表** | **22 种图表类型**使用纯 Dart 绘制，**不依赖 WebView** |
| **∑ 数学公式** | 支持行内和块级 LaTeX，使用 KaTeX 兼容渲染 |
| **📋 CommonMark + GFM** | 表格、任务列表、删除线、自动链接、脚注和 `<ruby>` 注音 |
| **🎨 8 款主题** | Red Graphite、Shibuya、Pink Blossom、Sky Blue、Dark Graphite、Dieci OLED、Nord、Midnight |
| **🌍 12 种语言** | 英语、中文、日语、韩语、德语、法语、意大利语、俄语、西班牙语、葡萄牙语、阿拉伯语、巴西葡萄牙语；阿拉伯语支持 RTL |

### 文件与输出

| 功能 | 描述 |
|---------|-------------|
| **📤 导出** | HTML、PDF 和 Word `.docx`；图表与代码高亮内嵌到 HTML，数学公式仍使用 KaTeX |
| **🔤 编码** | 打开时识别 UTF-8、UTF-16 和 GBK，支持有无 BOM，并按原编码写回 |
| **📂 文件树** | 侧边栏导航，支持拖拽文件夹 |
| **👀 外部变更** | 文档打开期间能发现其他程序的修改 |
| **💾 安全保存** | 原子写入，避免中断保存后留下半个文件 |
| **⌨️ 自定义快捷键** | 完全可配置的键盘绑定 |

### 保持轻量

| | |
|---------|-------------|
| **⚡ 快速启动** | 没有内嵌浏览器和编辑器框架，只有 22 个直接依赖 |
| **📄 大文件** | 解析、语法高亮和搜索均为单遍处理，并由性能测试设置预算 |
| **🧪 测试充分** | 2009 项测试覆盖解析器、导出器、providers 和编辑器组件 |

## ⚖️ 横向对比

与本项目所重构的原版编辑器、以及这个领域里最知名的一款相比。MarkText 那一列的每项数据都是从它 `v0.20.0-dev` 的源码里读出来的；Typora 是闭源的，没法用同样的方式核实，所以那一列只写它公开文档里说明的内容。

启动耗时来自同一台 Windows 机器，三个程序都在上面测。本项目的数据是程序自己记录的（它会写一份 `startup-trace.log`，这里取四次启动），另外两个是手工掐表——请把后两者当作较粗的一对。本项目的启动时间大部分并不是它自己的代码：0.7 秒里约 0.5 秒是 Windows 加载可执行文件与 Flutter 引擎启动，约 0.15 秒才是编辑器自身做的事。

| | **MarkText Plus** | **MarkText**（原版） | **Typora** |
|---|---|---|---|
| **运行时** | Flutter —— 编译型，无内嵌浏览器 | Electron 42 | Electron |
| **冷启动**（到文档上屏） | 热启动约 0.7 秒，冷启动约 1.4 秒 | 2~3 秒 | 2~3 秒 |
| **直接依赖数** | 22 | 56（desktop 包） | 闭源 |
| **许可** | MIT，免费 | MIT，免费 | 付费，闭源 |
| **编辑方式** | 源码、预览、以及两侧互相跟随的分屏；预览里可就地编辑单个块 | 实时预览（所见即所得），另有源码模式 | 实时预览（所见即所得），另有源码模式 |
| **图表** | 22 种 Mermaid 图，用 Dart 绘制，不用 WebView | Mermaid、flowchart.js、Vega-Lite、PlantUML —— 均经由 JavaScript | Mermaid、flowchart.js、js-sequence、PlantUML |
| **数学公式** | 兼容 KaTeX | KaTeX | KaTeX |
| **导出** | HTML、PDF、Word —— 均为内置 | HTML、PDF、Markdown；装了 pandoc 可支持更多格式 | 多种格式，大多经由 pandoc |
| **主题** | 8 | 32 | 很多，另有庞大的社区主题库 |
| **界面语言** | 12 | 10 | 若干 |
| **平台** | Windows、macOS、Linux（x64 与 arm64） | Windows、macOS、Linux | Windows、macOS、Linux |

### 对方更强的地方

这里如实写出来，因为一份只夸自己的对比表不值得读。

- **实时预览。** Typora 和 MarkText 都是直接编辑渲染后的文档，不需要切换模式。本项目给的是三种视图，外加在预览里就地打开某个块——**这是另一种东西**，习惯了 Typora 的人第一眼就会察觉。
- **主题。** 32 比 8，而且 Typora 背后有多年的社区 CSS 积累。
- **图表广度。** PlantUML 与 Vega-Lite 本项目没有实现。
- **年头。** Typora 打磨了十年。本项目还年轻，某些地方也确实像。

### 本项目更强的地方

- **没有内嵌浏览器。** 解析器、渲染器、语法高亮和图表引擎全部在此编写并编译进来。这就是这个项目存在的理由，上面的启动数据就是它换来的。
- **图表不依赖 JavaScript。** 22 种 Mermaid 图由 Dart 画笔绘制，因此能作为图片进入 PDF 与 Word 文件，而不是一段需要读者机器去执行的脚本。
- **导出 Word 不需要 pandoc。** 不必再装第二个程序。
- **免费且开源**，这一点 Typora 做不到。

## 🎨 主题

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

## 📦 安装

### 下载预编译版本

从 [Releases](https://github.com/SugarFatFree/marktext-plus/releases) 下载适合你平台的最新版本。

| 平台 | 架构 | 格式 |
|------|------|------|
| Windows | x64 | `.exe` 安装包 |
| macOS | ARM64 | `.dmg` |
| Linux | x64 / ARM64 | `.deb` / `.rpm` |

### 从源码构建

> **前置要求**：Flutter 3.x+、Dart 3.x+

```bash
git clone https://github.com/SugarFatFree/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

<details>
<summary><b>发布版本构建命令</b></summary>

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
<summary><b>macOS 用户：绕过未签名应用警告</b></summary>

> macOS 可能会显示"Apple 无法验证 MarkText Plus..."警告。将应用拖入"应用程序"文件夹后：
>
> ```bash
> xattr -cr /Applications/MarkText\ Plus.app
> sudo codesign --force --deep --sign - /Applications/MarkText\ Plus.app
> ```
</details>

## 🏗️ 架构

```
code/lib/
├── main.dart           # 应用入口
├── app.dart            # MaterialApp 主题/语言/国际化绑定
├── core/               # 主题 Token、配置、国际化（12 种语言）
├── models/             # TabInfo、FileNode
├── services/           # Markdown 解析器、文件 I/O、快捷键
├── providers/          # Riverpod 状态管理
└── ui/
    ├── editor/         # 源代码编辑器、预览渲染器、分屏视图
    ├── screens/        # 主页、设置页
    └── widgets/        # 菜单栏、侧边栏、标签栏、状态栏
```

四层架构：**UI** → **状态层** (Riverpod) → **服务层** → **平台层**

### 运行测试

```bash
cd code && flutter test
```

## 🤝 贡献

欢迎贡献！请随时提交 Pull Request。

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 📄 许可证

MIT 许可证 - 详见 [LICENSE](../../LICENSE) 文件。

基于 Luo Ran 及贡献者的 [MarkText](https://github.com/marktext/marktext) 项目。

## 🙏 致谢

- [MarkText](https://github.com/marktext/marktext) — 灵感来源的原版项目
- [Flutter](https://flutter.dev) — 跨平台框架
- 本项目使用的所有开源库

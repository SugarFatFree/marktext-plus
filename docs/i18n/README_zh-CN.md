<div align="center">

# MarkText Plus

**让写作成为一种享受的轻量级跨平台 Markdown 编辑器**

[![Release](https://img.shields.io/github/v/release/yourusername/marktext-plus?style=flat-square)](https://github.com/yourusername/marktext-plus/releases)
[![License](https://img.shields.io/github/license/yourusername/marktext-plus?style=flat-square)](../../LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey?style=flat-square)](https://github.com/yourusername/marktext-plus)

[English](../../README.md) | [日本語](README_ja-JP.md) | [한국어](README_ko-KR.md) | [Deutsch](README_de-DE.md) | [Français](README_fr-FR.md) | [Italiano](README_it-IT.md) | [Русский](README_ru-RU.md) | [Español](README_es-ES.md) | [Português](README_pt-PT.md) | [العربية](README_ar-SA.md) | [Português (Brasil)](README_pt-BR.md)

![MarkText Plus](../../docs/v1.1.1/picture/theme/红石墨.png)

</div>

---

## 💡 什么是 MarkText Plus？

MarkText Plus 是一款**现代化的 Markdown 编辑器**，重新设计自原版 [MarkText](https://github.com/marktext/marktext)，使用 Flutter 重构以实现真正的跨平台支持。它解决了传统 Markdown 编辑器的痛点：

- ❌ 启动缓慢、体积庞大 → ✅ **闪电般快速**，自研解析器
- ❌ 主题选择有限 → ✅ **5 款精美主题**（浅色 & 深色）
- ❌ 跨平台体验差 → ✅ **原生性能**，支持 Windows、macOS、Linux
- ❌ 配置复杂 → ✅ **3 条命令即可开始**

## 🚀 快速开始

不到 30 秒即可运行：

```bash
git clone https://github.com/yourusername/marktext-plus.git
cd marktext-plus/code
flutter pub get && flutter run
```

就这么简单！编辑器将启动并加载示例文档，立即开始编辑。

## ✨ 功能特性

| 功能 | 描述 |
|------|------|
| **📝 三种编辑模式** | 源代码语法高亮、实时预览、分屏模式 |
| **🎨 5 款精美主题** | 红石墨、涩谷、深色石墨、Dieci 纯黑、Nord 极光 |
| **🌍 12 种语言** | 英语、中文、日语、韩语、德语、法语、意大利语、俄语、西班牙语、葡萄牙语、阿拉伯语、巴西葡萄牙语 |
| **⚡ 极速响应** | 自研 Markdown 解析器和渲染器，无重型依赖 |
| **🔍 查找替换** | 全功能搜索，支持正则表达式 |
| **📂 文件树** | 侧边栏导航，支持拖拽文件夹 |
| **⌨️ 自定义快捷键** | ��全可配置的键盘绑定 |
| **💾 自动保存** | 基于 JSON 的持久化配置，永不丢失工作 |

## 🎨 主题

<table>
  <tr>
    <td align="center"><b>红石墨</b><br/><img src="../../docs/v1.1.1/picture/theme/红石墨.png" alt="红石墨" width="400"/></td>
    <td align="center"><b>涩谷</b><br/><img src="../../docs/v1.1.1/picture/theme/涩谷.png" alt="涩谷" width="400"/></td>
  </tr>
  <tr>
    <td align="center"><b>深色石墨</b><br/><img src="../../docs/v1.1.1/picture/theme/深色石墨.png" alt="深色石墨" width="400"/></td>
    <td align="center"><b>Dieci 纯黑</b><br/><img src="../../docs/v1.1.1/picture/theme/纯黑.png" alt="Dieci 纯黑" width="400"/></td>
  </tr>
  <tr>
    <td align="center" colspan="2"><b>Nord 极光</b><br/><img src="../../docs/v1.1.1/picture/theme/极光.png" alt="Nord 极光" width="400"/></td>
  </tr>
</table>

## 📦 安装

### 下载预编译版本

从 [Releases](https://github.com/yourusername/marktext-plus/releases) 下载适合你平台的最新版本。

| 平台 | 架构 | 格式 |
|------|------|------|
| Windows | x64 | `.exe` 安装包 |
| macOS | ARM64 | `.dmg` |
| Linux | x64 / ARM64 | `.deb` / `.rpm` |

### 从源码构建

> **前置要求**：Flutter 3.x+、Dart 3.x+

```bash
git clone https://github.com/yourusername/marktext-plus.git
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

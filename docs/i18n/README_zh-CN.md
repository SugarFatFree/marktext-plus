[English](../../README.md) | [日本語](README_ja-JP.md) | [한국어](README_ko-KR.md) | [Deutsch](README_de-DE.md) | [Français](README_fr-FR.md) | [Italiano](README_it-IT.md) | [Русский](README_ru-RU.md) | [Español](README_es-ES.md) | [Português](README_pt-PT.md) | [العربية](README_ar-SA.md) | [Português (Brasil)](README_pt-BR.md)

# MarkText Plus

基于 Flutter 构建的轻量级跨平台 Markdown 编辑器，重新设计自原版 [MarkText](https://github.com/marktext/marktext)。

## 功能特性

- **多语言支持**：支持 12 种语言，包括英语、中文、日语、韩语、德语、法语、意大利语、俄语、西班牙语、葡萄牙语、阿拉伯语和巴西葡萄牙语
- **轻量快速**：自研 Markdown 解析器和渲染器，性能优化
- **配置持久化**：基于 JSON 的设置存储，自动保存
- **双栏编辑**：源代码、预览和分屏模式
- **跨平台**：支持 Windows、macOS 和 Linux
- **现代化界面**：简洁的界面设计，内置 5 种主题
- **语法高亮**：源代码模式下实时 Markdown 语法高亮

## 安装

### 前置要求

- Flutter 3.x 或更高版本
- Dart 3.x 或更高版本

### 从源码构建

```bash
git clone https://github.com/yourusername/marktext-plus.git
cd marktext-plus/code
flutter pub get
flutter run
```

### 发布版本构建

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

### macOS 用户注意事项

> **注意**
> 由于未经 Apple 公证，macOS 版本会显示"Apple 无法验证 MarkText Plus 是否不含恶意软件..."的警告。
>
> 将 MarkText Plus 拖入"应用程序"文件夹后，请运行以下命令：
>
> ```bash
> xattr -cr /Applications/MarkText\ Plus.app
> sudo codesign --force --deep --sign - /Applications/MarkText\ Plus.app
> ```

## 开发

### 项目结构

```
code/
├── lib/
│   ├── main.dart              # 应用入口
│   ├── app.dart               # MaterialApp 配置
│   ├── core/                  # 核心配置和主题
│   ├── models/                # 数据模型
│   ├── services/              # 业务逻辑服务
│   ├── providers/             # Riverpod 状态管理
│   └── ui/                    # UI 组件
└── test/                      # 单元测试和组件测试
```

### 架构

四层架构：
- **UI 层**：Flutter 组件和页面
- **状态层**：Riverpod 状态管理
- **服务层**：业务逻辑和数据处理
- **平台层**：文件 I/O 和系统集成

### 运行测试

```bash
flutter test
```

## 贡献

欢迎贡献！请随时提交 Pull Request。

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](../../LICENSE) 文件。

基于 Luo Ran 及贡献者的 [MarkText](https://github.com/marktext/marktext) 项目。

## 致谢

- 原版 MarkText 项目及其贡献者
- Flutter 和 Dart 团队
- 本项目使用的所有开源库

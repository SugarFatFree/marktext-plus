# MarkText Plus - 项目开发记忆

## 项目概览

基于 Flutter 构建的轻量级跨平台 Markdown 编辑器，重新设计自 [MarkText](https://github.com/marktext/marktext)。

- **当前版本**: V1.1.3
- **开源协议**: MIT
- **支持平台**: Windows, macOS, Linux
- **主要语言**: Dart/Flutter
- **状态管理**: Riverpod

## 项目结构

```
marktext-plus/
├── code/                      # Flutter 应用源码
│   ├── lib/
│   │   ├── main.dart          # 入口文件（window_manager 初始化）
│   │   ├── app.dart           # MaterialApp（主题/语言/i18n 绑定）
│   │   ├── core/
│   │   │   ├── config/        # AppConfig 模型 + ConfigService（JSON 持久化）
│   │   │   ├── theme/         # AppTheme（8 个内置主题，token 系统）
│   │   │   └── i18n/l10n/     # 生成的本地化代码（12 种语言）
│   │   ├── models/            # TabInfo, FileNode
│   │   ├── services/          # MarkdownParser, FileService, ExportService
│   │   ├── providers/         # Riverpod: settings, tab, editor, file, locale
│   │   ├── ui/
│   │   │   ├── editor/        # SourceEditor, MarkdownRenderer, SplitEditor
│   │   │   │   └── mermaid/   # Mermaid 图表渲染（纯 Dart 实现）
│   │   │   ├── screens/       # HomeScreen, SettingsScreen
│   │   │   └── widgets/       # AppMenuBar, SideBar, EditorTabBar, StatusBar
│   │   └── utils/             # PlatformUtils, FileUtils
│   ├── test/                  # 单元测试和组件测试
│   └── l10n.yaml              # 本地化配置
├── docs/
│   ├── vX.Y.Z/                # 版本设计文档（PRD、规格说明、实现计划）
│   └── i18n/                  # README 翻译（11 种语言）
├── scripts/
│   └── release.sh             # 自动化发布脚本
└── .claude/
    ├── CLAUDE.md              # 本文件（项目开发记忆）
    └── commands/
        └── release.md         # 发布流程文档
```

## 核心架构

四层架构 + Riverpod 状态管理：

- **UI 层** (`lib/ui/`): Flutter 组件、页面
- **状态层** (`lib/providers/`): Riverpod StateNotifier providers
- **服务层** (`lib/services/`): Markdown 解析、文件 I/O、导出
- **平台层**: Flutter platform channels, window_manager

## 关键技术决策

### 编辑器
- **自研 Markdown 编辑器**：自建解析器和渲染器（不依赖第三方编辑器库）
- **三种编辑模式**：
  - Source（TextField + 行号 + 语法高亮）
  - Preview（AST → Widget 树）
  - Split（可拖动分隔条 + 300ms 防抖同步）

### 状态管理
- **Riverpod**: 所有状态使用 StateNotifier 模式
- **JSON 配置**: 通过 ConfigService 直接读写文件（不使用 shared_preferences/hive）
- **配置存储位置**: 系统应用支持目录（`path_provider.getApplicationSupportDirectory()`）

### 国际化
- **flutter_localizations + intl + .arb 文件**
- **12 种语言**: en, zh, ja, ko, de, fr, it, ru, es, pt, ar, pt_BR
- **RTL 支持**: 阿拉伯语右对齐布局
- **ARB 键命名**: camelCase，带区域前缀（如 `settingsGeneral`, `menuFile`, `editUndo`）

### 主题系统
- **Token 化设计**: `AppThemeTokens` 包含 14 个颜色 token
- **8 个内置主题**: Red Graphite, Shibuya, Pink Blossom, Sky Blue, Dark Graphite, Dieci OLED, Nord, Midnight
- **自动明暗模式**: 主题自动判断明暗，无需独立开关

### Mermaid 图表
- **纯 Dart/Flutter 实现**: 不依赖 WebView
- **支持图表类型**: Flowchart, Sequence, Gantt, Pie, Radar, Timeline, XY Chart, Kanban
- **布局引擎**: Dagre + Sugiyama 分层布局
- **交互功能**: 复制源码按钮

## 开发规范

### 代码风格
- **沟通语言**: 中文
- **代码注释和标识符**: 英文
- **Provider 命名**: `xxxProvider` 用于 StateNotifierProvider
- **文件组织**: 每个组件一个文件，按功能分组而非按层级
- **测试结构**: `test/` 目录镜像 `lib/` 结构

### Git 工作流
- **主分支**: `main`（稳定版本）
- **开发分支**: `dev`（日常开发）
- **提交格式**: 
  - `feat: 新功能描述`
  - `fix: 修复问题描述`
  - `docs: 文档更新`
  - `chore: 构建/工具链更新`
  - `release: prepare vX.Y.Z`
- **发布流程**: 使用 `scripts/release.sh` 自动化发布

### 版本管理
- **语义化版本**: `major.minor.patch`
- **版本文档**: 每个版本在 `docs/vX.Y.Z/` 下维护 PRD 和 bugfix 文档
- **CHANGELOG**: 遵循 [Keep a Changelog](https://keepachangelog.com/) 规范

## 常用命令

所有命令在 `code/` 目录下执行：

```bash
# 安装依赖
flutter pub get

# 代码分析（必须 0 错误 0 警告）
flutter analyze

# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/services/markdown_parser_test.dart

# 构建发布版本
flutter build windows --release
flutter build linux --release
flutter build macos --release

# 生成本地化文件（修改 .arb 文件后）
flutter gen-l10n

# 清理构建缓存
flutter clean
```

## 发布流程

使用自动化脚本：

```bash
./scripts/release.sh 1.1.4
```

或手动执行（参考 `.claude/commands/release.md`）：

1. 更新 `code/pubspec.yaml` 版本号
2. 更新 `CHANGELOG.md` 添加版本条目
3. 提交并推送到 `dev` 分支
4. 合并到 `main` 分支
5. 创建并推送 tag

## 已知问题和限制

### Windows 平台
- **单实例模式**: 依赖 `windows_single_instance` 包，仅 Windows 支持
- **文件关联**: 需要通过 MSIX 安装包才能正确关联 `.md` 文件
- **换行符**: 已修复 `\r\n` 导致 Markdown 语法失效的问题

### Mermaid 渲染
- **复杂图表**: 超大型图表可能性能下降
- **语法支持**: 部分高级 Mermaid 语法尚未实现
- **导出**: HTML 导出使用 CDN（v11），PDF 导出不支持 Mermaid

### 配置迁移
- **V1.1.3 变更**: 配置目录从 `~/.marktext-plus/` 迁移到系统应用目录
- **旧配置**: 不会自动迁移，用户需手动重新配置

## 最近更新（V1.1.3）

### 新增功能
- Mermaid 图表渲染（纯 Dart/Flutter 实现）
- Mermaid 图表复制源码按钮
- 单实例模式与文件打开行为配置
- 首次启动询问文件打开偏好
- 表格单元格内 Markdown 内联语法渲染

### 修复
- Windows 换行符（`\r\n`）导致 Markdown 语法失效
- 配置目录创建位置错误（从文件目录改为系统应用目录）
- Mermaid CDN 版本升级（v10 → v11）

### 改进
- Mermaid 图表字体放大（16px）
- 配置存储迁移到系统应用目录

## 开发注意事项

### 性能优化
- **预览模式**: 使用 AST 缓存，避免重复解析
- **语法高亮**: 使用 `flutter_highlight` 包，支持 100+ 语言
- **大文件**: 超过 10MB 的文件可能导致卡顿

### 测试要求
- **单元测试**: 所有 service 和 provider 必须有测试覆盖
- **组件测试**: 关键 UI 组件需要 widget test
- **集成测试**: 发布前必须手动测试核心功能

### 代码审查
- **flutter analyze**: 必须通过，0 错误 0 警告
- **格式化**: 使用 `dart format` 格式化代码
- **命名规范**: 遵循 Dart 官方命名规范

## 参考资源

- [Flutter 官方文档](https://flutter.dev/docs)
- [Riverpod 文档](https://riverpod.dev/)
- [Markdown 规范](https://commonmark.org/)
- [Mermaid 文档](https://mermaid.js.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [语义化版本](https://semver.org/)

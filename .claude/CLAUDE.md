# MarkText Plus - 项目开发记忆

## 项目概览

基于 Flutter 构建的轻量级跨平台 Markdown 编辑器，重新设计自 [MarkText](https://github.com/marktext/marktext)。

- **当前版本**: V1.5.6（`dev` 上正在攒 V1.5.7）
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
│   └── install-linux-desktop.sh   # Linux 桌面项安装（没有 release.sh，见下）
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

### 版本号在两处
`code/pubspec.yaml` 的 `version:` 与 `code/lib/core/constants.dart` 的 `appVersion`，
发版时两处都要改，只改一处会让「关于」对话框和安装包版本对不上。

### 国际化
- **flutter_localizations + intl + .arb 文件**
- **12 种语言**: en, zh, ja, ko, de, fr, it, ru, es, pt, ar, pt_BR
- **RTL 支持**: 阿拉伯语右对齐布局
- **ARB 键命名**: camelCase，带区域前缀（如 `settingsGeneral`, `menuFile`, `editUndo`）

### 主题系统
- **Token 化设计**: `AppThemeTokens` 包含 14 个颜色 token
- **8 个内置主题**: Red Graphite, Shibuya, Pink Blossom, Sky Blue, Dark Graphite, Dieci OLED, Nord, Midnight
- **自动明暗模式**: 主题自动判断明暗，无需独立开关

### 插件窗格：标签页内的四宫格（定死，别再改）

**形状由填了几个窗格决定。** 文档默认占左上。

| 宫格数 | 布局 | 插件填了哪些槽位 |
|--------|------|-----------------|
| 一宫格 | 文档占满整个标签页 | 无 |
| 二宫格 | **左右分割**，各占一半 | 任意一个（槽位名不影响） |
| 三宫格 | 上下分割，**其中一半再左右分割** | 见下 |
| 四宫格 | 左上、右上、左下、右下，四格等大 | `right` + `bottom` + `corner` |

**三宫格的两种形态，由插件自己选**：

| 填了哪些 | 结果 |
|---------|------|
| `right` + 其一 | **上半**左右分割（文档 \| `right`），下半整行 |
| `bottom` + `corner`（不填 `right`） | 上半整行（文档），**下半**左右分割 |

槽位名对应位置：`right`＝右上、`bottom`＝左下、`corner`＝右下。只填一个窗格时
一律左右分割——一个窗格就是一个窗格，不管它自称什么。

**三宫格下读者还能自己切**：窗格标题栏有一个上下互换的按钮（`swap_vert`），
把分割的那一半换到另一边。插件的选择只决定**初始**形态；哪一半被分割是一种
看法，不是插件可以一直攥着的决定。二宫格没有第二行、四宫格两半都已分割，
所以那两种形态下不画这个按钮——一个按了没反应的按钮比没有按钮更糟。

分隔条可拖动，手感与源码/预览之间那根一致（8px、拖动高亮、resize 光标）。

**这是标签页内部的能力**，与左右侧边栏是两回事：

| 容器 | 归属 | 内容从哪来 |
|------|------|-----------|
| 四宫格 | 标签页**内部** | 插件主动 push（`pane` / `panel` 动作） |
| 左侧边栏 | 标签页**外部**，独立能力 | 编辑器自己的文件树/搜索/目录 |
| 右侧边栏 | 标签页**外部**，独立能力 | 点图标 pull（运行同名命令），无图标时整条隐藏 |
| 悬浮卡片 | 浮在文档区右上角 | 短答案与提问（`show` / `ask`），可拖可关 |

**曾经的错误做法，不要再犯：**

- 右侧 360px 固定条 + 底部 240px 固定带 —— 那是装饰条不是宫格，四格四个尺寸
- `PluginResultPanel`：贴最右的 380px 固定条，既非宫格也非侧边栏。**三选一的容器等于没有容器**——读者无从知道某个插件会用哪一个。已删除，`panel` 动作并入宫格
- 按槽位名决定落点 —— 只填 `corner` 会留下两个空格子

### Mermaid 图表
- **纯 Dart/Flutter 实现**: 不依赖 WebView
- **支持图表类型（22 种，全部接入渲染器）**: Flowchart, Sequence, Class, State, ER, Journey,
  GitGraph, Mindmap, Pie, Gantt, Timeline, Kanban, Radar, Quadrant, Requirement, Sankey,
  Block, C4, Treemap, Architecture, Packet, XY Chart
  （核实办法：`grep 'case DiagramType\.' lib/ui/editor/mermaid/parser/mermaid_parser.dart`）
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
- **主分支**: `main`（稳定版本）——**每次发版都必须把 dev 合并进 main**，并同步更新 README
- **开发分支**: `dev`（日常开发）
- **提交格式**: 
  - `feat: 新功能描述`
  - `fix: 修复问题描述`
  - `docs: 文档更新`
  - `chore: 构建/工具链更新`
  - `release: prepare vX.Y.Z`
- **发布流程**: 手工按 `.claude/commands/release.md` 执行（`scripts/release.sh` **并不存在**，
  该文档末尾只是给出了它的内容供参考）

### 版本管理
- **语义化版本**: `major.minor.patch`
- **CHANGELOG**: 遵循 [Keep a Changelog](https://keepachangelog.com/) 规范

### 版本文档规范（必须遵循）

每个版本在 `docs/vX.Y.Z/` 下维护两个文档：

**`bugfix.md`**（Bug 修复记录）：
- 开头**必须**有总览表格：`| 编号 | 日期 | 标题 | 优先级 | 状态 |`
- 表格后是每个 BUG 的详细记录（现象、根因分析、修复方案、涉及文件）

**`PRD_需求文档.md`**（功能需求文档）：
- 开头**必须**有总览表格：`| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |`
- 表格后是每个 FEAT 的详细需求（两列表格：字段|内容，包含实现日期、需求描述、用户场景、实现方案、涉及文件、验收标准）

**关键规则**：
- 每个新版本开发时，必须同时创建这两个文档
- **开发过程中实时更新**：每修复一个 bug 或实现一个功能，立即写入对应文档（不要等到发布时再补）
- 总览表格不能省略
- **发布前必须检查**：执行发布流程前，必须先读取两个文档，确认内容非空且覆盖本版本所有改动。如果为空，必须先补充完整再继续发布
- 参考格式：`docs/v1.2.0/` 和 `docs/v1.2.1/`

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

# 构建打包：不在本机做！
# 完整构建一次要 ~1.2GB 磁盘、几十秒 CPU，本机资源宝贵。
# 四个平台的包一律由 .github/workflows/release.yml 在 CI 上出。
# 推送前本地只跑：flutter test 与 dart analyze --fatal-infos lib test

# 生成本地化文件（修改 .arb 文件后）
flutter gen-l10n

# 清理构建缓存
flutter clean
```

## 发布流程

按 `.claude/commands/release.md` 手工执行（**没有** `scripts/release.sh`）：

1. 走完该文档的「发布前必须检查」六项
2. 更新 `code/pubspec.yaml` 与 `code/lib/core/constants.dart` 的版本号
3. **更新 README.md**（功能表、版本引用、截图路径）
4. 更新 `CHANGELOG.md`，把 `## [Unreleased] - vX.Y.Z` 改成 `## [vX.Y.Z] - 日期`
5. 提交并推送到 `dev`
6. **合并到 `main` 并推送**
7. 创建并推送 tag，由 CI/CD 出包（**本机不做完整构建**）

## 已知问题和限制

### Windows 平台
- **Windows on ARM**: 暂时做不了。GitHub 的 ARM runner 可用，引擎产物
  （`windows-arm64`）存在，flutter 工具也认 `TargetPlatform.windows_arm64` 并会给
  CMake 传 `-A ARM64`——但 `build_windows.dart` 只按宿主 ABI 选目标、没有开关，
  且 Flutter **不发布 arm64 的 Windows SDK**（`flutter_windows_arm64_*.zip` 为 404，
  releases 清单 732 条全是 x64）。等上游发包，理由记在 `.github/workflows/release.yml` 里
- **单实例模式**: 依赖 `windows_single_instance` 包，仅 Windows 支持
- **文件关联**: 需要通过 MSIX 安装包才能正确关联 `.md` 文件
- **换行符**: 已修复 `\r\n` 导致 Markdown 语法失效的问题

### Mermaid 渲染
- **复杂图表**: 超大型图表可能性能下降
- **语法支持**: 部分高级 Mermaid 语法尚未实现
- **导出**: HTML 导出把图表与高亮**内嵌**，普通文档零外链；只有含数学公式时仍从 jsdelivr 取 KaTeX（见 `html_export_offline_test`，这是仅剩的一处外链）。**PDF 与 Word 导出会把图表渲染成 PNG 嵌入**（`app_menu_bar._renderMermaidImages` 先离屏渲染，再交给 `ExportService`），单张渲染失败时跳过该图而不影响整篇

### 上标与下标只能作用于一个词

`^x^` 和 `~x~` 的语法定义就是「一段不含空白的文字」（`[^\s^]+`）。选中一个短语按格式菜单里的上标，会写出 `^the note above^`——**预览把它画成字面的尖括号**。

**这是有意留着的**，三条替代路都更糟：静默拒绝＝按了没反应；禁用菜单项要让菜单栏 watch 选区，而菜单栏常驻、光标一直在动；给提示要写 12 种语言，为一个「看一眼就明白、再按一次就撤销」的误操作。

写下来是因为它看起来像 bug。测试在 `source_editor_prefix_test`「raising a phrase writes markup this editor does not read back」，理由在 `SourceEditor.wrapMarkers` 上方。

### 配置迁移
- **V1.1.3 变更**: 配置目录从 `~/.marktext-plus/` 迁移到系统应用目录
- **旧配置**: 不会自动迁移，用户需手动重新配置

## 最近更新

**不要在这里维护版本流水账**——它会过期，而且已经有三处更权威的来源：

- `CHANGELOG.md`：面向用户的逐版说明
- `docs/vX.Y.Z/bugfix.md`：每个 BUG 的现象、根因、修复、验证
- `docs/vX.Y.Z/PRD_需求文档.md`：每个 FEAT 的需求与验收

只在这里记**跨版本仍然成立的结论**（见上面各节）。

### 排查缺陷时最有效的两条视角

反复奏效、值得优先用的：

1. **一条规则被抄了好几份，其中一份没跟上。** 标题、列表、强调、编码这些规则
   在解析器、语法高亮、格式动作、导出里各有一份实现，只要有一份没同步，
   用户就会看到「预览和源码区说法不一致」。修法是把规则收敛到解析器里，
   让其他地方来问它（如 `headingLevelOf` / `headingTextOf` / `continuesListItems`）。
2. **编辑器说了与事实不符的话。** 状态栏写的编码不是真正写盘的编码；
   工具栏显示的标题级别和预览画出来的不一致；染成粗体的内容预览并不加粗。

### 测试纪律

**每个修复都要先证明测试能失败**：把改动改回旧逻辑，确认失败条数和失败信息
正是预期的那种损坏。注意两种无效的"破坏"：改成不能编译（那是加载失败，
不是行为失败），以及改动的字段本来就永远不为 null（那什么也没证明）。

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

# MarkText Plus V1.3.0 Bug 修复记录

> 本版本目标：对齐源项目 [MarkText](../../../marktext)（Electron + Vue3 + Muya）的全部功能，
> 重点攻克 **预览页编辑（WYSIWYG）**、**Mermaid 渲染完整性**、**桌面文件关联** 三大块。

## 总览

| 编号 | 日期 | 标题 | 优先级 | 状态 |
|------|------|------|--------|------|
| BUG-001 | 2026-08-27 | 系统级文件关联缺失：deb 无 postinst、两种包均未装 MIME 定义 | P0 | Linux 已修复 / mac 待修复 |
| BUG-002 | 2026-08-27 | 预览模式为只读 Widget 树，无法所见即所得编辑 | P0 | 阶段一已完成 |
| BUG-003 | 2026-08-27 | Mermaid `classDiagram` 检测到类型后直接返回 null，无渲染 | P0 | 已修复 |
| BUG-004 | 2026-08-27 | Mermaid 缺失 erDiagram / journey / gitGraph / mindmap / quadrantChart 等类型 | P1 | erDiagram、journey、gitGraph、mindmap 已完成，其余待补 |
| BUG-005 | 2026-08-27 | Mermaid `_cleanLines` 粗暴剥离 `%%`，破坏 `%%{init:...}%%` 指令与标签内文本 | P1 | 已修复 |
| BUG-006 | 2026-08-27 | Mermaid `graph`/`flowchart` 检测强制要求尾随空格，`graph TD;` 等写法失配 | P1 | 已修复 |
| BUG-007 | 2026-08-27 | `markdown_renderer` 的 `_diagramLanguages` 与实际支持类型错配 | P2 | 已修复 |
| BUG-008 | 2026-08-27 | 不支持 PlantUML / Vega-Lite 代码块（源项目支持） | P2 | 待修复 |
| BUG-009 | 2026-08-27 | Linux 使用 G_APPLICATION_NON_UNIQUE，每打开一个文件就新开一个进程 | P1 | 已修复（运行时行为待人工验证） |
| BUG-010 | 2026-08-27 | 启动时弹出「如何打开文件？」模态框，反复出现 | P0 | 已修复 |
| BUG-011 | 2026-08-27 | `flutter analyze` 在干净树上报 17 个 info，CI 无法作为门禁 | P1 | 已修复 |
| BUG-012 | 2026-08-27 | 预览模式任务列表复选框不可点击（`onTaskToggle` 从未接线） | P2 | 已修复 |
| BUG-013 | 2026-08-27 | `AppConstants.appVersion` 与 pubspec 版本号不一致，更新检查误报 | P1 | 已修复 |
| BUG-014 | 2026-08-27 | 测试对含不确定型进度条的界面调 `pumpAndSettle()`，CI 挂起 20 分钟以上 | P1 | 已修复 |
| BUG-015 | 2026-08-27 | `mermaid_renderer.dart` 工具栏文案硬编码中文，未走 i18n | P2 | 已修复 |
| BUG-016 | 2026-08-27 | 预览模式双击编辑的手势识别器使块内复选框延迟约 300ms 才响应 | P2 | 已修复 |
| BUG-017 | 2026-08-27 | 行前缀无条件叠加：标题、列表、引用格式重复应用都会累积标记 | P1 | 已修复 |
| BUG-018 | 2026-08-27 | 行内格式无条件包裹：`**bold**` 再点粗体变成 `****bold****` | P1 | 已修复 |
| BUG-019 | 2026-08-27 | PDF 导出直接打印原始 markdown 标记，`**粗体**` 的星号出现在页面上 | P1 | 已修复 |
| BUG-020 | 2026-08-27 | 单行 HTML 标签吞掉文档剩余全部内容 | **P0** | 已修复 |
| BUG-021 | 2026-08-27 | Kanban 只接受 `id[标题]`，按官方文档写法解析失败 | P1 | 已修复 |
| BUG-022 | 2026-08-27 | 行内解析四处误判：转义失效、snake_case 变斜体、金额变公式、上标跨空格 | P1 | 已修复 |
| BUG-023 | 2026-08-27 | 嵌套列表被压平，子列表与父项同级显示 | P1 | 已修复 |
| BUG-024 | 2026-08-27 | 三条导出路径的列表均丢失层级；PDF/Word 丢格式，HTML 丢任务框 | P1 | 已修复 |
| BUG-025 | 2026-08-27 | 列表项续行被踢出列表；项间空行把一个列表拆成两个 | P1 | 已修复 |
| BUG-026 | 2026-08-27 | 不支持 setext 标题与缩进代码块两种 CommonMark 基本语法 | P2 | 已修复 |
| BUG-027 | 2026-08-27 | 导出时表格单元格丢失行内格式，`**粗体**` 原样输出 | P2 | 已修复 |
| BUG-028 | 2026-08-27 | 导出的 HTML 不渲染数学公式，代码块无语法高亮 | P2 | 已修复 |
| BUG-029 | 2026-08-27 | 导出的 HTML 中本地图片全部失效（相对路径不再成立） | P1 | 已修复 |
| BUG-030 | 2026-08-27 | 导出的 PDF 中图片完全不显示，只剩替代文字 | P1 | 已修复 |
| BUG-031 | 2026-08-27 | 导出的 Word 中图片不显示；mermaid 图表被拉伸变形 | P1 | 已修复 |
| BUG-032 | 2026-08-27 | 嵌套引用层级丢失，内层 `>` 作为字面文字显示 | P2 | 已修复 |
| BUG-033 | 2026-08-27 | 图片标题混入路径致图片加载失败；链接 URL 被括号截断 | P1 | 已修复 |
| BUG-034 | 2026-08-27 | 不支持自动链接与引用式链接；链接定义行作为正文显示 | P1 | 已修复 |
| BUG-035 | 2026-08-27 | 裸网址不自动成为链接（GFM 行为） | P2 | 已修复 |
| BUG-036 | 2026-08-27 | 段落内换行在 HTML 导出后消失 | P2 | 已修复 |
| BUG-037 | 2026-08-27 | HTML 字符实体不解码，预览显示字面量、导出二次转义 | P2 | 已修复 |
| BUG-038 | 2026-08-27 | 关闭未保存标签页无提示，新建文档内容永久丢失 | **P0** | 已修复 |
| BUG-039 | 2026-08-27 | 「关闭其他/右侧/全部标签页」同样无提示，一次丢失多个文件 | **P0** | 已修复 |
| BUG-040 | 2026-08-27 | 直接关闭应用窗口，全部未保存内容一并丢失 | **P0** | 已修复 |
| BUG-041 | 2026-08-27 | 更新提示无法关闭；新建文件名硬编码英文 | P2 | 已修复 |
| BUG-042 | 2026-08-27 | 窗口大小/位置存了却从不读取，每次启动都回到默认尺寸 | P1 | 已修复 |
| BUG-043 | 2026-08-27 | Tab 键不缩进；Tab 大小与列表标记两项设置形同虚设 | P1 | 已修复 |

---

## BUG-001 双击 .md 文件反复弹出「打开方式」选择

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P0 |
| 状态 | 待修复 |
| 现象 | 在系统文件管理器中双击 `.md` 文件，系统每次都弹出「选择打开方式」对话框，而不是直接用 MarkText Plus 打开 |
| 根因分析 | `code/linux/` 下只有 `CMakeLists.txt` / `flutter` / `resources` / `runner`，**没有 `.desktop` 文件，也没有 MIME 类型声明**。Linux 桌面环境依赖 `~/.local/share/applications/*.desktop` 中的 `MimeType=text/markdown;` 与 `xdg-mime` 数据库来决定默认程序；缺失时每次打开都会走「打开方式」询问流程。Windows 侧同样没有注册表 / MSIX 文件关联（`.claude/CLAUDE.md` 的「已知问题」已记录）。macOS 侧 `Info.plist` 缺 `CFBundleDocumentTypes` |
| 修复方案 | 1) 新增 `code/linux/marktext-plus.desktop`，声明 `MimeType=text/markdown;text/x-markdown;text/plain;`、`Exec=marktext_plus %F`；<br>2) 新增 `code/linux/marktext-plus.xml`（shared-mime-info），随包安装到 `/usr/share/mime/packages/`；<br>3) CMakeLists 增加 install 规则；<br>4) macOS `Runner/Info.plist` 补 `CFBundleDocumentTypes`；<br>5) Windows 侧提供 MSIX 配置或 NSIS 安装脚本注册 `HKCR\.md` |
| 涉及文件 | `code/linux/CMakeLists.txt`、`code/linux/marktext-plus.desktop`(新增)、`code/linux/marktext-plus.xml`(新增)、`code/macos/Runner/Info.plist`、`code/windows/` 打包配置 |

---

## BUG-002 预览模式为只读 Widget 树，无法所见即所得编辑

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P0 |
| 状态 | 待修复 |
| 现象 | 源项目 MarkText 的核心卖点是 WYSIWYG（在渲染结果上直接编辑）。本项目 Preview 模式只能看不能改，只有 Source 模式可编辑 |
| 根因分析 | `lib/ui/editor/markdown_renderer.dart`（920 行）把 AST 渲染成**只读** `Text.rich` / `Container` 组合，没有任何可编辑区域；`lib/ui/editor/source_editor.dart` 才是 `TextField`。二者是完全独立的两套渲染路径，缺少源项目 Muya 那样的「block 内容可编辑 + 光标映射回源码位置」机制 |
| 修复方案 | 分阶段：<br>**阶段一**（本版本）：块级就地编辑 —— 每个块渲染时记录其在源码中的 `[start,end)` 偏移；点击某块时把该块替换为一个内联 `TextField`（只承载该块源码），失焦/回车时写回全文对应区间。<br>**阶段二**：内联富文本编辑（粗体/斜体等在编辑态显示为标记、非编辑态显示为样式），对齐 Muya 的 `paragraphContent` 行为。<br>需要 `MarkdownParser` 为每个 AST 节点补充 `sourceStart` / `sourceEnd` 字段 |
| 涉及文件 | `lib/services/markdown_parser.dart`、`lib/ui/editor/markdown_renderer.dart`、`lib/ui/editor/split_editor.dart`、`lib/providers/editor_provider.dart` |

---

## BUG-003 Mermaid classDiagram 无渲染

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P0 |
| 状态 | 待修复 |
| 现象 | ` ```mermaid ` 代码块内写 `classDiagram` 时，图表区域空白/报错 |
| 根因分析 | `lib/ui/editor/mermaid/parser/mermaid_parser.dart:165` 处 `case DiagramType.classDiagram: return null;` —— 类型被正确识别，但**根本没有实现 `ClassDiagramParser`**（`parser/` 目录下无对应文件）。同时缺少 `painter/class_diagram_painter.dart` |
| 修复方案 | 新增 `parser/class_diagram_parser.dart`（支持 `class A { +int x; +foo() }`、继承 `A <|-- B`、组合 `A *-- B`、聚合 `A o-- B`、关联 `A --> B`、依赖 `A ..> B`、实现 `A <|.. B`、基数标签 `"1" --> "*"`、`<<interface>>` 注解、`note for A "..."`），复用 Dagre 分层布局，新增 `painter/class_diagram_painter.dart` 绘制三段式类框（名称 / 属性 / 方法）与七种关系箭头 |
| 涉及文件 | `lib/ui/editor/mermaid/parser/class_diagram_parser.dart`(新增)、`lib/ui/editor/mermaid/painter/class_diagram_painter.dart`(新增)、`lib/ui/editor/mermaid/models/class_diagram.dart`(新增)、`lib/ui/editor/mermaid/parser/mermaid_parser.dart` |

---

## BUG-004 Mermaid 缺失多种官方图表类型

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 待修复 |
| 现象 | 源项目使用 `mermaid@^11.15.0` 全量支持；本项目自研子集只覆盖 flowchart / sequence / pie / gantt / timeline / kanban / radar / xyChart / stateDiagram |
| 根因分析 | `_detectDiagramType` 未覆盖，且无对应 parser/painter |
| 修复方案 | 按使用频率排期补齐：**erDiagram（已完成）** → **journey（已完成）** → **gitGraph（已完成）** → **mindmap（已完成）** → quadrantChart → requirementDiagram → sankey-beta → block-beta → C4Context。<br>erDiagram 实现要点：`ArrowType` 新增四个 crow's foot 记号（`erZeroOrOne` / `erExactlyOne` / `erZeroOrMore` / `erOneOrMore`），十六种基数组合由左右两个两字符 token 分别映射；`ErDiagramLayout` 与类图同法继承 `DagreLayout` 只覆写节点测量，因为实体框高度取决于属性行数 |
| 涉及文件 | `lib/ui/editor/mermaid/parser/`、`lib/ui/editor/mermaid/painter/`、`lib/ui/editor/mermaid/models/` |

---

## BUG-005 Mermaid 注释剥离破坏 init 指令

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 待修复 |
| 现象 | 图表中写 `%%{init: {'theme':'forest'}}%%` 时该行被整行吞掉，主题指令失效；节点标签内含 `%%` 的文本被截断 |
| 根因分析 | `mermaid_parser.dart` 的 `_cleanLines()` 直接 `line.indexOf('%%')` 后截断，不区分：<br>1) `%%{...}%%` 是**指令**而非注释；<br>2) `%%` 出现在 `[]` / `()` / `""` 内部时属于标签文本 |
| 修复方案 | 重写 `_cleanLines()`：先匹配 `^\s*%%\{.*\}%%\s*$` 提取为 directive 并单独解析（至少支持 `theme`）；其余情况扫描时跟踪引号/括号状态，只在「括号外且引号外」的 `%%` 处截断 |
| 涉及文件 | `lib/ui/editor/mermaid/parser/mermaid_parser.dart` |

---

## BUG-006 flowchart 类型检测过严

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 待修复 |
| 现象 | `graph TD;`（含分号）、`flowchart-elk LR`、`graph` 单独成行等合法写法无法识别为流程图 |
| 根因分析 | `_detectDiagramType` 用 `firstLine.startsWith('graph ')` / `startsWith('flowchart ')`，强制要求关键字后紧跟空格 |
| 修复方案 | 改用正则 `^(graph|flowchart)(-elk)?\b` 匹配，并允许方向标识缺省（默认 `TD`） |
| 涉及文件 | `lib/ui/editor/mermaid/parser/mermaid_parser.dart` |

---

## BUG-007 代码块语言与图表类型错配

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P2 |
| 状态 | 待修复 |
| 现象 | ` ```pie ` / ` ```sequence ` / ` ```mindmap ` 等被当作 Mermaid 交给渲染器，但其中 `mindmap` / `classdiagram` / `erdiagram` / `journey` / `gitgraph` 根本没有 parser，直接白屏；反之源项目支持的 ` ```flowchart `（flowchart.js 语法，非 mermaid）被错误当成 mermaid 解析 |
| 根因分析 | `lib/ui/editor/markdown_renderer.dart:336` 的 `_diagramLanguages` 集合是硬编码清单，与 `MermaidParser._detectDiagramType` 的真实能力集没有单一事实来源 |
| 修复方案 | `MermaidParser` 暴露 `static bool handlesLanguage(String)`，从 `supportedTypes` 派生而非另立清单，实现新类型时两处不可能再脱节；`markdown_renderer` 改为调用它。解析失败时由 `describeParseFailure` 给出具体原因（见 BUG-003 相关改动），而非空白。<br>**行为变化**：` ```sequence ` 不再当作图表标签 —— 它是 js-sequence-diagrams 的标记而非 mermaid 类型名（mermaid 用 `sequenceDiagram`），此类代码块现按普通代码块高亮显示。对 flowchart.js / PlantUML / Vega-Lite 语法的真正支持见 BUG-008 |
| 涉及文件 | `lib/ui/editor/markdown_renderer.dart`、`lib/ui/editor/mermaid/parser/mermaid_parser.dart`、`lib/ui/widgets/mermaid_renderer.dart` |

---

## BUG-008 不支持 PlantUML / Vega-Lite

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P2 |
| 状态 | 待修复 |
| 现象 | 源项目 `packages/muya/src/state/markdownToHtml.ts` 支持 ` ```plantuml ` 与 ` ```vega-lite ` 代码块渲染，本项目完全不支持 |
| 根因分析 | 功能未实现 |
| 修复方案 | PlantUML：走远端 server 渲染（源项目同样是 `options.plantumlServer`），编码后取 PNG/SVG；Vega-Lite：纯 Dart 实现基础 mark（bar/line/point/area）子集 |
| 涉及文件 | `lib/ui/editor/markdown_renderer.dart`、新增 `lib/ui/editor/diagram/plantuml_renderer.dart`、`lib/ui/editor/diagram/vega_lite_renderer.dart` |

---

## BUG-009 Linux 无单实例，重复开进程

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 待修复 |
| 现象 | Linux 下连续打开多个 `.md` 文件会启动多个独立进程/窗口，而不是在已有窗口中新开标签页 |
| 根因分析 | `code/linux/runner/my_application.cc:147` 使用 `G_APPLICATION_NON_UNIQUE` 创建 GApplication，禁用了 GTK 自带的单实例仲裁。`lib/main.dart` 里的单实例逻辑用的是 `windows_single_instance`，**只在 Windows 生效**（`if (Platform.isWindows)`） |
| 修复方案 | 改用 `G_APPLICATION_HANDLES_OPEN`；`local_command_line` 把存在的文件参数交给 `g_application_open()` 而非一律 `activate`，GTK 便会把第二次启动转发给已持有 application ID 的进程；`my_application_open` 在该进程内通过 `com.marktextplus/files` channel 下发路径并 `gtk_window_present` 抬起窗口；Dart 侧在 `main.dart` 注册 handler，复用既有的 `TabNotifier.openFilesFromSecondInstance()`。<br>**注意**：CI 只能验证 C++ 能否编译，单实例的运行时行为需要人工在 Linux 桌面上连续双击两个 `.md` 文件确认 |
| 涉及文件 | `code/linux/runner/my_application.cc`、`code/linux/runner/my_application.h`、`lib/main.dart`、`lib/providers/tab_provider.dart` |

---

## BUG-010 启动时弹出「如何打开文件？」模态框

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P0 |
| 状态 | 已修复 |
| 现象 | 双击 `.md` 文件启动应用时，弹出标题为「如何打开文件？」的模态对话框，要求在「在新窗口打开 / 在当前窗口打开」之间选择。用户反馈该框**反复出现**，而非只出现一次 |
| 根因分析 | `lib/ui/screens/home_screen.dart` 的 `_openStartupFiles()` 在 `config.fileOpenBehavior == FileOpenBehavior.notSet` 时弹出该框并写回配置。**重复出现的根因未能静态定位**：持久化链路 `updateConfig` → `ConfigService.save` → `File.writeAsString` 无防抖、无并发覆盖，`addRecentFile` 等其他写入点也都基于当前 state，看不出保存的选择会在哪里丢失。此外该框在 Linux 上问的问题本身无意义 —— 见 BUG-009，Linux 端根本没有单实例，永远是新进程 |
| 修复方案 | 不再猜测根因，直接移除该交互：打开方式属于偏好设置，不应以模态框拦截启动。设置页 `settings_screen.dart` 早已存在完整的三选下拉框，`notSet` 现在直接按「在当前窗口打开」处理。上游 MarkText 同样把它作为设置项而非启动询问。副产物：连带移除了 `Radio` 的 `groupValue`/`onChanged` 两处废弃 API 用法 |
| 涉及文件 | `lib/ui/screens/home_screen.dart` |

---

## BUG-011 analyze 基线不干净，CI 无法作为门禁

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 新增 CI 后首次运行即失败。`flutter analyze` 在**未经改动的干净树**上就报 17 个 info，退出码非 0 |
| 根因分析 | 仓库此前只有 tag 触发的 `release.yml`，没有任何 push/PR 级别检查，因此 analyze 的技术债长期无人发现。17 个 info 全部来自既有代码：9 处 `withOpacity`、4 处悬挂库文档注释、`Matrix4.scale`、`Radio.groupValue`/`onChanged`、`ReorderableListView.onReorder` |
| 修复方案 | 新增 `.github/workflows/ci.yml`（analyze + test + Linux release build），并清空全部 17 个 info：`withOpacity` → `withValues(alpha:)`；补 `library;` 指令；`Matrix4.scale` → `scaleByDouble`；`onReorder` → `onReorderItem`（新回调报告的已是移除后索引，故 `reorderTabs` 去掉 off-by-one 调整，其仅有单一调用点且无测试依赖）；`Radio` 随 BUG-010 一并消失 |
| 涉及文件 | `.github/workflows/ci.yml`、`code/lib/ui/editor/mermaid/painter/{gantt,timeline}_painter.dart`、`code/lib/ui/editor/mermaid/{mermaid.dart,models/*.dart}`、`code/lib/ui/widgets/{mermaid_renderer,editor_tab_bar}.dart`、`code/lib/providers/tab_provider.dart` |

---

## BUG-012 预览模式任务列表复选框不可点击

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P2 |
| 状态 | 待修复 |
| 现象 | 预览模式下渲染出的任务列表 `- [ ] xxx` 复选框是灰的，点不动 |
| 根因分析 | `MarkdownRenderer` 已经预留了 `onTaskToggle` 回调，`markdown_renderer.dart:465` 也写了 `onChanged: widget.onTaskToggle != null ? ... : null`。但 `home_screen.dart:530` 构造预览模式的 `MarkdownRenderer` 时**根本没有传这个回调**，于是 `onChanged` 恒为 null，Flutter 把 Checkbox 渲染为禁用态。回调签名里的 `lineIndex` 命名也有误导 —— 传入的实际是列表项在 `ListNode.items` 中的下标，不是源码行号 |
| 修复方案 | 随 BUG-002 一并处理：`MarkdownRenderer` 改为接收统一的 `onSourceChanged(String)` 回调，任务勾选走 `MarkdownParser.replaceBlock` 重写该 `ListNode` 的源码行，不再需要单独的 `onTaskToggle` |
| 涉及文件 | `lib/ui/editor/markdown_renderer.dart`、`lib/ui/screens/home_screen.dart` |

---

## BUG-013 版本号不一致导致更新检查误报

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 已经在用 v1.2.3 的用户，启动后仍被提示「有新版本 1.2.3 可用」 |
| 根因分析 | `code/lib/core/constants.dart` 的 `AppConstants.appVersion` 停留在 `'1.2.2'`，而 `code/pubspec.yaml` 已是 `1.2.3+1`。`home_screen.dart:86` 用 `AppConstants.appVersion` 去和 GitHub Releases 的最新 tag 比对，于是把用户当前已装的版本判定为「更新」。两处版本号没有单一事实来源，发布流程只改了 pubspec |
| 修复方案 | 本次统一升至 `1.3.0`。**后续每次发版必须同时改这两处** —— 更彻底的做法是让 `appVersion` 从 `PackageInfo` 读取而不是硬编码，已列入待办 |
| 涉及文件 | `code/lib/core/constants.dart`、`code/pubspec.yaml` |

---

## BUG-014 widget_test 挂起 CI

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | CI 的 `flutter test` 步骤持续 20 分钟以上不结束 |
| 根因分析 | `test/widget_test.dart` 对整个 `MarkTextPlusApp` 调用 `pumpAndSettle()`。HomeScreen 会渲染**不确定型**的 `CircularProgressIndicator`（`home_screen.dart:472` 与 `:613`），其动画永不停止，`pumpAndSettle` 于是一直 pump 到自身超时，而不是快速失败。此外该测试把 `ConfigService` 指向固定路径 `/tmp/marktext-test`，启动时的更新检查会往里写 `lastUpdateCheck`，造成跨次运行的状态泄漏 |
| 修复方案 | 改用单次 `pump()`（断言只需要首帧即可成立）；配置目录改为每次运行独立的临时目录并注册 tear-down |
| 涉及文件 | `code/test/widget_test.dart` |

---

## BUG-015 Mermaid 工具栏文案硬编码中文

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P2 |
| 状态 | 待修复 |
| 现象 | 项目支持 12 种语言，但 Mermaid 图表工具栏在任何语言下都显示中文 |
| 根因分析 | `lib/ui/widgets/mermaid_renderer.dart` 直接写死了四处字面量：`'双击图表全屏查看'`(:134)、`'全屏'`(:138)、`'另存为'`(:151)、`'复制源码'`(:164)，没有走 `AppLocalizations`。`test/ui/widgets/mermaid_renderer_test.dart` 也因此用 `find.text('复制源码')` 定位按钮 —— 一旦接入 i18n，该测试需同步改为按 icon 或 Key 定位 |
| 修复方案 | 在 12 份 `.arb` 中新增 5 个 key（实际硬编码有 5 处，`'保存图表为 PNG'` 这条 tooltip 初次排查时漏了），并同步更新生成的 `app_localizations*.dart`。`mermaid_renderer.dart` 改用 `AppLocalizations.of(context)!`，三个按钮加上 `Key`，测试改为按 Key 定位并为测试用 `MaterialApp` 补上 `localizationsDelegates`（否则 `of(context)!` 直接抛异常）。**排查中发现既有欠债**：`updateAvailable` / `updateDismiss` 除中文外的 11 种语言全是英文占位，gen-l10n 回退到了模板 —— 新增的 5 个 key 均提供了真实译文 |
| 涉及文件 | `lib/ui/widgets/mermaid_renderer.dart`、`lib/core/i18n/l10n/*.arb`、`test/ui/widgets/mermaid_renderer_test.dart` |

---

## BUG-016 双击编辑手势拖慢块内交互元素

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P2 |
| 状态 | 已修复 |
| 现象 | 预览模式下点击任务列表的复选框，要等约 300ms 才勾上 |
| 根因分析 | BUG-002 阶段一给每个块套了 `GestureDetector(onDoubleTap: ...)`。该识别器会进入手势竞技场（gesture arena）并**保持等待**直到双击超时（`kDoubleTapTimeout`，300ms）才让位，块内 `Checkbox` 自己的 tap 识别器因此被推迟。由 `markdown_renderer_edit_test.dart` 的复选框用例暴露 —— 断言处 `onSourceChanged` 仍为 null，正是因为回调尚未触发 |
| 修复方案 | 含任务项的 `ListNode` 不再包裹双击识别器：勾选复选框远比编辑任务列表源码频繁，前者优先。此类块改从源码窗格编辑。<br>同一批测试还暴露了测试自身的缺陷：`doubleTap` 辅助函数结束时识别器的 40ms 计时器尚未跑完，导致 flutter_test 报 pending timer —— 末尾改 `pump(kDoubleTapTimeout)` 排空 |
| 涉及文件 | `lib/ui/editor/markdown_renderer.dart`、`test/ui/editor/markdown_renderer_edit_test.dart` |

---

## BUG-017 标题格式叠加

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 光标停在 `# Title` 上再点「标题 2」得到 `## # Title`；`- item` 再点「无序列表」得到 `- - item`；`> quote` 再点「引用」得到 `> > quote`；`1. item` 点「无序列表」得到 `- 1. item` |
| 根因分析 | `source_editor.dart` 的 `_insertLinePrefix` **无条件**在行首插入前缀，从不检查行上已有什么。六个标题动作、有序/无序/任务列表、引用块共 10 个动作全部走它。实现 Paragraph 菜单、阅读这段代码时发现，先只注意到标题，随后核对调用点才发现列表与引用同样受影响 |
| 修复方案 | 新增 `_setHeadingLevel(int? level)`：先用 `^(#{1,6})\s+` 剥掉已有标记再写入新级别，`level` 为 null 时还原为普通段落。六个标题动作改为调用它。<br>顺带补上 Paragraph 菜单缺失的三个动作：`promoteHeading`（提升，H2→H1，越过 H1 则还原为段落）、`demoteHeading`（降低，H1→H2，普通段落降级则从 H1 起步，H6 到顶不再变化）、`toParagraph`。默认快捷键 `Ctrl+=` / `Ctrl+-`，并为 `_labelToKey` 补上 `=` 与 `-` 的映射 |
| 补充修复 | 列表与引用改用 `SourceEditor.applyLinePrefix(line, prefix)`：同前缀切换关闭、同家族替换、保留缩进（缩进承载列表层级）。该函数提为公开静态纯函数以便单测 —— 通过 widget 测一行文本要搭一整个编辑器。<br>验证时抓到一处逻辑错误：`- [x] item` 应用「无序列表」曾得到 `[x] item`，因为它确实以 `- ` 开头而被判为「切换关闭」。改为比较家族匹配到的**完整**标记，`- [x] ` ≠ `- `，于是走替换分支得到 `- item` |
| 涉及文件 | `lib/ui/editor/source_editor.dart`、`lib/providers/editor_provider.dart`、`lib/ui/widgets/app_menu_bar.dart`、`lib/services/keybinding_service.dart`、`lib/core/i18n/l10n/*`、`test/ui/editor/source_editor_prefix_test.dart` |

---

## BUG-018 行内格式标记无条件叠加

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 选中已加粗的 `**bold**` 再点「粗体」，得到 `****bold****` 而不是取消加粗 |
| 根因分析 | 与 BUG-017 同源。`source_editor.dart` 的 `_wrapSelection(before, after)` **无条件**在选区两侧插入标记，从不检查选区是否已被同样的标记包裹。粗体、斜体、删除线、下划线、上标、下标、高亮、行内代码、行内公式共 9 个动作全部走它 |
| 修复方案 | 新增公开静态纯函数 `SourceEditor.toggleWrap(text, start, end, before, after)`，返回记录 `({String text, int start, int end})`。三种情形：<br>① 选区**包含**标记（用户选了 `**bold**`）→ 剥掉；<br>② 标记紧邻选区**外侧**（用户只选了 `bold`）→ 同样剥掉，这是更常见的选法；<br>③ 其余情况 → 包裹。<br>**关键细节**：对 `**bold**` 应用斜体时，它确实以 `*` 开头结尾，朴素判断会剥掉一层变成 `*bold*`。因此加了「双写标记属于更长语法」的保护 —— `before == after && selected.startsWith(before + before)` 时不走剥离分支，于是得到 `***bold***`（嵌套），与 Typora 行为一致 |
| 涉及文件 | `lib/ui/editor/source_editor.dart`、`test/ui/editor/source_editor_prefix_test.dart` |

---

## BUG-019 PDF / Word 导出泄漏原始 markdown 标记

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 导出 PDF 后，正文里能看到 `**粗体**`、`[链接](url)`、`` `代码` `` 这些标记符号本身，而不是渲染后的格式。Word 导出的引用块同样如此 |
| 根因分析 | AST 节点同时持有 `content`（**原始 markdown 源码**）与 `inlineSpans`（解析后的行内片段）。HTML 与 DOCX 的正文走 `inlineSpans`（正确），但 PDF 的标题与段落、以及 DOCX 的引用块走的是 `content`，于是标记原样进入输出。沿着 BUG-017/018「共用函数」的线索继续读 `export_service.dart` 时发现 |
| 修复方案 | 新增 `_inlineSpansToPdf(spans, baseStyle:)` 生成 `List<pw.TextSpan>`，覆盖全部 13 种 `InlineType`；PDF 的标题、段落、引用块改用 `pw.RichText`。DOCX 引用块改走 `_inlineSpansToDocxTexts` —— 代价是丢掉整段的斜体灰，但引用的视觉标识本就由段落级的左边框、缩进与底纹承载。<br>同时补齐 DOCX 行内覆盖：`highlight`（底纹）、`footnoteRef`（上标）、`mathInline`（Cambria Math 斜体）、`image`（保留 alt 文本），并**移除 `default` 分支**使 switch 穷尽 —— 今后新增 `InlineType` 会由编译器报出，而不是静默降级为纯文本 |
| 已知遗留 | 脚注定义仍走原始文本。表格单元格已于 BUG-027 解决 |
| 涉及文件 | `lib/services/export_service.dart` |

---

## BUG-020 单行 HTML 标签吞掉文档剩余内容

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | **P0** |
| 状态 | 已修复 |
| 现象 | 文档里只要出现一行 `<div class="x">文字</div>`（开闭标签同行），**该行之后的所有内容在预览中全部消失**。`<br>`、`<img />` 等同理 |
| 根因分析 | `markdown_parser.dart` 的 HTML 块分支先把当前行收进块、随即 `i++` **跳过它**，然后从下一行开始搜索 `</tag>`。而闭标签就在刚跳过的那一行，于是永远搜不到，循环一路走到文件末尾，把后续所有块并入这一个 `HtmlBlockNode`。<br>void 元素（`<br>`、`<hr>`、`<img>`）和自闭合写法（`<img />`）从来就没有闭标签，同样会吞掉全文；用户漏写闭标签时亦然 |
| 发现方式 | **端到端 fixture 测试**。此前每个测试只解析独立片段，而这个 bug 需要「HTML 块 + 其后还有内容」的组合才会显形。`showcase.md` 里那行 `<div class="note">…</div>` 之后的 14 个 mermaid 图表全部消失，测试报告 `fence languages found: [dart, ]`，据此定位 |
| 修复方案 | 三种情形提前判定为「块到此为止」：当前行已含闭标签、行尾是 `/>`、标签属于 void 元素表。其余情况**先扫描**闭标签位置再消费 —— 找不到就只占一行，未闭合的标签代价是一行而非整篇文档 |
| 涉及文件 | `lib/services/markdown_parser.dart`、`test/services/markdown_parser_test.dart` |

---

## BUG-021 Kanban 仅接受一种列/任务写法

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 照 mermaid 官方文档写的 kanban 图整个渲染不出来 |
| 根因分析 | `kanban_parser.dart` 的列正则是 `^(\w+)\[([^\]]+)\]...$`，任务正则是 `^(\w+)\[([^\]]+)\]...$` —— 两者都**强制要求 id 前缀加方括号**。而 mermaid 文档里三种写法混用：裸标题 `Todo`、无 id 的 `[In progress]`、带 id 的 `docs[写博客]`。只要出现前两种，列表为空，`parse` 返回 null，整图不渲染 |
| 发现方式 | showcase fixture 的 kanban 段落按官方风格书写（裸列名 + 裸任务），BUG-020 修复后测试推进到逐图解析，随即报 `failed to parse: kanban` |
| 修复方案 | 列与任务正则改为三选一：`id[标题]` / `[标题]` / 裸文本，`wip:N` 与 `@{...}` 元数据后缀保持可选。缺 id 时以标题文本兜底作为 id —— 渲染本就只显示标题 |
| 涉及文件 | `lib/ui/editor/mermaid/parser/kanban_parser.dart`、`test/ui/editor/mermaid/mermaid_parser_test.dart` |

---

## BUG-022 行内解析的四处误判

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 四种日常写法被错误识别：<br>① `\*字面星号\*` —— 反斜杠转义无效，仍被当斜体；<br>② `snake_case_name` —— 中间的 `_case_` 被当斜体，代码标识符与文件名普遍中招；<br>③ `价格 $5 和 $10` —— `$5 和 $` 被当行内公式；<br>④ `x^2 and y^3` —— `^2 and y^` 被当上标 |
| 根因分析 | `parseInline` 用单条组合正则扫描全部行内语法。三处分支边界过宽：`_(.+?)_` 未排除词内下划线（CommonMark 规定 `_` 不可 intraword，而 `*` 可以）、`\$([^$]+)\$` 未要求两端非空白、`\^(.+?)\^` 与下标同样允许内含空格。转义则完全未实现 —— 十四个分支的组合正则无法逐个回看反斜杠 |
| 修复方案 | 前三者收紧正则：`$` 与 `^`/`~` 要求内容两端非空白，`_`/`__` 加 `(?<![a-zA-Z0-9])`/`(?![a-zA-Z0-9])` 边界。转义改为**预处理**：先把 `\<标点>` 替换为私有区哨兵字符（U+E000 起），正则扫描完再在每个 span 上还原为不带反斜杠的原字符。私有区共 6400 个码位，超出部分保持原样不替换 |
| 涉及文件 | `lib/services/markdown_parser.dart`、`test/services/markdown_parser_test.dart` |

---

## BUG-023 嵌套列表被压平

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 预览中子列表与父项左对齐，看不出层级 |
| 根因分析 | `_ulRe`/`_olRe` 的 `^[\s]*` 能匹配任意缩进，但缩进量随即被丢弃；`ListItem` 也没有承载层级的字段，一个 `ListNode` 的 items 是完全扁平的 |
| 修复方案 | `ListItem` 新增 `depth`。深度取自**该列表内各缩进宽度的排序位次**，而非固定空格数 —— 作者用 2 空格或 4 空格缩进都会得到 0、1、2，而不是 1、2 与 2、4。两个列表分支合并到共用的 `_buildListItems`，消除了原本重复的任务项解析逻辑 |
| 涉及文件 | `lib/services/markdown_parser.dart`、`lib/ui/editor/markdown_renderer.dart`、`test/services/markdown_parser_test.dart` |

---

## BUG-024 导出路径的列表缺陷

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 三条导出路径各有缺失：<br>① HTML —— 所有 `<li>` 平级，嵌套结构消失；任务项的复选框状态**完全丢失**（parser 已剥掉 `[ ]`，导出未补回）；<br>② PDF —— 列表项走 `_inlineSpansToText`，格式全丢且不缩进；<br>③ Word —— 同 PDF，且经 `builder.bullet(List<String>)` 只能传纯字符串 |
| 根因分析 | BUG-023 让 `ListItem` 有了 `depth`，但只有预览用上了。导出端此前也从未表达过层级 —— HTML 生成的是一段扁平 `<li>`，PDF/Word 则连行内格式都还停留在纯文本（BUG-019 当时只改了标题、段落、引用） |
| 修复方案 | HTML 改由 `_listToHtml` 按 depth 变化开合嵌套 `<ul>/<ol>`，任务项输出 `<input type="checkbox" disabled>`；PDF 列表项改用 `pw.RichText` + 按 depth 缩进；Word 弃用 `builder.bullet`，改为手工构建带 `indentLeft` 的 `DocxParagraph` 并走 `_inlineSpansToDocxTexts`。<br>有序列表的编号改为**按层级各自计数**，嵌套列表重新从 1 开始，而非沿用父级序号。<br>`_inlineSpansToText` 至此无人调用，已删除 |
| 涉及文件 | `lib/services/export_service.dart`、`test/fixtures_showcase_test.dart` |

---

## BUG-025 列表被续行与空行拆散

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | ① 列表项换行续写时，续行掉出列表变成独立段落，一个列表被拆成「列表 / 段落 / 列表」三块；② 列表项之间空一行，就变成两个互不相干的列表 |
| 根因分析 | 收集列表项的循环是 `while (i < lines.length && itemRe.hasMatch(lines[i]))` —— 只要当前行不匹配列表标记就立即停止。续行（缩进但无标记）和项间空行都不匹配，于是都被判为列表结束 |
| 修复方案 | 抽出 `_collectListItems`，返回「每项一组行」加列表结束位置。空行只有在其后不再有列表项时才结束列表；缩进的无标记行归属上一项。`_buildListItems` 相应改为接收每项的行组，续行以空格拼接（markdown 的软换行渲染为空格） |
| 验证要点 | 「列表后跟普通段落」必须仍拆成两个块 —— 空行之后不是列表项，列表就该结束。已作为测试固定下来 |
| 涉及文件 | `lib/services/markdown_parser.dart`、`test/services/markdown_parser_test.dart` |

---

## BUG-026 缺失 setext 标题与缩进代码块

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P2 |
| 状态 | 已修复 |
| 现象 | ① `标题` 下一行写 `=====` 或 `-----`（setext 写法）不生成标题，`=====` 原样显示为正文；② 用 4 空格缩进写的代码块被当普通段落，既无等宽字体也无背景 |
| 根因分析 | `_headingRe` 只覆盖 ATX 的 `#` 写法；代码块只有围栏 `_codeFenceRe` 一种。两者都是 CommonMark 基本语法 |
| 修复方案 | setext 检测放在段落分支之前 —— 它依赖**下一行**，无法与 ATX 写法并列判断。`---` 的歧义由分支顺序自然解决：单独一行的 `---` 已被前面的水平线分支消费，能走到 setext 检测就说明它前面有正文，而这正是 CommonMark 判定为标题下划线的条件。<br>缩进代码块要求前一行为空行或文档开头，因此不会打断段落（符合 CommonMark）；列表分支在其之前，故缩进的 `- item` 仍是嵌套列表而非代码 |
| 涉及文件 | `lib/services/markdown_parser.dart`、`test/services/markdown_parser_test.dart` |

---

## BUG-027 导出时表格单元格丢失行内格式

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P2 |
| 状态 | 已修复 |
| 现象 | 表格里写 `**粗体**` 或 `[链接](url)`，**预览正常**，但导出 HTML/PDF 后变成字面标记 |
| 根因分析 | `TableNode` 的 `headers`/`rows` 是纯 `List<String>`，不带 `inlineSpans`。预览端 `markdown_renderer` 渲染单元格时会调用 `parseInline`，所以显示正确；导出端却直接把原始字符串交给 `_escapeHtml` / `_normalizeForPdf`，标记原样输出。<br>**预览与导出对同一份数据采取了不同处理**，是这类不一致的典型来源 |
| 修复方案 | 导出端同样在渲染单元格时解析行内内容（`_cellParser.parseInline`），HTML 走 `_inlineSpansToHtml`（自带转义，不再需要 `_escapeHtml`），PDF 走 `_inlineSpansToPdf` + `pw.RichText` |
| 涉及文件 | `lib/services/export_service.dart`、`test/fixtures_showcase_test.dart` |

---

## BUG-028 导出的 HTML 缺少公式渲染与代码高亮

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P2 |
| 状态 | 已修复 |
| 现象 | 应用内预览正常的文档，导出 HTML 后：数学公式变成原始 LaTeX（如 `\[\int_0^1 x^2 dx\]`），代码块是纯黑白无着色 |
| 根因分析 | HTML 模板只引入了 mermaid 的 CDN，没有 KaTeX 与 highlight.js。预览端用 `flutter_math_fork` 渲染公式、用 `flutter_highlight` 着色代码，导出端两者皆无 —— 又一处「预览与导出对同一内容采取不同处理」<br>此外数学块被输出为 `<pre class="math-block">`，而 KaTeX 的 auto-render **刻意跳过 `pre` 与 `code` 元素**，即便引入 KaTeX 也不会渲染 |
| 修复方案 | 引入 KaTeX（CSS + JS + auto-render）与 highlight.js（CSS + common 包），脚本置于 body 末尾以确保内容已存在；数学块由 `<pre>` 改为 `<div>`。<br>**易错细节**：auto-render 的分隔符在 Dart 中须写作 `'\\['`，生成的 JS 才是 `'\['`。若只写一个反斜杠，JS 中 `\[` 属无效转义会退化为 `[`，分隔符便与实际输出的 `\[ ... \]` 对不上，公式依旧不渲染 |
| 涉及文件 | `lib/services/export_service.dart` |

---

## BUG-029 导出的 HTML 图片失效

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 文档中 `![图](assets/pic.png)` 在应用内显示正常，导出 HTML 后把文件移走或发给别人，**所有本地图片裂开** |
| 根因分析 | `<img src="$src">` 直接沿用原始相对路径，而该路径是相对**原文档目录**的。导出的 HTML 通常会被移动或转发，相对路径随即失效。<br>原文档路径其实是已知的（`activeTab.filePath`），只是 `exportToHtml` 的签名里没有这个参数 |
| 修复方案 | `exportToHtml` 新增可选的 `sourcePath`，导出前扫描 AST 收集本地图片、读入并转为 `data:` URI 内联，使 HTML 自包含。远程 URL 与已有的 `data:` 保持原样；单张超过 8 MB 的图片不内联（base64 会膨胀约三分之一，避免生成打不开的文件）；文件缺失或不可读时退回原路径，不让导出失败。<br>**细节**：data URI **不可**再经 `_escapeHtml`，否则 base64 尾部的 `=` 会变成实体而损坏图片 |
| 涉及文件 | `lib/services/export_service.dart`、`lib/ui/widgets/app_menu_bar.dart`、`test/services/export_image_test.dart` |

---

## BUG-030 导出的 PDF 不显示图片

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 文档中的图片导出 PDF 后完全消失，位置上只留下替代文字 |
| 根因分析 | `_inlineSpansToPdf` 的 `InlineType.image` 分支只回传 `pw.TextSpan(text: alt)`。PDF 侧其实**已经具备嵌图能力** —— mermaid 图表正是通过 `pw.Image(pw.MemoryImage(bytes))` 嵌入的，只是文档图片从未接上这条路 |
| 修复方案 | `exportToPdf` 同样接收 `sourcePath`，复用 BUG-029 新增的图片读取逻辑（抽出 `_readLocalImages` 返回字节与 MIME，HTML 侧再转 data URI，两条导出路径共用同一次文件读取）。段落若**仅含一个图片 span**，整段渲染为 `pw.Image`。<br>**未覆盖**：混在句子中间的行内图片仍显示替代文字 —— pdf 包的富文本无法在行内嵌入 widget；SVG 也跳过，`MemoryImage` 不能解码 |
| 涉及文件 | `lib/services/export_service.dart`、`lib/ui/widgets/app_menu_bar.dart` |

---

## BUG-031 Word 导出的图片缺失与变形

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | ① 文档图片导出 Word 后不显示，只剩替代文字；② mermaid 图表虽能嵌入，但一律被压成 400×300，**非 4:3 的图全部变形** |
| 根因分析 | 与 BUG-030 同源：`docx_creator` 的 `DocxImage` 早已在用（mermaid 走的就是它），文档图片却没接上。变形则是因为调用处把 `width: 400, height: 300` 写死 |
| 修复方案 | `exportToDocx` 接收 `sourcePath`，复用 `_readLocalImages`；仅含一个图片 span 的段落整段渲染为 `DocxImage`。<br>新增 `_imageSize` 从**文件头**读取真实像素尺寸：PNG 取 IHDR（偏移 16..24），GIF 取逻辑屏幕描述符（小端），JPEG 扫描至 SOF 段。如此无需引入图像解码包即可保持宽高比。`_fittedImageSize` 在此基础上限制最大宽度 450pt（A4 可打印宽度），mermaid 图表一并受益 |
| 涉及文件 | `lib/services/export_service.dart`、`lib/ui/widgets/app_menu_bar.dart`、`test/services/export_image_test.dart` |

---

## BUG-032 嵌套引用层级丢失

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P2 |
| 状态 | 已修复 |
| 现象 | `>> 内层引用` 渲染时层级消失，且多出来的 `>` 作为**字面文字**显示在引用内容里 |
| 根因分析 | `_blockquoteRe` 为 `^>\s?(.*)$`，只剥一个 `>`，剩下的 `> 内层` 被当作正文；`BlockquoteNode` 也没有承载层级的字段 |
| 修复方案 | 正则改为 `^(>+)\s?(.*)$` 捕获标记串长度作为层级。连续同层级的行合并为一个 `BlockquoteNode`，层级变化即另起一个节点 —— 完整的递归容器模型改动过大，而按层级切分足以正确表达嵌套且改动可控。预览按 depth 缩进；HTML 导出以**嵌套 `<blockquote>`** 表达（这正是 HTML 表示「引用中的引用」的方式），PDF 与 Word 按 depth 缩进 |
| 涉及文件 | `lib/services/markdown_parser.dart`、`lib/ui/editor/markdown_renderer.dart`、`lib/services/export_service.dart`、`test/services/markdown_parser_test.dart` |

---

## BUG-033 链接与图片的 URL 解析缺陷

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | ① `![图](pic.png "标题")` 的 `src` 变成 `pic.png "标题"`（含引号），**图片必然加载失败**；② `[wiki](https://en.wikipedia.org/wiki/Foo_(bar))` 的 URL 被截断为 `...Foo_(bar`，链接失效 —— 维基百科等带括号的链接极为常见 |
| 根因分析 | link/image 的 URL 部分写作 `\(([^)]+)\)`：遇到第一个 `)` 即停止（截断带括号的 URL），且不区分标题（把 `"标题"` 一并吞进路径）|
| 发现方式 | **本地 `dart run`**。`markdown_parser.dart` 仅依赖 `dart:convert`，无 Flutter 依赖，可直接用 `dart run` 加载并批量试探各种行内语法，无需 `pub get`，亦无需等待 CI |
| 修复方案 | URL 部分改为 `((?:[^()\s"]|\([^()]*\))+)`（允许一层平衡括号），其后接可选的 `(?:\s+"([^"]*)")?` 标题组。<br>**代价**：link/image 各新增一个捕获组，其后全部 12 个分支的组号整体后移 2 位。批量重排时出错 —— 手工改写的分支开头 `group(7)` 落入替换区间被二次替换，导致「条件用 9、取值用 7」，`$E=mc^2$` 当场空断言崩溃。本地一跑即现原形并修正；若推给 CI，只会得到一条测试失败信息，且要等五分钟 |
| 涉及文件 | `lib/services/markdown_parser.dart`、`test/services/markdown_parser_test.dart` |

---

## BUG-034 自动链接与引用式链接缺失

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | ① `<https://example.com>` 不成为链接，且位于行首时**被误判为 HTML 块**；② `[文字][ref]` 不成为链接；③ 最严重：链接定义行 `[ref]: https://…` 直接**作为正文显示给用户** |
| 根因分析 | 行内正则没有自动链接与引用式链接两种形式；`_htmlBlockStartRe` 为 `^<(\w+)`，`<https://…>` 中的 `https` 被当作标签名；链接定义行不被任何分支识别，落到段落分支当作普通文字 |
| 修复方案 | HTML 块正则改为 `^<([a-zA-Z][a-zA-Z0-9-]*)(?=[\s/>])` —— 标签名后必须跟着能开启属性或闭合标签的字符，`<https` 后是 `:` 故被排除。<br>行内新增自动链接与 `[文字][标签]`；`parse()` 开头**预扫描**收集全部定义（引用可能出现在定义之前），定义行本身不生成节点。未能解析的引用保持原样文本，而非生成指向空处的链接。<br>**关键取舍**：两个新形式的捕获组一律**追加在正则末尾**（组 19–21），使既有 18 个组的编号完全不动 —— BUG-033 中间插入捕获组导致组号重排出错的教训 |
| 涉及文件 | `lib/services/markdown_parser.dart`、`test/services/markdown_parser_test.dart` |

---

## BUG-035 裸网址不自动链接

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P2 |
| 状态 | 已修复 |
| 现象 | 直接写 `https://example.com`（不加尖括号、不写成 `[]()`）不会成为链接，而 GitHub、Typora 等均会自动识别 |
| 根因分析 | 行内正则只覆盖 `[]()`、`<>` 两种形式，未包含 GFM 的裸网址 |
| 修复方案 | 追加为**最后一个**分支（组 22），确保已位于 `[]()` 或 `<>` 内的网址先被对应分支消费，不会重复匹配。末尾标点（`. , ; : ! ?`）从链接中剥离并作为独立文本 span 补回 —— 「见 https://example.com。」中的句号属于句子而非网址 |
| 涉及文件 | `lib/services/markdown_parser.dart`、`test/services/markdown_parser_test.dart` |

---

## BUG-036 段落内换行在 HTML 导出后消失

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P2 |
| 状态 | 已修复 |
| 现象 | 段落内换行（软换行）在预览中正常断行，导出 HTML 后被并成一行 |
| 根因分析 | 段落 span 的文本保留 `\n`。预览端 Flutter 的 `Text` 直接渲染换行；Word 端 `docx_creator` 的 `DocxText` 会将 `\n` 输出为 `w:br`；PDF 的 `RichText` 同样保留 —— **唯独 HTML**：`<p>` 中的裸换行符会被浏览器折叠为空格 |
| 修复方案 | `_inlineSpansToHtml` 中将转义后文本的 `\n` 替换为 `<br>`。行内代码不跨行（`` `[^`]+` `` 不匹配换行），故不受影响 |
| 涉及文件 | `lib/services/export_service.dart`、`test/fixtures_showcase_test.dart` |

---

## BUG-037 HTML 字符实体不解码

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P2 |
| 状态 | 已修复 |
| 现象 | 文档中写 `&amp;`，预览原样显示 `&amp;` 而非 `&`；导出 HTML 时 `_escapeHtml` 又把其中的 `&` 转成 `&amp;`，产生 `&amp;amp;`，浏览器最终显示 `&amp;` —— **二次转义** |
| 根因分析 | `parseInline` 从不解码字符实体，文本原样进入 span |
| 修复方案 | 解析末尾对每个 span 解码实体：命名实体覆盖常用一批（`amp`/`lt`/`gt`/`quot`/`nbsp`/`copy`/`mdash` 等），数字实体支持十进制与十六进制。<br>三项边界：超出 Unicode 范围或落在代理区的码点保持原样，不生成非法字符串；未知实体名保持原样；**行内代码内的实体不解码**（CommonMark 规定代码片段逐字保留）。<br>解码后 span 持有真实字符 `&`，各导出端再各自转义一次，恰好正确 |
| 涉及文件 | `lib/services/markdown_parser.dart`、`test/services/markdown_parser_test.dart` |

---

## BUG-038 关闭未保存标签页导致内容丢失

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | **P0** |
| 状态 | 已修复 |
| 现象 | 新建文档 → 输入内容 → 点标签页的 × → **内容永久丢失，无任何提示** |
| 根因分析 | `editor_tab_bar.dart` 的关闭按钮直接调用 `removeTab`，不检查 `isModified`。<br>自动保存虽默认开启，却帮不上忙：`_performAutoSave` 开头即 `if (tab.filePath == null) return` —— **从未保存过的新建文档没有路径，根本不参与自动保存**。已存盘的文件尚有自动保存兜底，新建文档则是彻底丢失。<br>更值得注意的是：`unsavedChanges` / `unsavedChangesMessage` / `save` / `dontSave` / `cancel` 这套文案**在 12 种语言中一应俱全，但代码中一处引用都没有** —— 该对话框设计完毕却从未接线 |
| 修复方案 | 关闭前检查 `isModified`，弹出三选对话框（取消 / 不保存 / 保存），复用既有文案。「保存」时若文档尚无路径则先走另存为；**用户取消另存为，或写入失败，均中止关闭** —— 否则恰恰丢掉了保存想要保护的内容。<br>`removeTab` 本身保持不变：确认属于 UI 层职责，provider 层不应弹窗 |
| 相关 | 自动保存失败时 `catch` 为空。此处**行为本身正确**（标签页保持已修改状态，关闭确认仍会触发，状态栏圆点仍在），已补注释说明缘由，避免后人误以为是遗漏而「修正」成静默 `markSaved` |
| 涉及文件 | `lib/ui/widgets/editor_tab_bar.dart`、`lib/providers/tab_provider.dart` |

---

## BUG-039 批量关闭标签页丢失多个文件

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | **P0** |
| 状态 | 已修复 |
| 现象 | 标签页右键菜单的「关闭其他标签页」「关闭右侧标签页」「关闭全部标签页」不作任何询问，**一次丢失多个未保存文件** |
| 根因分析 | 与 BUG-038 同源。`closeOtherTabs` / `closeTabsToRight` / `closeAllTabs` 均不检查 `isModified`，UI 层直接调用。修完单个关闭后顺藤摸到此处 —— 影响面比单个关闭更大 |
| 修复方案 | 三者统一走 `_closeMany`：先筛出将被关闭的未保存标签，逐一**列出文件名**再询问（批量场景下不列名，用户无从判断将丢失什么），最多列 5 个、其余以计数概括。选择「保存」时逐个保存，**任一保存被取消即中止整个操作** —— 继续关闭其余标签仍会丢掉这一个的内容。`saveTab` 提升为静态方法以便复用 |
| 附带核实 | `FileWatcherService` 仅用于刷新侧边栏文件树，**不重载已打开标签页的内容**，故外部修改不会覆盖本地未保存的编辑 —— 此处无缺陷 |
| 涉及文件 | `lib/ui/widgets/editor_tab_bar.dart` |

---

## BUG-040 关闭应用窗口丢失全部未保存内容

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | **P0** |
| 状态 | 已修复 |
| 现象 | 编辑若干文件后直接点窗口的 ×，**所有未保存内容一次性丢失**，无任何提示 |
| 根因分析 | 代码中**完全没有窗口关闭拦截** —— 既无 `windowManager.setPreventClose`，也无 `WindowListener`。`main.dart` 里 `didChangeAppLifecycleState` 虽处理了 `detached`，但那只保存窗口尺寸，且此刻进程已在退出途中，既无法阻止关闭，也无法弹出对话框。<br>这是三个关闭场景中**影响最大**的一个：单个标签页丢一个文件，批量关闭丢若干个，关窗口丢整个会话 |
| 修复方案 | 在 `HomeScreen` 混入 `WindowListener` 并 `setPreventClose(true)`，于 `onWindowClose` 中检查全部标签页。<br>**监听器必须放在这里而非 `main.dart` 的 `_AppLifecycleWrapper`**：后者位于 `MaterialApp` 之外，既无 `Navigator` 也无 `Localizations`，无法弹出本地化对话框。<br>确认后调用 `windowManager.destroy()` 真正退出；任一保存被取消则中止退出。`setPreventClose` 包在 try/catch 中 —— 无窗口环境（如测试）下应保持原有行为 |
| 涉及文件 | `lib/ui/screens/home_screen.dart` |

---

## BUG-041 两处「半截功能」

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P2 |
| 状态 | 已修复 |
| 现象 | ① 状态栏的新版本徽标**无法关闭**，只要检测到新版就一直挂着；② 新建文档的标签名恒为英文 `Untitled`，中文等界面下亦然 |
| 发现方式 | **系统性排查**：BUG-038 暴露出「文案齐全但代码从未引用」这一模式，遂用脚本比对 `app_en.arb` 的 247 个 key 与 `lib/` 中的实际引用，得到 21 个未引用项，逐一核对成因 |
| 排查结论 | 21 项中：4 项属 BUG-010 移除弹窗后的残留、2 项属 v1.2.0 移除按钮后的残留（均为预期）；`noRecentFiles` / `openRecentFiles` 等与 `fileNoRecentFiles` 等**重复定义**，实际使用的是后者；`editFindInFiles` / `comingSoon` 对应尚未实现的功能；真正的缺陷是本条的两项 |
| 根因分析 | ① `UpdateNotifier.dismiss()` 与文案 `updateDismiss` 均已就绪，**却没有任何 UI 调用** —— `dismissed` 恒为 false；徽标也只显示版本号，未使用 `updateAvailable` 说明这是什么。② `TabInfo.fileName` 默认值硬编码 `'Untitled'`，而 `TabInfo` 是纯模型、无从获取本地化 |
| 修复方案 | ① 徽标拆为两个可点区域：版本号跳转下载页（tooltip 用 `updateAvailable`），旁加关闭按钮调用 `dismiss()`（tooltip 用 `updateDismiss`）；② 由持有 `l10n` 的 `_newFile` 传入 `l10n.untitled` |
| 涉及文件 | `lib/ui/widgets/status_bar.dart`、`lib/ui/widgets/app_menu_bar.dart` |

---

## BUG-042 窗口状态持久化名存实亡

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 调整窗口大小或位置后重启，**每次都回到默认的 1280×720**。`.claude/CLAUDE.md` 中「窗口状态持久化（位置/大小/最大化）」一项与事实不符 |
| 发现方式 | 延续 BUG-041 的思路，用脚本比对 `AppConfig` 的 33 个字段与 `lib/` 中的读取点，得到 9 个「只写不读」的字段，其中 5 个正是窗口几何 |
| 根因分析 | **两端都是半截的**：<br>① 启动端 —— `WindowOptions` 写死 `Size(1280, 720)`，从不读取配置；<br>② 保存端 —— `x`/`y` 硬编码 `0`、`isMaximized` 硬编码 `false`，注释称「没有 platform channel 拿不到位置」，然而 `windowManager.getPosition()` 完全可用，该包本就是既有依赖。更糟的是**这些假值会覆盖掉已存的真实值**；<br>③ 时机 —— 保存发生在 `AppLifecycleState.detached`，此时窗口已在销毁途中，本就取不到几何信息 |
| 修复方案 | 配置加载提前至构造 `WindowOptions` 之前，以保存的尺寸开窗；位置与最大化状态无法经 `WindowOptions` 传递，故在 `waitUntilReadyToShow` 回调中调用 `setPosition` / `maximize` 应用。<br>保存改在 `HomeScreen.onWindowClose`（BUG-040 已引入该拦截）—— 此刻窗口尚存，可取得真实的尺寸、位置与最大化状态。**两条退出路径都要保存**：无未保存内容的那条才是常态，只在有未保存内容时保存等于几乎不保存。<br>`main.dart` 中原有的 `_AppLifecycleWrapper` 唯一职责就是写入这些假值，已整体移除 |
| 其余「只写不读」字段 | `splitRatio`（分屏比例存而不复原）、`imageStorageMode` / `imageFolder`（图片设置尚未实现）—— 均属未实现功能，另行跟踪 |
| 涉及文件 | `lib/main.dart`、`lib/ui/screens/home_screen.dart` |

---

## BUG-043 Tab 键不缩进，两项设置形同虚设

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | ① 编辑器中按 Tab **不缩进**，而是把焦点移到下一个控件；② 设置中的「Tab 大小（2/4/8）」改了毫无效果；③ 设置中的「无序列表标记（- / * / +）」改了仍插入 `-` |
| 发现方式 | 沿用 BUG-042 的比对思路，检查各设置项**是否真的被读取**：`tabSize`、`enableHtml` 与 `bulletListMarker` 均仅在设置页自身被读（用于回显当前值），编辑器一概不读 |
| 排查中的一次失误 | 初次核查时凭 CLAUDE.md 中「列表标记符」的说法臆造了字段名 `listMarker` 去检索，得到「0 处读取」的结论 —— 而该名称**根本不存在**，真实字段是 `bulletListMarker`。grep 一个不存在的标识符必然返回 0，这个「0」毫无意义。CI 以 `The getter 'listMarker' isn't defined for AppConfig` 报错后才发现。**核查字段务必以定义为准，不可凭文档措辞臆断** |
| 根因分析 | `TextField` 默认把 Tab 交给焦点遍历，代码中没有任何 Tab 处理，`tabSize` 因而无人读取；无序列表动作硬编码 `'- '`，`listMarker` 同样无人读取 |
| 修复方案 | 在既有的 `_handleKeyEvent` 中拦截 Tab：按配置的宽度插入空格；有选区时对整行生效，Shift+Tab 反缩进。无序列表动作改用 `settings.listMarker` |
| 未修复项 | `enableHtml` 同样只在设置页被读取，但其「开启」语义需要真正的 HTML 渲染能力 —— 当前 HTML 块一律以等宽源码呈现，并无渲染。**不做假实现**，此项作为待实现功能单独跟踪 |
| 涉及文件 | `lib/ui/editor/source_editor.dart` |

---

## CI 基础设施说明（非代码缺陷）

2026-08-27 有一次 CI 失败于 `Install dependencies`：

```
Because marktext_plus depends on flutter_highlight any which doesn't exist
(authorization failed), version solving failed.
```

系 pub.dev 拉取依赖时的临时授权故障，与提交内容无关，Analyze 与测试均未执行。经 `workflow_dispatch` 重新触发后恢复。**遇到 `Install dependencies` 失败应先怀疑此类外部故障，而非代码。**

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
| 已知遗留 | PDF 表格单元格与脚注定义仍走原始文本：`TableNode` 的 `headers`/`rows` 是纯 `String`，没有 `inlineSpans`，需要 parser 先支持单元格内行内解析 |
| 涉及文件 | `lib/services/export_service.dart` |

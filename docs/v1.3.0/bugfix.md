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
| BUG-044 | 2026-08-27 | 代码字体设置无效；分屏比例存了不恢复 | P2 | 已修复 |
| BUG-045 | 2026-08-27 | 「在新窗口打开」设置无效，选了仍在当前窗口打开 | P2 | 已修复 |
| BUG-046 | 2026-08-27 | 所有标签页共用一个撤销栈，撤销可能取回另一文件的内容 | **P0** | 已修复 |
| BUG-047 | 2026-08-27 | 全部替换会吃掉正文：重叠匹配 + 陈旧偏移 | **P0** | 已修复 |
| BUG-048 | 2026-08-27 | 12 语言应用里存在硬编码中文界面文案 | P2 | 已修复 |
| BUG-049 | 2026-08-27 | Mermaid 日/韩/俄文节点被合并成同一个节点 | P1 | 已修复 |
| BUG-050 | 2026-08-27 | 启动/打开文件夹卡顿：侧边栏一次性递归遍历整棵目录树 | **P0** | 已修复 |
| BUG-051 | 2026-08-27 | 每次重绘都全量重扫语法高亮，大文件每次按键停顿数百毫秒 | **P0** | 已修复 |
| BUG-052 | 2026-08-27 | 字数统计：日/韩/俄文一律统计为 0，且 1MB 文档卡 280ms | P1 | 已修复 |
| BUG-053 | 2026-08-27 | 预览渐进渲染呈二次方增长，双栏模式下每次按键重放一轮 | **P0** | 已修复 |
| BUG-054 | 2026-08-27 | 重绘范围过宽：光标一动就重建命令表，配置一写就重建整个应用 | P1 | 已修复 |
| BUG-055 | 2026-08-27 | 双栏模式预览是只读的：勾选框点不动、块内编辑失效 | P1 | 已修复 |
| BUG-056 | 2026-08-27 | 自动保存全局只有一个定时器，切到另一个标签就会漏存 | **P0** | 已修复 |
| BUG-057 | 2026-08-27 | 源码编辑器销毁后 provider 仍指向已释放的控制器 | P1 | 已修复 |
| BUG-058 | 2026-08-27 | 一次拖入多张图片会互相覆盖，只剩最后一张 | P1 | 已修复 |
| BUG-059 | 2026-08-27 | 「文本方向」设置无效，选了 RTL 也没反应 | P2 | 已修复 |
| BUG-060 | 2026-08-27 | 菜单里所有快捷键都只是「画上去的」，按了没反应 | **P0** | 已修复 |
| BUG-061 | 2026-08-27 | 配置非原子写入且可并发，一次崩溃就让全部设置回到默认 | **P0** | 已修复 |
| BUG-062 | 2026-08-27 | `graph TD` 等 7 种图表导出成纯代码块；四份图表语言清单已互相漂移 | P1 | 已修复 |
| BUG-063 | 2026-08-27 | 保存会把 CRLF 文件整篇改写成 LF；状态栏恒显示「LF」 | **P0** | 已修复 |
| BUG-064 | 2026-08-27 | 五条打开路径绕过换行归一化；拖入/启动打开的文件立刻被标记为已修改 | P1 | 已修复 |
| BUG-065 | 2026-08-27 | 文件夹内搜索同步遍历整棵树、无结果上限、旧结果会覆盖新结果 | P1 | 已修复 |
| BUG-066 | 2026-08-27 | 递归监听整个项目：耗尽 inotify 配额即抛出无人接管的异常 | P1 | 已修复 |

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
| 状态 | 已修复（运行时行为待人工验证） |
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

## BUG-044 代码字体设置无效，分屏比例不恢复

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P2 |
| 状态 | 已修复 |
| 现象 | ① 设置中更改「代码字体」无任何效果，代码块始终使用平台通用等宽字体；② 拖动分屏分隔条后重启，比例回到对半 |
| 发现方式 | 以**从 `AppConfig` 提取的真实字段名**重做 BUG-043 的检查（前次手写候选名导致误判，见该条「排查中的一次失误」）。32 个字段中：4 个仅被设置页自身读取、3 个从未被读取 |
| 完整结论 | **仅设置页读取**：`enableHtml`（需 HTML 渲染能力，另行跟踪）、`codeFontFamily`（本条修复）、`textDirection`（RTL 手动覆盖，未实现）、`fileOpenBehavior`（已于 BUG-045 修复）。<br>**从未读取**：`splitRatio`（本条修复）、`imageStorageMode` / `imageFolder`（图片设置未实现）|
| 修复方案 | 代码块样式改用 `config.codeFontFamily`，并以 `monospace` 作为 `fontFamilyFallback` —— 配置的字体在目标系统上未必存在。<br>分屏比例在 `initState` 中读回并 `clamp(0.2, 0.8)`（配置文件可能被手工改成越界值），拖动时以 400ms 防抖写回，避免每帧一次磁盘写入；定时器在 `dispose` 中取消 |
| 涉及文件 | `lib/ui/editor/markdown_renderer.dart`、`lib/ui/editor/split_editor.dart` |

---

## BUG-045 「在新窗口打开」设置无效

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P2 |
| 状态 | 已修复 |
| 现象 | 设置中选择「在新窗口打开」后，从文件管理器双击 `.md` 仍在当前窗口新开标签页 |
| 根因分析 | 又一处「能力已具备、只差接线」：`_newWindow()` 早已能跨平台启动新进程（菜单「新建窗口」即用它），而 `fileOpenBehavior` 除设置页回显外无人读取。<br>关键在于**该判断应置于何处**：单实例层（Linux 的 `G_APPLICATION_HANDLES_OPEN`、Windows 的 `windows_single_instance`）位于原生侧，读不到 Dart 配置，必然把第二次启动转发进来。因此只能在接收端 `openFilesFromSecondInstance` 判断，若配置为「新窗口」再启动新进程 |
| 修复方案 | 启动逻辑提取为 `PlatformUtils.launchNewWindow({String? filePath})` 供菜单与本处共用（macOS 需 `open -n`，直接执行可执行文件只会激活既有实例）。`openFilesFromSecondInstance` 开头检查配置，为 `newWindow` 时逐个文件启动新进程后返回 |
| 提交前自查 | `FileOpenBehavior` 定义于 `app_config.dart`，而 `tab_provider.dart` 仅 import 了 `settings_provider.dart` —— Dart 的 import **不传递**，该枚举实际不可见。此问题在推送前经可见性检查发现并补齐 import，未流入 CI |
| 涉及文件 | `lib/utils/platform_utils.dart`、`lib/providers/tab_provider.dart`、`lib/ui/widgets/app_menu_bar.dart` |

---

## BUG-046 撤销历史在标签页之间串用

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | **P0** |
| 状态 | 已修复 |
| 现象 | 在标签页 A 编辑后切到标签页 B 按 Ctrl+Z，**B 的内容被替换为 A 的历史快照** —— 属内容损坏而非单纯的功能失效 |
| 根因分析 | `editorProvider` 是全局单例，`_undoStack` / `_redoStack` 各只有一份。切换标签时 `SourceEditor` 因 key 变化而重建，`initState` 把新文档压入**同一个栈**，于是栈中混杂多个文件的快照。撤销时自然可能取回另一个文件的内容 |
| 附带问题 | 撤销栈**无上限**。每 300ms 防抖压入一份**完整文档副本**，长时间编辑大文件会持续累积，内存只增不减 |
| 修复方案 | 历史改为按 `tabId` 分桶（`Map<String, List<String>>`）；`SourceEditor` / `SplitEditor` 新增必传的 `tabId`，`initState` 中先 `setHistoryTab` 再 `pushHistory`。栈上限 200 条，超出时**从最旧一端裁剪** —— 撤销针对的是近期操作。标签关闭时 `removeTab` 调用 `forgetHistory` 释放该桶 |
| 涉及文件 | `lib/providers/editor_provider.dart`、`lib/providers/tab_provider.dart`、`lib/ui/editor/source_editor.dart`、`lib/ui/editor/split_editor.dart`、`lib/ui/screens/home_screen.dart` |

---

## BUG-047 全部替换会吃掉正文

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | **P0** |
| 状态 | 已修复 |
| 现象 | 在 `aaaa` 中查找 `aa` 替换为 `b`，结果不是 `bb` 而是 **`b`** —— 少了两个字符。计数器也显示「3 处」而实际只有 2 处 |
| 根因分析 | `_findMatches` 的扫描循环写的是 `index = pos + 1`，即**每次只前进一个字符**，于是产生了**互相重叠**的匹配区间 `[0,2] [1,3] [2,4]`。`_replaceAll` 从后往前逐个 splice，后一次 splice 的区间落在前一次已经改写过的文本上，越切越短 —— 这不是「替换错了」，是**丢数据** |
| 第二个根因 | 查找栏打开期间用户仍可继续编辑正文，但 `_matches` 只在**查找词变化**时重算。文档改动后偏移全部失效，此时点「替换」就会按旧偏移改写**不相干的位置** |
| 顺带发现 | ① `_buildOptionButton` 接收 `tooltip` 参数却**从未渲染** `Tooltip`，导致 `Aa` / `\b` / `.*` 三个按钮没有任何说明；② 正则模式下扫描分支根本不做全词判断，但 `\b` 按钮照样可以点亮，属于**假开关** |
| 修复方案 | ① 扫描改为 `index = pos + pattern.length`，保证匹配不重叠；② 记录扫描时的文本快照 `_scannedText`，替换前比对，不一致则先重扫再返回；③ 监听正文控制器，正文变化时重扫但**不移动光标**（用户正在打字）；④ 「替换」后定位到刚写入位置**之后**的下一个匹配，而不是弹回第 0 个 —— 顺带杜绝了「查 a 替换成 aa」时原地死循环；⑤ 补上 `Tooltip`；⑥ 正则模式下禁用全词按钮并置灰 |
| 涉及文件 | `lib/ui/widgets/find_replace_bar.dart`、`test/ui/widgets/find_replace_bar_test.dart` |
| 验证方式 | 扫描逻辑抽为 `FindReplaceBar.findMatches` 静态方法并补 9 条单测，其中一条直接按替换全部的方式回填区间，断言 `aaaa` → `bb`，让回归表现为**正文损坏**而不只是计数不符 |

---

## BUG-048 12 语言应用里的硬编码中文界面文案

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P2 |
| 状态 | 已修复 |
| 现象 | 英文（及其余 10 种语言）界面下，工具栏提示、编辑模式提示、查找栏的「源代码/预览」切换、Mermaid 全屏查看器的标题与手势提示**全部显示中文** |
| 根因分析 | 这些控件是后加的，作者直接写了中文字面量，没有走 `AppLocalizations`。`flutter analyze` 不会报这类问题，只有把「界面里出现的字面量」和「arb 里声明的键」两边对照才看得出来 |
| 修复方案 | 复用已有键（`viewSourceCode`、`viewPreview`、`sidebarSearch`、`viewShowSidebar`/`viewHideSidebar`、`viewZoomIn`/`viewZoomOut`、`viewResetZoom`、`commandSourceMode`/`commandPreviewMode`/`commandSplitMode`），并新增 3 个键 `close`、`mermaidViewerTitle`、`mermaidViewerHint`，为 12 种语言全部补齐译文与生成代码 |
| 保留不改 | `settings_screen.dart` 中的 `'简体中文'`、`'日本語'` —— 语言选择列表**本就应当用各自的语言书写**，不是缺陷 |
| 涉及文件 | `lib/ui/widgets/app_menu_bar.dart`、`lib/ui/widgets/find_replace_bar.dart`、`lib/ui/widgets/mermaid_renderer.dart`、`lib/core/i18n/l10n/*.arb`、`lib/core/i18n/l10n/app_localizations*.dart` |
| 验证方式 | 脚本比对 arb 键集合与生成代码：250 个键、244 个无参 getter + 6 个带参方法，11 个语言实现类**无一缺项** |

---

## BUG-049 Mermaid 日/韩/俄文节点被合并成同一个节点

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 状态图 `[*] --> ひらがな` / `ひらがな --> カタカナ` 只渲染出**一个**状态；类图 `고객 <|-- 주문` 只有**一个**类；`Müller` 和 `Möller` 也会变成同一个节点 |
| 根因分析 | 三个解析器（类图、状态图、ER 图）各自用 `RegExp(r'[^a-zA-Z0-9_一-龥]')` 把标识符里「不认识」的字符换成 `_`。这个白名单只含 ASCII 和 **CJK 基本汉字区 U+4E00–U+9FA5**，于是**假名、谚文、西里尔、希腊字母、带变音符的拉丁字母全部被换成下划线**。`ひらがな` 和 `カタカナ` 都变成 `____` —— 节点按 id 入表，**第二个直接覆盖第一个** |
| 影响范围 | 本应用发行 12 种语言，其中就包括日语和韩语；这类图在这两种语言的用户手里必然出错 |
| 修复方案 | 抽出共用的 `normalizeMermaidId`（`lib/ui/editor/mermaid/parser/identifier.dart`），改用 Unicode 属性类 `[^\p{L}\p{M}\p{N}_]`（`unicode: true`）：**只折叠空白和标点，保留任何文字系统的字母**。ER 图额外保留 `-`，与原行为一致 |
| 涉及文件 | `lib/ui/editor/mermaid/parser/identifier.dart`（新增）、`class_diagram_parser.dart`、`state_diagram_parser.dart`、`er_diagram_parser.dart`、`test/ui/editor/mermaid/identifier_test.dart`（新增） |
| 验证方式 | 单测既覆盖净化函数本身（含「5 个不同名字必须得到 5 个不同 id」），也在**解析层**断言日文状态图保留两个状态、韩文类图保留两个类且边的两端 id 正确 |

---

## BUG-050 启动与打开文件夹卡顿：一次性递归遍历整棵目录树

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | **P0** |
| 状态 | 已修复 |
| 用户反馈 | 「怎么感觉现在启动打开文件好慢啊」 |
| 现象 | 启动时窗口出来后要愣好几秒才能用；打开一个稍大的项目文件夹同样卡住 |
| 根因分析 | `FileService.buildFileTree` **递归遍历整棵目录树**后才返回，侧边栏才能显示第一层。`.git`、`node_modules` 这类目录全都会被走完。而 `_restoreSideBarDirectory` 在**每次启动**都会对上次打开的目录做这件事 |
| 雪上加霜 | ① 每层里 `nodes[nodes.indexOf(node)] = ...`，`indexOf` 是线性查找，单层目录项一多就是 **O(n²)**；② 文件监听每收到一次事件（比如保存文件）就**重建整棵树**；③ 重建后展开状态全部丢失，新建/重命名文件后目录树会整个塌回去 |
| 实测数据 | 本仓库（1571 个节点）：递归 **335 ms** vs 只列一层 **0 ms**；`~/.pub-cache/hosted/pub.dev`（35887 个节点）：递归 **2643 ms** vs 只列一层 **4 ms**（**660 倍**）；1500 个同级子目录：407 ms vs 29 ms |
| 修复方案 | ① `listDirectory` 只读一层，`buildFileTree` 删除；② `FileNotifier` 用一个 `_expanded` 路径集合作为展开状态的**唯一真相**，只读取用户展开过的那些目录；③ 展开状态因此能跨刷新保留，重命名/新建后目录树不再塌陷；④ 目录读不动（权限、已删除）时返回空而不是抛异常；⑤ 排序改为不区分大小写 |
| 涉及文件 | `lib/services/file_service.dart`、`lib/providers/file_provider.dart`、`lib/models/file_node.dart`、`test/services/file_service_test.dart` |

---

## BUG-051 每次重绘都全量重扫语法高亮

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | **P0** |
| 状态 | 已修复 |
| 现象 | 文件一大，打字就明显跟不上；开着查找栏时更严重，几乎卡死 |
| 根因分析 | `HighlightingController.buildTextSpan` 是 Flutter 在**每一次重绘**时调用的（光标移动、失焦、搜索命中更新都算），而它每次都把**整篇文档**重新切行、重新跑 6 条正则。1 MB 文档一次就是 **212 ms** |
| 第二个热点 | `_highlightInline` 每前进一个位置，就对**每条正则**做 `text.substring(pos)`（最多 3 次），长段落因此退化成二次方 |
| 第三个热点 | `_applySearchHighlight` 对**每个 span** 遍历**全部匹配**，内层还有一个 `indexOf`。80000 span / 1973 个匹配时单次 **1329 ms** —— 大文件里一开搜索就是整窗冻结 |
| 修复方案 | ① 新增 `IncrementalMarkdownHighlighter`：**按行缓存 span**，比对新旧行数组的公共前缀与公共后缀，只重扫改动的那几行；② 行内扫描改用 `RegExp.allMatches(text, pos)`，带偏移且惰性，不再复制字符串；③ 搜索叠加改为**双指针归并**（两个列表本就都按文档顺序升序）；④ 超过 2 MB 的文档直接不高亮 —— 这时瓶颈已不是扫描而是 Flutter 给几十万个 span 排版，状态栏会显示「大文件已关闭语法高亮」，编辑功能不受影响 |
| 实测数据 | 50 KB：22.1 → **1.2 ms**；200 KB：48.5 → **6.2 ms**；1 MB：212 → **23.7 ms**。文本没变的重绘 1 MB 只要 14 ms。搜索叠加 80000 span：1329 → **12 ms**（**110 倍**） |
| 涉及文件 | `lib/ui/editor/syntax_highlighter.dart`、`lib/ui/editor/highlighting_controller.dart`、`lib/ui/widgets/status_bar.dart`、`lib/core/i18n/l10n/*`、`test/ui/editor/syntax_highlighter_test.dart` |
| 验证方式 | 本地用桩类型跑真实源码对拍：**3600 次随机编辑**（插入/删除/改行/追加字符）下增量结果与全量重扫**逐 span 完全一致**；搜索叠加新旧算法 **2000 组随机输入**结果一致。两者都断言拼回的文本等于原文 |

---

## BUG-052 字数统计把日/韩/俄文算成 0

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 写日文、韩文、俄文时状态栏词数恒为 **0**；`café` 被算成 2 个词；1 MB 文档每次统计卡 280 ms |
| 根因分析 | `countWords` 只认两个字符类：`[\u4e00-\u9fa5]`（汉字基本区）按字计，`[a-zA-Z0-9]+` 按词计。**假名、谚文、西里尔、希腊字母一个都不匹配**，于是完全不计数；带变音符的拉丁字母会把词从中间断开。性能上则是三遍正则加一次 `replaceAll` 复制出整篇文档的副本，跑在 UI isolate 上，打字停顿 300 ms 后就会抖一下 |
| 修复方案 | 改为**单遍遍历码点**：CJK 与假名、谚文按字计（这几种语言本来就这么报字数），其余「非空白非标点」的码点按词计。字符数改按**码点**计，一个 emoji 算 1 个字符而不是 2 |
| 实测数据 | 1 MB 文档：280 → **13 ms**（**21 倍**） |
| 涉及文件 | `lib/services/word_count_service.dart`、`test/services/word_count_service_test.dart`（新增） |

---

## BUG-053 预览渐进渲染呈二次方增长

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | **P0** |
| 状态 | 已修复 |
| 现象 | 预览大文档时底部的转圈要转很久；双栏模式下一边打字，右侧预览会反复「塌回顶部再慢慢长出来」 |
| 根因分析 | 渐进渲染每帧只增加**固定 50 个块**，而每一帧又要把**已渲染的全部块重新构建一遍**（外层是 `Column`，不是惰性列表），总构建量因此是二次方。20000 个块要 **400 帧、401 万次控件构建** —— 60fps 下就是**近 7 秒的持续掉帧** |
| 第二个根因 | 内容一变就把 `_renderedNodeCount` 重置为 0。双栏模式下编辑防抖 300ms 触发一次，于是**每 300ms 重放一轮上述过程**，预览也就跟着塌回顶部 |
| 第三个根因 | 每一帧给每个标题**重新 `GlobalKey()`**。key 变了等于控件身份变了，Flutter 只能丢弃并重建该标题的整个 element，等于每帧都白做一遍 |
| 修复方案 | ① 批次改为**倍增**（50 → 100 → 200 …，上限每帧 2000）；② 内容变化时保留已渲染数量，只做上下界裁剪；③ 标题 key 按**序号**缓存复用 —— 按序号而不是按行号，是因为两个标题可能被报在同一行，同一个 GlobalKey 在树里出现两次会直接崩溃（参见 v1.2.2 的重复 GlobalKey 问题）；④ 批次调度加 `_batchScheduled` 去重，避免一帧内重复登记 |
| 实测数据 | 1000 个块：20 帧 / 10500 次 → **6 帧 / 2550 次**；5000 个块：100 帧 / 252500 次 → **8 帧 / 11350 次（22×）**；20000 个块：400 帧 / 401 万次 → **16 帧 / 12.4 万次（32×）** |
| 遗留 | 外层仍是 `SingleChildScrollView` + `Column`，全部块都会实例化。换成 `ListView.builder` 可以只构建可见块，但会影响 `SelectionArea` 的跨屏选择（预览富文本复制依赖它）与标题 GlobalKey 滚动定位，需要单独设计，留待后续版本 |
| 涉及文件 | `lib/ui/editor/markdown_renderer.dart` |

---

## BUG-054 重绘范围过宽

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 移动光标、拖动分栏条这类与内容无关的操作，也会带来整屏级别的重建开销 |
| 根因分析 | ① `HomeScreen.build` 里 `ref.watch(editorProvider)` 订阅的是**整个编辑器状态**，而 `cursorLine`/`cursorCol` 每移动一次光标就变，于是整个主界面每次光标移动都重建 —— 但它实际只用到 `showFindReplace` 一个字段；② `build` 里还调用 `_registerCommands`，每次都 `clear()` 后重新构造三十来个 `Command`，连带三十多次带参本地化字符串格式化；③ `MarkTextPlusApp.build` 里 `ref.watch(settingsProvider)` 订阅**整份配置**，任何一次写入（分栏条位置防抖写、已打开文件列表、上次检查更新时间、窗口几何）都会重建整个 `MaterialApp`；④ 每次重建都新造一个 `ThemeData`（要构建全部组件子主题）；⑤ `windowManager.setBrightness` 作为副作用写在 `build` 里，每次重建都发一次平台通道调用 |
| 修复方案 | ① `HomeScreen` 改用 `editorProvider.select((s) => s.showFindReplace)`；② 命令表按 `AppLocalizations` 实例身份缓存，只在切换语言时重建；③ 应用根改用 `settingsProvider.select((c) => c.themeName)`；④ `AppTheme.getTheme` 按主题名缓存 `ThemeData`（共 8 个且不可变）；⑤ 亮度只在真正变化时才下发 |
| 顺带优化 | 换行归一化先判断有没有 `\r` 再动手 —— 替换会复制出两份完整文档，而多数文件根本没有回车符。5 MB 文档：30 → **4.6 ms**，而且这件事在打开文件时会做**两遍**（`FileService` 一次、`HighlightingController` 一次） |
| 涉及文件 | `lib/app.dart`、`lib/core/theme/app_theme.dart`、`lib/ui/screens/home_screen.dart`、`lib/services/file_service.dart`、`lib/ui/editor/highlighting_controller.dart` |

---

## BUG-055 双栏模式预览是只读的

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 单独的预览模式里点任务列表的勾选框、双击块内编辑都正常；一切到**双栏模式**，右侧预览就完全点不动 |
| 根因分析 | `SplitEditor` 构造 `MarkdownRenderer` 时**没有传 `onSourceChanged`**。`_toggleTask` 与 `_commitEdit` 一开头就 `if (onChanged == null) return;`，于是静默失效 —— 不报错、不提示，看起来就是「点了没反应」 |
| 为何不能直接补上回调 | 回写要让左侧源码面板同步。但 `SourceEditor` 只在 `initState` 读一次 `initialContent`，之后不再理会。而**不能拿内容本身当同步信号**：打字时父组件持有的副本总比编辑器控制器**慢一个按键**，若据此覆盖控制器，正好会吃掉刚敲进去的那个字符 |
| 修复方案 | 给 `SourceEditor` 加一个 `externalRevision` 计数器：只有**预览侧发起**的改写才递增它，`didUpdateWidget` 仅在该计数变化时才采纳新内容，并把光标位置按新长度做钳制保留。打字回显路径计数不变，因此完全不受影响 |
| 顺带修复 | `_onContentChanged` 原本每个按键都 `setState`，只为把刚产生的文本再喂回 `SourceEditor.initialContent` —— 而该字段根本不会被二次读取。去掉这次 `setState`，每个按键少重建一整个源码编辑器 |
| 涉及文件 | `lib/ui/editor/split_editor.dart`、`lib/ui/editor/source_editor.dart` |

---

## BUG-056 自动保存会漏掉标签页

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | **P0** |
| 状态 | 已修复 |
| 现象 | 开着自动保存，先改标签页 A，紧接着切到标签页 B 也改一下 —— **A 的改动永远不会被写盘**，而界面上没有任何异样提示 |
| 根因分析 | `TabNotifier` 只有**一个** `_autoSaveTimer`。`_scheduleAutoSave(tabId)` 一上来就 `_autoSaveTimer?.cancel()`，取消的是**上一个标签页**的待保存任务，而且不会重新排期。于是在自动保存延迟窗口内切换标签，前一个文档就被静默跳过 |
| 严重性 | 用户开自动保存正是为了不用操心保存。这里的失败是**静默**的：文件没写，而用户以为写了 |
| 修复方案 | 定时器改为按 `tabId` 分桶（`Map<String, Timer>`），各标签互不干扰；定时器触发后自行从表中移除；`dispose` 取消全部；关闭标签页时取消它自己的待保存任务，避免对着已不存在的标签触发 |
| 涉及文件 | `lib/providers/tab_provider.dart` |
| 相关 | 与 BUG-046（撤销栈全局共享）同源：**本该按文档隔离的状态被做成了全局单例** |

---

## BUG-057 源码编辑器销毁后 provider 仍指向已释放的控制器

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 从源码模式切到**预览模式**后按 Ctrl+F，查找栏搜的是**切换那一刻的文本快照** —— 之后在预览里改的内容一概搜不到 |
| 根因分析 | `SourceEditor.initState` 会把自己的 `TextEditingController` 注册进 `editorProvider`，但 `dispose` 只 `dispose()` 控制器，**从不归还注册**。切到预览模式后源码编辑器被销毁，provider 里那个指针依然非空，只是指向一个已释放的对象。而 `HomeScreen` 判断「当前有没有源码编辑器」用的正是「controller 是否为 null」，于是走进了 `FindReplaceBar(textController: controller)` 分支，而不是本该走的 `rawContent` 分支 |
| 为何以前没崩 | 旧代码只读 `controller.text`，读一个已释放的 `ChangeNotifier` 不会断言，所以表现为「搜到的是旧内容」而不是崩溃。BUG-047 给查找栏加了 `addListener` 之后，同一条路径就会在 debug 下直接断言失败 |
| 修复方案 | `EditorNotifier` 新增 `clearController` / `clearEditorScrollController`，`SourceEditor.dispose` 在释放前归还注册。两者都做**同一性判断**后再清空 —— 切换模式时新编辑器会先于旧编辑器销毁完成注册，无条件清空反而会把新的抹掉 |
| 连带修复 | 预览模式下 controller 变回 null，查找栏因此正确走 `rawContent` 分支，搜的是实时内容 |
| 涉及文件 | `lib/providers/editor_provider.dart`、`lib/ui/editor/source_editor.dart` |
| 已知遗留 | 预览模式下的编辑（勾选框、块内编辑）走的是 `tabProvider.updateContent`，**不进撤销栈**，因此 Ctrl+Z 撤不回来。要修好需要把撤销历史的载体从「控制器」改成「文档文本」，属于设计调整，留待后续版本 |

---

## BUG-058 一次拖入多张图片会互相覆盖

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 一次选中多张图片拖进编辑器，Markdown 里插入了多条 `![image](...)`，但**多数指向同一个文件**，磁盘上只剩最后一张 |
| 根因分析 | 目标文件名用 `${baseName}_${millisecondsSinceEpoch}${ext}` 保证唯一。但 `_handleImageDrop` 是一个循环，`File.copy` 比时钟走得快 —— 同一毫秒内复制的几张会算出**完全相同的文件名**，后一次 `copy` 直接覆盖前一次 |
| 复现 | 本地对真实实现连续调用 5 次 `storeImage`，确实出现了同毫秒碰撞（第 3、4 次时间戳相同） |
| 修复方案 | 抽出 `_unusedPath`：目标已存在时追加 `-1`、`-2`… 直到空位。粘贴路径同样走这个函数 |
| 涉及文件 | `lib/services/image_service.dart`、`test/services/image_service_test.dart`（新增） |
| 验证方式 | 单测连续存 5 次同一张图，断言得到 **5 个互不相同**且都真实存在的路径 |

---

## BUG-059 「文本方向」设置无效

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P2 |
| 状态 | 已修复 |
| 现象 | 设置页里能选 LTR / RTL，选完存进了配置文件，但界面方向纹丝不动 |
| 根因分析 | `app.dart` 的 `Directionality` 写死了 `locale.languageCode == 'ar' ? rtl : ltr`，**从不读** `config.textDirection`。用「配置里声明了什么」对照「代码里读了什么」一扫就露出来了 |
| 修复方案 | 显式选择的 `'rtl'` 优先；未显式选择时仍由语言决定，阿拉伯语默认保持从右往左 |
| 涉及文件 | `lib/app.dart` |
| 同批排查结果 | 32 个配置字段逐一比对「声明 vs 读取」，改完后仅剩 `enableHtml` 一项仍未生效 —— 它的「开启」状态需要真正的 HTML 渲染能力，目前没有，属于功能缺失而非接线遗漏，记在 FEAT 待办里 |

---

## BUG-060 菜单里所有快捷键都只是「画上去的」

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | **P0** |
| 状态 | 已修复 |
| 现象 | 菜单里每一项后面都标着 Ctrl+B、Ctrl+S、Ctrl+Z…… 但**按下去几乎全都没反应**。只有 Ctrl+P / Ctrl+F / Ctrl+H 是真的，因为它们额外写在 `HomeScreen` 的 `Focus.onKeyEvent` 里；Ctrl+A / Ctrl+C / Ctrl+V / Ctrl+Z 看似能用，那是 Flutter 的 `TextField` **自带的**文本编辑快捷键，与菜单无关 |
| 根因分析 | 用的是 Material 的 `MenuBar`，其 `MenuItemButton.shortcut` **只负责显示**。Flutter SDK 源码里写得很直白：`menu_anchor.dart` 的 `shortcuts_note` 模板原话是 *"Even though the shortcut labels are displayed in the menu, **shortcuts are not automatically handled**. They must be available in whatever context they are appropriate, and handled via another mechanism."* —— 全项目搜不到任何 `ShortcutRegistry` / `Shortcuts` / `CallbackShortcuts` |
| 连带问题 | ① 设置页把 `find`/`replace`/`save`/`open`/`undo`/`redo`/`selectAll`/`duplicateLine` 列为可自定义，但菜单里这 8 项的快捷键是**硬编码**的，改了绑定连显示都不变；② 设置页还列了 `heading4/5/6`、`inlineMath`、`mathBlock`，而 `defaultKeybindings` 里**根本没有**这五项，显示为空白；③ 数学公式两个菜单项连 `shortcut:` 都没写 |
| 修复方案 | ① `KeybindingService` 新增 `activatorFor`（给菜单显示）与 `actionForEvent`（给按键匹配），**两者读同一张表**，从此不可能显示一套、执行另一套；②按作用域拆分处理位置：**编辑类**动作（全部格式化、标题、列表、撤销/重做）放在 `SourceEditor` 自己的 `Focus` 里，**窗口级**动作（打开、保存、查找、替换）放在 `HomeScreen`；这样 Ctrl+A / Ctrl+Z 在查找栏或设置输入框里仍然归那个输入框；③补齐缺失的 5 个默认绑定；④给数学项补上 `shortcut:` |
| 为什么能抢在 Flutter 前面 | Flutter 自带的文本编辑快捷键挂在 `WidgetsApp` 根部。按键事件是**从获得焦点的节点向上冒泡**的，所以编辑器与主界面上的 `Focus.onKeyEvent` 会**先于**根部的 `DefaultTextEditingShortcuts` 收到事件。这也正是撤销能走编辑器自己的历史、而不是 `TextField` 私有历史的原因 |
| 自查发现的缺陷 | 反向索引一开始**没有按平台区分缓存**。「Ctrl」在 macOS 上要解析成 Command，而缓存是首次调用时按当时的平台建的。实际运行中平台不会变，所以用户碰不到；是本地对拍时按 mac / 非 mac 各跑一遍才暴露出来的，已改为缓存连同平台标记一起校验 |
| 涉及文件 | `lib/services/keybinding_service.dart`、`lib/ui/widgets/app_menu_bar.dart`、`lib/ui/screens/home_screen.dart`、`lib/ui/editor/source_editor.dart`、`test/services/keybinding_service_test.dart`（新增） |
| 补充加固 | `_save()` 是 fire-and-forget（调用方不 await），写失败会变成**无人接管的异步异常**。已加 try/catch —— 内存里的绑定这一会话内依然正确，不该因为写盘失败而把整个应用带崩。另暴露 `pendingWrite` 供测试等待写入落定，以及 `configDirectory` 供测试改写目标目录，避免跑测试时覆盖开发者自己的键位配置 |
| 验证方式 | 本地用桩类型对**真实服务**跑了 20 条断言：显示格式、mac 下 Ctrl→Command、`Ctrl+S` 与 `Ctrl+Shift+S` 必须区分、`Ctrl+Z` 与 `Ctrl+Shift+Z` 必须区分、裸按键不算快捷键、改绑后索引与菜单同步更新、空绑定与非法键名都安全返回 null。仓库内单测另外断言**默认表无重复组合、每条都能解析** |

---

## BUG-061 配置非原子写入，一次崩溃就让全部设置回到默认

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | **P0** |
| 状态 | 已修复 |
| 现象 | 主题、语言、字号、窗口尺寸等**全部设置突然一起回到默认值**，没有任何提示。这也是 BUG-010 里那句「该框反复出现，根因未能静态定位」最可能的解释 |
| 根因分析 | `ConfigService.save` 直接 `File.writeAsString` **就地覆盖**：进程若在写到一半时被结束，磁盘上留下的是一个**被截断的 JSON**。`load` 解析失败后 `catch (_)` 返回 `AppConfig()` —— 于是所有设置静默归零，连坏掉的文件都会被下一次保存**覆盖掉**，用户既失去设置也失去了恢复的可能 |
| 第二个根因 | `save` 可以并发。`updateConfig` 是异步的，而拖动分栏条、打开文件、记录最近文件、关闭时写窗口几何都会调它，多次 `writeAsString` 指向同一个路径时可以**交错**，同样会写出半截文件 |
| 修复方案 | ① 先写 `config.json.tmp`（带 `flush: true`）再 `rename` 覆盖 —— rename 是原子的，磁盘上任何时刻要么是旧配置要么是新配置，不存在中间态；② 保存串行化：正在写时把新配置**排队**，只保留最后一份（每次保存携带的都是完整配置，中间态没有意义），返回同一个 future；③ 解析失败时把坏文件改名为 `config.json.corrupt` 留档，而不是让它被下一次保存悄悄覆盖 |
| 平台确认 | 本机实测 `File.rename` 覆盖已存在文件是成功的（POSIX 语义）；Windows 上 Dart 的实现走 `MoveFileEx`，同样允许覆盖 |
| 涉及文件 | `lib/core/config/config_service.dart`、`test/core/config/config_service_test.dart` |
| 验证方式 | 本地对真实实现跑：并发发起 20 次保存后，文件仍是**合法 JSON** 且内容为最后一次的值；截断的配置被正确挪到 `.corrupt` 且**内容原样保留**。仓库内单测新增 4 条覆盖同样场景（原有 3 条保留） |

---

## BUG-062 导出时 `graph TD` 等图表退化成纯代码块

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 预览里显示得好好的图表，导出成 PDF / Word / HTML 后**变成一段纯代码**。其中包括 ```graph TD —— 写流程图**最常见**的写法 |
| 根因分析 | 「哪些代码块算图表」这件事在项目里有**四份硬编码清单**：`MermaidParser.supportedTypes`（真正的那份，15 项）、`ExportService._mermaidLanguages`（11 项）、`nodeToHtml` 里内联的 `diagramLangs`（11 项）、`AppMenuBar._mermaidLanguages`（11 项）。后三份已经和第一份漂移开了 |
| 具体差异 | 导出侧**缺** `graph`、`sequenceDiagram`、`timeline`、`kanban`、`radar-beta`、`xychart`、`quadrantChart` 共 7 项；反过来多了一个 `sequence`，而 mermaid 根本没有这个标签 |
| 比「显示不对」更严重的一层 | 导出流程是**先按顺序把图表渲染成 PNG 存进 `mermaid_0`、`mermaid_1`… 再遍历文档、数到第几个图表就取第几张图**。渲染端和放置端各用一份清单，一旦不一致，**编号就会错位、放进去的是别的图**。目前两份恰好相同所以没出事，但这是随时会踩的雷 |
| 修复方案 | 删掉全部三份副本，统一调用 `MermaidParser.handlesLanguage` —— 与预览判定的是同一个函数，从此不可能「预览认、导出不认」 |
| 涉及文件 | `lib/services/export_service.dart`、`lib/ui/widgets/app_menu_bar.dart`、`test/fixtures_showcase_test.dart` |
| 验证方式 | 新增端到端断言：把 `showcase.md` 里**每一个**预览会渲染的图表块过一遍 `nodeToHtml`，都必须输出 `<pre class="mermaid">`；另断言未知标签仍退回普通代码块。本地另用桩逐个标签对拍了新旧判定，确认变化正是上述 7 增 1 减 |
| 同源问题 | 与 BUG-007（`markdown_renderer` 的 `_diagramLanguages` 错配）是同一个病根，当时只修了渲染器那一处，没有顺着找出其余三处 |

---

## BUG-063 保存会把 CRLF 文件整篇改写成 LF

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | **P0** |
| 状态 | 已修复 |
| 现象 | 打开一个 Windows 风格（CRLF）的 Markdown 文件，只改一个字保存 —— `git diff` 显示**整个文件每一行都变了**。状态栏则不论文件实际用什么，**永远显示「LF」** |
| 根因分析 | 读入时把 CRLF 归一化成 LF（这是对的，编辑器内部统一用 LF 才好处理），但**保存时直接把归一化后的内容写回**，等于悄悄替用户改写了整个文件的行尾。状态栏那个「LF」则根本是 arb 里的一个**字面量**，不是从文件读出来的 |
| 影响 | 对使用 Windows、或仓库里 `.gitattributes` 规定 CRLF 的用户，每次保存都会制造出一个全文件 diff，代码评审时几乎无法阅读。这属于**未经请求就改动用户文件** |
| 修复方案 | ① 新增 `LineEnding` 模型：读入时 `detect`，随 `TabInfo` 记住，保存时 `apply` 还原；② 文档保存**六处分散实现**（`editor_tab_bar`、`app_menu_bar` ×2、`home_screen`、`tab_provider`）统一收敛到 `FileService.saveDocument`，行尾选择不可能在一处生效、在另一处遗漏；③ 状态栏改为显示 `tab.lineEnding.label`；④ 新建文档默认 LF |
| 涉及文件 | `lib/models/line_ending.dart`（新增）、`lib/models/tab_info.dart`、`lib/services/file_service.dart`、`lib/providers/tab_provider.dart`、`lib/ui/widgets/{editor_tab_bar,app_menu_bar,status_bar}.dart`、`lib/ui/screens/home_screen.dart`、`test/models/line_ending_test.dart`（新增）、`test/services/file_service_test.dart` |
| 验证方式 | 单测断言 **CRLF 文件读入再存回逐字节一致**、LF 文件同样、CRLF 展开不会产生 `\r\r\n`；本地对真实模型跑了 12 条断言全部通过 |

---

## BUG-064 五条打开路径绕过换行归一化

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | CLAUDE.md 里记着「已修复 `\r\n` 导致 Markdown 语法失效的问题」，但实际只在**一条**打开路径上生效 |
| 根因分析 | 打开文档共有六条路径，其中**五条**直接 `File(path).readAsString()`，完全绕过 `FileService.readFile`：侧边栏点文件、文件→打开、最近文件、拖放/启动打开、预览里点本地 md 链接。只有「第二个实例转发过来的文件」走了 `FileService`。之所以看起来没问题，是因为 `HighlightingController` 在文本进入编辑器时又归一化了一次 —— 但 `tab.content` 里仍是 CRLF，而**预览和导出读的正是 `tab.content`**，所以在动手编辑之前，预览与导出看到的都是带 `\r` 的内容 |
| 同批发现 | 拖放与启动打开这两条路径读完内容后调的是 `updateContent`，而它会把 `isModified` 置为 **true** —— 于是**刚打开的文件立刻就是「已修改」状态**：关闭时会弹未保存确认，自动保存也会无谓地重写一遍文件 |
| 修复方案 | 五条路径统一改走 `FileService.readFileWithLineEnding`（隔离读取那两条因为要跨 isolate，改为在主 isolate 侧归一化）；`loadTabContent` 增加行尾参数，且它**不会**把标签置为已修改 |
| 涉及文件 | `lib/ui/widgets/side_bar.dart`、`lib/ui/widgets/app_menu_bar.dart`、`lib/ui/screens/home_screen.dart`、`lib/ui/editor/markdown_renderer.dart`、`lib/providers/tab_provider.dart` |
| 教训 | 与 BUG-062 同型：**同一件事有多份实现时，修好一份不等于修好了这件事**。这次直接把出口收敛成一个函数，而不是逐个打补丁 |

---

## BUG-065 文件夹内搜索会卡死界面

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 在稍大的项目文件夹里用侧边栏搜索，**窗口会整个卡住**；搜常见词时结果列表长得没有意义 |
| 根因分析 | ① `_searchInDirectory` 用的是 **`dir.listSync()`** —— 同步遍历整棵目录树，跑在 UI isolate 上，搜索期间界面完全无响应；② **没有结果上限**，搜一个常见词会产出几万条 `_SearchResult`，每条都带路径和整行文本，全部塞进 `ListView`；③ 只跳过 `.` 开头的目录，**`node_modules` 之类照读不误**；④ 每一行都重新执行一次 `query.toLowerCase()`；⑤ **没有代次控制** —— 前一次搜索若比后一次慢，它的 `setState` 会把新结果**覆盖**掉 |
| 修复方案 | ① 改用异步 `dir.list()`；② 结果上限 500 条，达到即停止遍历；③ 跳过 `node_modules`、`vendor`、`build`、`dist`、`target`；④ 查询词进入递归前就转小写一次；⑤ 引入 `_searchGeneration`，每层递归和写回结果前都校验，过期的搜索直接放弃 |
| 关于上限 | 上限做成**可见**的：达到上限时计数显示为 `500+` 而不是 `500`，不让「只搜到这些」和「搜够了就停」看起来一样 |
| 实测数据 | 构造 60 个 docs 文档 + 400 个 node_modules 包，搜 `the`：**122 ms / 读 460 个文件 / 6 万条结果** → **1 ms / 读 3 个文件 / 500 条**。而这 122 ms 原本是**同步阻塞**在 UI 线程上的，真实仓库会是数秒 |
| 涉及文件 | `lib/ui/widgets/side_bar.dart` |

---

## BUG-066 递归监听整个项目会耗尽 inotify 配额

| 字段 | 内容 |
|------|------|
| 发现日期 | 2026-08-27 |
| 优先级 | P1 |
| 状态 | 已修复 |
| 现象 | 在较大的项目目录上打开侧边栏，可能直接抛异常；被监听的目录若在使用中被删除，同样会抛 |
| 根因分析 | `dir.watch(recursive: true)` 在 Linux 上是**每个子目录一个 inotify watch**，大型项目很容易超过 `fs.inotify.max_user_watches`（常见默认 8192）。而 `listen(...)` **没有 `onError`**，流上的错误会成为**无人接管的异步异常** —— 在 Flutter 里这会直接把应用带崩，代价却只是「目录树不会自动刷新」这么点事 |
| 更根本的一点 | 自 BUG-050 把目录树改成惰性加载后，界面上**只显示用户展开过的那几层**。为了刷新这几层而递归监听整棵树，本身就不成比例 |
| 修复方案 | ① 监听范围改为**恰好是当前展开的那些目录**，非递归；② 每次树刷新后**对账**（新增的加订阅、不再需要的退订），而不是全部重订 —— 重订会无谓地翻腾文件描述符；③ 每个订阅各自 `onError`，失败只让那个目录停止自动刷新，不影响其余部分，更不会把应用带崩 |
| 涉及文件 | `lib/services/file_watcher_service.dart`、`lib/providers/file_provider.dart`、`test/services/file_watcher_service_test.dart`（新增） |
| 验证方式 | 本地对真实实现验证五种情形：只订阅 a 时改动 b 不触发、加订阅 b 后改动 b 触发一次、退订 a 后改动 a 不触发、订阅不存在的目录不抛异常、**监听中的目录被删除后程序仍在运行**。仓库内单测覆盖同样五项 |

---

## CI 基础设施说明（非代码缺陷）

2026-08-27 有一次 CI 失败于 `Install dependencies`：

```
Because marktext_plus depends on flutter_highlight any which doesn't exist
(authorization failed), version solving failed.
```

系 pub.dev 拉取依赖时的临时授权故障，与提交内容无关，Analyze 与测试均未执行。经 `workflow_dispatch` 重新触发后恢复。**遇到 `Install dependencies` 失败应先怀疑此类外部故障，而非代码。**

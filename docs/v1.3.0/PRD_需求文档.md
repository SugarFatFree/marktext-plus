# MarkText Plus v1.3.0 — 功能需求文档

本版本的目标是**对齐源项目 MarkText 的功能**，主线是 Mermaid 图表类型补全与预览模式的可编辑化。

## 总览

| 编号 | 日期 | 标题 | 优先级 | 难易度 | 状态 |
|------|------|------|--------|--------|------|
| FEAT-001 | 2026-08-27 | 预览模式所见即所得编辑（阶段一：块级） | 高 | 困难 | 已实现 |
| FEAT-002 | 2026-08-27 | Mermaid 补齐 erDiagram / journey / gitGraph / mindmap | 高 | 困难 | 已实现 |
| FEAT-003 | 2026-08-27 | Mermaid 新增 quadrantChart（象限图） | 中 | 中等 | 已实现 |
| FEAT-004 | 2026-08-27 | 关闭未保存内容时给出确认 | 高 | 中等 | 已实现 |
| FEAT-005 | 2026-08-27 | 记忆并恢复窗口几何与会话 | 中 | 简单 | 已实现 |
| FEAT-006 | 2026-08-27 | GitHub Actions 持续集成与 Windows/Linux 构建产物 | 高 | 简单 | 已实现 |
| FEAT-007 | 2026-08-27 | 大文件与大目录的性能基线 | 高 | 困难 | 已实现 |
| FEAT-008 | 2026-08-27 | Mermaid 补齐 requirementDiagram / sankey / block / C4 | 中 | 困难 | 待实现 |

## 详细需求

### FEAT-001 — 预览模式所见即所得编辑（阶段一：块级）

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-27 |
| 优先级 | 高 |
| 难易度 | 困难 |
| 需求描述 | 源项目 MarkText 的核心卖点就是「预览即编辑」。本项目原先预览模式是**只读控件树**，只能切回源码模式修改 |
| 用户场景 | 1. 在预览里双击某个段落/标题/代码块，就地改，回车提交<br>2. 点任务列表的勾选框直接切换 `[ ]` / `[x]`<br>3. 双栏模式下同样可用，左侧源码面板同步更新 |
| 实现方案 | 1. AST 节点记录 `sourceStart` / `sourceEnd`，配合 `MarkdownParser.sourceOfBlock` 与 `replaceBlock`，做到「改哪块就只重写哪块源码」<br>2. `MarkdownRenderer` 新增 `onSourceChanged` 回调与 `_wrapEditable`（双击进入编辑）<br>3. 任务列表**不走**双击包装 —— 手势竞技场的双击等待会让单击勾选延迟约 300ms<br>4. `SplitEditor` 通过 `externalRevision` 计数把预览侧的改写推给源码面板（详见 BUG-055） |
| 涉及文件 | `lib/services/markdown_parser.dart`、`lib/ui/editor/markdown_renderer.dart`、`lib/ui/editor/split_editor.dart`、`lib/ui/editor/source_editor.dart` |
| 验收标准 | 1. 预览模式双击段落进入编辑，Esc 取消、失焦提交<br>2. 勾选框单击即响应，无可感知延迟<br>3. 双栏模式下预览的改动立即反映到左侧源码，且不吃掉正在输入的字符 |
| 后续 | 阶段二为**行内**富文本编辑（直接在渲染结果上编辑而非编辑块源码），留待后续版本 |

---

### FEAT-002 — Mermaid 补齐 erDiagram / journey / gitGraph / mindmap

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-27 |
| 优先级 | 高 |
| 难易度 | 困难 |
| 需求描述 | 源项目内置 mermaid v11，支持全部图表类型；本项目为**纯 Dart 实现**（不依赖 WebView），此前缺失四种常用类型 |
| 实现方案 | 每种类型一套 `models` + `parser` + `painter` + `layout`，接入 `MermaidParser` 的类型检测、解析分派、`supportedTypes` 与 `MermaidDiagram` 的画笔分派 |
| 涉及文件 | `lib/ui/editor/mermaid/{models,parser,painter,layout}/` |
| 验收标准 | `test/fixtures/showcase.md` 中每种类型都能解析为已知类型且不为 `unknown` |

---

### FEAT-003 — Mermaid 新增 quadrantChart（象限图）

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-27 |
| 优先级 | 中 |
| 难易度 | 中等 |
| 需求描述 | 支持 mermaid 的 `quadrantChart`：把一批条目按两个维度打分，画进四个带标签的象限里 |
| 用户场景 | 产品/运营做优先级排布（影响面 × 投入）、竞品定位图等 |
| 实现方案 | 1. `QuadrantChartData` / `QuadrantPoint` 模型；`y` 按**自下而上**存储（与 mermaid 的书写直觉一致，绘制时再翻转）<br>2. 解析支持：`title`、`x-axis A --> B`（无箭头时只命名低端）、`quadrant-1..4`、`标签: [x, y] radius: r, color: #rgb`<br>3. 坐标越界钳制到 `[0,1]`，否则会画到图外<br>4. 颜色支持 `#rgb` / `#rrggbb` / `#aarrggbb`；无法解析时返回 null 用默认色，而不是猜一个<br>5. 象限编号按 mermaid 约定：**1 = 右上，逆时针**<br>6. `QuadrantChartLayout` 保证绘图区为正方形，四周留出坐标轴文案的余量；y 轴文案旋转 90° 沿轴排布 |
| 涉及文件 | `lib/ui/editor/mermaid/models/quadrant_chart.dart`（新增）<br>`lib/ui/editor/mermaid/parser/quadrant_parser.dart`（新增）<br>`lib/ui/editor/mermaid/painter/quadrant_painter.dart`（新增）<br>`lib/ui/editor/mermaid/layout/layout_engine.dart`<br>`lib/ui/editor/mermaid/models/diagram.dart`、`parser/mermaid_parser.dart`、`widgets/mermaid_diagram.dart` |
| 验收标准 | 1. mermaid 官方文档中的完整示例能正确解析出标题、两条轴的四个端点标签、四个象限标签与全部数据点<br>2. `radius:` 与 `color:` 修饰生效<br>3. 光有 `quadrantChart` 一行时返回 null（回退显示源码），而不是画一个空框<br>4. `handlesLanguage('quadrantChart')` 为真 |

---

### FEAT-004 — 关闭未保存内容时给出确认

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-27 |
| 优先级 | 高 |
| 难易度 | 中等 |
| 需求描述 | 关闭标签页、批量关闭、关闭窗口三条路径原先都会**静默丢弃**未保存内容 |
| 实现方案 | `EditorTabBar` 统一 `_askAboutUnsavedChanges` / `_askAboutUnsavedTabs`；`HomeScreen` 用 `window_manager` 的 `setPreventClose` + `onWindowClose` 接管窗口关闭 |
| 涉及文件 | `lib/ui/widgets/editor_tab_bar.dart`、`lib/ui/screens/home_screen.dart`、`lib/main.dart` |
| 验收标准 | 三条路径都弹出「保存 / 不保存 / 取消」，取消时不关闭 |
| 备注 | 详见 BUG-038、BUG-039、BUG-040 |

---

### FEAT-005 — 记忆并恢复窗口几何与会话

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-27 |
| 优先级 | 中 |
| 难易度 | 简单 |
| 需求描述 | 窗口大小/位置/最大化状态、分栏比例原先「存了但从不读」，每次启动都回到默认值 |
| 实现方案 | 配置在 `WindowOptions` **之前**加载；位置与最大化状态在 `waitUntilReadyToShow` 里补齐；分栏比例在 `SplitEditor.initState` 读取 |
| 涉及文件 | `lib/main.dart`、`lib/ui/screens/home_screen.dart`、`lib/ui/editor/split_editor.dart` |
| 验收标准 | 重启后窗口尺寸、位置、最大化状态与分栏比例均与关闭时一致 |
| 备注 | 详见 BUG-042、BUG-044 |

---

### FEAT-006 — GitHub Actions 持续集成与 Windows/Linux 构建产物

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-27 |
| 优先级 | 高 |
| 难易度 | 简单 |
| 需求描述 | 本机不具备执行完整 Flutter 构建的资源，需要把 `flutter analyze` / `flutter test` 与两个平台的构建都放到 CI |
| 实现方案 | `analyze` 作业跑分析与测试；`build-linux` 打 tar.gz，`build-windows` 直接上传目录（Action 本身会打包，再套一层压缩会让用户解压两次）；产物保留 14 天；支持 `workflow_dispatch` 手动重跑；`concurrency` 开 `cancel-in-progress` |
| 涉及文件 | `.github/workflows/ci.yml`（新增） |
| 验收标准 | 每次推送 `main` / `dev` 自动跑；分析与测试零错误零警告；两个平台的产物可直接下载 |

---

### FEAT-007 — 大文件与大目录的性能基线

| 字段 | 内容 |
|------|------|
| 实现日期 | 2026-08-27 |
| 优先级 | 高 |
| 难易度 | 困难 |
| 需求描述 | 用户反馈「启动打开文件好慢」。目标是做到**轻量、秒开、占用低、支持大文件** |
| 实现方案 | 目录树改惰性加载；语法高亮改按行增量缓存；搜索高亮改双指针归并；字数统计改单遍码点扫描；预览渐进渲染改倍增批次；收窄重绘订阅范围 |
| 实测结果 | 打开文件夹（35887 节点）2643 → **4 ms**；预览 20000 块 401 万 → **12.4 万**次控件构建；大文件搜索重绘 1329 → **12 ms**；1MB 字数统计 280 → **13 ms**；1MB 按键 212 → **24 ms** |
| 涉及文件 | 见 BUG-050 ~ BUG-054 |
| 验收标准 | 上述场景均不再出现可感知停顿；超过 2 MB 的文档关闭语法高亮并在状态栏说明，编辑功能不受影响 |
| 遗留 | 预览外层仍是 `SingleChildScrollView` + `Column`，未虚拟化（见 BUG-053 遗留项） |

---

### FEAT-008 — Mermaid 补齐 requirementDiagram / sankey / block / C4

| 字段 | 内容 |
|------|------|
| 计划日期 | 待定 |
| 优先级 | 中 |
| 难易度 | 困难 |
| 状态 | **待实现** |
| 需求描述 | 相对源项目内置的 mermaid v11，本项目仍缺 `requirementDiagram`、`sankey-beta`、`block-beta`、`C4Context` 四类 |
| 备注 | 这四类各自需要独立的布局算法（尤其 sankey 的流量守恒布局与 block 的网格布局），不适合与其他改动合并推进 |
